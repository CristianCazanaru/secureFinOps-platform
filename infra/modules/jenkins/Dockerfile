FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && \
    apt-get install -y docker.io jq && \
    rm -rf /var/lib/apt/lists/*
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN usermod -aG docker jenkins
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/login || exit 1
USER jenkins
ENTRYPOINT ["/entrypoint.sh"]