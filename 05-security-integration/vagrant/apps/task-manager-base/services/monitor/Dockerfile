# --- Stage 1: The Builder ---
FROM golang:1.21-alpine AS builder

# Install git for fetching dependencies if necessary
RUN apk add --no-cache git

WORKDIR /app

# Copy dependency files first
# COPY go.mod go.sum* ./
COPY go.mod *.go ./
RUN go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o monitor .

# --- Stage 2: The Final Image ---
FROM alpine:3.23.3

# Add CA certificates for secure connections
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy only the compiled binary from the builder stage
COPY --from=builder /app/monitor .

# Expose Go Fiber port
EXPOSE 8080

# Run the binary
CMD ["./monitor"]