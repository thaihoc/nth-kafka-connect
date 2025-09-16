# Thử nghiệm triển khai CDC cho Oracle sử dụng Kafka Connect và Debezium Connector

## Môi trường

Oracle Database 19c: bật archive log mode, có LogMiner user với đầy đủ quyền cần thiết. Yêu cầu chi tiết tại: https://debezium.io/documentation/reference/2.6/connectors/oracle.html#setting-up-oracle.

Kafka cluster v3.7.0.

ElasticSearch 8.x

Kafka Connect v3.7.0: Sử dụng Debezium Connector v2.6 cho Oracle, dùng công cụ LogMiner để đọc redo log trong Oracle.

Sử dụng Podman để build và run image. OS arch: amd64.

## Kịch bản

Xây dựng luồng stream dữ liệu từ Oracle sang Elastic Search sử dụng Kafka Connect và Debezium Connector cho Oracle. Sử dụng Spring Boot để nhận dữ liệu thay đổi trên Kafka và đẩy vào ElasticSearch.

## Cài đặt 

Vì Github không thể lưu file có dung lượng quá lớn bạn cần tải source binary của Kafka và Debezium về thư mục project.

Link download Kafka: https://archive.apache.org/dist/kafka/3.7.0/kafka_2.13-3.7.0.tgz

Link download Debezium Connector: https://repo1.maven.org/maven2/io/debezium/debezium-connector-oracle/2.6.1.Final/debezium-connector-oracle-2.6.1.Final-plugin.tar.gz

Sau khi tải xong chúng ta tiến hành build image:

```bash
podman build -t nth-kafka-connect:3.7.0-oracle19c .
```
Cài đặt Oracle và Kafka theo hướng dẫn:

* Hướng dẫn cài đặt Oracle 19c sử dụng Podman: https://github.com/thaihoc/nth-oracle/blob/main/README.md
* Hướng dẫn cài đặt Kafka 3.7.0 sử dụng Podman: https://github.com/thaihoc/nth-kafka/blob/main/README.md


Giờ đây bạn đã có thể start Kafka Connect:

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

Kiểm tra Kafka connect đã được cài đặt thành công bằng cách truy cập vào URL: http://localhost:8083/. Kết quả trả về như sau:

```json
{
    "version": "3.7.0",
    "commit": "2ae524ed625438c5",
    "kafka_cluster_id": "_6ltKJ5xTh6Zq0z9MU-I6g"
}
```

## Cấu hình Oracle Database

Tham khảo hướng dẫn chi tiết của Debezium: https://debezium.io/documentation/reference/2.6/connectors/oracle.html#setting-up-oracle

#### Tạo dữ liệu mẫu để thử nghiệm

Tạo dữ liệu mẫu theo hướng dẫn được cung cấp tại: https://github.com/thaihoc/oracle-sample-db

#### Cấu hình Supplemetal Logging

Enable supplemental logging ở mức DB để phục vụ cho những event cần lưu đầy đủ thông tin dạng before/after. Chạy lệnh sau với tài khoản DBA lần lượt trên CDB và PDB1:

```sql
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
```

#### Tạo LogMiner user cho Connector

Tham khảo hướng dẫn tại: https://debezium.io/documentation/reference/2.6/connectors/oracle.html#creating-users-for-the-connector

Đăng nhập vào PDB bằng tài khoản DBA và chạy lệnh:

```sql
CREATE TABLESPACE logminer_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/ORCLPDB1/logminer_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
```

Đăng nhập vào CDB bằng tài khoản DBA và lần lượt chạy các lệnh:

```sql
CREATE TABLESPACE logminer_tbs DATAFILE '/opt/oracle/oradata/ORCLCDB/logminer_tbs.dbf'
    SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;

CREATE USER c##dbzuser IDENTIFIED BY dbz
    DEFAULT TABLESPACE logminer_tbs
    QUOTA UNLIMITED ON logminer_tbs
    CONTAINER=ALL;

GRANT CREATE SESSION TO c##dbzuser CONTAINER=ALL; 
GRANT SET CONTAINER TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$DATABASE to c##dbzuser CONTAINER=ALL; 
GRANT FLASHBACK ANY TABLE TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ANY TABLE TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT_CATALOG_ROLE TO c##dbzuser CONTAINER=ALL; 
GRANT EXECUTE_CATALOG_ROLE TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ANY TRANSACTION TO c##dbzuser CONTAINER=ALL; 
GRANT LOGMINING TO c##dbzuser CONTAINER=ALL; 

GRANT CREATE TABLE TO c##dbzuser CONTAINER=ALL; 
GRANT LOCK ANY TABLE TO c##dbzuser CONTAINER=ALL; 
GRANT CREATE SEQUENCE TO c##dbzuser CONTAINER=ALL; 

GRANT EXECUTE ON DBMS_LOGMNR TO c##dbzuser CONTAINER=ALL; 
GRANT EXECUTE ON DBMS_LOGMNR_D TO c##dbzuser CONTAINER=ALL; 

GRANT SELECT ON V_$LOG TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOG_HISTORY TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGMNR_LOGS TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGMNR_CONTENTS TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGMNR_PARAMETERS TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$LOGFILE TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$ARCHIVED_LOG TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$TRANSACTION TO c##dbzuser CONTAINER=ALL; 

GRANT SELECT ON V_$MYSTAT TO c##dbzuser CONTAINER=ALL; 
GRANT SELECT ON V_$STATNAME TO c##dbzuser CONTAINER=ALL; 
```

#### Tạo Source Connector

Trên Linux:

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d @source-oracle-connector.json
```

Trên Window PowerShell:

```bash
Invoke-WebRequest `
  -Uri http://localhost:8083/connectors `
  -Method POST `
  -ContentType "application/json" `
  -InFile "source-oracle-connector.json"
```

Response tạo thành công với status code 201 và response body:

```json
{
    "name": "nth-sample-connector",
    "config": {
        "connector.class": "io.debezium.connector.oracle.OracleConnector",
        "tasks.max": "1",
        "database.hostname": "oracle19c",
        "database.port": "1521",
        "database.user": "c##dbzuser",
        "database.password": "dbz",
        "database.dbname": "ORCLCDB",
        "topic.prefix": "nth1",
        "database.pdb.name": "ORCLPDB1",
        "database.connection.adapter": "logminer",
        "snapshot.mode": "initial",
        "schema.include.list": "NTH_SAMPLE",
        "table.include.list": "NTH_SAMPLE.STUDENTS,NTH_SAMPLE.COURSES",
        "name": "nth-sample-connector"
    },
    "tasks": [],
    "type": "source"
}
```

#### Subcribe topic để quan sát dữ liệu

Dữ liệu bảng `NTH_SAMPLE.STUDENTS`:

```bash
podman exec -it kafka370 kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic nth1.NTH_SAMPLE.STUDENTS --from-beginning
```

Dữ liệu bảng `NTH_SAMPLE.COURSES`:

```bash
podman exec -it kafka370 kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic nth1.NTH_SAMPLE.COURSES --from-beginning
```

## Tham khảo

Tài liệu Kafka Connect v3.7.0: https://kafka.apache.org/37/documentation.html#connect_overview

Kafka Connect v3.7.0 REST API Swagger: https://kafka.apache.org/37/generated/connect_rest.yaml

Tài liệu về Debezium Connector v2.6: https://debezium.io/releases/2.6/

Kiểm tra network

```bash
podman run --rm -it --network nth --cap-add=NET_RAW busybox ping kafka370
```

Đăng nhập với SQLPlus:

```bash
podman exec -it oracle19c sqlplus / as sysdba
```

Kiểm tra Supplemental Logging đã bật:

```sql
SELECT SUPPLEMENTAL_LOG_DATA_MIN,
       SUPPLEMENTAL_LOG_DATA_PK,
       SUPPLEMENTAL_LOG_DATA_UI,
       SUPPLEMENTAL_LOG_DATA_FK
FROM V$DATABASE;
```

Kết quả mong muốn: Ít nhất cột `SUPPLEMENTAL_LOG_DATA_MIN` và `SUPPLEMENTAL_LOG_DATA_PK` phải là `YES`.
