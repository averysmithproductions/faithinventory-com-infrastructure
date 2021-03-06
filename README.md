# faithinventory-com-infrastructure
[![faithinventory-com-infrastructure badge](https://img.shields.io/badge/faithinventory.com-infrastructure-%23b88e83?style=for-the-badge&logo=amazon)](https://faithinventory.com/)

Prerequisites
- [An AWS Account with programmatic permission](https://aws.amazon.com/)
- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

## Project Description

The FaithInventory Infrastructure declares the cloud environment that hosts [faithinventory.com](https://faithinventory.com).

The site is hosted using [AWS CloudFormation](https://aws.amazon.com/cloudformation/).

The CloudFormation templates are located in the [cloudformation](cloudformation/) directory.

The templates have codenames which represent the "elements" of the infrastructure. The names are:

| stack | file | description |
|-|-|-|
| Global | [cloudformation/global.yaml](./cloudformation/global.yaml) | The *Global* Stack that creates the Hosted Zone Id and TLS Certificate. These resources are shared across all Child Stacks and all Environments. <br /><br />[<img title="Global Stack icon" src="https://user-images.githubusercontent.com/261457/85490288-7ffdfa00-b59f-11ea-8754-a789c2b7e866.png" width="90" />](https://github.com/averysmithproductions/faithinventory-com-infrastructure#diagram) |
| Environment | [cloudformation/environment.yaml](./cloudformation/environment.yaml) | The *Parent* Stack that nests all the child stacks. It handles all updates between child stacks.<br /><br />[<img title="Environment Stack icon" src="https://user-images.githubusercontent.com/261457/85490288-7ffdfa00-b59f-11ea-8754-a789c2b7e866.png" width="90" />](https://github.com/averysmithproductions/faithinventory-com-infrastructure#diagram) |
| PlatinumEnoch | [cloudformation/platinumenoch.template.yaml](./cloudformation/platinumenoch.template.yaml) | The *Child* Stack that holds the front-end application. Please note that this "template" template is designed to remove a circular dependency between this stack and BariumNahum.<br /><br />[<img title="ThalliumEli icon" src="https://user-images.githubusercontent.com/261457/85481153-4a511500-b58f-11ea-8020-ec01f0b878f9.png" width="90" />](https://github.com/averysmithproductions/faithinventory-com-infrastructure#diagram)<br /><br /> PlatinumEnochS3Bucket Code Repo:<br /><br />[![faithinventory-com-platinumenoch badge](https://img.shields.io/badge/faithinventory.com-platinumenoch-%23b88e83?style=for-the-badge&logo=gatsby)](https://github.com/averysmithproductions/faithinventory-com-platinumenoch) |
| ThalliumEli | [cloudformation/thalliumeli.template.yaml](./cloudformation/thalliumeli.template.yaml) | The *Child* Stack that holds the api microservices. Please note that this "template" template is designed to remove a circular dependency between this stack and BariumNahum. <br /><br />[<img title="ThalliumEli icon" src="https://user-images.githubusercontent.com/261457/85421172-1dc2dc00-b542-11ea-8c9e-277d92efa9f7.png" width="90" />](https://github.com/averysmithproductions/faithinventory-com-infrastructure#diagram)<br /><br />ThalliumEliLambda Code Repo:<br /><br />[![faithinventory-com-thalliumeli badge](https://img.shields.io/badge/faithinventory.com-thalliumeli-%23b88e83?style=for-the-badge&logo=javascript)](https://github.com/averysmithproductions/faithinventory-com-thalliumeli) |
| BariumNahum | [cloudformation/bariumnahum.yaml](./cloudformation/bariumnahum.yaml) | The *Child* Stack that contains the application CDN.<br /><br />[<img title="BariumNahum Stack icon" src="https://user-images.githubusercontent.com/261457/85490495-db2fec80-b59f-11ea-89d1-468f0b6091d2.png" width="90" />](https://github.com/averysmithproductions/faithinventory-com-infrastructure#diagram) |
| ArgonTimothy | [cloudformation/argontimothy.yaml](./cloudformation/argontimothy.yaml) | The *Child* Stack that maps the Hosted Zone Id and A Records to the CDN.<br /><br />[<img title="ArgonTimothy Stack icon" src="https://user-images.githubusercontent.com/261457/85490620-192d1080-b5a0-11ea-94e3-a35b611d1c50.png" height="110" />](https://github.com/averysmithproductions/faithinventory-com-infrastructure#diagram) |

## Diagram

Here is a diagram of what the infrastructure looks like:

![FaithInventory Infrastructure Diagram](https://user-images.githubusercontent.com/261457/85934229-40d8ed00-b8ae-11ea-9348-8a5d55108fa1.png)

## Deployment

Please note, a minimum of two environments have to be deployed, in the following order:

1. `<domainname-prefix>-global-stack`
2. `<domainname-prefix>-<environment-a>-stack`
3. `<domainname-prefix>-<environment-b>-stack`[Optional]
4. `<domainname-prefix>-<environment-c>-stack`[Optional]
etc...

To deploy, follow these steps

### 1. Upload values to parameter store

run the following command:
`sh cp ./scripts/put-parameters.example.sh ./scripts/put-parameters.sh`
Then open './scripts/put-parameters.sh' and update the following:

| environment | variable | description |
|-|-|-|
| global | webhookId | the id used to invoke the Gatsby Cloud webhook. This is found in the gatsbyjs.com site settings. |
| prod | emailAddress | An environment credential needed for ThalliumEliSES to send magic link emails. |
| dev | emailAddress | An environment credential needed for ThalliumEliSES to send magic link emails. |

After that, go to your terminal and run the following command:
`sh ./scripts/put-parameters.sh <awsProfile>`

### 2. Deploy the global stack

Next, run the following command:
`sh ./scripts/deploy.sh faithinventory.com global <awsProfile>`

Then follow the 2 step installation process, which is:

> Step 1 of 2 (AWS Route 53)
> Copy the DNS Addresses from the ${DOMAIN_NAME} Hosted Zone here:
> [https://console.aws.amazon.com/route53/home?region=us-east-1](https://console.aws.amazon.com/route53/home?region=us-east-1)
> into your domain registrar's DNS records.

> Step 2 of 2 (AWS Certificate Manager)
> Click '$DOMAIN_NAME' > 'Create Record in Route 53' for each pending validation here:
> [https://console.aws.amazon.com/acm/home?region=us-east-1](https://console.aws.amazon.com/acm/home?region=us-east-1)

#### 3. Deploy your environment stack.

To deploy an environment stack, run:
`sh ./scripts/deploy.sh faithinventory.com prod <awsProfile>`

and/or

`sh ./scripts/deploy.sh faithinventory.com dev <awsProfile>`

and/or

`sh ./scripts/deploy.sh faithinventory.com <some-other-environment> <awsProfile>`

### Security

**All non-production environments are secured with a Basic Authenticaion Request Header.**

In order to create an username and password combination, follow these steps:

1. Navigate to (https://console.aws.amazon.com/dynamodb/home?region=us-east-1#tables:)[https://console.aws.amazon.com/dynamodb/home?region=us-east-1#tables:]
2. Click '`<environmment>-PlatinumEnochBasicAuthTable`' > 'Items'
3. Click, 'Create Item', then add the following values, replacing `<authUser>` and `<authPass>` with strings from [Random.org](https://www.random.org/strings/?num=1&len=20&digits=on&upperalpha=on&loweralpha=on&unique=on&format=html&rnd=new):

| name | value |
|-|-|
| partitionKey | 'published' |
| authUser | `<authUser>` |
| authPass | `<authPass>` |

In order to add the `<authPass>`, you should:
4. Click the plus button to the left of "authUser".
5. In the drop-down box, Click 'Append' > 'String'
6. In the "field" input, "authPass"
7. In the "value" input, enter your random password string.
8. Click, 'Save'.
9. Now, navigate to `<environment>`.faithinventory.com and enter the `<authUser>` and `<authPass>`. You should now be able to sign into the lower environment.

To add, update and/or delete auth users at a later date, just edit the '`<environment>-PlatinumEnochBasicAuthTable`', accordingly.

### Warning

Sometimes redeploying a child stack is prevented due to a Lambda@Edge reserved name from a previous deployment.

To enable new deployments to occur, follow these steps:

1. open the `./scripts/deploy.sh` file to edit it.

2. on line 7, update the `CACHE_HASH` value with a [random string](https://www.random.org/strings/?num=1&len=6&digits=on&upperalpha=on&loweralpha=on&unique=on&format=html&rnd=new).

3. re-run the deployment script, ie:

`sh ./scripts/deploy.sh faithinventory.com prod <awsProfile>`

Please keep in mind you should go into the AWS Lambda console and delete any Lambda@Edge functions that are not in use. You'll have to give AWS some time to free the function up to the point of being able to deleted. **Sometimes it can take days!**

More info about Lambda@Edge replicas and caching can be found at this link:
https://stackoverflow.com/questions/45296923/cannot-delete-aws-lambdaedge-replicas

### About the PlatinumEnochCacheInvalidator Lambda

The purpose of this lambda is to enable the PlatinumEnochS3Bucket to clear it's own cache. This is critical it receives s3 file syncs from Gatsby Cloud, and without this Lambda CloudFront would not know to clear its cache, thus preventing site updates to show.


The Lambda receives notifications from S3 via SQS.

The AWS Documentation says that SQS can detected when it's empty by analyzing the attributes:

```
ApproximateNumberOfMessagesVisible
ApproximateNumberOfMessagesNotVisible
ApproximateNumberOfMessagesDelayed
```

If they evaluate to less than or equal to 1, then that means that the queue is empty or close to empty.

- https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html#sqs-long-polling

but after further analysis and development, it appears that the SQS object doesn't have the property, `ApproximateNumberOfMessagesNotVisible`. It only has `ApproximateNumberOfMessages`.

Therefore, we will just use the `ApproximateNumberOfMessages` value instead.

Next, because of the polling mechanism behind SQS, it inconsistenly reports the above attributes as less than or equal to 1. Polling is not an accurate way to assess what's left in the queue. It's only a guess unless the poll request happens to perfectly land on the last queue or so.

So the Lambda kicks off an invalidation at the start of every log group.

The idea here is the latency between the S3 Put Object event, the SQS delay, and time CloudFront takes to invalidate will be enough time to catch clear files on S3, even though the queue messages have not actually completed yet.

Just in case, if this is on the last or so queue message in the log group, kick off an invalidation.

Ultimately, this Lambda  kicks off multiple CloudFront invalidations since multiple requests can pass this use-case.

In theory, it's better to kick off a few more invalidations than none at all. The limit of concurrent invalidations is 3000. Running 5-10 invalidations is a tolerable to perform CloudFront invalidations of S3.