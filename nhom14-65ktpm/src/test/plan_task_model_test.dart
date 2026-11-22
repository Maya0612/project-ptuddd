import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/models/plan_model.dart';
import 'package:nhom14_app/models/task_model.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 22, 10);
  final dueDate = DateTime.utc(2026, 12, 1);

  TaskModel task({String id = 'task-1', TaskStatus status = TaskStatus.todo}) {
    return TaskModel(
      id: id,
      planId: 'plan-1',
      userId: 'user-1',
      title: 'Hoàn thành đề cương',
      phase: 'Chuẩn bị',
      description: 'Viết đề cương chi tiết',
      dueDate: dueDate,
      status: status,
      orderIndex: 1,
      completedAt: status == TaskStatus.done ? createdAt : null,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  PlanModel plan({List<TaskModel> tasks = const []}) {
    return PlanModel(
      id: 'plan-1',
      userId: 'user-1',
      personalTopicId: 'topic-1',
      title: 'Kế hoạch tốt nghiệp',
      description: 'Chuẩn bị đồ án',
      startDate: createdAt,
      endDate: dueDate,
      status: PlanStatus.active,
      createdAt: createdAt,
      updatedAt: createdAt,
      tasks: tasks,
    );
  }

  group('PlanModel', () {
    test('calculates progress and returns zero when there are no tasks', () {
      expect(plan().progress, 0);
      expect(
        plan(
          tasks: [
            task(status: TaskStatus.done),
            task(id: 'task-2'),
          ],
        ).progress,
        50,
      );
    });

    test('round trips JSON including nested tasks', () {
      final original = plan(tasks: [task(status: TaskStatus.done)]);
      final json = original.toJson()
        ..['tasks'] = original.tasks.map((item) => item.toJson()).toList();
      final decoded = PlanModel.fromJson(json);

      expect(decoded.id, original.id);
      expect(decoded.personalTopicId, original.personalTopicId);
      expect(decoded.startDate, DateTime(2026, 11, 22));
      expect(decoded.endDate, DateTime(2026, 12, 1));
      expect(decoded.status, original.status);
      expect(decoded.tasks.single.status, TaskStatus.done);
      expect(decoded.progress, 100);
    });
  });

  group('TaskModel', () {
    test('converts todo and done statuses to and from database values', () {
      expect(TaskStatus.todo.toDatabaseValue(), 'todo');
      expect(TaskStatus.fromDatabaseValue('todo'), TaskStatus.todo);
      expect(TaskStatus.done.toDatabaseValue(), 'done');
      expect(TaskStatus.fromDatabaseValue('done'), TaskStatus.done);
    });

    test('round trips JSON fields and nullable dates', () {
      final original = task(status: TaskStatus.done);
      final decoded = TaskModel.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.planId, original.planId);
      expect(decoded.title, original.title);
      expect(decoded.phase, original.phase);
      expect(decoded.dueDate, DateTime(2026, 12, 1));
      expect(decoded.status, TaskStatus.done);
      expect(decoded.completedAt, original.completedAt);
      expect(decoded.orderIndex, original.orderIndex);
    });
  });
}
