/// Địa chỉ backend. Đổi khi chạy: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8088
/// (10.0.2.2 = máy tính của bạn nhìn từ máy ảo Android).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://project-prm393.onrender.com',
);

/// Chạy offline bằng dữ liệu giả: flutter run --dart-define=USE_MOCK=true
const bool kUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
