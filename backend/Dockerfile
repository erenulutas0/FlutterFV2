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
# Piper is fetched from GitHub on every build that misses this layer's cache, so a
# deploy is only as reliable as the VPS's route to github.com. One deploy died here
# after "Failed to connect to github.com port 443 after 136070 ms" -- 136 seconds is
# not a slow download, it is a connection that never opened, which is what an AAAA
# record with no working IPv6 route looks like. Hence -4, a connect timeout short
# enough to fail fast, and retries: a release should not turn on one TCP handshake.
ARG PIPER_TTS_ARCHIVE=piper_amd64.tar.gz
ARG PIPER_TTS_DOWNLOAD_URL=https://github.com/rhasspy/piper/releases/download/v${PIPER_TTS_VERSION}/${PIPER_TTS_ARCHIVE}
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl xz-utils fontconfig fonts-dejavu-core libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt \
    && curl -4 -fsSL --connect-timeout 20 --max-time 300 \
        --retry 5 --retry-delay 5 --retry-connrefused --retry-all-errors \
        "$PIPER_TTS_DOWNLOAD_URL" -o /tmp/piper.tar.gz \
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
