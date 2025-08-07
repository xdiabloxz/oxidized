FROM ruby:2.7.7

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  build-essential git-core libssh2-1-dev libssl-dev pkg-config cmake libgmp-dev && \
  apt-get autoremove -y && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN gem install oxidized --no-document

WORKDIR /root/.config/oxidized