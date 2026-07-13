FROM jenkins/jenkins:lts-jdk21
USER root
RUN apt-get update && \
    apt-get install -y docker.io jq && \
    rm -rf /var/lib/apt/lists/*
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]