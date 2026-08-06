FROM jenkins/jenkins:lts-jdk21

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        docker-cli \
        docker-buildx \
        jq \
        curl \
    && rm -rf /var/lib/apt/lists/*
COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl --fail --silent http://localhost:8080/login || exit 1

USER jenkins

ENTRYPOINT ["/entrypoint.sh"]