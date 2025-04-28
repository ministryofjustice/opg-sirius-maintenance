FROM node:16.13.0-alpine3.12 as asset-env

WORKDIR /app

COPY assets assets
COPY package.json .
COPY yarn.lock .

RUN yarn && yarn build

FROM golang:1.24 as build-env

WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o /go/bin/opg-sirius-maintenance

FROM alpine:3

WORKDIR /go/bin

RUN apk --update --no-cache add \
    ca-certificates \
    && rm -rf /var/cache/apk/*
RUN apk --no-cache add tzdata
RUN apk upgrade --no-cache busybox libcrypto3 libssl3

COPY --from=build-env /go/bin/opg-sirius-maintenance opg-sirius-maintenance
COPY --from=build-env /app/static static
COPY --from=asset-env /app/static static


RUN addgroup -S app && \
    adduser -S -g app app && \
    chown -R app:app opg-sirius-maintenance static
USER app
ENTRYPOINT ["./opg-sirius-maintenance"]
