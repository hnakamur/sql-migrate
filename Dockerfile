# syntax = docker/dockerfile:experimental

# Use ubuntu image
FROM ubuntu:18.04
RUN apt-get update \
 && apt-get install -y curl build-essential

ARG GO_VERSION=1.14.1
ARG NFPM_VERSION=v1.2.1
ARG GHR_VERSION=0.13.0

# Download go, nfpm, and ghr
WORKDIR /tmp
RUN curl -LO https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
RUN curl -LO https://github.com/goreleaser/nfpm/releases/download/${NFPM_VERSION}/nfpm_amd64.deb
RUN curl -LO https://github.com/tcnksm/ghr/releases/download/v${GHR_VERSION}/ghr_v${GHR_VERSION}_linux_amd64.tar.gz

# Install go, nfpm, and ghr
RUN tar xf go${GO_VERSION}.linux-amd64.tar.gz -C /usr/local
RUN dpkg -i nfpm_amd64.deb
RUN tar xf ghr_v${GHR_VERSION}_linux_amd64.tar.gz --strip-component=1 -C /usr/local/bin/ ghr_v${GHR_VERSION}_linux_amd64/ghr

# Build executable to ./sql-migrate
ARG SQL_MIGRATE_VERSION
ARG SQL_MIGRATE_COMMIT
RUN curl -LO https://github.com/rubenv/sql-migrate/archive/${SQL_MIGRATE_COMMIT}.tar.gz
RUN mkdir -p /src/sql-migrate
WORKDIR /src/sql-migrate
RUN tar zxf /tmp/${SQL_MIGRATE_COMMIT}.tar.gz --strip-component=1
WORKDIR /src/sql-migrate/sql-migrate
RUN PATH=/usr/local/go/bin:$PATH go build -trimpath -tags netgo

# build tar.gz, deb, and rpm packages
WORKDIR /src/sql-migrate
COPY nfpm.yaml /src/sql-migrate/
RUN mkdir /pkg \
 && tar cf - sql-migrate/sql-migrate | gzip -9 > /pkg/sql-migrate.linux-amd64.tar.gz \
 && nfpm pkg --target /pkg/sql-migrate.amd64.deb \
 && nfpm pkg --target /pkg/sql-migrate.x86_64.rpm

### make release
ARG GITHUB_USER=hnakamur
ARG GITHUB_REPO=sql-migrate
RUN --mount=type=secret,id=github_token,target=/github_token \
   ghr -username "$GITHUB_USER" \
       -repository "$GITHUB_REPO" \
       -token $(cat /github_token) \
       -commitish "$SQL_MIGRATE_COMMIT" \
       "$SQL_MIGRATE_VERSION" \
       /pkg
