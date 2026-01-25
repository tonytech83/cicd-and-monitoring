# Use the official Golang image as the base
FROM golang:1.24-alpine AS builder

# Set environment variables
ENV CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Set working directory inside the container
WORKDIR /build

# Initialize and create a new go.mod file
RUN go mod init go-counter

# Copy the entire application source
COPY . .

# Download dependencies
RUN go mod tidy

# Build the Go binary
RUN go build -o app .

# Final lightweight stage
FROM alpine:3.21 AS final

# Copy the compiled binary from the builder stage
COPY --from=builder /build/app /bin/app

# Expose the application's port
EXPOSE 8000

# Run the application
CMD ["bin/app"]