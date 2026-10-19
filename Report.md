# HƯỚNG DẪN CHI TIẾT TỪNG BƯỚC LÀM BÀI THI CUỐI KỲ DEVOPS
## Đề 008: Quản lý thư viện (Spring Boot 4 + MySQL + Nginx)

Tài liệu này hướng dẫn chi tiết từng bước để bạn tự thực hiện bài thi kết thúc môn DevOps đạt điểm tối đa (100/100 điểm).

---

## 📑 TỔNG QUAN CÁC PHẦN THI VÀ ĐIỂM SỐ

| Phần | Nội dung | Điểm | File thực hiện |
| :---: | :--- | :---: | :--- |
| **Phần 1** | Khởi tạo repository & điền thông tin sinh viên | **10đ** | `student.env` |
| **Phần 2** | Hoàn thiện Dockerfile multi-stage cho backend | **25đ** | `Dockerfile` |
| **Phần 3** | Hoàn thiện docker-compose.yml | **20đ** | `docker-compose.yml` |
| **Phần 4** | Pipeline CI/CD với GitHub Actions | **35đ** | `.github/workflows/ci-cd.yml` |
| **Phần 5** | Chụp ảnh minh chứng & nộp bài | **10đ** | `screenshots/` & `submission-content/` |

---

## BƯỚC 1: KHỞI TẠO REPOSITORY & ĐIỀN THÔNG TIN (PHẦN 1 - 10 ĐIỂM)

### 1.1. Điền file `student.env`
Mở file [`student.env`](file:///Users/trongtri/Documents/devops/ontap_final/devops-final-app-de008/student.env) và điền đầy đủ các thông tin cá nhân. **Lưu ý:**
- Không được để trống bất kỳ trường nào (nếu để trống, pipeline CI/CD sẽ báo lỗi và dừng ngay lập tức).
- **Tuyệt đối không sửa** `EXAM_CODE="008"` và `MYSQL_DATABASE="ptit_library_db"`.
- `APP_PORT`: Đặt cổng từ `8080` trở lên (ví dụ: `8088`), tránh trùng với bạn khác hoặc port đã dùng trên VPS.
- `COMPOSE_PROJECT_NAME`: Đặt theo dạng `<tên-viết-tắt>-de008` (ví dụ: `trongtri-de008`).

**Nội dung điền mẫu cho file `student.env`:**
```properties
# ---------- 1. Thông tin sinh viên ----------
STUDENT_NAME="Đào Trọng Trí"
STUDENT_ID="PTIT062"
STUDENT_CLASS="D20CQCN01-B"
STUDENT_EMAIL="daotrongtri21092006@gmail.com"
GITHUB_USERNAME="daotrongtri"

# ---------- 2. Thông số triển khai trên server chung ----------
EXAM_CODE="008"
APP_PORT="8088"
COMPOSE_PROJECT_NAME="trongtri-de008"

# ---------- 3. Cơ sở dữ liệu MySQL ----------
MYSQL_DATABASE="ptit_library_db"
MYSQL_USER="library_user"
MYSQL_PASSWORD="library_password_123"
MYSQL_ROOT_PASSWORD="root_password_123"
```

---

## BƯỚC 2: HOÀN THIỆN DOCKERFILE MULTI-STAGE (PHẦN 2 - 25 ĐIỂM)

Mở file [`Dockerfile`](file:///Users/trongtri/Documents/devops/ontap_final/devops-final-app-de008/Dockerfile) và thay thế các ô `______` theo kỹ thuật Multi-stage build:
1. **Stage 1 (`build`)**: 
   - Dùng `FROM gradle:8.14-jdk21-alpine AS build` (Spring Boot 4 yêu cầu Gradle >= 8.14).
   - Copy `build.gradle settings.gradle ./` và chạy `RUN gradle dependencies --no-daemon` để cache layer thư viện.
   - Copy `src ./src` và chạy `RUN gradle bootJar -x test --no-daemon` đóng gói file JAR.
2. **Stage 2 (`runtime`)**:
   - Dùng `FROM eclipse-temurin:21-jre-alpine AS runtime`.
   - Nhận biến `ARG APP_VERSION=dev` gán vào `ENV APP_VERSION=${APP_VERSION}`.
   - Tạo user thường: `RUN addgroup -S spring && adduser -S spring -G spring`.
   - Copy file JAR từ stage 1: `COPY --from=build /workspace/build/libs/app.jar /app/app.jar`.
   - Chạy với quyền user thường: `USER spring:spring`.
   - Mở port backend: `EXPOSE 8080`.
   - Entrypoint dạng exec: `ENTRYPOINT ["java", "-jar", "/app/app.jar"]`.

**Nội dung hoàn chỉnh của `Dockerfile`:**
```dockerfile
# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - (multi-stage build cho Spring Boot 4 / Java 21 / Gradle)
# =============================================================================

# ---------- Stage 1: build - biên dịch & đóng gói bằng Gradle + JDK 21 ----------
FROM gradle:8.14-jdk21-alpine AS build
WORKDIR /workspace

# Copy build.gradle + settings.gradle trước, tải dependency để tận dụng cache layer
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon

# Copy mã nguồn rồi đóng gói file JAR (bỏ qua test)
COPY src ./src
RUN gradle bootJar -x test --no-daemon

# ---------- Stage 2: runtime - chỉ chứa JRE 21 + file JAR ----------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Phiên bản ứng dụng truyền vào lúc build (docker compose: build-arg APP_VERSION)
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

WORKDIR /app

# Chạy ứng dụng bằng user thường, không dùng root
RUN addgroup -S spring && adduser -S spring -G spring
# Chỉ lấy file JAR từ stage build
COPY --from=build /workspace/build/libs/app.jar /app/app.jar
USER spring:spring

EXPOSE 8080

# ENTRYPOINT dạng exec (mảng JSON)
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

---

## BƯỚC 3: HOÀN THIỆN DOCKER-COMPOSE.YML (PHẦN 3 - 20 ĐIỂM)

Mở file [`docker-compose.yml`](file:///Users/trongtri/Documents/devops/ontap_final/devops-final-app-de008/docker-compose.yml) và điền các mục `TODO 1` đến `TODO 5`:
- **TODO 1**: `context: .` và truyền `args: APP_VERSION: ${APP_VERSION:-local}`.
- **TODO 2**: Đặt tên image: `image: ${APP_IMAGE:-devops-final-app}:${APP_TAG:-latest}`.
- **TODO 3**: Lấy thông tin CSDL từ biến trong `student.env`:
  - `DB_NAME: ${MYSQL_DATABASE}`
  - `DB_USER: ${MYSQL_USER}`
  - `DB_PASSWORD: ${MYSQL_PASSWORD}`
- **TODO 4**: Nginx publish cổng cá nhân: `ports: - "${APP_PORT}:80"`.
- **TODO 5**: Mount file cấu hình Nginx read-only: `volumes: - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro`.

**Đoạn cấu hình 2 service `app` và `nginx` trong `docker-compose.yml`:**
```yaml
  # ---------------------------------------------------------------- Spring Boot
  app:
    # TODO 1: build image từ thư mục gốc của repository
    build:
      context: .
      args:
        APP_VERSION: ${APP_VERSION:-local}
    # TODO 2: tên image = <APP_IMAGE>:<APP_TAG>
    image: ${APP_IMAGE:-devops-final-app}:${APP_TAG:-latest}
    restart: unless-stopped
    environment:
      DB_HOST: mysql
      DB_PORT: "3306"
      # TODO 3: lấy tên database, tài khoản, mật khẩu MySQL từ student.env
      DB_NAME: ${MYSQL_DATABASE}
      DB_USER: ${MYSQL_USER}
      DB_PASSWORD: ${MYSQL_PASSWORD}
      TZ: Asia/Ho_Chi_Minh
    depends_on:
      mysql:
        condition: service_healthy
    networks:
      - db-net
      - proxy-net

  # ---------------------------------------------------------------- Nginx (reverse proxy)
  nginx:
    image: nginx:1.27-alpine
    restart: unless-stopped
    # TODO 4: publish cổng cá nhân APP_PORT ra cổng 80 của container
    ports:
      - "${APP_PORT}:80"
    # TODO 5: mount (read-only) nginx/default.conf -> /etc/nginx/conf.d/default.conf
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app
    networks:
      - proxy-net
```

### Kiểm tra thử cú pháp Docker Compose:
Chạy lệnh sau trên terminal:
```bash
docker compose --env-file student.env config
```
Nếu lệnh chạy thành công không báo lỗi là file cấu hình đã chuẩn xác.

---

## BƯỚC 4: PIPELINE CI/CD VỚI GITHUB ACTIONS (PHẦN 4 - 35 ĐIỂM)

### 4.1. Chuẩn bị kết nối tới VPS Server
1. **Tạo SSH Key trên máy tính của bạn**:
   ```bash
   ssh-keygen -t ed25519 -f deploy_key -N ""
   ```
   *(Sẽ sinh ra 2 file: `deploy_key` là private key, `deploy_key.pub` là public key)*.
2. **Thêm public key vào VPS**:
   ```bash
   cat deploy_key.pub | ssh devopsg5@103.72.57.148 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
   ```
3. **Cấu hình 3 GitHub Secrets** (Truy cập repo trên GitHub ➔ **Settings** ➔ **Secrets and variables** ➔ **Actions** ➔ **New repository secret**):
   - `SERVER_HOST`: `103.72.57.148`
   - `SERVER_USER`: `devopsg5`
   - `SERVER_SSH_KEY`: Copy toàn bộ nội dung file private key `deploy_key`.
4. **Cấp quyền cho GitHub Actions ghi Packages**:
   - Vào **Settings** ➔ **Actions** ➔ **General** ➔ mục **Workflow permissions**: Chọn **Read and write permissions** và bấm **Save**.

### 4.2. Hoàn thiện `.github/workflows/ci-cd.yml`
Mở file [`.github/workflows/ci-cd.yml`](file:///Users/trongtri/Documents/devops/ontap_final/devops-final-app-de008/.github/workflows/ci-cd.yml) và điền các mục `TODO 1` đến `TODO 6`:

- **TODO 1** (Dòng 62): Khởi động bằng Docker Compose:
  ```yaml
        run: docker compose --env-file student.env up -d --build --wait --wait-timeout 300
  ```
- **TODO 2** (Dòng 81-82): Thông tin đăng nhập GHCR:
  ```yaml
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
  ```
- **TODO 3** (Dòng 88-91): Push image lên GHCR với 2 tag:
  ```yaml
        run: |
          docker tag "$IMAGE:${{ github.sha }}" "$IMAGE:latest"
          docker push "$IMAGE:${{ github.sha }}"
          docker push "$IMAGE:latest"
  ```
- **TODO 4** (Dòng 100): Khai báo phụ thuộc job build:
  ```yaml
    needs: build
  ```
- **TODO 5** (Dòng 117-119): Kết nối SSH qua secrets:
  ```yaml
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SERVER_SSH_KEY }}
  ```
- **TODO 6** (Dòng 133-134): Kéo image mới và chạy lại (không build trên server):
  ```bash
            docker compose --env-file student.env pull app
            docker compose --env-file student.env up -d --no-build
  ```

---

## BƯỚC 5: ĐẨY LÊN GITHUB & CHỤP 4 ẢNH MINH CHỨNG (PHẦN 5 - 10 ĐIỂM)

### 5.1. Khởi tạo Git và Push mã nguồn
1. Đổi tên thư mục thành `devops-final-de008-daotrongtri` (hoặc tên theo đề bài).
2. Tạo repository **Public** trên GitHub: `devops-final-de008-daotrongtri`.
3. Chạy các lệnh sau:
   ```bash
   git init
   git add .
   git commit -m "feat: complete devops final exam de008"
   git branch -M main
   git remote add origin https://github.com/<username-cua-ban>/devops-final-de008-daotrongtri.git
   git push -u origin main
   ```

### 5.2. Chụp 4 ảnh minh chứng lưu vào thư mục `screenshots/`
Sau khi pipeline hoàn tất, bạn chụp 4 ảnh màn hình sau:

1. **`01-actions.png`**:
   - Vào tab **Actions** trên GitHub repository.
   - Chụp màn hình workflow chạy trên nhánh `main` có tích xanh thành công cả 2 job `Build & Test` và `Deploy lên server`.
2. **`02-ghcr.png`**:
   - Vào trang cá nhân GitHub ➔ mục **Packages** ➔ chọn package image `app` của repository.
   - Chụp màn hình hiển thị package có 2 tag: **commit SHA** và **`latest`**.
3. **`03-compose-ps.png`**:
   - Mở terminal/Termius kết nối vào VPS, truy cập vào thư mục dự án và chạy:
     ```bash
     docker compose --env-file student.env ps
     ```
   - Chụp màn hình hiển thị cả 3 service (`app`, `mysql`, `nginx`) đều ở trạng thái `Up`.
4. **`04-website.png`**:
   - Mở trình duyệt truy cập: `http://103.72.57.148:8088/` (hoặc `http://103.72.57.148:8088/api/books`).
   - Chụp màn hình trình duyệt hiển thị danh sách 8 cuốn sách dưới dạng JSON.

### 5.3. Hoàn tất nộp bài
1. Copy 4 ảnh trên vào cả thư mục `screenshots/` và `submission-content/`.
2. Commit và push ảnh lên GitHub:
   ```bash
   git add screenshots/ submission-content/
   git commit -m "docs: add screenshots"
   git push origin main
   ```
3. Nộp link GitHub repository public lên hệ thống RAIA.
Cách 1: Áp dụng quyền Docker ngay lập tức (Nếu lúc trước bạn đã dùng lệnh usermod)

Gõ lệnh sau để terminal load lại danh sách nhóm quyền (bao gồm quyền docker):

Bash
newgrp docker
Chạy lại lệnh hiển thị container:

Bash
docker compose --env-file student.env ps
Cách 2: Chuyển sang dùng tài khoản root (Chắc chắn thành công)
Nếu cách 1 vẫn báo permission denied, bạn hãy mượn quyền root để chạy lệnh chụp ảnh:

Gõ lệnh chuyển sang tài khoản quản trị viên:

Bash
su -
(Nhập mật khẩu root của server)

Di chuyển thẳng tới thư mục chứa code của bạn:

Bash
cd /home/toandev/devops-final-de001-nguyenvantoan
Chạy lệnh hiển thị container:

Bash
docker compose --env-file student.env ps
Bash
cat /root/.ssh/authorized_keys
Hãy nhìn kỹ xem đoạn mã in ra có bị thiếu chữ, cắt cụt, hoặc lẫn ký tự rác do bạn bấm nhầm bàn phím lúc bị treo không. Nó phải là một dòng chữ dài liền mạch bắt đầu bằng ssh-ed25519.... Nếu thấy sai hoặc trống trơn, bạn cần dùng nano mở ra xóa đi dán lại cho đúng.

2. Phân quyền thư mục bị lỏng (SSH rất khắt khe)
Nếu quyền của thư mục .ssh hoặc file bên trong quá lỏng lẻo, SSH daemon trên Linux sẽ tự động vô hiệu hóa tính năng đăng nhập bằng khóa. Hãy chạy 2 lệnh này trên server để chuẩn hóa lại:

Bash
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys
3. Server cấm đăng nhập thẳng bằng tài khoản Root (Khả năng cao nhất)
Đa số các máy chủ Linux đều cấu hình mặc định cấm tài khoản root đăng nhập từ xa qua SSH vì lý do bảo mật (chỉ cho phép user thường đăng nhập rồi dùng lệnh su để chuyển quyền).
Cách kiểm tra: Trên máy Windows của bạn, mở terminal mới tinh và thử gõ ssh root@<IP_SERVER>. Nếu nó văng ra lỗi Permission denied ngay lập tức, chứng tỏ server đã cấm SSH root.

💡 Giải pháp "cứu net" nhanh nhất để nộp bài (Khuyên dùng):
Thay vì loay hoay sửa cấu hình cho root, bạn hãy quay về dùng tài khoản toandev ban đầu. Vì hiện tại bạn đã có thể truy cập vào tài khoản root trên terminal, hãy dùng chính quyền root đó để "giải cứu" tài khoản toandev khỏi lỗi Docker ban nãy:

Đang đứng ở tài khoản root trên server, gõ lệnh này để cấp quyền Docker cho Toàn:

Bash
usermod -aG docker toandev
sudo chown -R $USER:$USER ~/.ssh
(Nếu hệ thống hỏi mật khẩu, hãy nhập mật khẩu của tài khoản toandev)

Cấp quyền chuẩn cho thư mục .ssh (Chỉ chủ sở hữu mới có quyền đọc/ghi/thực thi):

Bash
chmod 700 ~/.ssh
Tạo file authorized_keys (nếu chưa có) và cấp quyền chuẩn cho file:

Bash
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
Mở lại trình soạn thảo để dán Public Key:

Bash
nano ~/.ssh/authorized_keys
