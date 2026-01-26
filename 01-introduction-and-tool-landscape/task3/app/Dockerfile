FROM node:current-alpine3.23

# Set workdir
WORKDIR /app

# Install the required packages
RUN npm install express mariadb

# Copy only app.js file to workdir
COPY app.js .

# Create non-root user
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

# Switch to the non-root user
USER appuser

EXPOSE 5000

# Run the application
CMD ["node", "app.js"]
