FROM golang:1.24 AS builder

WORKDIR /app

COPY go.mod go.sum ./
COPY libs ./libs
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/bin/apirest ./main.go

FROM gcr.io/distroless/base-debian12

WORKDIR /app
COPY --from=builder /app/bin/apirest /app/apirest

EXPOSE 8080

ENTRYPOINT ["/app/apirest"]
