# Empacotamento e Supervisão de Serviços Nativos Selecionados (A05)

> **Atividade:** `A05 · Empacotar e supervisionar serviços nativos selecionados`  
> **Prioridade:** P1 · Porte: L · Dependências: A04 (Concluída)  
> **Status:** Concluído e Validado em Suite Automatizada  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivos

Conforme definido na decisão arquitetural **A04** (`plan/72-decisao-arquitetura-por-dominio.md`), ferramentas essenciais do desenvolvedor (Git, DAP, LSP, ripgrep) utilizam processos independentes operando via streams `stdio` (JSON-RPC ou CLI), garantindo isolamento total de falhas em relação ao runtime Flutter do Orkest Code.

A atividade **A05** entrega o subsistema de **resolução, empacotamento, ciclo de vida e supervisão robusta** desses serviços nativos, atendendo a todos os critérios de aceite:
1. **Resolução de Binários por OS e Arquitetura (`NativeBinaryResolver`):** Mapeamento para `macos-arm64`, `macos-x64`, `linux-arm64`, `linux-x64`, `windows-arm64` e `windows-x64` (com sufixo `.exe`);
2. **Ciclo de Vida e Encerramento Forçado de Filhos (`NativeServiceSupervisor`):** Descarte seguro de processos filhos via envio inicial de `SIGTERM` e escalonamento para `SIGKILL` após timeout configurável (`killTimeout`), prevenindo processos órfãos no descarte da UI (`dispose`);
3. **Validação de Handshake e Versão de Protocolo:** Detecção precoce de incompatibilidades com rejeição limpa e erro tipado (`IncompatibleProtocolException`);
4. **Proteção contra Loop de Quedas ("Crash Loop"):** Detecção de crashes sucessivos dentro de uma janela de tempo (`crashWindow`), com auto-restart controlado e transição para o estado `NativeServiceState.degraded` quando o limite (`maxCrashesInWindow`) for atingido;
5. **Rollback de Atualização:** Capacidade de reverter para o binário anterior (`fallbackBinaryPath`) e reiniciar o serviço de forma resiliente;
6. **Sanitização de Logs (`LogSanitizer`):** Mascaramento em tempo real de tokens Bearer, chaves privadas PEM, senhas em flags CLI, senhas em JSON e credenciais embutidas em URLs de conexão, garantindo que nada sensível seja gravado em logs ou telemetria;
7. **Ausência de Ferramentas Externas:** Tratamento gracioso via `NativeBinaryNotFoundException` com lista dos caminhos inspecionados quando um binário opcional ou obrigatório não estiver presente no sistema.

---

## 2. Componentes Entregues

- **`LogSanitizer`** (`cockpit/lib/app/orkest/domain/services/log_sanitizer.dart`):
  - Sanitizador de expressões regulares de alta precisão para proteção de logs de subprocessos.
- **`NativeBinaryResolver`** (`cockpit/lib/app/orkest/domain/services/native_binary_resolver.dart`):
  - Enum `NativePlatformArch` com detecção de plataforma em tempo de execução;
  - Resolução em cascata: binários empacotados no bundle -> pasta local de desenvolvimento `.orkest/bin/` -> `PATH` do sistema;
  - Exceção especializada `NativeBinaryNotFoundException`.
- **`NativeServiceSupervisor`** (`cockpit/lib/app/orkest/domain/services/native_service_supervisor.dart`):
  - Estados do ciclo de vida: `unstarted`, `starting`, `running`, `stopping`, `stopped`, `degraded`;
  - Configuração extensível `NativeServiceConfig`;
  - `start()`, `stop()`, `restart()`, `rollback()`, `performHandshake()`, `dispose()`.

---

## 3. Validação e Qualidade

- **15 testes unitários dedicados** em:
  - `cockpit/test/domain/log_sanitizer_test.dart` (5 testes);
  - `cockpit/test/domain/native_binary_resolver_test.dart` (5 testes);
  - `cockpit/test/domain/native_service_supervisor_test.dart` (5 testes).
- **100% de aprovação** na suíte de testes automatizados.
- **Análise estática limpa** via `dart analyze --fatal-infos` (0 issues).
