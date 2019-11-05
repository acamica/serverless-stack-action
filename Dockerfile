FROM python:3.7-alpine

LABEL "com.github.actions.name"="S3 Download"
LABEL "com.github.actions.description"="Download files from AWS S3 bucket"

LABEL version="0.0.1"
LABEL repository="https://github.com/ia-flash/s3-download-action"
LABEL homepage="https://iaflash.fr/"
LABEL maintainer="cristianpb"

# https://github.com/aws/aws-cli/blob/master/CHANGELOG.rst
ENV AWSCLI_VERSION='1.16.238'

RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
