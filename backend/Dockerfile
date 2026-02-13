# Build Stage
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Run Stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Install runtime tools and Piper TTS Linux runtime.
ARG PIPER_TTS_VERSION=1.2.0
ARG PIPER_TTS_ARCHIVE=piper_amd64.tar.gz
ARG PIPER_TTS_DOWNLOAD_URL=https://github.com/rhasspy/piper/releases/download/v${PIPER_TTS_VERSION}/${PIPER_TTS_ARCHIVE}
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl xz-utils fontconfig fonts-dejavu-core libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt \
    && curl -fsSL "$PIPER_TTS_DOWNLOAD_URL" -o /tmp/piper.tar.gz \
    && tar -xzf /tmp/piper.tar.gz -C /opt \
    && rm -f /tmp/piper.tar.gz \
    && test -x /opt/piper/piper \
    && chmod +x /opt/piper/piper

# Create non-root user for security
RUN groupadd --system spring && useradd --system --gid spring spring
ENV PIPER_TTS_PATH=/opt/piper/piper
USER spring:spring

EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
