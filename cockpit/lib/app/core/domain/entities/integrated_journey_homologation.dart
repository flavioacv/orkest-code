/// Fases sequenciais da jornada completa do desenvolvedor no Orkest Code (Q01).
enum DeveloperJourneyStage {
  searchAndOpenProject, // 1. Busca e abertura do projeto/workspace
  editAndRefactor, // 2. Edição de buffer, navegação LSP e refatoração
  testAndDebug, // 3. Execução de testes, coverage e sessão de depuração DAP
  reviewHunksAndConflicts, // 4. Revisão de hunks Git e resolução visual de conflitos 3-way
  resumeHarnessExecution, // 5. Continuação com harness de IA no terminal sem vazamentos
}

/// Status de execução de uma etapa de homologação (Q01).
enum HomologationStatus {
  passed,
  failed,
  skipped,
}

/// Resultado de uma etapa individual da jornada integrada (Q01).
class JourneyStepResult {
  const JourneyStepResult({
    required this.stage,
    required this.status,
    required this.durationMs,
    required this.allocatedMemoryDeltaMb,
    required this.assertionsPassed,
    required this.details,
  });

  final DeveloperJourneyStage stage;
  final HomologationStatus status;
  final double durationMs;
  final double allocatedMemoryDeltaMb;
  final int assertionsPassed;
  final String details;

  bool get isSuccessful => status == HomologationStatus.passed;
}

/// Relatório consolidado da homologação da jornada integrada (Q01).
class IntegratedJourneyReport {
  const IntegratedJourneyReport({
    required this.steps,
    required this.totalDurationMs,
    required this.peakRssMb,
    required this.allStagesPassed,
    required this.governancePassed,
    required this.targetEnvironment,
  });

  final List<JourneyStepResult> steps;
  final double totalDurationMs;
  final double peakRssMb;
  final bool allStagesPassed;
  final bool governancePassed;
  final String targetEnvironment; // Desktop Local, SSH Remoto, WSL

  int get totalAssertionsPassed =>
      steps.fold(0, (sum, step) => sum + step.assertionsPassed);
}

/// Registro de aviso e licença de componente terceiro (Q01).
class ThirdPartyNoticeEntry {
  const ThirdPartyNoticeEntry({
    required this.componentName,
    required this.licenseType, // MIT, Apache-2.0, BSD-3-Clause, etc.
    required this.isPermissive,
    required this.hasAttributionNotice,
    required this.avoidsCopyleftContamination,
  });

  final String componentName;
  final String licenseType;
  final bool isPermissive;
  final bool hasAttributionNotice;
  final bool avoidsCopyleftContamination;
}

/// Política e verificação de governança para rollout reversível e feature flags (Q01).
class RollbackGovernancePolicy {
  const RollbackGovernancePolicy({
    required this.featureFlags,
    required this.allFlagsReversible,
    required this.cleanRollbackConfirmed,
    required this.requiresExplicitMergeApproval,
    required this.thirdPartyNotices,
  });

  final Map<String, bool> featureFlags;
  final bool allFlagsReversible;
  final bool cleanRollbackConfirmed;
  final bool requiresExplicitMergeApproval;
  final List<ThirdPartyNoticeEntry> thirdPartyNotices;

  /// Valida se o pacote está 100% em conformidade com as regras de governança.
  bool get isCompliant =>
      allFlagsReversible &&
      cleanRollbackConfirmed &&
      requiresExplicitMergeApproval &&
      thirdPartyNotices.every(
        (n) => n.isPermissive && n.hasAttributionNotice && n.avoidsCopyleftContamination,
      );
}
