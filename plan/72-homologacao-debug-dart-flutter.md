# Homologação de Debug Dart e Flutter (R03 Orkest Code)

> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`  
> **Status:** Concluído e Validado

---

## 1. Contexto e Motivação
A atividade `R03 · Homologar debug Dart e Flutter` consolida o suporte de depuração nativa no Orkest Code para as linguagens primárias da plataforma (Dart e Flutter), operando diretamente sobre os adaptadores DAP oficiais fornecidos pelos SDKs (`dart debug_adapter` e `flutter debug_adapter`).

Essa arquitetura elimina proxies intermediários e garante fidelidade com o comportamento do ecossistema de desenvolvimento, incluindo Hot Reload, Hot Restart, filtros de exceção e seleção de alvos de dispositivo.

---

## 2. Componentes Entregues

### 2.1. Adaptador Especializado Dart / Flutter (`cockpit/lib/app/core/data/dap/dart_debug_adapter.dart`)
- **Tipos de Alvo (`DartDebugType`):**
  - `dartCli`: Scripts e ferramentas CLI Dart (`dart run`).
  - `dartTest`: Suíte de testes unitários Dart (`dart test`).
  - `flutterApp`: Aplicações móveis e desktop Flutter (`flutter run`).
  - `flutterTest`: Testes de widget e integração Flutter (`flutter test`).
- **Alvo Configurável (`DartDebugTarget`):**
  - Parâmetros: `program`, `cwd`, `args`, `toolArgs`, `vmAdditionalArgs`, `deviceId`, `noDebug`.
  - Serialização para argumentos oficiais de `launch` do adaptador DAP Dart/Flutter.
  - Construtor estático para argumentos de `attach` com conexão a `vmServiceUri`.
- **Orquestração de Processo (`DartDebugAdapter`):**
  - Resolução do comando oficial do SDK (`dart debug_adapter` e `flutter debug_adapter`), com suporte a caminhos de SDK customizados (`sdkPath`).
  - Inicialização transparente de subprocesso stdio e encapsulamento em `DapClient`.

### 2.2. Protocolo DAP Estendido (`cockpit/lib/app/core/data/dap/dap_client.dart`)
- **Factory `fromProcess`:** Criação de instâncias `DapClient` a partir de um `Process` Dart em execução.
- **Requisições de Exceção (`setExceptionBreakpoints`):** Envio dos filtros suportados pela VM (`None`, `All`, `Unhandled`).
- **Hot Reload & Hot Restart (`hotReload`, `hotRestart`):** Requisições customizadas DAP do Flutter via JSON-RPC com tratamento tipado de respostas de sucesso e mensagens de erro.

### 2.3. Controller de Sessão Integrado (`cockpit/lib/app/core/data/dap/debug_session_controller.dart`)
- `startDartSession`: Inicia a sessão especializada, armazena `activeTarget`, configura breakpoints e define modo de exceção.
- Detecção reativa `isFlutter` para ativação condicional de capacidades de hot reload/restart.
- Métodos `hotReload()` e `hotRestart()` com logs estruturados no console de depuração.
- Controle dinâmico do filtro de exceções (`setExceptionMode`).
- Limpeza de recursos e término do subprocesso no descarte/encerramento da sessão.

### 2.4. Controles de UI Aprimorados (`cockpit/lib/app/orkest/ui/widgets/debug_toolbar.dart`)
- **Ações Visuais Flutter:** Botões dedicados de Hot Reload (ícone de raio/zap) e Hot Restart (ícone de rotação) renderizados na barra flutuante quando o alvo ativo for Flutter.
- **Atalhos de Teclado Nativos:**
  - `Ctrl+F5`: Hot Reload
  - `Ctrl+Shift+F5`: Hot Restart
  - `F5`: Continuar execução
  - `F10`: Passar Sobre (Step Over / Next)
  - `F11`: Entrar (Step Into)
  - `Shift+F11`: Sair (Step Out)
  - `Shift+F5`: Parar depuração

---

## 3. Validação e Testes Automatizados
- **Suíte de Testes Especializada (`cockpit/test/data/dart_debug_adapter_test.dart`):**
  - Resolução de comandos Dart e Flutter com SDK padrão e SDK customizado.
  - Formatação precisa dos argumentos de launch e attach.
  - Ciclo de vida com mock do adaptador DAP Dart/Flutter.
  - Execução bem-sucedida de Hot Reload e Hot Restart.
  - Modos de captura de exceções (`Unhandled`, `All`).
  - Limpeza completa do estado e desativação de controles no encerramento.
- **Suítes de Regressão e UI:** 20 testes DAP aprovados (`dap_core_test.dart`, `debug_widgets_test.dart`, `dart_debug_adapter_test.dart`).
- **Análise Estática:** `dart analyze --fatal-infos` com **zero issues** no projeto `cockpit`.
