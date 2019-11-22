#!/bin/sh

set -e

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_REGION" ]; then
  echo "AWS_REGION is not set. Quitting."
  exit 1
fi

if [ -z "$STAGE" ]; then
  echo "STAGE is not set. Quitting."
  exit 1
fi

# Create a dedicated profile for this action to avoid
# conflicts with other actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
aws configure --profile push-s3-cfn <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

for file in $FILES
do
  case "$file" in
  "serverless/"*)
    # get file name
    filename=$(basename $file)
    # get hash content of file
    hash=$(cat $file)
    # Use our dedicated profile and suppress verbose messages.
    # All other flags are optional via `args:` directive.
    aws s3 cp s3://${AWS_S3_BUCKET}/${hash}.yml ./ --profile push-s3-cfn

    aws cloudformation deploy --template-file ./${hash}.yml \
        --stack-name $filename-${STAGE} \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides Stage=${STAGE} Git_Hash=${GIT_HASH} \
        --profile push-s3-cfn
  ;;
  *       ) echo no ;;
  esac
done

