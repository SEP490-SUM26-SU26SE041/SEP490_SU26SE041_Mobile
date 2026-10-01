// ─── RAG API Models ───────────────────────────────────────────────────────────
// Schema reference: RAG_Mobile_Integration.md (sections 3.x)
//
// Các model này map 1-1 với response của RAG FastAPI backend
// (https://rag-nong-nghiep-api-15ms.onrender.com).
//
// Quy ước:
//   - role = 'user' | 'assistant'
//   - history chỉ gửi tối đa 12 messages gần nhất (BE token limit)
//   - retrieval_only=true → trả chunks nguyên văn, không qua LLM tổng hợp

/// Knowledge groups hỗ trợ filter theo BE.
enum KnowledgeGroup {
  all(null, '🌐', 'Tất cả', 'Tìm trong mọi nhóm'),
  crops('crops', '🌱', 'Cây trồng', 'Kỹ thuật canh tác cây trồng'),
  livestock('livestock', '🐄', 'Chăn nuôi', 'Kỹ thuật chăn nuôi'),
  soil('soil', '🌍', 'Đất & phân bón', 'Đặc tính đất, dinh dưỡng'),
  pest('pest', '🐛', 'Sâu bệnh & BVTV', 'Phòng trị sâu bệnh'),
  general('general', '📚', 'Tổng hợp', 'Kiến thức nông nghiệp tổng quát');

  const KnowledgeGroup(this.value, this.emoji, this.label, this.description);
  final String? value;
  final String emoji;
  final String label;
  final String description;

  static KnowledgeGroup fromValue(String? v) {
    return KnowledgeGroup.values.firstWhere(
      (e) => e.value == v,
      orElse: () => KnowledgeGroup.all,
    );
  }
}

/// Scope của role (để tách conversation history).
enum RagScope {
  student('student'),
  technician('technician');

  const RagScope(this.value);
  final String value;

  static RagScope fromValue(String? v) {
    return RagScope.values.firstWhere(
      (e) => e.value == v,
      orElse: () => RagScope.student,
    );
  }
}

/// Citation source từ response BE (mục 3.2.2).
class RagSource {
  RagSource({
    required this.fileName,
    this.source,
    this.pageNumber,
    this.title,
    this.section,
    this.knowledgeGroup,
    required this.text,
  });

  final String fileName;
  final String? source;
  final int? pageNumber;
  final String? title;
  final String? section;
  final String? knowledgeGroup;
  final String text;

  /// Format citation chuẩn để copy:
  ///   Nguồn: file.pdf | Trang X | Mục 3.2 Bệnh đạo ôn
  String get citationLabel {
    final parts = <String>['Nguồn: $fileName'];
    if (pageNumber != null) parts.add('Trang $pageNumber');
    if (section != null && section!.isNotEmpty) parts.add('Mục $section');
    return parts.join(' | ');
  }

  factory RagSource.fromJson(Map<String, dynamic> json) {
    return RagSource(
      fileName: (json['file_name'] ?? 'unknown.pdf') as String,
      source: json['source'] as String?,
      pageNumber: (json['page_number'] as num?)?.toInt(),
      title: json['title'] as String?,
      section: json['section'] as String?,
      knowledgeGroup: json['knowledge_group'] as String?,
      text: (json['text'] ?? '') as String,
    );
  }
}

/// History item gửi cho BE (mục 3.2.1).
class RagHistoryItem {
  RagHistoryItem({required this.role, required this.content});

  /// 'user' | 'assistant'
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Kết quả trả về từ /chat endpoint.
class RagChatResult {
  RagChatResult({
    required this.success,
    required this.answer,
    required this.queryUsed,
    required this.sources,
    this.error,
  });

  final bool success;
  final String answer;
  final String? queryUsed;
  final List<RagSource> sources;
  final String? error;

  bool get isRetrievalOnly => success && answer.startsWith('(') && answer.contains('đoạn trích');
  bool get hasError => !success || (error != null && error!.isNotEmpty);

  factory RagChatResult.fromJson(Map<String, dynamic> json) {
    return RagChatResult(
      success: json['success'] == true,
      answer: (json['answer'] ?? '') as String,
      queryUsed: json['query_used'] as String?,
      sources: ((json['sources'] as List?) ?? const [])
          .map((s) => RagSource.fromJson(s as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );
  }
}

/// Health response từ /health (mục 3.1).
class RagHealth {
  RagHealth({required this.online, required this.indexLoaded, required this.nVectors});

  final bool online;
  final bool indexLoaded;
  final int nVectors;

  factory RagHealth.fromResponse(Map<String, dynamic> json) {
    return RagHealth(
      online: true,
      indexLoaded: json['index_loaded'] == true,
      nVectors: (json['n_vectors'] as num?)?.toInt() ?? 0,
    );
  }

  factory RagHealth.offline() => RagHealth(online: false, indexLoaded: false, nVectors: 0);
}

/// Message trong conversation lưu local (mục 4.1).
class RagStoredMessage {
  RagStoredMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.ts,
    this.sources = const [],
  });

  final int id; // auto-increment local
  final String conversationId;
  final String role;
  final String content;
  final DateTime ts;
  final List<RagSource> sources;

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'role': role,
        'content': content,
        'ts': ts.toIso8601String(),
        'sources': sources.map((s) => {
              'file_name': s.fileName,
              'source': s.source,
              'page_number': s.pageNumber,
              'title': s.title,
              'section': s.section,
              'knowledge_group': s.knowledgeGroup,
              'text': s.text,
            }).toList(),
      };

  factory RagStoredMessage.fromJson(Map<String, dynamic> json) {
    return RagStoredMessage(
      id: (json['id'] as num).toInt(),
      conversationId: json['conversationId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      ts: DateTime.parse(json['ts'] as String),
      sources: ((json['sources'] as List?) ?? const [])
          .map((s) => RagSource.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Conversation metadata lưu local (mục 4.1).
class RagConversation {
  RagConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.scope,
    this.knowledgeGroup,
    this.retrievalOnly = true,
  });

  final String id; // uuid
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final RagScope scope;

  /// null = Tất cả (mặc định theo role user chọn).
  String? knowledgeGroup;

  /// Default ON theo spec mục 4.2 (web v1.3 mặc định bật).
  bool retrievalOnly;

  /// 'YYYY-MM-DD' để group theo ngày.
  String get day =>
      '${updatedAt.year.toString().padLeft(4, '0')}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'scope': scope.value,
        'knowledgeGroup': knowledgeGroup,
        'retrievalOnly': retrievalOnly,
      };

  factory RagConversation.fromJson(Map<String, dynamic> json) {
    return RagConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      scope: RagScope.fromValue(json['scope'] as String?),
      knowledgeGroup: json['knowledgeGroup'] as String?,
      retrievalOnly: json['retrievalOnly'] as bool? ?? true,
    );
  }
}

/// Group theo ngày cho conversation drawer.
enum ConversationDayBucket {
  today,
  yesterday,
  thisWeek,
  older,
}

extension ConversationDayBucketX on ConversationDayBucket {
  String get label => switch (this) {
        ConversationDayBucket.today => 'Hôm nay',
        ConversationDayBucket.yesterday => 'Hôm qua',
        ConversationDayBucket.thisWeek => 'Tuần này',
        ConversationDayBucket.older => 'Cũ hơn',
      };
}

ConversationDayBucket bucketForDay(DateTime when) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(when.year, when.month, when.day);
  final diff = today.difference(d).inDays;
  if (diff <= 0) return ConversationDayBucket.today;
  if (diff == 1) return ConversationDayBucket.yesterday;
  if (diff < 7) return ConversationDayBucket.thisWeek;
  return ConversationDayBucket.older;
}
