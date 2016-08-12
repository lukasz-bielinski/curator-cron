FROM ubuntu:16.10


RUN apt-get update \
&& apt-get install --yes --force-yes python-setuptools build-essential python-dev libffi-dev libssl-dev libyaml-dev git \
# install python deps && easy_install pip \ && pip install PyYAML \ && pip install elasticsearch-curator==3.4
RUN apt-get update && \
  apt-get install -y   ca-certificates --no-install-recommends && \
  apt-get clean -y
rm -rf /var/lib/apt/lists/*





COPY curatorcron /var/spool/cron/crontabs/root
CMD crond -l 2 -f
