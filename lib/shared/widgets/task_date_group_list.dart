/// Widget chia sẻ dùng để hiển thị danh sách task được **gom nhóm theo ngày
/// due** (UTC+7).
///
/// Mục đích: dùng chung cho **Student / Technician / Researcher / …** để đảm
/// bảo UI đồng bộ tuyệt đối giữa các role.
///
/// Quy tắc hiển thị (theo quyết định product):
/// - Mỗi task vào đúng **1 section theo ngày due** (`dateOnlyInVN`).
/// - Task cùng ngày → gom chung 1 section.
/// - Section sort **giảm dần** theo ngày (gần nhất lên đầu), NGOẠI LỆ:
///   • Các ngày **quá hạn** (trước hôm nay) → sort **tăng dần** (quá hạn
///     lâu nhất lên đầu — giúp user xử lý task cũ trước).
///   • **Hoàn thành** → luôn ở cuối (dù ngày nào).
/// - Trong section: task quá hạn/hôm nay/tương lai sort theo `dueDate` ASC
///   (deadline sớm trước). Task hoàn thành sort DESC (mới nhất trước).
/// - Header label thân thiện:
///   • "Hôm nay" / "Hôm qua" / "Ngày mai"
///   • "Quá hạn N ngày" / "N ngày nữa" (chỉ trong khoảng 2–7 ngày)
///   • Còn lại: "Thứ Hai, 15/10" (kèm năm nếu khác năm hiện tại)
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../models/growth_task_model.dart';

/// Render danh sách [tasks] được gom nhóm theo ngày due, mỗi section có
/// header sticky-style và mỗi task render qua [itemBuilder].
///
/// Caller chỉ cần truyền:
/// - `tasks`: danh sách task đã được filter ở caller (vd. theo filter chip).
/// - `itemBuilder`: trả về Widget cho mỗi task.
class TaskDateGroupList extends StatelessWidget {
  const TaskDateGroupList({
    super.key,
    required this.tasks,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.emptyWidget,
    this.sectionSpacing = 8,
  });

  final List<TaskModel> tasks;
  final Widget Function(BuildContext context, TaskModel task, int indexInSection)
      itemBuilder;
  final EdgeInsetsGeometry padding;
  final Widget? emptyWidget;

  /// Khoảng cách giữa 2 sections (gap dưới mỗi column section).
  final double sectionSpacing;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không có công việc'),
            ),
          );
    }

    final grouped = _groupByDate(tasks);
    final sections = grouped.keys.toList();
    final today = todayInVN();
    _sortSections(sections, today);

    return ListView.builder(
      padding: padding,
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final sectionKey = sections[i];
        final sectionTasks = grouped[sectionKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateSectionHeader(
              groupKey: sectionKey,
              count: sectionTasks.length,
              today: today,
            ),
            const SizedBox(height: 10),
            ...List.generate(sectionTasks.length, (idx) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx == sectionTasks.length - 1 ? 0 : 12,
                ),
                child: itemBuilder(context, sectionTasks[idx], idx),
              );
            }),
            SizedBox(height: sectionSpacing),
          ],
        );
      },
    );
  }

  /// Group task theo **ngày due** (UTC+7). Task Completed → gom riêng ở cuối.
  static Map<String, List<TaskModel>> _groupByDate(List<TaskModel> tasks) {
    final Map<String, List<TaskModel>> grouped = {};
    for (final task in tasks) {
      if (task.status == TaskStatus.completed) {
        grouped
            .putIfAbsent(_completedGroupKey, () => [])
            .add(task);
        continue;
      }
      final dueDate = dateOnlyInVN(task.dueDate);
      final isoKey =
          '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(isoKey, () => []).add(task);
    }

    // Sort task trong từng group:
    //  - Hoàn thành: DESC (xem cái vừa xong trước).
    //  - Còn lại: ASC theo deadline (sớm nhất lên đầu trong section).
    grouped.forEach((key, list) {
      if (key == _completedGroupKey) {
        list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
      } else {
        list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      }
    });

    return grouped;
  }

  /// Sort sections theo ngày GIẢM DẦN (gần nhất lên đầu), nhưng:
  /// - Ngày quá hạn → TĂNG DẦN (cũ nhất lên đầu).
  /// - Hoàn thành → cuối cùng.
  static void _sortSections(List<String> sections, DateTime today) {
    sections.sort((a, b) {
      if (a == _completedGroupKey) return 1;
      if (b == _completedGroupKey) return -1;

      final ad = _parseGroupDate(a)!;
      final bd = _parseGroupDate(b)!;

      final aPast = ad.isBefore(today);
      final bPast = bd.isBefore(today);

      if (aPast && bPast) return ad.compareTo(bd); // cũ nhất lên đầu
      if (!aPast && !bPast) return bd.compareTo(ad); // gần nhất lên đầu
      return aPast ? -1 : 1; // phần quá hạn ưu tiên
    });
  }

  static const String _completedGroupKey = '__completed__';

  static DateTime? _parseGroupDate(String key) {
    if (key == _completedGroupKey) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

/// ─── Internal: date-based section header ────────────────────────────────

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({
    required this.groupKey,
    required this.count,
    required this.today,
  });

  final String groupKey;
  final int count;
  final DateTime today;

  /// Sentinel key cho section "Hoàn thành" — match với key trong _TaskDateGroupList.
  static const String _completedGroupKey = '__completed__';

  DateTime? get _groupDate {
    if (groupKey == _completedGroupKey) return null;
    final parts = groupKey.split('-');
    if (parts.length != 3) return null;
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  String get _label {
    if (groupKey == _completedGroupKey) return 'Hoàn thành';
    final date = _groupDate;
    if (date == null) return groupKey;

    // Format chỉ ngày (không kèm thứ trong tuần, khó biết tuần nào).
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return date.year != today.year ? '$dd/$mm/${date.year}' : '$dd/$mm';
  }

  Color get _color {
    if (groupKey == _completedGroupKey) return AppColors.success;
    final date = _groupDate;
    if (date == null) return AppColors.primary;
    final todayD = DateTime.utc(today.year, today.month, today.day);
    final diff = todayD.difference(date).inDays;
    if (diff == 0) return AppColors.warning;
    if (diff > 0) return AppColors.error;
    if (diff == -1) return AppColors.info;
    return AppColors.primary;
  }

  IconData? get _icon {
    if (groupKey == _completedGroupKey) return Icons.check_circle_rounded;
    final date = _groupDate;
    if (date == null) return null;
    final todayD = DateTime.utc(today.year, today.month, today.day);
    final diff = todayD.difference(date).inDays;
    if (diff == 0) return Icons.today_rounded;
    if (diff > 0) return Icons.warning_amber_rounded;
    if (diff == -1) return Icons.upcoming_rounded;
    return Icons.calendar_today_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Section $_label với $count công việc',
      container: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _color.withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_icon != null) ...[
                  Icon(_icon, size: 14, color: _color),
                  const SizedBox(width: 4),
                ],
                Text(_label,
                    style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: _color)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: _color.withAlpha(30),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$count',
                      style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700, color: _color)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _color.withAlpha(60),
                    (isDark ? AppColors.borderDark : AppColors.borderLight)
                        .withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}