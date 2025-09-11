#!/bin/bash

set -e

CONFIG_FILE="$NTH/connect-distributed.properties"

echo "bootstrap.servers=$BOOTSTRAP_SERVERS" > $CONFIG_FILE
echo "group.id=$GROUP_ID" >> $CONFIG_FILE

echo "key.converter=$KEY_CONVERTER" >> $CONFIG_FILE
echo "value.converter=$VALUE_CONVERTER" >> $CONFIG_FILE
echo "key.converter.schemas.enable=$KEY_CONVERTER_SCHEMAS_ENABLE" >> $CONFIG_FILE
echo "value.converter.schemas.enable=$VALUE_CONVERTER_SCHEMAS_ENABLE" >> $CONFIG_FILE

echo "offset.storage.topic=$OFFSET_STORAGE_TOPIC" >> $CONFIG_FILE
echo "offset.storage.replication.factor=$OFFSET_STORAGE_REPLICATION_FACTOR" >> $CONFIG_FILE

echo "status.storage.topic=$STATUS_STORAGE_TOPIC" >> $CONFIG_FILE
echo "status.storage.replication.factor=$STATUS_STORAGE_REPLICATION_FACTOR" >> $CONFIG_FILE

echo "config.storage.topic=$CONFIG_STORAGE_TOPIC" >> $CONFIG_FILE
echo "config.storage.replication.factor=$CONFIG_STORAGE_REPLICATION_FACTOR" >> $CONFIG_FILE

echo "offset.flush.interval.ms=$OFFSET_FLUSH_INTERVAL_MS" >> $CONFIG_FILE

echo "plugin.path=$PLUGIN_PATH" >> $CONFIG_FILE

echo "[$(date +"%Y-%m-%d %H:%M:%S")][NTH][INFO] Created kafka connect configuration file at $CONFIG_FILE";

exec "$@"

