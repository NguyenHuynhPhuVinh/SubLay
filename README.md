# **SubLay**

🎬 Xem video YouTube với phụ đề `.srt` tùy chỉnh, đồng bộ hoàn hảo theo ý muốn của bạn.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/nguyenhuynhphuvinh/dutup-srt)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/platform-Android%20|%20iOS%20|%20Web%20|%20Desktop-lightgrey)](https://flutter.dev)

**SubLay** là một ứng dụng đa nền tảng được xây dựng bằng Flutter, giải quyết vấn đề xem video YouTube với các tệp phụ đề `.srt` bên ngoài. Dễ dàng tải lên tệp phụ đề hoặc dán trực tiếp nội dung để có trải nghiệm xem phim, học tập và giải trí không giới hạn.

*<-- (Đề xuất: Thêm ảnh GIF minh họa ứng dụng hoạt động tại đây) -->*

## ✨ Tính năng nổi bật

*   📺 **Trình phát YouTube tích hợp:** Trải nghiệm xem video mượt mà, toàn màn hình ngay trong ứng dụng.
*   📂 **Hỗ trợ phụ đề SRT linh hoạt:** Dễ dàng tải lên tệp `.srt` từ thiết bị hoặc dán trực tiếp nội dung phụ đề.
*   ️✨ **Lớp phủ phụ đề mượt mà:** Phụ đề được hiển thị đè lên video một cách chuyên nghiệp, không che khuất nội dung quan trọng.
*   ️️⚙️ **Tùy chỉnh phụ đề chuyên sâu:** Điều chỉnh thời gian (timing), kiểu chữ và vị trí của phụ đề để đồng bộ hoàn hảo.
*   💾 **Lịch sử xem thông minh:** Tự động lưu lại các video đã xem cùng với phụ đề để dễ dàng truy cập lại.
*   🎨 **Giao diện hiện đại:** Thiết kế theo chuẩn Material Design 3, hỗ trợ cả chế độ Sáng (Light) và Tối (Dark).

## 📱 Nền tảng hỗ trợ

Ứng dụng được xây dựng với Flutter và hỗ trợ các nền tảng sau:

-   [x] Android
-   [x] iOS
-   [x] Web
-   [x] Windows
-   [x] macOS
-   [x] Linux

## 🏗️ Kiến trúc & Công nghệ

Dự án được xây dựng dựa trên các nguyên tắc và công nghệ hiện đại để đảm bảo hiệu suất, khả năng bảo trì và mở rộng:

*   **Kiến trúc:** Clean Architecture kết hợp với mô hình **MVC (Model-View-Controller)** giúp tách biệt rõ ràng các lớp logic, giao diện và dữ liệu.
*   **Quản lý trạng thái:** **GetX** được sử dụng làm giải pháp toàn diện cho State Management, Dependency Injection và Navigation.
*   **Lưu trữ cục bộ:** **Hive** được chọn làm cơ sở dữ liệu NoSQL hiệu suất cao để lưu trữ lịch sử video và cài đặt người dùng.
*   **Thành phần cốt lõi:**
    *   **Framework:** Flutter & Dart
    *   **Video Player:** `youtube_player_iframe`
    *   **Xử lý phụ đề:** `subtitle` & `srt_parser` tùy chỉnh
    *   **Giao diện:** Material 3, GetWidget, Iconsax
    *   **Network:** Dio

## 🚀 Bắt đầu

### Yêu cầu hệ thống

-   Flutter SDK >= 3.8.1
-   Dart SDK >= 3.0.0
-   Môi trường phát triển: Android Studio / VS Code

### Các bước cài đặt

1.  **Clone repository:**
    ```bash
    git clone https://github.com/nguyenhuynhphuvinh/dutup-srt.git
    cd dutup-srt
    ```

2.  **Cài đặt các gói phụ thuộc:**
    ```bash
    flutter pub get
    ```

3.  **Tạo mã nguồn tự động (cho Hive):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

4.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

## 🤝 Đóng góp

Chúng tôi luôn chào đón các đóng góp để làm cho ứng dụng tốt hơn! Vui lòng tuân thủ quy trình sau:

1.  **Fork** repository này.
2.  Tạo một nhánh mới (`git checkout -b feature/tinh-nang-moi`).
3.  Thực hiện các thay đổi và **commit** (`git commit -m 'Thêm một tính năng tuyệt vời'`).
4.  **Push** lên nhánh của bạn (`git push origin feature/tinh-nang-moi`).
5.  Mở một **Pull Request**.

Nếu bạn phát hiện lỗi, vui lòng tạo một **Issue** trên GitHub.

## 📄 Giấy phép

Dự án này được cấp phép theo **MIT License**. Xem chi tiết tại file `LICENSE`.

## 🙏 Lời cảm ơn

*   Cảm ơn đội ngũ **Flutter** đã tạo ra một framework tuyệt vời.
*   Cảm ơn cộng đồng **GetX** vì những giải pháp quản lý trạng thái mạnh mẽ.
*   Xin cảm ơn tất cả các tác giả của những thư viện mã nguồn mở đã được sử dụng trong dự án này.

---

<div align="center">
  <p>Made with ❤️ and Flutter</p>
  <p>⭐ Hãy gắn sao cho repo này nếu bạn thấy nó hữu ích!</p>
</div>
