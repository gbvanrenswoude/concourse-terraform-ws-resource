FROM alpine:3.8
LABEL maintainer "gijsbert.renswoude@nn-group.com"

ARG AWS_DEFAULT_REGION=eu-west-1
ARG TERRAFORM_VERSION=0.11.10
ARG TERRAFORM_PROVIDER_ARCHIVE_VERSION=1.1.0
ARG TERRAFORM_PROVIDER_AWS_VERSION=2.6.0
ARG TERRAFORM_PROVIDER_TEMPLATE_VERSION=1.0.0
ARG TERRAFORM_PROVIDER_TERRAFORM_VERSION=1.0.2
ARG TERRAFORM_PROVIDER_TLS_VERSION=1.2.0
ARG TERRAFORM_PROVIDER_LOCAL_VERSION=1.1.0
ARG TERRAFORM_PROVIDER_NULL_VERSION=1.0.0
ARG KUBECTL_VERSION=v1.12.0


RUN apk add --update --upgrade --no-cache jq bash curl

# add python to be able to run py scripts in tf.
RUN apk -v --update add \
        python3-dev \
        groff \
        less \
        mailcap \
        zip \
        && \
        rm /var/cache/apk/*

RUN pip3 install --no-cache --upgrade \
        pip \
        setuptools && \
    pip3 install --no-cache --upgrade \
        awscli \
        botocore \
        boto3

RUN curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/darwin/amd64/kubectl . && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

RUN aws s3 cp s3://yourbuckettobuildaws-iam-auth/aws-iam-authenticator . && \
    chmod +x aws-iam-authenticator && \
    mv aws-iam-authenticator /usr/local/bin/

# mount aws creds dir
VOLUME /root/.aws

# Use custom-terraform-plugins folder to prevent downloading all the time (pay less and gain speed)
# Downloaded from https://releases.hashicorp.com/terraform-provider-aws/
RUN curl -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-aws_${TERRAFORM_PROVIDER_AWS_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-aws/${TERRAFORM_PROVIDER_AWS_VERSION}/terraform-provider-aws_${TERRAFORM_PROVIDER_AWS_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-terraform_${TERRAFORM_PROVIDER_TERRAFORM_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-terraform/${TERRAFORM_PROVIDER_TERRAFORM_VERSION}/terraform-provider-terraform_${TERRAFORM_PROVIDER_TERRAFORM_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-template_${TERRAFORM_PROVIDER_TEMPLATE_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-template/${TERRAFORM_PROVIDER_TEMPLATE_VERSION}/terraform-provider-template_${TERRAFORM_PROVIDER_TEMPLATE_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-archive_${TERRAFORM_PROVIDER_ARCHIVE_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-archive/${TERRAFORM_PROVIDER_ARCHIVE_VERSION}/terraform-provider-archive_${TERRAFORM_PROVIDER_ARCHIVE_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-tls_${TERRAFORM_PROVIDER_TLS_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-tls/${TERRAFORM_PROVIDER_TLS_VERSION}/terraform-provider-tls_${TERRAFORM_PROVIDER_TLS_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-null_${TERRAFORM_PROVIDER_NULL_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-null/${TERRAFORM_PROVIDER_NULL_VERSION}/terraform-provider-null_${TERRAFORM_PROVIDER_NULL_VERSION}_linux_amd64.zip && \
    curl -o terraform-provider-local_${TERRAFORM_PROVIDER_LOCAL_VERSION}_linux_amd64.zip https://releases.hashicorp.com/terraform-provider-local/${TERRAFORM_PROVIDER_LOCAL_VERSION}/terraform-provider-local_${TERRAFORM_PROVIDER_LOCAL_VERSION}_linux_amd64.zip && \
    mkdir /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-aws_${TERRAFORM_PROVIDER_AWS_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-terraform_${TERRAFORM_PROVIDER_TERRAFORM_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-template_${TERRAFORM_PROVIDER_TEMPLATE_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-archive_${TERRAFORM_PROVIDER_ARCHIVE_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-tls_${TERRAFORM_PROVIDER_TLS_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-null_${TERRAFORM_PROVIDER_NULL_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform-provider-local_${TERRAFORM_PROVIDER_LOCAL_VERSION}_linux_amd64.zip -d /usr/lib/custom-terraform-plugins && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/local/bin/ && \
    rm -rf *.zip

ADD assets /opt/resource
ADD test /opt/test
RUN chmod +x /opt/resource/*

CMD ["/bin/sh"]
