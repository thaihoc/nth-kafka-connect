# Giải pháp đối soát dữ liệu (Data Reconciliation)

Việc đối soát dữ liệu (data reconciliation) khi triển khai CDC từ Oracle 19c sang Elastic Search (ELS) với Kafka Connect và Debezium là một bước cực kỳ quan trọng để đảm bảo tính toàn vẹn và chính xác của dữ liệu giữa nguồn (Oracle) và ELS. Dưới đây là một số giải pháp khả thi bạn có thể xem xét để thực hiện:

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
- Có thể chia dữ liệu theo range để dễ khoanh vùng dữ liệu lỗi

Ưu điểm:
- Dễ thực hiện
- Hiệu năng tốt
- Dữ liệu phát sinh ít
- Áp dụng được cho dữ liệu cũ

Nhược điểm:
- Nếu lệch vài bản ghi, chỉ biết có lệch mà không biết chi tiết bản ghi nào

## So sánh row-by-row

Ý tưởng: kiểm tra và so sánh dữ liệu theo từng dòng dữ liệu giữa DB nguồn và DB đích.

Cách thực hiện:
- Dữ liệu khi nhận được từ Kafka thực hiện lưu vào DB đích tương ứng
- Viết Job định kỳ so sánh dữ liệu theo dừng dòng dữ liệu giữa bảng ở DB nguồn và DB đích
- Cung cấp các metrics cho hệ thống giám sát (số lượng bản ghi lệch, danh sách bản ghi lệch, ...)
- Có thể chia dữ liệu theo range để tối ưu hiệu năng và dễ dàng đối soát đối với trường hợp DB dữ liệu lớn.

Ưu điểm:
- Đảm bảo dữ liệu nhất quán (100% chính xác)
- Áp dụng được cho dữ liệu cũ

Nhược điểm:
- Rất tốn tài nguyên (CPU, RAM, I/O, network)
- Không phù hợp cho bảng lớn hàng trăm triệu bản ghi

## So sánh theo góc độ nghiệp vụ

Ý tưởng: so sánh các đối tượng dữ liệu dưới góc nhìn nghiệp vụ (ví dụ: tổng số đơn hàng, tổng số tiền, giá trị max/min ngày đặt hàng, ...)

Cách thực hiện:
- Xác định các đối tượng dữ liệu cần so sánh dưới góc nhìn nghiệp vụ
- Thực hiện tính toán trước dữ liệu ở DB nguồn và DB đích (nếu cần)
- Viết Job so sánh giữa DB nguồn và DB đích
- Cung cấp các metrics cho hệ thống giám sát

Ưu điểm:
- Đảm bảo được dữ liệu luôn khớp ở góc nhìn end-user
- Có thể tận dụng các báo cáo hoặc nhắc việc sẳn có
- Áp dụng được cho dữ liệu cũ

Nhược điểm:
- Cần phải hiểu rõ nghiệp vụ
- Không phù hợp đối vo đối với hệ thống lớn, nghiệp vụ phức tạp
- Chỉ phát hiện được sai lệch, không biết được chi tiết

## Sử dụng các công cụ bên thứ 3

Ý tưởng: áp dụng các công cụ chuyên dụng có sẳn trên thị trường hiện nay như Airbyte Data Diff, Datafold, Great Expectations...

Cách làm:
- Nghiên cứu và đánh giá các công cụ
- Lựa chọn công cụ phù hợp với nhu cầu
- Tùy chỉnh công cụ (nếu có)
- Cài đặt, cấu hình và triển khai

Ưu điểm:
- Giảm được chi phí phát triển, chỉ cần thời gian nghiên cứu cách sử dụng
- Có sẳn các báo cáo trực quan, metrics giám sát

Nhược điểm:
- Có thể tốn chi phí bản quyền
- Cần nhiều thời gian để nghiên cứu, đánh giá và lựa chọn
- Có thể cần đến hạ tầng lớn và tính toán mạnh tùy vào công cụ sử dụng
- Mức độ tùy chỉnh, mở rộng có giới hạn
- Rủi ro vấn đề lỗi ATTT có thể fix không kịp thời