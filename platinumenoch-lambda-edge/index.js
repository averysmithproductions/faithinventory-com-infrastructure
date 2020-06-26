exports.handler = (event, context, callback) => {
  console.log('A', JSON.stringify(event.Records[0].cf))
  // basic auth script, for more information, visit - https://medium.com/hackernoon/serverless-password-protecting-a-static-website-in-an-aws-s3-bucket-bfaaa01b8666
  const { request } = event.Records[0].cf
  const host = request.headers.host[0].value
  const hostPieces = host.split('.')
  const environment = (hostPieces.length === 2) ? 'prod' : hostPieces[0]
  if (environment === 'prod') {
    console.log('B')
    callback(null, request)
  } else {
    console.log('C')
    // Get request headers
    const { headers } = request
    // Configure authentication
    // const authUser = '<authUser>'
    // const authPass = '<authPass>'
    // const authString = `Basic ${authUser}:${authPass}`
    // const authStrings = [
    //   `Basic ${authUser}:${authPass}` // share this authentication with others
    // ]
    const AWS = require('aws-sdk')
    AWS.config.update({region: 'us-east-1'})
    const getAuthUsers = () => new Promise( async (resolve, reject) => {
      console.log('D')
      var params = {
          KeyConditionExpression: 'partitionKey = :partitionKey',
          ExpressionAttributeValues: {
              ':partitionKey': 'published'
          },
          TableName: `${environment}-PlatinumEnochBasicAuthTable`
      }
      console.log('E', params)
      try {
        const dynamo = new AWS.DynamoDB.DocumentClient()
        const data = await dynamo.query(params).promise()
        const authStrings = data.Items.map( ({ authUser, authPass }) => `Basic ${authUser}:${authPass}`)
        resolve(authStrings)
      } catch (err) {
        reject(err)
      }
    })
    let submitted
    const body = 'Unauthorized access.'
    const response = {
        status: '401',
        statusDescription: 'Unauthorized',
        body: body,
        headers: {
            'www-authenticate': [{key: 'WWW-Authenticate', value:'Basic'}]
        }
    }
    if (headers.authorization) {
      console.log('H')
      submitted = `Basic ${Buffer.from(headers.authorization[0].value.split('Basic ')[1], 'base64').toString('ascii')}`
      getAuthUsers().then( authStrings => {
        if (authStrings.includes(submitted)) {
          console.log('I')
          callback(null, request)
        } else {
          console.log('J')
          callback(null, response)
        }
      }).catch( err => {
        console.log('K', err)
        callback(null, response)
      })
    } else {
      console.log('L')
      callback(null, response)
    }
  }
}