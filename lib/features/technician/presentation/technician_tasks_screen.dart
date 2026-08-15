import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/presentation/widgets/task_hub.dart';
import '../providers/technician_my_tasks_provider.dart';

class TechnicianTasksScreen extends ConsumerWidget {
  const TechnicianTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(technicianBucketAsSharedProvider);
    return Scaffold(
      body: SafeArea(
        child: TaskHub(
          tasks: tasks,
          rolePath: 'tech',
          title: 'Công việc kỹ thuật',
          subtitle: 'Theo dõi tác vụ IoT, đo lường & bảo trì',
        ),
      ),
    );
  }
}
