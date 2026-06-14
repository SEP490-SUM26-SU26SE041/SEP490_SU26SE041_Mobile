import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/snms_card.dart';

class RequestReviewScreen extends StatefulWidget {
  const RequestReviewScreen({super.key});

  @override
  State<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends State<RequestReviewScreen> {
  final List<_ExperimentRequest> _requests = _mockRequests;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Duyệt Yêu Cầu', style: tt.titleLarge),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
          ),
        ],
      ),
      body: _requests.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _RequestCard(
                    request: request,
                    onTap: () => _showRequestDetail(context, request),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 80, color: AppColors.success.withAlpha(128)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tất cả yêu cầu đã được xử lý',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Không có yêu cầu nào đang chờ duyệt',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetail(BuildContext context, _ExperimentRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailSheet(
        request: request,
        onApprove: () => _handleApprove(context, request),
        onReject: () => _showRejectDialog(context, request),
      ),
    );
  }

  void _handleApprove(BuildContext context, _ExperimentRequest request) {
    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            const Text('Yêu cầu đã được phê duyệt!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, _ExperimentRequest request) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do từ chối:'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _requests.removeWhere((r) => r.id == request.id);
              });
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.cancel_rounded, color: Colors.white),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Yêu cầu đã bị từ chối'),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final _ExperimentRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SNMSCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.science_outlined,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          request.researcherName,
                          style: tt.bodySmall?.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Chờ duyệt',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.category_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                request.cropVariety,
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(Icons.straighten_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${request.requiredBeds} luống',
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Icon(Icons.calendar_today_rounded,
                  size: 14, color: cs.onSurface.withAlpha(128)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                _formatDateRange(request.expectedStart, request.expectedEnd),
                style: tt.bodySmall?.copyWith(color: cs.onSurface.withAlpha(153)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    return '${start.day}/${start.month} - ${end.day}/${end.month}/${end.year}';
  }
}

class _RequestDetailSheet extends StatelessWidget {
  const _RequestDetailSheet({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final _ExperimentRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outline.withAlpha(77),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.science_rounded,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.title,
                              style: tt.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                request.researcherName,
                                style: tt.bodyMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Thông tin yêu cầu', style: tt.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _DetailCard(
                  children: [
                    _DetailRow(label: 'Giống cây trồng', value: request.cropVariety),
                    _DetailRow(
                      label: 'Số lượng cây',
                      value: '${request.plantQuantity} cây',
                    ),
                    _DetailRow(
                      label: 'Số nhóm thí nghiệm',
                      value: '${request.groupCount} nhóm',
                    ),
                    _DetailRow(
                      label: 'Yêu cầu luống',
                      value: '${request.requiredBeds} luống',
                    ),
                    _DetailRow(
                      label: 'Diện tích yêu cầu',
                      value: '${request.requiredArea} m²',
                    ),
                    _DetailRow(
                      label: 'Ngày bắt đầu dự kiến',
                      value: _formatDate(request.expectedStart),
                    ),
                    _DetailRow(
                      label: 'Ngày kết thúc dự kiến',
                      value: _formatDate(request.expectedEnd),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Yêu cầu giám sát', style: tt.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _MonitoringChecklist(monitoringRequirements: request.monitoringRequirements),
                const SizedBox(height: AppSpacing.lg),
                if (request.description.isNotEmpty) ...[
                  Text('Mục tiêu', style: tt.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  _DetailCard(
                    children: [
                      Text(
                        request.description,
                        style: tt.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text('Tài nguyên yêu cầu', style: tt.titleMedium),
                const SizedBox(height: AppSpacing.md),
                _ResourcesCard(resources: request.requiredResources),
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text('Từ chối'),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text('Phê duyệt'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface.withAlpha(153))),
          Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MonitoringChecklist extends StatelessWidget {
  const _MonitoringChecklist({required this.monitoringRequirements});

  final List<String> monitoringRequirements;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SNMSCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: monitoringRequirements.map((req) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.success),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(req, style: tt.bodyMedium),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  const _ResourcesCard({required this.resources});

  final Map<String, dynamic> resources;

  @override
  Widget build(BuildContext context) {
    return SNMSCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _ResourceRow(
            icon: Icons.grid_view_rounded,
            label: 'Số luống',
            value: '${resources['beds'] ?? 0}',
          ),
          const Divider(height: AppSpacing.lg),
          _ResourceRow(
            icon: Icons.straighten_rounded,
            label: 'Diện tích',
            value: '${resources['area'] ?? 0} m²',
          ),
          const Divider(height: AppSpacing.lg),
          _ResourceRow(
            icon: Icons.people_outline_rounded,
            label: 'Nhân sự',
            value: '${resources['staff'] ?? 0} người',
          ),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withAlpha(153)),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: tt.bodyMedium),
        const Spacer(),
        Text(value,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ExperimentRequest {
  const _ExperimentRequest({
    required this.id,
    required this.title,
    required this.researcherName,
    required this.cropVariety,
    required this.plantQuantity,
    required this.groupCount,
    required this.requiredBeds,
    required this.requiredArea,
    required this.expectedStart,
    required this.expectedEnd,
    required this.monitoringRequirements,
    required this.requiredResources,
    required this.description,
  });

  final String id;
  final String title;
  final String researcherName;
  final String cropVariety;
  final int plantQuantity;
  final int groupCount;
  final int requiredBeds;
  final double requiredArea;
  final DateTime expectedStart;
  final DateTime expectedEnd;
  final List<String> monitoringRequirements;
  final Map<String, dynamic> requiredResources;
  final String description;
}

final _mockRequests = [
  _ExperimentRequest(
    id: 'req-001',
    title: 'Thí nghiệm tưới nhỏ giọt thông minh trên cà chua bi',
    researcherName: 'TS. Nguyễn Minh Khoa',
    cropVariety: 'Cà chua bi Cherry 101',
    plantQuantity: 60,
    groupCount: 2,
    requiredBeds: 4,
    requiredArea: 24.0,
    expectedStart: DateTime(2024, 7, 1),
    expectedEnd: DateTime(2024, 9, 30),
    monitoringRequirements: const [
      'Nhiệt độ',
      'Độ ẩm',
      'Độ ẩm đất',
      'Cường độ ánh sáng',
    ],
    requiredResources: const {
      'beds': 4,
      'area': 24.0,
      'staff': 2,
    },
    description:
        'Nghiên cứu so sánh hiệu quả tưới nhỏ giọt thông minh có điều khiển theo cảm biến với phương pháp tưới truyền thống trên giống cà chua bi. Mục tiêu: tăng tỷ lệ sống và giảm 30% lượng nước sử dụng.',
  ),
  _ExperimentRequest(
    id: 'req-002',
    title: 'So sánh giống ớt chuông trong điều kiện nhà kính',
    researcherName: 'TS. Trần Thị Lan',
    cropVariety: 'Ớt chuông đỏ',
    plantQuantity: 80,
    groupCount: 3,
    requiredBeds: 6,
    requiredArea: 36.0,
    expectedStart: DateTime(2024, 8, 1),
    expectedEnd: DateTime(2024, 11, 30),
    monitoringRequirements: const [
      'Nhiệt độ',
      'Độ ẩm',
      'CO2',
    ],
    requiredResources: const {
      'beds': 6,
      'area': 36.0,
      'staff': 3,
    },
    description:
        'Đánh giá khả năng sinh trưởng và năng suất của 3 giống ớt chuông khác nhau trong điều kiện nhà kính có kiểm soát môi trường.',
  ),
  _ExperimentRequest(
    id: 'req-003',
    title: 'Thí nghiệm phân bón hữu cơ trên rau muống',
    researcherName: 'PGS. Hoàng Văn Minh',
    cropVariety: 'Rau muống VT5',
    plantQuantity: 120,
    groupCount: 2,
    requiredBeds: 3,
    requiredArea: 12.0,
    expectedStart: DateTime(2024, 9, 15),
    expectedEnd: DateTime(2024, 10, 30),
    monitoringRequirements: const [
      'Độ ẩm đất',
      'Cường độ ánh sáng',
    ],
    requiredResources: const {
      'beds': 3,
      'area': 12.0,
      'staff': 1,
    },
    description:
        'So sánh hiệu quả của phân bón hữu cơ vi sinh với phân bón NPK truyền thống trên rau muống. Đánh giá về năng suất, chất lượng và hàm lượng vi chất dinh dưỡng.',
  ),
];
