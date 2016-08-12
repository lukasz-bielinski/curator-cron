FROM alpine:3.3

# ... do your other task related docker setup


FROM ubuntu:16.10
ENV CURATOR_VERSION=3.4

RUN apt-get update && \
  apt-get install -y pip git ca-certificates --no-install-recommends && \
  apt-get clean -y && \
rm -rf /var/lib/apt/lists/*

RUN pip install elasticsearch-curator==$CURATOR_VERSION=3.4



COPY curatorcron /var/spool/cron/crontabs/root
CMD crond -l 2 -f
