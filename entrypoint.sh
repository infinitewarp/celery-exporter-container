#!/bin/sh

#
# celery-exporter entrypoint for cloudigrade.
#

if [ -z "${ACG_CONFIG}" ]; then
  export REDIS_USERNAME=${REDIS_USERNAME:-""}
  export REDIS_PASSWORD=${REDIT_PASSWORD:-""}
  export REDIS_HOST=${REDIS_HOST:-"localhost"}
  export REDIS_PORT=${REDIS_PORT:-"6379"}
  export METRICS_PORT=${CELERY_METRICS_PORT:-"9808"}
else
  export REDIS_USERNAME="`cat $ACG_CONFIG | jq -r '.inMemoryDb.username // empty'`"
  export REDIS_PASSWORD="`cat $ACG_CONFIG | jq -r '.inMemoryDb.password // empty'`"
  export REDIS_HOST="`cat $ACG_CONFIG | jq -r '.inMemoryDb.hostname // empty'`"
  export REDIS_PORT="`cat $ACG_CONFIG | jq -r '.inMemoryDb.port // empty'`"
  export METRICS_PORT=`cat $ACG_CONFIG | jq -r '.endpoints[] | select(.app == "cloudigrade" and .name == "metrics").port'`
fi


REDIS_AUTH=""
if [ -n "${REDIS_PASSWORD}" ]; then
  REDIS_AUTH="${REDIS_USERNAME}:${REDIS_PASSWORD}@"
fi
REDIS_URL="redis://${REDIS_AUTH}${REDIS_HOST}:${REDIS_PORT}"

LOG_LEVEL="INFO"
if [ -n "${CELERY_METRICS_LOG_LEVEL}" ]; then
  LOG_LEVEL="${CELERY_METRICS_LOG_LEVEL}"
fi

RETRY_INTERVAL=1
if [ -n "${CELERY_METRICS_RETRY_INTERVAL}" ]; then
  RETRY_INTERVAL=${CELERY_METRICS_RETRY_INTERVAL}
fi

echo "Starting celery-exporter ..."
echo "  port:                    ${METRICS_PORT}"
echo "  broker-url:              redis://${REDIS_HOST}:${REDIS_PORT}"
echo "  retry-interval:          ${RETRY_INTERVAL}"
echo "  log-level:               ${LOG_LEVEL}"

BROKER_TRANSPORT_OPTIONS=""
if [ -n "${CLOUDIGRADE_ENVIRONMENT}" ]; then
  BROKER_TRANSPORT_OPTION="global_keyprefix=${CLOUDIGRADE_ENVIRONMENT}-"
  echo "  broker-transport-option: ${BROKER_TRANSPORT_OPTION}"
  BROKER_TRANSPORT_OPTIONS="--broker-transport-option ${BROKER_TRANSPORT_OPTION}"
fi

python /opt/celery-exporter/cli.py --port ${METRICS_PORT} --broker-url "${REDIS_URL}" --retry-interval ${RETRY_INTERVAL} --log-level "${LOG_LEVEL}" ${BROKER_TRANSPORT_OPTIONS}

