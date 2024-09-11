# syntax=docker/dockerfile:1.10-labs

# https://registry.access.redhat.com/ubi8/ubi
FROM registry.access.redhat.com/ubi8/ubi:8.8-854
LABEL maintainer="Red Hat, Inc."

LABEL com.redhat.component="devfile-base-container"
LABEL name="devfile/base-developer-image"
LABEL version="ubi8"

#label for EULA
LABEL com.redhat.license_terms="https://www.redhat.com/en/about/red-hat-end-user-license-agreements#UBI"

#labels for container catalog
LABEL summary="devfile base developer image"
LABEL description="Image with base developers tools. Languages SDK and runtimes excluded."
LABEL io.k8s.display-name="devfile-developer-base"
LABEL io.openshift.expose-services=""

USER 0

# renovate: datasource=repology depName=ubi_8/curl versioning=loose
ENV CURL_VERSION="7.61.1-30.el8_8.2"

# renovate: datasource=github-releases depName=cli/cli versioning=loose
ENV GH_CLI_VERSION="v2.30.0"

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf update -y && \
    dnf install -y curl-"${CURL_VERSION}"

## gh-cli
RUN \
    TEMP_DIR="$(mktemp -d)"; \
    cd "${TEMP_DIR}"; \
    GH_ARCH="linux_amd64"; \
    GH_TGZ="gh_${GH_CLI_VERSION}_${GH_ARCH}.tar.gz"; \
    GH_TGZ_URL="https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/${GH_TGZ}"; \
    GH_CHEKSUMS_URL="https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_checksums.txt"; \
    curl -sSLO "${GH_TGZ_URL}"; \
    curl -sSLO "${GH_CHEKSUMS_URL}"; \
    sha256sum --ignore-missing -c "gh_${GH_CLI_VERSION}_checksums.txt" 2>&1 | grep OK; \
    tar -zxvf "${GH_TGZ}"; \
    mv "gh_${GH_CLI_VERSION}_${GH_ARCH}"/bin/gh /usr/local/bin/; \
    cd -; \
    rm -rf "${TEMP_DIR}"

COPY --chown=0:0 entrypoint.sh /
RUN \
    # add user and configure it
    useradd -u 10001 -G wheel,root -d /home/user --shell /bin/bash -m user && \
    # Setup $PS1 for a consistent and reasonable prompt
    echo "export PS1='\W \`git branch --show-current 2>/dev/null | sed -r -e \"s@^(.+)@\(\1\) @\"\`$ '" >> /home/user/.bashrc && \
    # Set permissions on /etc/passwd and /home to allow arbitrary users to write
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh

USER 10001
ENV HOME=/home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]
