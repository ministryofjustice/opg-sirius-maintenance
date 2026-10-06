FROM node:24-alpine3.23@sha256:9ec4a2e289874ed0d722e1772ec2de45d2801541db8612f3638b26f128c69ac2 AS asset-env

WORKDIR /app

COPY assets assets
COPY package.json .
COPY package-lock.json .

RUN npm ci --ignore-scripts &&\
    npm run build

FROM golang:1.27@sha256:3680233e3204827fbdc66088528ae6d4b3d034f51d03a99d454f6de034888244 AS build-env

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
