FROM node:16.13.0-alpine3.12 AS asset-env

WORKDIR /app

COPY assets assets
COPY package.json .
COPY yarn.lock .

RUN yarn && yarn build

FROM golang:1.25@sha256:379065f16fe8cce7949001ba9cffc827cd4b93d69495dec405befd1c13e19bb3 AS build-env

ARG TARGETARCH
WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -a -installsuffix cgo -o /go/bin/opg-sirius-maintenance

FROM alpine:3@sha256:a2d49ea686c2adfe3c992e47dc3b5e7fa6e6b5055609400dc2acaeb241c829f4

WORKDIR /go/bin

RUN apk --update --no-cache add \
    ca-certificates \
    && rm -rf /var/cache/apk/*
RUN apk --no-cache add tzdata
RUN apk upgrade --no-cache busybox libcrypto3 libssl3 musl musl-utils zlib

COPY --from=build-env /go/bin/opg-sirius-maintenance opg-sirius-maintenance
COPY --from=build-env /app/static static
COPY --from=asset-env /app/static static


RUN addgroup -S app && \
    adduser -S -g app app && \
    chown -R app:app opg-sirius-maintenance static
USER app
ENTRYPOINT ["./opg-sirius-maintenance"]
