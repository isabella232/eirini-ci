FROM golang:latest

ENV PATH="$GOPATH/bin:${PATH}"

RUN  apt-get update \
  && apt-get install --yes \
       --no-install-recommends \
       apt-transport-https \
       ca-certificates \
       conntrack \
       curl \
       git \
       gnupg2 \
       iptables \
       jq \
       lsb-release \
       python3-pip \
       python3-setuptools \
       shellcheck \
       software-properties-common \
       sshfs \
       sudo \
       unzip \
       vim \
       wget \
  && rm -rf /var/lib/apt/lists/*

# telepresence
RUN curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh | bash
RUN apt-get install -y --no-install-recommends telepresence

# kubectl
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl

# CF CLI
RUN wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
RUN echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
RUN sudo apt-get update && sudo apt-get install -y cf7-cli

# ginkgo && shfmt
RUN go get -u github.com/onsi/ginkgo/ginkgo github.com/onsi/gomega/...
RUN GO111MODULE="on" go get -u mvdan.cc/sh/cmd/shfmt

# goml
RUN wget --quiet --output-document /usr/bin/goml https://github.com/JulzDiverse/goml/releases/download/v0.7.0/goml-linux-amd64 && chmod +x /usr/bin/goml

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
  && sudo apt update \
  && sudo apt install -y yarn

# pack
RUN curl -sSL "https://github.com/buildpacks/pack/releases/download/v0.14.2/pack-v0.14.2-linux.tgz" | tar -C "/usr/local/bin/" --no-same-owner -xzv pack

# yq
RUN pip3 install wheel
RUN pip3 install yq

# ytt, kapp, etc.
RUN curl -L https://carvel.dev/install.sh | bash

# docker
RUN curl -L https://get.docker.com | sh
