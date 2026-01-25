FROM node:22

# Set workdir
WORKDIR /app

# Install the required packages
RUN npm install express mariadb

# Copy all filse to workdir
COPY . .

EXPOSE 5000

# Run the application
CMD ["node", "app.js"]
