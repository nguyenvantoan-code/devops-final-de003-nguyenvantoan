-- =============================================================================
--  database/init.sql - Khởi tạo dữ liệu cho đề 003: Quản lý công việc
--  MySQL tự chạy file này ở LẦN KHỞI ĐỘNG ĐẦU TIÊN khi được mount vào
--  /docker-entrypoint-initdb.d/  (database và user do biến MYSQL_* tạo sẵn)
-- =============================================================================
SET NAMES utf8mb4;

USE ptit_task_db;

CREATE TABLE IF NOT EXISTS tasks (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    title           VARCHAR(150) NOT NULL,
    assignee        VARCHAR(100) NOT NULL,
    priority        VARCHAR(20) NOT NULL,
    status          VARCHAR(30) NOT NULL,
    due_date        DATE NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tasks (title, assignee, priority, status, due_date) VALUES
    ('Viết Dockerfile multi-stage', 'Nguyễn Văn An', 'Cao', 'Đang làm', '2026-11-20'),
    ('Cấu hình Docker Compose', 'Trần Thị Bình', 'Cao', 'Chưa làm', '2026-11-22'),
    ('Thiết lập GitHub Actions', 'Lê Văn Cường', 'Cao', 'Chưa làm', '2026-11-25'),
    ('Cấu hình Nginx reverse proxy', 'Phạm Thị Dung', 'Trung bình', 'Hoàn thành', '2026-11-15'),
    ('Viết script khởi tạo MySQL', 'Hoàng Văn Em', 'Trung bình', 'Hoàn thành', '2026-11-14'),
    ('Viết README triển khai', 'Vũ Thị Giang', 'Thấp', 'Đang làm', '2026-11-28'),
    ('Thiết lập giám sát log', 'Đỗ Văn Hùng', 'Thấp', 'Chưa làm', '2026-12-02'),
    ('Kiểm thử smoke test', 'Ngô Thị Lan', 'Trung bình', 'Đang làm', '2026-11-26');
