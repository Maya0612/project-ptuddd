import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/models/plan_model.dart';
import 'package:nhom14_app/screens/plan_list_screen.dart';
import 'package:nhom14_app/services/planning_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _TrackingPlanningService extends PlanningService {
  _TrackingPlanningService()
    : this._(SupabaseClient('https://example.supabase.co', 'test-anon-key'));

  _TrackingPlanningService._(this.client) : super(client: client);

  final SupabaseClient client;

  final requestedTopicIds = <String>[];

  void dispose() => client.auth.stopAutoRefresh();

  @override
  Future<List<PlanModel>> getPlans({required String personalTopicId}) async {
    requestedTopicIds.add(personalTopicId);
    return [];
  }
}

void main() {
  testWidgets('reloads plans when the selected personal topic changes', (
    tester,
  ) async {
    final service = _TrackingPlanningService();
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: PlanListScreen(personalTopicId: 'topic-1', service: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: PlanListScreen(personalTopicId: 'topic-2', service: service),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.requestedTopicIds, ['topic-1', 'topic-2']);
  });
}
