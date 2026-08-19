FROM golang:1.26-alpine AS build
WORKDIR /src
COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/freebuff-proxy ./cmd/freebuff-proxy

FROM alpine:3.20
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
WORKDIR /app
RUN mkdir -p /app/dump /app/logs
COPY --from=build /out/freebuff-proxy /usr/local/bin/freebuff-proxy
EXPOSE 3457
ENTRYPOINT ["/usr/local/bin/freebuff-proxy"]
