FROM node:16.13.0-alpine3.12 AS asset-env

WORKDIR /app

COPY assets assets
COPY package.json .
COPY yarn.lock .

RUN yarn && yarn build

FROM golang:1.26@sha256:983a0823d3dab83604654972fe6bbda13142a7c57f987804fbdddb9d47dad9ec AS build-env

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 65532 \
    app

ARG TARGETARCH
WORKDIR /app

COPY go.mod .
COPY go.sum .

RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -a -installsuffix cgo -o /go/bin/opg-sirius-maintenance

FROM build-env AS healthcheck-build
WORKDIR /app

COPY healthcheck healthcheck

WORKDIR /app/healthcheck
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /go/bin/healthcheck

FROM scratch

WORKDIR /go/bin

COPY --from=build-env /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build-env /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build-env /etc/passwd /etc/passwd
COPY --from=build-env /etc/group /etc/group

COPY --from=build-env /go/bin/opg-sirius-maintenance opg-sirius-maintenance
COPY --from=healthcheck-build /go/bin/healthcheck healthcheck
COPY --from=build-env /app/static static
COPY --from=asset-env /app/static static

USER app
HEALTHCHECK --interval=5s --timeout=5s --start-period=5s --retries=5 CMD [ "/go/bin/healthcheck" ]
ENTRYPOINT ["./opg-sirius-maintenance"]
