#!/bin/bash

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
aws configure --profile s3-download-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

for file in $FILES
do
  echo "$file"
  if [[ $file == "serverless/"* ]]; then
    # get file name
    echo "serverless file"
    filename=$(basename $file)
    # get hash content of file
    hash=$(<$file)
    # Use our dedicated profile and suppress verbose messages.
    # All other flags are optional via `args:` directive.
    sh -c "aws s3 cp s3://${AWS_S3_BUCKET}/$hash.yml"

    sh -c "aws cloudformation deploy --template-file ./$hash \
        --stack-name $filename-${STAGE} \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides Stage=${STAGE}"
  fi
done

