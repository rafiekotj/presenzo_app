class Endpoint {
  static const String baseUrl = "https://appabsensi.mobileprojp.com/api";

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  /// POST - Register akun baru
  /// ✅ DIPAKAI | 📁 services/api/register.dart | 📦 models/register_model.dart
  /// Dipakai di RegisterScreen untuk membuat akun baru
  static const String register = "$baseUrl/register";

  /// POST - Autentikasi user
  /// ✅ DIPAKAI | 📁 services/api/login.dart | 📦 models/login_model.dart
  /// Dipakai di LoginScreen untuk autentikasi user
  static const String login = "$baseUrl/login";

  /// POST - Minta OTP untuk reset password
  /// ✅ DIPAKAI | 📁 services/api/forgot_password.dart | 📦 models/-
  /// Dipakai di ForgotPasswordScreen untuk meminta OTP
  static const String forgotPassword = "$baseUrl/forgot-password";

  /// POST - Reset password dengan OTP
  /// ✅ DIPAKAI | 📁 services/api/reset_password.dart | 📦 models/-
  /// Dipakai di NewPasswordScreen setelah OTP valid
  static const String resetPassword = "$baseUrl/reset-password";

  // ============================================================================
  // PROFILE ENDPOINTS
  // ============================================================================

  /// GET/PUT - Ambil/update data profil user
  /// ✅ DIPAKAI | 📁 services/api/get_user.dart, update_profile.dart | 📦 models/get_model.dart
  /// GET: Dipakai di HomeScreen dan ProfileScreen untuk ambil data user
  /// PUT: Dipakai di ProfileScreen untuk edit nama, phone, training, batch
  static const String profile = "$baseUrl/profile";

  /// PUT - Upload/ganti foto profil
  /// ✅ DIPAKAI | 📁 services/api/profile_photo.dart | 📦 models/get_model.dart
  /// Untuk upload/ganti foto profil di ProfileEditScreen
  static const String profilePhoto = "$baseUrl/profile/photo";

  // ============================================================================
  // ATTENDANCE CHECK-IN/CHECK-OUT ENDPOINTS
  // ============================================================================

  /// POST - Check in absensi
  /// ✅ DIPAKAI | 📁 services/api/attendance.dart | 📦 models/attendance_model.dart
  /// Dipakai di PresensiScreen untuk check in dengan lokasi, waktu, dan status
  static const String absenCheckIn = "$baseUrl/absen/check-in";

  /// POST - Check out absensi
  /// ✅ DIPAKAI | 📁 services/api/attendance.dart | 📦 models/attendance_model.dart
  /// Dipakai di PresensiScreen untuk check out
  static const String absenCheckOut = "$baseUrl/absen/check-out";

  /// POST - Submit izin/cuti
  /// ✅ DIPAKAI | 📁 services/api/attendance.dart | 📦 models/attendance_model.dart
  /// Dipakai di PresensiScreen saat user memilih mode izin dan input alasan
  static const String izin = "$baseUrl/izin";

  /// GET - Lihat status absensi hari ini
  /// ✅ DIPAKAI | 📁 services/api/attendance.dart | 📦 models/attendance_model.dart
  /// Dipakai di PresensiScreen untuk lihat status absensi hari ini
  /// Query parameter: attendance_date
  static const String absenToday = "$baseUrl/absen/today";

  /// GET - Ambil statistik absensi
  /// ✅ DIPAKAI | 📁 services/api/attendance.dart | 📦 models/attendance_model.dart
  /// Dipakai untuk ambil statistik absensi (total, sudah absen hari ini, dll)
  /// Optional query parameters: year, start, end
  static const String absenStats = "$baseUrl/absen/stats";

  /// GET - Ambil riwayat absensi
  /// ✅ DIPAKAI | 📁 services/api/attendance.dart | 📦 models/attendance_model.dart
  /// Dipakai di HomeScreen (riwayat 5 hari) dan RiwayatScreen (riwayat bulanan)
  /// Required query parameters: start, end (format: yyyy-MM-dd)
  /// Optional query parameters: limit
  static const String absenHistory = "$baseUrl/absen/history";

  /// DELETE - Hapus/koreksi data absensi (path parameter: id)
  /// ⏸️ BELUM DIPAKAI | 📄 services/api/attendance.dart (jika diperlukan) | 📦 models/attendance_model.dart
  /// Path parameter: id (attendance ID)
  /// Kemungkinan untuk admin atau koreksi data di panel admin
  static String absenById(String id) => "$baseUrl/absen/$id";

  // ============================================================================
  // SYSTEM ENDPOINTS
  // ============================================================================

  /// POST - Simpan token push notification
  /// ⏸️ BELUM DIPAKAI | 📄 services/api/[future].dart | 📦 models/-
  /// Untuk menyimpan token push notification (future feature)
  static const String deviceToken = "$baseUrl/device-token";

  // ============================================================================
  // MASTER DATA ENDPOINTS
  // ============================================================================

  /// GET - Daftar user (admin)
  /// ⏸️ BELUM DIPAKAI | 📄 services/api/[future].dart | 📦 models/-
  /// Kemungkinan untuk halaman admin atau user management
  static const String users = "$baseUrl/users";

  /// GET - Ambil daftar training
  /// ✅ DIPAKAI | 📁 services/api/training.dart | 📦 models/training_model.dart
  /// Dipakai di RegisterScreen untuk pilih training
  static const String trainings = "$baseUrl/trainings";

  /// GET - Detail training (path parameter: id)
  /// ⏸️ BELUM DIPAKAI | 📄 services/api/training.dart (jika diperlukan) | 📦 models/training_model.dart
  /// Path parameter: id (training ID) untuk detail training
  /// Kemungkinan akan dipakai untuk lihat detail training tertentu
  static String trainingById(String id) => "$baseUrl/trainings/$id";

  /// GET - Ambil daftar batch
  /// ✅ DIPAKAI | 📁 services/api/batch.dart | 📦 models/batch_model.dart
  /// Dipakai di RegisterScreen untuk pilih batch
  static const String batches = "$baseUrl/batches";
}
