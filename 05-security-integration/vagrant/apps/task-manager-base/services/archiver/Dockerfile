# --- Stage 1: Build ---
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /app

# Copy the Maven wrapper and pom.xml
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
# Download dependencies (this layer is cached if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline

# Copy source and build
COPY src ./src
RUN ./mvnw clean package -DskipTests

# --- Stage 2: Runtime ---
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Copy only the built JAR file from the builder stage
COPY --from=build /app/target/*.jar app.jar

# No port exposed because it's a background worker!
# Standard Spring Boot port
# EXPOSE 8080

# Environment variable for Redis
ENV REDIS_HOST=redis-db

ENTRYPOINT ["java", "-jar", "app.jar"]