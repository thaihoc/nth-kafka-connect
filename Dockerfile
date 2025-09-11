FROM eclipse-temurin:17-jdk

# Biến môi trường
ENV KAFKA_HOME=/opt/kafka_2.13-3.7.0
ENV KAFKA_CONNECT_PLUGINS=/opt/connectors
ENV NTH=/opt/nth

# Biến môi trường cấu hình Kafka Connect
ENV BOOTSTRAP_SERVERS=localhost:9092
ENV GROUP_ID=nth-connect-cluster

ENV KEY_CONVERTER=org.apache.kafka.connect.json.JsonConverter
ENV VALUE_CONVERTER=org.apache.kafka.connect.json.JsonConverter
ENV KEY_CONVERTER_SCHEMAS_ENABLE=true
ENV VALUE_CONVERTER_SCHEMAS_ENABLE=true

ENV OFFSET_STORAGE_TOPIC=nth-connect-offsets
ENV OFFSET_STORAGE_REPLICATION_FACTOR=1

ENV STATUS_STORAGE_TOPIC=nth-connect-configs
ENV STATUS_STORAGE_REPLICATION_FACTOR=1

ENV CONFIG_STORAGE_TOPIC=nth-connect-status
ENV CONFIG_STORAGE_REPLICATION_FACTOR=1

ENV OFFSET_FLUSH_INTERVAL_MS=10000

ENV PLUGIN_PATH=$KAFKA_CONNECT_PLUGINS

# Copy Kafka đã giải nén sẵn vào image
ADD kafka_2.13-3.7.0.tgz /opt

# Copy plugin Debezium vào thư mục plugins
ADD debezium-connector-oracle-2.6.1.Final-plugin.tar.gz $KAFKA_CONNECT_PLUGINS/

# Tạo config cho Kafka Connect
COPY entrypoint.sh $NTH/
RUN chmod +x $NTH/entrypoint.sh

# Mở port REST API của Kafka Connect
EXPOSE 8083

WORKDIR $KAFKA_HOME

# Chạy script tạo cấu hình
ENTRYPOINT ["/opt/nth/entrypoint.sh"]

# Start Kafka Connect
CMD ["bin/connect-distributed.sh", "/opt/nth/connect-distributed.properties"]  
