FROM alpine:3.3



RUN apk add --update \
    python \
    python-dev \
    py-pip \
    build-base \
  && pip install virtualenv elasticsearch-curator==3.4 \
  && rm -rf /var/cache/apk/*


COPY curatorcron /var/spool/cron/crontabs/root
CMD crond -l 2 -f
