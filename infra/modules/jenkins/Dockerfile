FROM jenkins/jenkins:lts-jdk21

ARG DOCKER_GID=999

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends docker.io jq curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupmod -g "${DOCKER_GID}" docker \
    && usermod -aG docker jenkins

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl --fail --silent http://localhost:8080/login || exit 1

USER jenkins

ENTRYPOINT ["/entrypoint.sh"]