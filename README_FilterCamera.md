# Filter Camera iOS App

## 1. Hướng dẫn build và chạy project

### Yêu cầu môi trường
- Xcode 15+
- iOS 16+

### Các bước chạy
1. Clone project:
2. Mở project bằng Xcode: FilterCamera.xcodeproj
3. Chọn simulator hoặc thiết bị thật
4. Run project (Cmd + R)
---

## 2. Kiến trúc sử dụng và lý do lựa chọn

### Kiến trúc
Ứng dụng sử dụng:
- **MVVM (Model - View - ViewModel)**
- Kết hợp **Service Layer**

### Lý do chọn MVVM
- Tách biệt UI và logic rõ ràng
- Dễ test và maintain
- Phù hợp với SwiftUI

### Service Layer
- Tách logic phức tạp (Camera, IAP, Ads)
- Dễ tái sử dụng

---

## 3. Thư viện third-party (nếu có) và lý do sử dụng

### Google AdMob
- Dùng để hiển thị quảng cáo
- Hỗ trợ nhiều loại ads (Interstitial, Native)

- Chủ yếu sử dụng **Native APIs**
  - AVFoundation (camera)
  - CoreImage (filter GPU)
  - StoreKit 2 (purchase)

---

## 4. Những tính năng đã hoàn thành / chưa hoàn thành

### Đã hoàn thành

#### Flow chính
- Splash → Onboarding → Paywall → Camera → Result

#### Camera
- Preview realtime
- Quay video (15s / 30s / 60s / 120s)
- Filter ngẫu nhiên
- Overlay image
- Auto stop theo thời gian
- Xử lý bằng GPU (CoreImage)

#### Result
- Preview video
- Loop video
- Save vào thư viện
- Record lại

#### Purchase
- Load product từ StoreKit
- Mua subscription
- Restore purchase
- Kiểm tra trạng thái premium

#### Ads
- Splash: Interstitial
- Onboarding: Native medium
- Camera: Native small
- Result: Native large
- Ẩn ads khi user mua premium

---

### Chưa hoàn thành / hạn chế

- UI chưa giống 100% Figma (Không truy cập vào được file Figma)
- Chưa tối ưu hiệu năng hoàn toàn
- Error handling chưa đầy đủ
- Chưa cache filter

---

## 5. Các điểm cần cải thiện nếu có thêm thời gian

### Feature
- Thêm chức năng nhận diện vị trí khuôn mặt và thêm filter lên các bộ phận lên khuôn mặt.
- Thêm chức năng tương tác trên màn hình, quay video người chơi.

### Performance
- Tối ưu pipeline camera
- Giảm load GPU
- Cache filter / overlay

### UI/UX
- Improve animation
- Smooth transition giữa các màn

### Testing
- Unit test ViewModel
- Test flow purchase


