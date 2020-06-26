DOMAIN_NAME=$1
ENVIRONMENT=$2
TEMPLATE=./cloudformation/environment.yaml
# work-around to enable a stack to be deployed while a previous Lambda@Edge function deletes.
# update with a newly random string when a Lambda@Edge function stops a new deployment from occuring.
# string generated from random.org.
CACHE_HASH=cpKdES
[[ $ENVIRONMENT != prod ]] && SUBDOMAIN="$ENVIRONMENT". || SUBDOMAIN=""

if [ $ENVIRONMENT != 'global' ] && [ $ENVIRONMENT != 'prod' ] && [ $ENVIRONMENT != 'dev' ] && [ $ENVIRONMENT != 'avery' ]; then
    echo "Environment $ENVIRONMENT is not valid"
    exit 1
elif [ ! -f $TEMPLATE ]; then
    echo "file $TEMPLATE does not exist"
    exit 1
else
  AWS_PROFILE=$3
  BUCKET_PREFIX=$(sed -e "s,\.,-," <<<$DOMAIN_NAME)
  PROJECT="$BUCKET_PREFIX"-"$ENVIRONMENT"-stack
  DEPLOYMENT_BUCKET=$PROJECT
  DOMAIN_NAME_REDIRECT="${SUBDOMAIN}www.${DOMAIN_NAME}"
  DOMAIN_NAME=${SUBDOMAIN}$DOMAIN_NAME

  # make a build directory to store cloudformation artifacts
  rm -rf build
  mkdir build

  if [ $ENVIRONMENT = 'global' ] ; then
    echo "------------------"
    echo "Step 1 of 2 (AWS Route 53)"
    echo "Copy the DNS Addresses from the ${DOMAIN_NAME} Hosted Zone here:"
    echo "https://console.aws.amazon.com/route53/home?region=us-east-1"
    echo "into your domain registrar's DNS records."
    echo "------------------"
    echo "Step 2 of 2 (AWS Certificate Manager)"
    echo "Click '$DOMAIN_NAME' > 'Create Record in Route 53' for each pending validation here:"
    echo "https://console.aws.amazon.com/acm/home?region=us-east-1#/"
    echo "------------------"
    GLOBAL_TEMPLATE=./cloudformation/global.yaml
    GLOBAL_STACK="$BUCKET_PREFIX"-global-stack
    # generate next stage yaml file
    aws cloudformation package                                \
        --template-file $GLOBAL_TEMPLATE                      \
        --output-template-file build/output.yaml              \
        --s3-bucket $DEPLOYMENT_BUCKET                        \
        --profile $AWS_PROFILE

    # the actual deployment step
    aws cloudformation deploy                                 \
        --template-file build/output.yaml                     \
        --stack-name $GLOBAL_STACK                            \
        --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND  \
        --profile $AWS_PROFILE                                \
        --parameter-overrides DomainName=$DOMAIN_NAME Environment=$ENVIRONMENT
  else
    # make the deployment bucket in case it doesn't exist
    aws s3 rb s3://$DEPLOYMENT_BUCKET --force --profile $AWS_PROFILE
    aws s3 mb s3://$DEPLOYMENT_BUCKET --profile $AWS_PROFILE

    # zip up PlatinumEnoch Lambda@Edge code and upload
    zip -j ./build/lambda.zip ./platinumenoch-lambda-edge/index.js
    aws s3 cp ./build/lambda.zip s3://$DEPLOYMENT_BUCKET/platinumenoch-lambda-edge/ --profile $AWS_PROFILE

    # create ThalliumEliStack with templatized <BariumNahumCDNDistributionId> environment variable
    #  this strategy removes the circular dependency between ThalliumEliStack and BariumNahumStack
    cp ./cloudformation/thalliumeli.template.yaml ./cloudformation/thalliumeli.yaml

    aws s3 sync ./cloudformation s3://$DEPLOYMENT_BUCKET/cloudformation --delete --exclude 'global.yaml' --exclude 'thalliumeli.template.yaml' --profile $AWS_PROFILE

    # if bucket and/or lambda.zip file is not found
      # seed lambda with bucket and file
    THALLIUMELI_API_BUCKET="$ENVIRONMENT"-thalliumeli-api
    aws s3api head-object --bucket $THALLIUMELI_API_BUCKET --key lambda.zip --profile $AWS_PROFILE || not_exist=true
    if [ $not_exist ]; then
      # make the thallium eli api bucket in case it doesn't exist
      aws s3 mb s3://$THALLIUMELI_API_BUCKET --profile $AWS_PROFILE
      # seed the bucket in case this file doesn't exist
      SEED_ZIPFILE=thalliumeli-lambda-seed.zip
      aws s3 cp scripts/$SEED_ZIPFILE s3://$THALLIUMELI_API_BUCKET --profile $AWS_PROFILE
      aws s3 mv s3://$THALLIUMELI_API_BUCKET/$SEED_ZIPFILE s3://$THALLIUMELI_API_BUCKET/lambda.zip --profile $AWS_PROFILE
    fi

    # generate next stage yaml file
    aws cloudformation package                                \
        --template-file $TEMPLATE                             \
        --output-template-file build/output.yaml              \
        --s3-bucket $DEPLOYMENT_BUCKET                        \
        --profile $AWS_PROFILE

    # the actual deployment step
    aws cloudformation deploy                                 \
        --template-file build/output.yaml                     \
        --stack-name $PROJECT                                 \
        --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND  \
        --profile $AWS_PROFILE                                \
        --parameter-overrides CacheHash=$CACHE_HASH DomainName=$DOMAIN_NAME DomainNameRedirect=$DOMAIN_NAME_REDIRECT Environment=$ENVIRONMENT TemplatesBucketName=$DEPLOYMENT_BUCKET

    # now connect ThalliumEliStack to BariumNahumStack
    DISTRIBUTION_ID_FRAGMENT='BARIUMNAHUM_DISTRIBUTION_ID:\
            Fn::ImportValue:\
              !Sub "${Environment}-BariumNahumCDNDistributionId"'
    sed -i '' -e "s%BARIUMNAHUM_DISTRIBUTION_ID: <BariumNahumCDNDistributionId>%$DISTRIBUTION_ID_FRAGMENT%" ./cloudformation/thalliumeli.yaml
    aws s3 cp ./cloudformation/thalliumeli.yaml s3://$DEPLOYMENT_BUCKET/cloudformation/thalliumeli.yaml --profile $AWS_PROFILE

    # apply the above patch
    aws cloudformation deploy                                 \
        --template-file build/output.yaml                     \
        --stack-name $PROJECT                                 \
        --capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND  \
        --profile $AWS_PROFILE                                \
        --parameter-overrides DomainName=$DOMAIN_NAME DomainNameRedirect=$DOMAIN_NAME_REDIRECT Environment=$ENVIRONMENT
  fi
fi