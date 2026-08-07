/// Helper parse + format datetime từ API response.
///
/// **Quy ước timezone (SNMS - đồ án tốt nghiệp):**
/// - Ứng dụng chạy ở múi giờ **Việt Nam (UTC+7)**.
/// - Backend có thể trả về:
///   1. ISO 8601 có `Z` / offset → giữ nguyên instant (UTC), so sánh với `DateTime.now()` OK.
///   2. ISO 8601 không có offset (naive local) → coi như **UTC+7**, convert về instant.
///   3. String rỗng / null → fallback `DateTime.now()`.
///
/// Helper `parseApiDateTime` xử lý cả 3 trường hợp trên, đảm bảo `dueDate`
/// luôn là instant (UTC) để so sánh chính xác với `DateTime.now()`.
///
/// Khi **hiển thị** lên UI, dùng `formatDateTime(dt)` / `formatDate(dt)` /
/// `formatTime(dt)` — các helper này tự động convert sang local time của
/// client (mặc định UTC+7 cho máy ở VN) rồi format theo pattern.
library;

import 'package:intl/intl.dart' as intl;

DateTime? parseApiDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  // Nếu chuỗi ISO không kèm offset/ký tự 'Z' → backend trả naive local (UTC+7).
  // Trong Dart, `DateTime.tryParse('2026-08-07T10:00:00')` được hiểu là local time
  // của máy client (có thể sai). Ta ép thành UTC+7 rồi convert về UTC instant.
  final hasZoneInfo = raw.contains('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  if (!hasZoneInfo) {
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).subtract(const Duration(hours: 7));
  }
  return parsed.toUtc();
}

/// Parse + fallback `DateTime.now()` khi null/invalid.
DateTime parseApiDateTimeOrNow(String? raw) {
  return parseApiDateTime(raw) ?? DateTime.now();
}

/// Strip phần time, chỉ giữ ngày (theo UTC) để so sánh cùng ngày.
DateTime dateOnlyUtc(DateTime dt) {
  return DateTime.utc(dt.year, dt.month, dt.day);
}

/// Format helper dùng chung — luôn convert sang local VN trước khi format
/// để hiển thị nhất quán với múi giờ của người dùng (mặc định VN UTC+7).
String formatDateTime(
  DateTime? dt, {
  String pattern = 'dd/MM/yyyy HH:mm',
}) {
  if (dt == null) return '';
  return intl.DateFormat(pattern).format(dt.toLocal());
}

/// Format helper cho riêng ngày (không kèm giờ).
String formatDate(
  DateTime? dt, {
  String pattern = 'dd/MM/yyyy',
}) {
  if (dt == null) return '';
  return intl.DateFormat(pattern).format(dt.toLocal());
}

/// Format helper cho riêng giờ (không kèm ngày).
String formatTime(
  DateTime? dt, {
  String pattern = 'HH:mm',
}) {
  if (dt == null) return '';
  return intl.DateFormat(pattern).format(dt.toLocal());
}
