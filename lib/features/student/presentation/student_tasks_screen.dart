import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/presentation/widgets/task_hub.dart';
import '../../tasks/providers/my_tasks_provider.dart';

class StudentTasksScreen extends ConsumerWidget {
  const StudentTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(myTasksProvider);
    return Scaffold(
      body: SafeArea(
        child: TaskHub(
          tasks: tasks,
          rolePath: 'student',
          title: 'Công việc của tôi',
          subtitle: 'Cập nhật realtime theo từng giai đoạn thí nghiệm',
        ),
      ),
    );
  }
}
