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

stagingfolder=$STAGE
if [ "$STAGE" = "staging" ]; then
  stagingfolder=""
fi

for gitfile in $FILES
do
  actiontype=$(echo $gitfile | cut -d' ' -f1)
  file=$(echo $gitfile | cut -d' ' -f2)
  case "$file" in
  "serverless/$stagingfolder"*)
    if [ "$actiontype" = "D" ]; then
        echo "Deleted, we should delete stack"
    else
      # get file name
      filename=$(basename $file)
      # get hash content of file
      hashfile=$(cat $file)
      hash=$(echo $hashfile | tr -d '\r')
      # Use our dedicated profile and suppress verbose messages.
      # All other flags are optional via `args:` directive.
      aws s3 cp s3://${AWS_S3_BUCKET}/${hash}.yml ./ --profile push-s3-cfn

      aws cloudformation deploy --template-file ./${hash}.yml \
          --stack-name $filename-${STAGE} \
          --capabilities CAPABILITY_NAMED_IAM \
          --parameter-overrides Stage=${STAGE} GitHash=${hash} \
          --no-fail-on-empty-changeset \
          --profile push-s3-cfn &
    fi
  ;;
  *       ) echo no ;;
  esac
done
wait

