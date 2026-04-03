class Endpoint {
  static const String baseUrl = "https://absensib1.mobileprojp.com/api";

  // Auth endpoints
  /// POST - Dipakai di RegisterScreen untuk membuat akun baru
  static const String register = "$baseUrl/register";

  /// POST - Dipakai di LoginScreen untuk autentikasi user
  static const String login = "$baseUrl/login";

  /// POST - Kemungkinan akan dipakai di ForgotPasswordScreen untuk meminta OTP
  static const String forgotPassword = "$baseUrl/forgot-password";

  /// POST - Kemungkinan akan dipakai di NewPasswordScreen setelah OTP valid
  static const String resetPassword = "$baseUrl/reset-password";

  // Profile endpoints
  /// GET/PUT - Dipakai di HomeScreen dan ProfileScreen untuk ambil data dan edit nama user
  static const String profile = "$baseUrl/profile";

  /// PUT - Belum dipakai, kemungkinan untuk upload/ganti foto profil di ProfileScreen
  static const String profilePhoto = "$baseUrl/profile/photo";

  // Attendance check-in/check-out endpoints
  /// POST - Dipakai di PresensiScreen untuk check in dengan lokasi, waktu, dan status
  static const String absenCheckIn = "$baseUrl/absen/check-in";

  /// POST - Belum dipakai, kemungkinan akan dipakai di PresensiScreen saat fitur check out ditambah
  static const String absenCheckOut = "$baseUrl/absen/check-out";

  /// POST - Dipakai di PresensiScreen saat user memilih mode izin dan input alasan
  static const String izin = "$baseUrl/izin";

  /// GET - Dipakai di PresensiScreen untuk lihat status absensi hari ini
  /// Query parameter: attendance_date
  static const String absenToday = "$baseUrl/absen/today";

  /// GET - Dipakai di PresensiScreen untuk ambil statistik absensi (total, sudah absen hari ini, dll)
  /// Optional query parameters: year, start, end
  static const String absenStats = "$baseUrl/absen/stats";

  /// GET - Belum dipakai, kemungkinan akan dipakai di RiwayatScreen untuk list riwayat bulanan
  /// Required query parameters: start, end (format: yyyy-MM-dd)
  static const String absenHistory = "$baseUrl/absen/history";

  /// DELETE - Belum dipakai, kemungkinan untuk admin atau koreksi data di panel admin
  /// Path parameter: id (attendance ID)
  static String absenById(String id) => "$baseUrl/absen/$id";

  // System endpoints
  /// POST - Belum dipakai, kemungkinan setelah login untuk menyimpan token push notification
  static const String deviceToken = "$baseUrl/device-token";

  // Admin/Master data endpoints
  /// GET - Belum dipakai, kemungkinan untuk halaman admin atau user management
  static const String users = "$baseUrl/users";

  /// GET - Belum dipakai, kemungkinan akan dipakai di registrasi atau edit profil untuk pilih training
  static const String trainings = "$baseUrl/trainings";

  /// GET - Belum dipakai, kemungkinan akan dipakai di registrasi atau edit profil untuk pilih batch
  /// Path parameter: id (training ID) jika perlu detail training
  static String trainingById(String id) => "$baseUrl/trainings/$id";

  /// GET - Belum dipakai, kemungkinan akan dipakai di registrasi atau edit profil untuk pilih batch
  static const String batches = "$baseUrl/batches";
}
