# Chiến lược đối soát dữ liệu (Data Reconciliation)

Việc đối soát dữ liệu (data reconciliation) khi triển khai CDC từ Oracle 19c sang Elastic Search (ELS) với Kafka Connect và Debezium là một bước cực kỳ quan trọng để đảm bảo tính toàn vẹn và chính xác của dữ liệu giữa nguồn (Oracle) và ELS. 

Hiện nay cũng có một số công cụ bên thứ 3 hỗ trợ thực hiện như Airbyte Data Diff, pgCompare (Crunchy Data), Database Table Data Comparison Tool (DBSolo)... Tuy nhiên mỗi công cụ điều có ưu/nhược điểm khác nhau, và cần phải có nhiều thời gian để đánh giá và so sánh, cho dù thế nào đi nữa thì khi dùng công cụ ngoài chúng ta sẽ bị hạn chế bởi khả năng tùy chỉnh và mở rộng. Trong khi, việc sử dụng các giải pháp tự phát triển cũng không mất nhiều thời gian và mang lại nhiều lợi ích hơn. Vì vậy, nếu dự án của bạn muốn triển khai lâu dài và xem xét khả năng tùy chỉnh mở rộng là ưu tiên hàng đầu tôi khuyên bạn nên chọn giải pháp tự xây dựng.

Dưới đây là một số giải pháp/chiến lược khả thi bạn có thể xem xét để thực hiện:

## Audit Table

Ý tưởng: Ghi dữ liệu các sự kiện INSERT/UPDATE/DELETE vào bảng audit, update trạng thái CDC vào từng sự kiện để biết sự kiện nào CDC `thành công`, `thất bại` hoặc `chưa thực hiện`.

Cách thực hiện:
- Tạo bảng audit trong Oracle để ghi lại các thay đổi (INSERT/UPDATE/DELETE), mặc định trạng thái CDC là `chưa thực hiện`
- Tại DB đích, sau khi quá trình CDC đã thực hiện xong update trạng thái dữ liệu audit tương ứng trong Oracle
- Cung cấp metrics cho hệ thống giám sát gồm: số lượng/danh sách audit data đã CDC thành công, thất bại, chưa thực hiện...

Ưu điểm: 
- Dễ dàng kiểm tra và phát hiện sai lệch
- Ít ảnh hưởng đến bảng gốc
- Không ảnh hưởng khi thiết kế DB giữa DB nguồn và DB đích khác nhau

Nhược điểm: 
- Code thêm vào hệ thống nguồn để ghi dữ liệu audit và metrics giám sát => phức tạp và ảnh hưởng hiệu năng ở hệ thống nguồn
- Code thêm ở hệ thống đích lưu trạng thái CDC vào DB nguồn => điều này cũng có thể ảnh hưởng hiệu năng của DB nguồn
- Dữ liệu có thể phình to vì phải lưu thêm dữ liệu audit => cần giải quyết vấn đề tăng trưởng dữ liệu audit
- Không áp dụng được đối với liệu cũ

Mẹo: thay vì lưu dữ liệu Audit trực tiếp vào Oracle, ta có thể dùng Redis hoặc MongoDB để tối ưu hiệu năng.

## So sánh số lượng

Ý tưởng: so sánh số lượng bảng ghi giữa DB nguồn và DB đích.

Cách thực hiện:
- Tại DB đích tạo thêm bảng để lưu tổng số lượng bản ghi đã CDC thành công của từng bảng ở DB nguồn
- Khi nhận dữ liệu từ Kafka thực hiện update số lượng bản ghi
- Viết Job định kỳ so sánh số lượng bản ghi giữa DB nguồn và DB đích
- Cung cấp metrics cho hệ thống giám sát

Ưu điểm:
- Dễ thực hiện
- Hiệu năng tốt
- Dữ liệu phát sinh ít
- Không ảnh hưởng khi thiết kế DB giữa DB nguồn và DB đích khác nhau
- Áp dụng được cho dữ liệu cũ

Nhược điểm:
- Nếu lệch vài bản ghi, chỉ biết có lệch mà không biết chi tiết bản ghi nào

## So sánh row-by-row

Ý tưởng: kiểm tra và so sánh dữ liệu theo từng dòng dữ liệu giữa DB nguồn và DB đích.

Cách thực hiện:
- Dữ liệu khi nhận được từ Kafka thực hiện lưu vào DB đích tương ứng
- Viết Job định kỳ so sánh dữ liệu theo dừng dòng dữ liệu giữa bảng ở DB nguồn và DB đích
- Cung cấp các metrics cho hệ thống giám sát (số lượng bản ghi lệch, danh sách bản ghi lệch, ...)

Ưu điểm:
- Đảm bảo dữ liệu nhất quán (100% chính xác)

Nhược điểm:
- Rất tốn tài nguyên (CPU, I/O, network)
- Không phù hợp cho bảng lớn hàng trăm triệu bản ghi
