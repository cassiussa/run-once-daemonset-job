FROM scratch
ADD centos-7-docker.tar.xz /

LABEL maintainer = "Cassius John-Adams <cassius.s.adams@gmail.com>" \
    org.label-schema.schema-version = "1.0" \
    org.label-schema.name="CentOS Base Image" \
    org.label-schema.vendor="CentOS" \
    org.label-schema.license="GPLv2" \
    org.label-schema.build-date="20180402"

RUN yum install -y git openssh bc && \
    yum clean all && \
    rm -rf /var/cache/yum

ADD bin/* /bin/

# Seperated from above RUN for better build caching
RUN chmod +x /bin/dumb-init && \
    mkdir /scripts/ && \
    chmod +x /bin/docker && \
    tar -xvzf /bin/oc.tar.gz

COPY scripts/ /scripts/

ENTRYPOINT ["/bin/dumb-init", "--"]
