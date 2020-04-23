FROM bash:5

RUN apk add --update-cache \
    git \
    openssh-client \
    && rm -rf /var/cache/apk/*

COPY gitfile.sh /usr/local/bin/gitfile

ENTRYPOINT /usr/local/bin/gitfile