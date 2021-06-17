ARG ALPINE_VERSION=3.12
ARG CENTOS_VERSION=8

# Use Python36, insteaf of python38, because Azure-CLI depends on
ARG PYTHON_VERSION=36
ARG NODE_VERSION=12
ARG JDK_VERSION=11
ARG MAVEN_VERSION=3.6.3

ARG KUBECTL_VERSION=1.19.0
ARG DOCKER_COMPOSE_VERSION=1.28.2
ARG AWS_VERSION=2.0.30
ARG AZURE_VERSION=2.12.1-1.el7
ARG GCLOUD_SDK_VERSION=312.0.0
ARG KAFKA_VERSION=2.6.2
ARG KAFKA_SCALA_VERSION=2.13
ARG MONGO_VERSION=4.4.0

# Zulu OpenJDK builds
FROM azul/zulu-openjdk-centos:11 AS java11

FROM alpine:${ALPINE_VERSION} AS ALPINE_CURL
RUN apk add --no-cache curl

#
# Kafka CLI
#
FROM ALPINE_CURL AS KAFKA_CLI
ARG KAFKA_VERSION
ARG KAFKA_SCALA_VERSION
RUN curl -fsSL http://apache.mirrors.hoobly.com/kafka/${KAFKA_VERSION}/kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION}.tgz -o /tmp/kafka-cli.tgz \
  && mkdir -p /export/ \
  && tar -xzvf /tmp/kafka-cli.tgz -C /export/ \
  && rm /tmp/kafka-cli.tgz

#
# Mongo Shell
#
FROM ALPINE_CURL AS MONGO_SHELL
ARG MONGO_VERSION
RUN curl -fsSL https://downloads.mongodb.org/linux/mongodb-shell-linux-x86_64-ubuntu1804-${MONGO_VERSION}.tgz -o /tmp/mongodb-shell.tgz \
  && mkdir -p /export/ \
  && tar -xzvf /tmp/mongodb-shell.tgz -C /export/ \
  && rm /tmp/mongodb-shell.tgz

#
# AWS CLI
#
FROM centos:${CENTOS_VERSION} AS AWS_CLI
ARG AWS_VERSION
ARG PYTHON_VERSION
RUN dnf install -y unzip python${PYTHON_VERSION} \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_VERSION}.zip" -o "/tmp/awscli.zip" \
  && mkdir -p /export/ \
  && unzip /tmp/awscli.zip -d /tmp/ \
  && /tmp/aws/install -i /export/aws

#
# Google Cloud-SDK - XXX Try with gcr.io/google.com/cloudsdktool/cloud-sdk:slim|latest
#
FROM centos:${CENTOS_VERSION} AS GCLOUD_SDK
ARG GCLOUD_SDK_VERSION
ARG PYTHON_VERSION
RUN dnf install -y python${PYTHON_VERSION} \
  && curl "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz?hl=fr" -o "/tmp/google-cloud-sdk.tag.gz" \
  && mkdir -p /export/ \
  && tar zxvf /tmp/google-cloud-sdk.tag.gz -C /export/ \
  && rm /tmp/google-cloud-sdk.tag.gz \
  && /export/google-cloud-sdk/install.sh -q \
  && /export/google-cloud-sdk/bin/gcloud components update -q

#
# Maven
#
FROM ALPINE_CURL AS MAVEN
ARG MAVEN_VERSION
RUN curl -fsSL -o /tmp/apache-maven.tar.gz https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && mkdir -p /export/maven \
  && tar -xzf /tmp/apache-maven.tar.gz -C /export/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz

#
# Kubectl
#

FROM ALPINE_CURL AS KUBECTL
ARG KUBECTL_VERSION
RUN curl -o /tmp/kubectl -L https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/darwin/amd64/kubectl \
  && mkdir -p /export/kubectl \
  && chmod a+rx /tmp/kubectl \
  && mv /tmp/kubectl /export/kubectl

#
# Final Image
#
FROM centos:${CENTOS_VERSION}

ARG AWS_VERSION
ARG AZURE_VERSION
ARG GCLOUD_SDK_VERSION

ARG JDK_VERSION
ARG MAVEN_VERSION
ARG KUBECTL_VERSION
ARG DOCKER_COMPOSE_VERSION
ARG PYTHON_VERSION
ARG NODE_VERSION
ARG KAFKA_VERSION
ARG KAFKA_SCALA_VERSION
ARG MONGO_VERSION

# Create corresponding Env variable to easily review associated version
ENV CENTOS_VERSION=${CENTOS_VERSION}
ENV AWS_VERSION=${AWS_VERSION}
ENV AZURE_VERSION=${AZURE_VERSION}
ENV GCLOUD_SDK_VERSION=${GCLOUD_SDK_VERSION}

ENV JDK_VERSION=${JDK_VERSION}
ENV MAVEN_VERSION=${MAVEN_VERSION}
ENV KUBECTL_VERSION=${KUBECTL_VERSION}
ENV DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION}
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV NODE_VERSION=${NODE_VERSION}
ENV KAFKA_VERSION=${KAFKA_VERSION}
ENV ARG KAFKA_SCALA_VERSION=${KAFKA_SCALA_VERSION}
ENV MONGO_VERSION=${MONGO_VERSION}

# Install Tooling
RUN dnf install -y dnf-utils \
  && dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo \
  && dnf install -y sudo docker-ce-cli curl tmux wget man nano git procps openssh vim zsh libxslt expect unzip python${PYTHON_VERSION} \
  && dnf clean all

# Install JDK
COPY --from=java11 /usr/lib/jvm/zulu11-ca /usr/local/openjdk-11
ENV JAVA_HOME=/usr/local/openjdk-${JDK_VERSION}
ENV PATH=${JAVA_HOME}/jre/bin:${JAVA_HOME}/bin/:${PATH}

# Tooling
COPY --from=KAFKA_CLI /export/kafka_${KAFKA_SCALA_VERSION}-${KAFKA_VERSION} /usr/local/tools/kafka_cli
COPY --from=MONGO_SHELL /export/mongodb-linux-x86_64-ubuntu1804-${MONGO_VERSION} /usr/local/tools/mongodb_shell
COPY --from=AWS_CLI /export/aws /usr/local/tools/awscli
COPY --from=GCLOUD_SDK /export/google-cloud-sdk /usr/local/tools/gcloud-sdk
COPY --from=MAVEN /export/maven /usr/local/tools/maven
COPY --from=KUBECTL /export/kubectl /usr/local/tools/kubectl

# Docker-Compose
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
  && chmod a+x /usr/local/bin/docker-compose

# Setup PATH
ENV PATH /usr/local/tools/kafka_cli/bin:/usr/local/tools/mongodb_shell/bin:/usr/local/tools/gcloud-sdk/bin:/usr/local/tools/awscli/v2/${AWS_VERSION}/bin:${PATH}
RUN ln -s /usr/local/tools/maven/bin/mvn /usr/local/bin/ \
  && ln -s /usr/local/tools/azure/az /usr/local/bin/ \
  && ln -s /usr/local/tools/kubectl/kubectl /usr/local/bin/
ENV MAVEN_HOME /usr/local/tools/maven

# Azure-CLI
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
  && echo $'[azure-cli]\nname=Microsoft - Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' > /etc/yum.repos.d/azure-cli.repo \
  && dnf install -y azure-cli-${AZURE_VERSION} \
  && rm -rf /etc/yum.repos.d/azure-cli.repo

# Install Node, Nuxeo-CLI, NPM
RUN dnf module install -y nodejs:${NODE_VERSION} \
  && dnf clean all \
  && npm install -g nuxeo-cli yarn

# Create Nuxeo user
RUN umask 002 \
  && adduser -u 900 -G docker,root -c '' --shell /usr/bin/zsh nuxeo \
  && chmod a+rX /home/nuxeo \
  && chmod g+s /home/nuxeo/ \
  && echo "nuxeo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# install fixuid
RUN USER=nuxeo && \
  GROUP=nuxeo && \
  curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
  chown root:root /usr/local/bin/fixuid && \
  chmod 4755 /usr/local/bin/fixuid && \
  mkdir -p /etc/fixuid && \
  printf "user: $USER\ngroup: $GROUP\npaths: \n - /\n" > /etc/fixuid/config.yml

# Run last scrip to init volumes and cleanup groups
COPY bootstrap-volumes.sh /tmp/bootstrap-volumes.sh
RUN sh /tmp/bootstrap-volumes.sh && rm /tmp/bootstrap-volumes.sh

VOLUME [ "/home/nuxeo/.m2/repository" ]
WORKDIR /home/nuxeo
