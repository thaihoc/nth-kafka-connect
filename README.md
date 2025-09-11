# Thử nghiệm triển khai CDC sử dụng Kafka Connect, Oracle và Debezium Connector

## Môi trường

Oracle Database 19c: bật archive log mode, có LogMiner user với đầy đủ quyền cần thiết. Yêu cầu chi tiết tại: https://debezium.io/documentation/reference/2.6/connectors/oracle.html#setting-up-oracle.

Kafka cluster v3.7.0.

ElasticSearch 8.x

Kafka Connect v3.7.0: Sử dụng Debezium Connector v2.6 cho Oracle, dùng cơ chế LogMiner để đọc redo log trong Oracle.

Sử dụng Podman để build và run image.

## Download Kafka và Debezium

Tải source binary của Kafka và Debezium về thư mục project.

Link download Kafka: https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz

Link download Debezium Connector: https://repo1.maven.org/maven2/io/debezium/debezium-connector-oracle/2.6.1.Final/debezium-connector-oracle-2.6.1.Final-plugin.tar.gz

## Kịch bản

Xây dựng luồng stream dữ liệu từ Oracle sang Elastic Search sử dụng Kafka Connect và Debezium Connector cho Oracle. Sử dụng Spring Boot để nhận dữ liệu thay đổi trên Kafka và đẩy vào ElasticSearch.

## Cài đặt 

Build image

```bash
podman build -t nth-kafka-connect:3.7.0-oracle19c .
```

Giả sử Oracle và Kafka đã được cài đặt trước. Start Kafka Connect:

```bash
podman run -d --network nth --name kafka-connect-370 -p 8083:8083
    -e BOOTSTRAP_SERVERS=kafka370:9092
    -e GROUP_ID=nth-connect-cluster
    nth-kafka-connect:3.7.0-oracle19c
```

Các biến môi trường hỗ trợ gồm:

| Tên biến môi trường | Tham số cấu hình tương ứng |
| ----- | --------------- |
| BOOTSTRAP_SERVERS | bootstrap.servers |
| GROUP_ID | group.id |
| KEY_CONVERTER | key.converter |
| CONFIG_FILE | value.converter | 
| KEY_CONVERTER_SCHEMAS_ENABLE | key.converter.schemas.enable |
| VALUE_CONVERTER_SCHEMAS_ENABLE | value.converter.schemas.enable |
| OFFSET_STORAGE_TOPIC | offset.storage.topic |
| OFFSET_STORAGE_REPLICATION_FACTOR | offset.storage.replication.factor |
| STATUS_STORAGE_TOPIC | status.storage.topic |
| STATUS_STORAGE_REPLICATION_FACTOR | status.storage.replication.factor |
| CONFIG_STORAGE_TOPIC | config.storage.topic
| CONFIG_STORAGE_REPLICATION_FACTOR | config.storage.replication.factor |
| OFFSET_FLUSH_INTERVAL_MS | offset.flush.interval.ms |
| PLUGIN_PATH | plugin.path |

Kiểm tra Kafka connect đang chạy bằng cách truy cập vào URL: http://localhost:8083/. Kết quả trả về như sau:

```json
{
    "version": "3.7.0",
    "commit": "2ae524ed625438c5",
    "kafka_cluster_id": "_6ltKJ5xTh6Zq0z9MU-I6g"
}
```

## Tham khảo

Tài liệu Kafka Connect v3.7.0: https://kafka.apache.org/37/documentation.html#connect_overview

Tài liệu về Debezium Connector v2.6: https://debezium.io/releases/2.6/

Kiểm tra network

```bash
podman run --rm -it --network nth --cap-add=NET_RAW busybox ping kafka370
```