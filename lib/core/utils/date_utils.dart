/// Helper parse + format datetime từ API response.
///
/// **Quy ước timezone (SNMS - đồ án tốt nghiệp):**
/// - Ứng dụng dành cho người Việt Nam, hiển thị theo **UTC+7** (ICT).
/// - Backend trả về ISO 8601 **UTC** (kết thúc bằng `Z` hoặc offset).
/// - Helper `parseApiDateTime` ép mọi trường hợp về UTC instant để so sánh chính xác.
///
/// Khi **hiển thị** lên UI, dùng `formatDateTime` / `formatDate` / `formatTime` —
/// các helper này **tự convert sang UTC+7** (không phụ thuộc local time của máy).
///
/// ⚠️ Lý do phải hard-code UTC+7:
/// - Nếu dùng `dt.toLocal()` thì máy client ở timezone khác (ví dụ UTC, UTC+9...)
///   sẽ hiển thị sai giờ Việt Nam. Vì app này chỉ dành cho user VN, ta ép cứng
///   sang UTC+7.
library;

import 'package:intl/intl.dart' as intl;

/// Offset VN: UTC+7.
const Duration _vnOffset = Duration(hours: 7);

/// Convert từ UTC instant sang wall-clock theo UTC+7.
DateTime _toVN(DateTime dt) {
  // Ensure Input is UTC instant.
  final utc = dt.isUtc ? dt : dt.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
    utc.millisecond,
    utc.microsecond,
  ).add(_vnOffset);
}

/// Parse datetime từ string API response, trả về UTC instant.
///
/// Chấp nhận:
/// - ISO 8601 có `Z` hoặc offset (`+07:00`, `-05:00`...) → UTC instant.
/// - ISO 8601 **không** có offset → coi như UTC+7 (wall-clock), convert về UTC.
/// - null / empty / invalid → null.
DateTime? parseApiDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  final hasZoneInfo = raw.contains('Z') ||
      RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  if (!hasZoneInfo) {
    // Naive (no offset) — treat as UTC+7 wall-clock, convert to UTC instant.
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).subtract(_vnOffset);
  }
  return parsed.toUtc();
}

/// Parse + fallback `DateTime.now()` khi null/invalid.
DateTime parseApiDateTimeOrNow(String? raw) {
  return parseApiDateTime(raw) ?? DateTime.now();
}

/// Strip phần time, chỉ giữ ngày theo UTC+7 wall-clock.
DateTime dateOnlyInVN(DateTime dt) {
  final vn = _toVN(dt);
  return DateTime.utc(vn.year, vn.month, vn.day);
}

/// Strip phần time, chỉ giữ ngày (theo UTC) để so sánh cùng ngày.
DateTime dateOnlyUtc(DateTime dt) {
  return DateTime.utc(dt.year, dt.month, dt.day);
}

/// "Hôm nay" theo UTC+7, dùng cho các so sánh trong ngày.
DateTime todayInVN() {
  final now = DateTime.now().toUtc();
  final vn = now.add(_vnOffset);
  return DateTime.utc(vn.year, vn.month, vn.day);
}

/// Ngày mai theo UTC+7 (00:00 UTC+7).
DateTime tomorrowInVN() {
  return todayInVN().add(const Duration(days: 1));
}

/// Ngày mốt (ngày kia) theo UTC+7.
DateTime dayAfterTomorrowInVN() {
  return todayInVN().add(const Duration(days: 2));
}

/// So sánh 2 DateTime theo ngày UTC+7 (chỉ so date, bỏ qua time).
bool isSameDayInVN(DateTime a, DateTime b) {
  final va = _toVN(a);
  final vb = _toVN(b);
  return va.year == vb.year && va.month == vb.month && va.day == vb.day;
}

/// ─── Format helpers — luôn hiển thị theo UTC+7 ──────────────────────────────

String formatDateTime(
  DateTime? dt, {
  String pattern = 'dd/MM/yyyy HH:mm',
}) {
  if (dt == null) return '';
  return intl.DateFormat(pattern).format(_toVN(dt));
}

/// Format helper cho riêng ngày (không kèm giờ), theo UTC+7.
String formatDate(
  DateTime? dt, {
  String pattern = 'dd/MM/yyyy',
}) {
  if (dt == null) return '';
  return intl.DateFormat(pattern).format(_toVN(dt));
}

/// Format helper cho riêng giờ (không kèm ngày), theo UTC+7.
String formatTime(
  DateTime? dt, {
  String pattern = 'HH:mm',
}) {
  if (dt == null) return '';
  return intl.DateFormat(pattern).format(_toVN(dt));
}

/// Format "dd/MM HH:mm" — gọn cho dueDate của task.
String formatDateShort(DateTime? dt) {
  if (dt == null) return '';
  final vn = _toVN(dt);
  final mm = vn.month.toString().padLeft(2, '0');
  final dd = vn.day.toString().padLeft(2, '0');
  final hh = vn.hour.toString().padLeft(2, '0');
  final mi = vn.minute.toString().padLeft(2, '0');
  return '$dd/$mm $hh:$mi';
}

/// Format "dd/MM/yyyy HH:mm" — đầy đủ ngày + giờ. Dùng cho dueDate task.
String formatDueDate(DateTime? dt) {
  if (dt == null) return '';
  return formatDateTime(dt, pattern: 'dd/MM/yyyy HH:mm');
}