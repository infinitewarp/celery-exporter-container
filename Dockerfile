FROM registry.access.redhat.com/ubi8/ubi-minimal:8.5

EXPOSE 9808 8000

WORKDIR /opt/celery-exporter
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && microdnf update \
    && microdnf install -y gzip jq procps-ng tar \
    && microdnf clean all

RUN microdnf install -y python39 python39-pip \
    && if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3.9 /usr/bin/python; fi \
    && if [[ ! -e /usr/bin/pip ]]; then ln -s /usr/bin/pip3.9 /usr/bin/pip; fi \
    && pip install -U pip \
    && pip install poetry

RUN curl https://codeload.github.com/abellotti/celery-exporter/tar.gz/refs/tags/v1.0.2 --output celery-exporter.tar.gz \
    && tar -xf celery-exporter.tar.gz --strip-components=1 \
    && rm -f celery-exporter.tar.gz \
    && poetry config virtualenvs.create false && poetry install --no-interaction

ENV PYTHONUNBUFFERED 1

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
