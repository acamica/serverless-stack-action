#!/bin/sh

set -e

if [ -z "${{inputs.AWS_S3_BUCKET}}" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "${{inputs.AWS_ACCESS_KEY_ID}}" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "${{inputs.AWS_SECRET_ACCESS_KEY}}" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

if [ -z "${{inputs.AWS_REGION}}" ]; then
  echo "AWS_REGION is not set. Quitting."
  exit 1
fi

if [ -z "${{inputs.STAGE}}" ]; then
  echo "STAGE is not set. Quitting."
  exit 1
fi

# Create a dedicated profile for this action to avoid
# conflicts with other actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
aws configure --profile s3-download-action <<-EOF > /dev/null 2>&1
${{inputs.AWS_ACCESS_KEY_ID}}
${{inputs.AWS_SECRET_ACCESS_KEY}}
${{inputs.AWS_REGION}}
text
EOF

for file in ${{ inputs.FILES }}
do
  if [[ $file == "serverless/"* ]]; then
    # get file name
    filename=$(basename $file)
    # get hash content of file
    hash=$(<$file)
    # Use our dedicated profile and suppress verbose messages.
    # All other flags are optional via `args:` directive.
    sh -c "aws s3 cp s3://${{inputs.AWS_S3_BUCKET}}/$hash.yml"

    sh -c "aws cloudformation deploy --template-file ./$hash \
        --stack-name $filename-${{inputs.STAGE}} \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides Stage=${{inputs.STAGE}}"
  fi
done

