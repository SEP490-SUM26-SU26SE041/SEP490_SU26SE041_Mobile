/// Constants cho các AI provider được BE hỗ trợ.
///
/// Mỗi provider có model riêng, dùng để scan ảnh cây trồng.
/// Tên phải KHỚP với enum `AiProvider` phía BE.
class AiProviders {
  AiProviders._();

  /// Phát hiện bệnh trên lá cà chua (9 loại bệnh).
  static const String tomatoLeafDisease = 'TomatoLeafDiseaseOnnx';

  /// Phát hiện sâu bệnh nông nghiệp (Snails, Beetles, etc.).
  static const String argoPest = 'ArgoPestOnnx';

  /// Provider mặc định cho ảnh mới.
  static const String defaultProvider = tomatoLeafDisease;

  /// Lấy tất cả provider được hỗ trợ.
  static const List<String> all = [tomatoLeafDisease, argoPest];

  /// Map provider → metadata hiển thị (tên tiếng Việt, icon, màu, mô tả).
  static AiProviderMeta getMeta(String? provider) {
    switch (provider) {
      case tomatoLeafDisease:
        return const AiProviderMeta(
          id: tomatoLeafDisease,
          shortName: 'Tomato',
          fullName: 'Tomato Leaf Disease',
          vietnameseName: 'Bệnh lá cà chua',
          emoji: '🍅',
          colorValue: 0xFFE53935,
          description: 'Phát hiện 9 loại bệnh trên lá cà chua',
        );
      case argoPest:
        return const AiProviderMeta(
          id: argoPest,
          shortName: 'Argo Pest',
          fullName: 'Argo Pest Detection',
          vietnameseName: 'Sâu bệnh nông nghiệp',
          emoji: '🐛',
          colorValue: 0xFFFFA726,
          description: 'Phát hiện sâu bệnh cây trồng',
        );
      default:
        return AiProviderMeta(
          id: provider ?? 'unknown',
          shortName: (provider ?? 'unknown').length > 8
              ? (provider ?? 'unknown').substring(0, 8)
              : (provider ?? 'unknown'),
          fullName: provider ?? 'Unknown',
          vietnameseName: 'Không xác định',
          emoji: '🤖',
          colorValue: 0xFF90A4AE,
          description: 'Provider không xác định',
        );
    }
  }
}

/// Metadata hiển thị cho 1 AI provider.
class AiProviderMeta {
  const AiProviderMeta({
    required this.id,
    required this.shortName,
    required this.fullName,
    required this.vietnameseName,
    required this.emoji,
    required this.colorValue,
    required this.description,
  });

  final String id;
  final String shortName;
  final String fullName;
  final String vietnameseName;
  final String emoji;

  /// Color value (ARGB int) — dùng `Color(colorValue)`.
  final int colorValue;
  final String description;
}
