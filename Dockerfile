# U,Z mount volume options are required for podman (rootless).
# the local .ssh folder should only contain the single required keypair to connect to digiges, to not leak other private keys into the container.
# > docker run --rm -v ~/.ssh:/root/.ssh:ro,U,Z -v $(pwd)/logs:/app/logs digiges-monthly-log-aggregator bash month-agg-log.sh 202603

# deno requires glibc, alpine doesn't have it, so use debian instead.
FROM debian:bullseye-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    gzip \
    unzip \
    rsync \
    curl \
    ca-certificates \
    openssh-client \
    && curl -fsSL https://deno.land/x/install/install.sh | bash -s v2.9.0 \
    && mv /root/.deno/bin/deno /usr/local/bin/deno \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY *.sh .
COPY *.ts .
COPY *.conf .

CMD ["/bin/bash"]