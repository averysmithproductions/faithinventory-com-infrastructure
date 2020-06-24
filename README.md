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

| stack | file | description | child repo |
|-|-|-|-|
| Global | [cloudformation/global.yaml](./cloudformation/global.yaml) | The *Global* Stack that creates the Hosted Zone Id and TLS Certificate. These resources are shared across all Child Stacks and all Environments. |  |
| Environment | [cloudformation/environment.yaml](./cloudformation/environment.yaml) | The *Parent* Stack that nests all the child stacks. It handles all updates between child stacks. |  |
| PlatinumEnoch | [cloudformation/platinumenoch.yaml](./cloudformation/platinumenoch.yaml) | The *Child* Stack that holds the front-end application. | [![faithinventory-com-platinumenoch badge](https://img.shields.io/badge/faithinventory.com-platinumenoch-%23b88e83?logo=gatsby)](https://github.com/averysmithproductions/faithinventory-com-platinumenoch) |
| ThalliumEli | [cloudformation/thalliumeli.template.yaml](./cloudformation/thalliumeli.template.yaml) | The *Child* Stack that holds the api microservices. Please note that this "template" template is designed to remove a circular dependency between this stack and BariumNahum. | [![faithinventory-com-thalliumeli badge](https://img.shields.io/badge/faithinventory.com-thalliumeli-%23b88e83?logo=javascript)](https://github.com/averysmithproductions/faithinventory-com-thalliumeli) |
| BariumNahum | [cloudformation/bariumnahum.yaml](./cloudformation/bariumnahum.yaml) | The *Child* Stack that contains the application CDN. |  |
| ArgonTimothy | [cloudformation/argontimothy.yaml](./cloudformation/argontimothy.yaml) | The *Child* Stack that maps the Hosted Zone Id and A Records to the CDN. |  |

## Diagram

Here is a diagram of what the infrastructure looks like:

![FaithInventory Infrastructure Diagram](https://user-images.githubusercontent.com/261457/85328008-f286b100-b49d-11ea-9dd5-4163790784f3.png)

## Deployment

Please note, a minimum of two environments have to be deployed, in the following order:

1. `<domainname-prefix>-global-stack`
2. `<domainname-prefix>-<environment-a>-stack`
[Optional]
3. `<domainname-prefix>-<environment-b>-stack`[Optional]
4. `<domainname-prefix>-<environment-c>-stack`[Optional]
etc...

To deploy, following the following steps

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