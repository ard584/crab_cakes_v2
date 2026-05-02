import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:ui_prototype/application/sync/interfaces/project_sync_repo.dart';

import 'package:ui_prototype/application/sync/usecases/apply_sync_plan.dart';
import 'package:ui_prototype/application/sync/usecases/build_sync_plan.dart';
import 'package:ui_prototype/application/sync/usecases/check_sync_compat.dart';

import 'package:ui_prototype/application/sync/dtos/sync_plan.dart';

import 'package:ui_prototype/infrastructure/sync/sqlite_project_sync_repo.dart';


final projectSyncRepositoryProvider = Provider<ProjectSyncRepo>((ref) {
  return SqliteProjectSyncRepository();
});

final checkSyncCompatibilityProvider = Provider<CheckSyncCompat>((ref) {
  final repo = ref.watch(projectSyncRepositoryProvider);
  return CheckSyncCompat(repo);
});

final buildSyncPlanProvider = Provider<BuildSyncPlan>((ref) {
  final repo = ref.watch(projectSyncRepositoryProvider);
  final checkCompatibility = ref.watch(checkSyncCompatibilityProvider);

  return BuildSyncPlan(
    repo: repo,
    checkCompat: checkCompatibility,
  );
});

final applySyncPlanProvider = Provider<ApplySyncPlan>((ref) {
  final repo = ref.watch(projectSyncRepositoryProvider);
  return ApplySyncPlan(repo);
});


//-------------------------- WIRING COMPLETE ----------------------------------


class ProjectSyncState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final SyncPlan? plan;

  const ProjectSyncState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.plan,
  });

  ProjectSyncState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    SyncPlan? plan,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearPlan = false,
  }) {
    return ProjectSyncState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
      plan: clearPlan ? null : plan ?? this.plan,
    );
  }
}


class ProjectSyncNotifier extends Notifier<ProjectSyncState> {
  @override
  ProjectSyncState build() {
    return const ProjectSyncState();
  }

  Future<void> previewSync({
    required String activeDbPath,
    required String candidateDbPath,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
      clearPlan: true,
    );

    try {
      final checkCompatibility = ref.read(checkSyncCompatibilityProvider);

      final compatibility = await checkCompatibility(
        activeDbPath: activeDbPath,
        candidateDbPath: candidateDbPath,
      );

      if (!compatibility.isCompatible) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: compatibility.reason ?? 'Projects are not compatible.',
        );
        return;
      }

      final buildSyncPlan = ref.read(buildSyncPlanProvider);

      final plan = await buildSyncPlan(
        activeDbPath: activeDbPath,
        candidateDbPath: candidateDbPath,
      );

      state = state.copyWith(
        isLoading: false,
        plan: plan,
        successMessage: 'Sync preview ready.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> applySync({
    required String activeDbPath,
    required String candidateDbPath,
  }) async {
    final plan = state.plan;

    if (plan == null) {
      state = state.copyWith(
        errorMessage: 'No sync plan available. Preview sync first.',
      );
      return;
    }

    if (plan.totalConflicts > 0) {
      state = state.copyWith(
        errorMessage: 'Cannot sync while conflicts exist.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final applySyncPlan = ref.read(applySyncPlanProvider);

      await applySyncPlan(
        activeDbPath: activeDbPath,
        candidateDbPath: candidateDbPath,
        plan: plan,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Sync completed successfully.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final projectSyncNotifierProvider =
    NotifierProvider<ProjectSyncNotifier, ProjectSyncState>(
  ProjectSyncNotifier.new,
);