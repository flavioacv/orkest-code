# X03 · Avaliação de Docker, Build e Deployment

**Status:** Concluído  
**Data de Conclusão:** 05/11/2026  
**Prioridade:** P3 · **Porte:** L  
**Dependências:** R01, A04  
**Branch:** `fix/harness-state-detection`  
**Referência:** ide-docker, ide-build, ide-remote, build-tools  
**Destino:** Tasks, SSH e serviços remotos existentes  

---

## 1. Contexto e Objetivos

O item X03 estabelece a infraestrutura técnica para inspeção de containers Docker/Podman, descoberta inteligente de tarefas de build legítimas e execução segura de deployments com confirmação explícita no ecossistema do Orkest Code:
1. **Inspeção e Ciclo de Vida Docker/Podman (`DockerInspectionParser`):** Decodificação estruturada das saídas JSON de `docker ps` e `docker inspect`, mapeando identificadores, nomes primários, imagens, estados de execução (`running`, `exited`, `paused`, `restarting`), endereços IP de rede interna, portas mapeadas, montagens de volumes e políticas de reinicialização.
2. **Descoberta Contextual de Build sem Instalação Forçada (`UsefulBuildTaskDetector`):** Detecção estática de manifestos existentes no workspace (`pubspec.yaml`, `Cargo.toml`, `package.json`, `go.mod`, `Makefile`, `Dockerfile`, `compose.yaml`), gerando tarefas úteis classificadas por tipo (`bundle`, `compile`, `test`, `dockerBuild`) sem jamais instalar dependências ou executáveis automaticamente no host do usuário.
3. **Plano de Deployment com Preview e Confirmação Obrigatória (`DeploymentPlanService`):** Comparação atômica entre o inventário de artefatos locais e remotos (`added`, `modified`, `deleted`, `unchanged`), cômputo de bytes a transferir e imposição estrita de barreira de segurança: qualquer execução de deployment sem confirmação humana explícita (`isConfirmed == true`) é bloqueada e lança erro de estado impeditivo.

---

## 2. Componentes Implementados

### 2.1 Entidades de Domínio (`cockpit/lib/app/core/domain/entities/docker_build_deploy.dart`)
- **`DockerContainerStatus`**: Enum com os estados canônicos de containers.
- **`DockerContainer`**: Representação imutável com ID, nomes, imagem, status, portas, comandos e mounts.
- **`DockerInspectReport`**: Relatório aprofundado contendo configurações de rede, IP, volumes, variáveis de ambiente e restart policy.
- **`BuildTaskKind`** & **`UsefulBuildTask`**: Modelagem imutável de tarefas legítimas de build com ferramenta associada, diretório de execução e linha de comando completa.
- **`DeploymentDiffKind`** & **`DeploymentDiffEntry`**: Entradas de diferença por arquivo com tamanho em bytes e hashes.
- **`DeploymentPlan`**: Plano consolidado de deployment com contadores de alterações, bytes a transferir e flag inviolável de segurança `isConfirmed`.

### 2.2 Serviços de Domínio (`cockpit/lib/app/core/domain/services/docker_build_deploy_service.dart`)
- **`DockerInspectionParser`**: Parser de saídas JSONL de `ps` e JSON detalhado de `inspect`.
- **`UsefulBuildTaskDetector`**: Analisador de manifestos de projeto no workspace.
- **`DeploymentPlanService`**: Orquestrador de planos de deployment com cálculo de diffs, método `confirmPlan` e bloqueio rigoroso em `executeDeployment` caso o plano não tenha sido previamente confirmado.

---

## 3. Validação e Qualidade

- **Testes Unitários:** 5 testes em `cockpit/test/domain/docker_build_deploy_test.dart`:
  1. Parsing preciso de JSON de containers ativos e inativos com portas e comandos;
  2. Parsing de relatório `docker inspect` com IP, portas, volumes e restart policy;
  3. Descoberta de tarefas de build para Flutter, Cargo, NPM e Docker sem instalação de ferramentas;
  4. Cálculo de diffs de deployment (added, modified, deleted, unchanged) e volume de transferência;
  5. Bloqueio determinístico de deployment sem confirmação e execução segura após confirmação.
- **Suíte Combinada:** 31 testes aprovados em conjunto (`docker_build_deploy_test.dart`, `http_advanced_tools_test.dart`, `editor_productivity_test.dart`).
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` concluído com **0 issues**.
