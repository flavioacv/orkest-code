import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/integrated_journey_homologation.dart';
import 'package:orkest_code/app/core/domain/services/integrated_journey_homologation_service.dart';

void main() {
  group('Q01 · IntegratedJourneyHomologationService (Jornada Completa da IDE)', () {
    const service = IntegratedJourneyHomologationService();

    test('executa com sucesso todos os 5 estágios sequenciais da jornada do desenvolvedor', () {
      final report = service.runFullJourneyHomologation(
        projectRoot: '/Volumes/Externo 1/projetos/zurc/remote_pi',
        targetEnvironment: 'Desktop Local',
      );

      expect(report.allStagesPassed, isTrue);
      expect(report.governancePassed, isTrue);
      expect(report.steps.length, equals(5));

      // 1. Busca e abertura
      final step1 = report.steps.firstWhere((s) => s.stage == DeveloperJourneyStage.searchAndOpenProject);
      expect(step1.isSuccessful, isTrue);
      expect(step1.durationMs, lessThan(30.0));

      // 2. Edição e refatoração
      final step2 = report.steps.firstWhere((s) => s.stage == DeveloperJourneyStage.editAndRefactor);
      expect(step2.isSuccessful, isTrue);
      expect(step2.durationMs, lessThan(60.0));

      // 3. Testes e depuração
      final step3 = report.steps.firstWhere((s) => s.stage == DeveloperJourneyStage.testAndDebug);
      expect(step3.isSuccessful, isTrue);
      expect(step3.durationMs, lessThan(120.0));

      // 4. Revisão de hunks e conflitos
      final step4 = report.steps.firstWhere((s) => s.stage == DeveloperJourneyStage.reviewHunksAndConflicts);
      expect(step4.isSuccessful, isTrue);
      expect(step4.durationMs, lessThan(50.0));

      // 5. Continuação com harness
      final step5 = report.steps.firstWhere((s) => s.stage == DeveloperJourneyStage.resumeHarnessExecution);
      expect(step5.isSuccessful, isTrue);
      expect(step5.durationMs, lessThan(40.0));

      // Métricas agregadas
      expect(report.totalDurationMs, lessThan(300.0));
      expect(report.peakRssMb, lessThan(100.0));
      expect(report.totalAssertionsPassed, greaterThanOrEqualTo(25));
    });

    test('valida paridade de execução para ambientes remotos (SSH e WSL)', () {
      final reportSsh = service.runFullJourneyHomologation(
        projectRoot: '/remote/user/repo',
        targetEnvironment: 'SSH Remoto',
      );

      final reportWsl = service.runFullJourneyHomologation(
        projectRoot: '/mnt/c/Users/repo',
        targetEnvironment: 'WSL',
      );

      expect(reportSsh.allStagesPassed, isTrue);
      expect(reportWsl.allStagesPassed, isTrue);
      expect(reportSsh.targetEnvironment, equals('SSH Remoto'));
      expect(reportWsl.targetEnvironment, equals('WSL'));
    });
  });

  group('Q01 · RollbackGovernancePolicy (Governança e Rollback Reversível)', () {
    const service = IntegratedJourneyHomologationService();

    test('garante que todas as feature flags são reversíveis com rollback limpo confirmado', () {
      final governance = service.auditRollbackAndGovernance();

      expect(governance.isCompliant, isTrue);
      expect(governance.allFlagsReversible, isTrue);
      expect(governance.cleanRollbackConfirmed, isTrue);
      expect(governance.featureFlags.containsKey('useNativeOfficeWorld'), isTrue);
      expect(governance.featureFlags.containsKey('enableDapMultiLanguage'), isTrue);
      expect(governance.featureFlags.containsKey('enableLspAdvancedInlays'), isTrue);
      expect(governance.featureFlags.containsKey('enableOptimisticDbEdit'), isTrue);
      expect(governance.featureFlags.containsKey('enableDirectTerminalHarness'), isTrue);
      expect(governance.featureFlags.containsKey('enableDockerUsefulTasks'), isTrue);
    });

    test('exige estritamente aprovação explícita antes de qualquer merge em branch de produção', () {
      final governance = service.auditRollbackAndGovernance();

      expect(governance.requiresExplicitMergeApproval, isTrue);
    });

    test('certifica que componentes de terceiros possuem licenças permissivas sem contaminação copyleft', () {
      final governance = service.auditRollbackAndGovernance();

      expect(governance.thirdPartyNotices, isNotEmpty);
      for (final notice in governance.thirdPartyNotices) {
        expect(notice.isPermissive, isTrue, reason: '${notice.componentName} deve ser permissivo');
        expect(notice.hasAttributionNotice, isTrue, reason: '${notice.componentName} deve ter atribuição');
        expect(notice.avoidsCopyleftContamination, isTrue, reason: '${notice.componentName} não pode contaminar');
      }
    });
  });
}
