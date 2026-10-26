///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsPtBr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPtBr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ptBr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt-BR>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsPtBr _root = this; // ignore: unused_field

	@override 
	TranslationsPtBr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPtBr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$core$pt_BR core = _Translations$core$pt_BR._(_root);
	@override late final _Translations$common$pt_BR common = _Translations$common$pt_BR._(_root);
	@override late final _Translations$orkest$pt_BR orkest = _Translations$orkest$pt_BR._(_root);
	@override late final _Translations$settings$pt_BR settings = _Translations$settings$pt_BR._(_root);
	@override late final _Translations$automation$pt_BR automation = _Translations$automation$pt_BR._(_root);
	@override late final _Translations$fileOperation$pt_BR fileOperation = _Translations$fileOperation$pt_BR._(_root);
	@override late final _Translations$theme$pt_BR theme = _Translations$theme$pt_BR._(_root);
}

// Path: core
class _Translations$core$pt_BR extends Translations$core$en {
	_Translations$core$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$core$bootstrapError$pt_BR bootstrapError = _Translations$core$bootstrapError$pt_BR._(_root);
	@override late final _Translations$core$macosNotifications$pt_BR macosNotifications = _Translations$core$macosNotifications$pt_BR._(_root);
	@override late final _Translations$core$appErrorView$pt_BR appErrorView = _Translations$core$appErrorView$pt_BR._(_root);
	@override late final _Translations$core$errorReportDialog$pt_BR errorReportDialog = _Translations$core$errorReportDialog$pt_BR._(_root);
	@override late final _Translations$core$windowControls$pt_BR windowControls = _Translations$core$windowControls$pt_BR._(_root);
	@override late final _Translations$core$crash$pt_BR crash = _Translations$core$crash$pt_BR._(_root);
	@override late final _Translations$core$menu$pt_BR menu = _Translations$core$menu$pt_BR._(_root);
}

// Path: common
class _Translations$common$pt_BR extends Translations$common$en {
	_Translations$common$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Confirmar';
	@override String get create => 'Criar';
	@override String get gotIt => 'Entendi';
	@override String get save => 'Salvar';
	@override String get close => 'Fechar';
	@override String get delete => 'Excluir';
	@override String get done => 'Concluído';
	@override String get add => 'Adicionar';
	@override String get test => 'Testar';
	@override String get ok => 'OK';
	@override String get loading => 'Carregando…';
	@override String get checking => 'Verificando…';
	@override String get remove => 'Remover';
	@override String get restart => 'Reiniciar';
	@override String get settings => 'Configurações';
	@override String get send => 'Enviar';
	@override String get open => 'Abrir';
	@override String get dismiss => 'Dispensar';
	@override String get report => 'Reportar';
	@override String get copyCode => 'Copiar código';
	@override String get search => 'Buscar';
	@override String get noResults => 'Nenhum resultado';
}

// Path: orkest
class _Translations$orkest$pt_BR extends Translations$orkest$en {
	_Translations$orkest$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$orkest$officeWorld$pt_BR officeWorld = _Translations$orkest$officeWorld$pt_BR._(_root);
	@override late final _Translations$orkest$confirmDialog$pt_BR confirmDialog = _Translations$orkest$confirmDialog$pt_BR._(_root);
	@override late final _Translations$orkest$neovim$pt_BR neovim = _Translations$orkest$neovim$pt_BR._(_root);
	@override late final _Translations$orkest$worktreeCreateDialog$pt_BR worktreeCreateDialog = _Translations$orkest$worktreeCreateDialog$pt_BR._(_root);
	@override late final _Translations$orkest$commitMessageDialog$pt_BR commitMessageDialog = _Translations$orkest$commitMessageDialog$pt_BR._(_root);
	@override late final _Translations$orkest$tasksPanel$pt_BR tasksPanel = _Translations$orkest$tasksPanel$pt_BR._(_root);
	@override late final _Translations$orkest$orkestPage$pt_BR orkestPage = _Translations$orkest$orkestPage$pt_BR._(_root);
	@override late final _Translations$orkest$branchPicker$pt_BR branchPicker = _Translations$orkest$branchPicker$pt_BR._(_root);
	@override late final _Translations$orkest$welcomeView$pt_BR welcomeView = _Translations$orkest$welcomeView$pt_BR._(_root);
	@override late final _Translations$orkest$paneView$pt_BR paneView = _Translations$orkest$paneView$pt_BR._(_root);
	@override late final _Translations$orkest$fileTreePanel$pt_BR fileTreePanel = _Translations$orkest$fileTreePanel$pt_BR._(_root);
	@override late final _Translations$orkest$fileViewer$pt_BR fileViewer = _Translations$orkest$fileViewer$pt_BR._(_root);
	@override late final _Translations$orkest$workspaceSettingsDialog$pt_BR workspaceSettingsDialog = _Translations$orkest$workspaceSettingsDialog$pt_BR._(_root);
	@override late final _Translations$orkest$realmDialogs$pt_BR realmDialogs = _Translations$orkest$realmDialogs$pt_BR._(_root);
	@override late final _Translations$orkest$dbRedisTable$pt_BR dbRedisTable = _Translations$orkest$dbRedisTable$pt_BR._(_root);
	@override late final _Translations$orkest$dbQueryView$pt_BR dbQueryView = _Translations$orkest$dbQueryView$pt_BR._(_root);
	@override late final _Translations$orkest$httpView$pt_BR httpView = _Translations$orkest$httpView$pt_BR._(_root);
	@override late final _Translations$orkest$kanbanView$pt_BR kanbanView = _Translations$orkest$kanbanView$pt_BR._(_root);
	@override late final _Translations$orkest$dbPanel$pt_BR dbPanel = _Translations$orkest$dbPanel$pt_BR._(_root);
	@override late final _Translations$orkest$dbMongoView$pt_BR dbMongoView = _Translations$orkest$dbMongoView$pt_BR._(_root);
	@override late final _Translations$orkest$dbConnectionDialog$pt_BR dbConnectionDialog = _Translations$orkest$dbConnectionDialog$pt_BR._(_root);
	@override late final _Translations$orkest$sshPrompts$pt_BR sshPrompts = _Translations$orkest$sshPrompts$pt_BR._(_root);
	@override late final _Translations$orkest$projectsRail$pt_BR projectsRail = _Translations$orkest$projectsRail$pt_BR._(_root);
	@override late final _Translations$orkest$findBar$pt_BR findBar = _Translations$orkest$findBar$pt_BR._(_root);
	@override late final _Translations$orkest$contentSearch$pt_BR contentSearch = _Translations$orkest$contentSearch$pt_BR._(_root);
	@override late final _Translations$orkest$topbar$pt_BR topbar = _Translations$orkest$topbar$pt_BR._(_root);
	@override late final _Translations$orkest$tasks$pt_BR tasks = _Translations$orkest$tasks$pt_BR._(_root);
	@override late final _Translations$orkest$notifications$pt_BR notifications = _Translations$orkest$notifications$pt_BR._(_root);
	@override late final _Translations$orkest$terminalLink$pt_BR terminalLink = _Translations$orkest$terminalLink$pt_BR._(_root);
	@override late final _Translations$orkest$terminal$pt_BR terminal = _Translations$orkest$terminal$pt_BR._(_root);
	@override late final _Translations$orkest$remoteHost$pt_BR remoteHost = _Translations$orkest$remoteHost$pt_BR._(_root);
	@override late final _Translations$orkest$browserPane$pt_BR browserPane = _Translations$orkest$browserPane$pt_BR._(_root);
	@override late final _Translations$orkest$documentWindow$pt_BR documentWindow = _Translations$orkest$documentWindow$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$pt_BR gallery = _Translations$orkest$gallery$pt_BR._(_root);
	@override late final _Translations$orkest$notebook$pt_BR notebook = _Translations$orkest$notebook$pt_BR._(_root);
	@override late final _Translations$orkest$layoutPreview$pt_BR layoutPreview = _Translations$orkest$layoutPreview$pt_BR._(_root);
	@override late final _Translations$orkest$telemetry$pt_BR telemetry = _Translations$orkest$telemetry$pt_BR._(_root);
	@override late final _Translations$orkest$panelView$pt_BR panelView = _Translations$orkest$panelView$pt_BR._(_root);
}

// Path: settings
class _Translations$settings$pt_BR extends Translations$settings$en {
	_Translations$settings$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$language$pt_BR language = _Translations$settings$language$pt_BR._(_root);
	@override late final _Translations$settings$page$pt_BR page = _Translations$settings$page$pt_BR._(_root);
	@override late final _Translations$settings$remoteHosts$pt_BR remoteHosts = _Translations$settings$remoteHosts$pt_BR._(_root);
}

// Path: automation
class _Translations$automation$pt_BR extends Translations$automation$en {
	_Translations$automation$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$automation$error$pt_BR error = _Translations$automation$error$pt_BR._(_root);
}

// Path: fileOperation
class _Translations$fileOperation$pt_BR extends Translations$fileOperation$en {
	_Translations$fileOperation$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$fileOperation$error$pt_BR error = _Translations$fileOperation$error$pt_BR._(_root);
}

// Path: theme
class _Translations$theme$pt_BR extends Translations$theme$en {
	_Translations$theme$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$theme$error$pt_BR error = _Translations$theme$error$pt_BR._(_root);
}

// Path: core.bootstrapError
class _Translations$core$bootstrapError$pt_BR extends Translations$core$bootstrapError$en {
	_Translations$core$bootstrapError$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Falha ao inicializar o Orkest Code';
	@override String get retry => 'Tentar novamente';
}

// Path: core.macosNotifications
class _Translations$core$macosNotifications$pt_BR extends Translations$core$macosNotifications$en {
	_Translations$core$macosNotifications$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ativar notificações no macOS';
	@override String get intro => 'As notificações estão desativadas nas configurações do sistema. Siga os passos abaixo para ativá-las:';
	@override String get step1 => 'Abra as Configurações do Sistema no seu Mac.';
	@override String get step2 => 'Acesse a seção Notificações na barra lateral esquerda.';
	@override String get step3 => 'Encontre e selecione o aplicativo Orkest Code na lista.';
	@override String get step4 => 'Ative a opção Permitir Notificações.';
	@override String get tip => 'Dica: se o aplicativo não aparecer na lista, feche e reabra-o para acionar seu registro no sistema.';
	@override String get gotIt => 'Entendi';
}

// Path: core.appErrorView
class _Translations$core$appErrorView$pt_BR extends Translations$core$appErrorView$en {
	_Translations$core$appErrorView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get renderFailed => 'Esta parte do aplicativo falhou ao renderizar';
	@override String get details => 'Detalhes';
	@override String get renderErrorTitle => 'Erro de renderização';
}

// Path: core.errorReportDialog
class _Translations$core$errorReportDialog$pt_BR extends Translations$core$errorReportDialog$en {
	_Translations$core$errorReportDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get defaultDescription => 'Algo deu errado. Os detalhes abaixo foram salvos no log — você pode reportá-los para que isso seja corrigido.';
	@override String get copyDetails => 'Copiar detalhes';
	@override String get reportIssue => 'Reportar problema';
}

// Path: core.windowControls
class _Translations$core$windowControls$pt_BR extends Translations$core$windowControls$en {
	_Translations$core$windowControls$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get minimize => 'Minimizar';
	@override String get maximize => 'Maximizar';
	@override String get close => 'Fechar';
}

// Path: core.crash
class _Translations$core$crash$pt_BR extends Translations$core$crash$en {
	_Translations$core$crash$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Encerramento inesperado';
	@override String get bannerTitle => 'O Orkest Code fechou inesperadamente';
	@override String get report => 'Reportar';
	@override String get dismiss => 'Dispensar';
	@override String crashMessage({required Object version}) => 'A sessão anterior (versão ${version}) terminou sem encerrar corretamente. Quer reportar? O log vai junto e você pode revisar tudo antes de enviar.';
	@override String crashError({required Object startedAt, required Object pid}) => 'A sessão iniciada em ${startedAt} (pid ${pid}) terminou sem encerramento limpo.';
	@override String get crashDescription => 'Nenhum erro foi capturado: o app foi encerrado pelo sistema. O log abaixo é dessa sessão e é a parte mais útil.';
}

// Path: core.menu
class _Translations$core$menu$pt_BR extends Translations$core$menu$en {
	_Translations$core$menu$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get settings => 'Configurações…';
	@override String get checkForUpdates => 'Verificar Atualizações…';
	@override String get file => 'Arquivo';
	@override String get newTerminal => 'Novo Terminal';
	@override String get openWorkspace => 'Abrir Workspace';
	@override String get goToFile => 'Ir para Arquivo…';
	@override String get save => 'Salvar';
	@override String get discard => 'Descartar';
	@override String get format => 'Formatar';
	@override String get view => 'Exibir';
	@override String get toggleWorkspacePanel => 'Alternar Painel de Workspaces';
	@override String get toggleFiles => 'Alternar Arquivos';
	@override String get splitRight => 'Dividir à Direita';
	@override String get splitDown => 'Dividir Abaixo';
	@override String get focusPane => 'Focar Painel';
	@override String get focusLeft => 'Esquerda  (⌘⌥←)';
	@override String get focusRight => 'Direita  (⌘⌥→)';
	@override String get focusUp => 'Acima  (⌘⌥↑)';
	@override String get focusDown => 'Abaixo  (⌘⌥↓)';
	@override String get selectTab => 'Selecionar Aba';
	@override String tabN({required Object n}) => 'Aba ${n}';
	@override String get lastTab => 'Última Aba';
	@override String get previousWorkspace => 'Workspace Anterior';
	@override String get nextWorkspace => 'Próximo Workspace';
	@override String get zoomIn => 'Aumentar Zoom';
	@override String get zoomOut => 'Diminuir Zoom';
	@override String get actualSize => 'Tamanho Real';
	@override String get window => 'Janela';
	@override String get quit => 'Sair';
	@override String get minimize => 'Minimizar';
	@override String get zoom => 'Zoom';
}

// Path: orkest.officeWorld
class _Translations$orkest$officeWorld$pt_BR extends Translations$orkest$officeWorld$en {
	_Translations$orkest$officeWorld$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get reception => 'Recepção';
	@override String get cafe => 'Copa';
	@override String get restrooms => 'Banheiros';
	@override String get lounge => 'Lounge';
	@override String get rosterTitle => 'Agentes do escritório';
	@override String get rosterSearch => 'Buscar agentes ou projetos';
	@override String get rosterEmpty => 'Nenhum agente ativo encontrado';
	@override String get activityFeed => 'Atividade';
	@override String get activityEmpty => 'As atividades observadas aparecerão aqui.';
	@override String get collapseRoster => 'Recolher lista de agentes';
	@override String get collapseFeed => 'Recolher atividades';
	@override String get reopenRoster => 'Agentes';
	@override String get reopenFeed => 'Atividade';
	@override String get working => 'Trabalhando';
	@override String get waiting => 'Aguardando';
	@override String get idle => 'Disponível';
	@override String get agentProfile => 'Perfil do agente';
	@override String get project => 'Projeto';
	@override String get provider => 'Agente';
	@override String get currentStatus => 'Status atual';
	@override String get followAgent => 'Seguir personagem';
	@override String get stopFollowingAgent => 'Parar de seguir';
	@override String get centerAgent => 'Centralizar personagem';
	@override String get sessionDuration => 'Sessão atual no Orkest Code';
	@override String get workingDirectory => 'Diretório de trabalho';
	@override String get statsPending => 'O Orkest Code ainda não coleta estatísticas de modelo, tokens e ferramentas.';
	@override String get recentActivity => 'Atividade recente nesta execução';
	@override String get promptReceived => 'Recebeu um pedido';
	@override String get agentThinking => 'Pensando';
	@override String get agentResponded => 'Resposta enviada';
	@override String get activityError => 'Algo deu errado';
	@override String get readingFile => 'Lendo arquivo';
	@override String get searchingCode => 'Buscando no código';
	@override String get editingFile => 'Editando arquivo';
	@override String get writingFile => 'Escrevendo arquivo';
	@override String get runningCommand => 'Comando no terminal';
	@override String get runningTests => 'Rodando testes';
	@override String get browsingWeb => 'Pesquisando na web';
	@override String get organizingTasks => 'Organizando tarefas';
	@override String get callingSubagents => 'Chamando subagentes';
	@override String get toolCompleted => 'Concluiu uma ferramenta';
	@override String get usingTool => 'Usando ferramenta';
	@override String get editAgentName => 'Editar nome do agente';
	@override String get agentName => 'Nome do agente';
	@override String get workingInTerminal => 'Trabalhando no terminal';
	@override String get waitingInTerminal => 'Precisa de você no terminal';
	@override String get waitingBubble => 'Responder no terminal';
	@override String get respond => 'Responder';
	@override String get dismissNotification => 'Dispensar aviso';
	@override String get editAppearance => 'Editar personagem';
	@override String get randomizeAppearance => 'Sortear';
	@override String get resetAppearance => 'Voltar ao sorteio';
	@override String get skin => 'Pele';
	@override String get hair => 'Cabelo';
	@override String get beard => 'Barba';
	@override String get eyes => 'Olhos';
	@override String get top => 'Parte de cima';
	@override String get bottom => 'Parte de baixo';
	@override String get shoes => 'Sapatos';
	@override String get accessory => 'Acessório';
	@override String get turnCompleted => 'Turno concluído';
	@override String get subagentFailed => 'Subagente falhou';
	@override String get subagentInterrupted => 'Subagente interrompido';
	@override String get openTerminal => 'Abrir terminal';
	@override String get interactInOffice => 'Interagir no Office';
	@override String get liveTerminal => 'Terminal ao vivo';
	@override String get terminalInputPlaceholder => 'Digite no terminal…';
	@override String get terminalOfficeHint => 'A entrada vai para a sessão original. Use as opções de resposta que o agente mostrar neste terminal.';
	@override String get appearance => 'Aparência do escritório';
	@override String get officeTheme => 'Tema sazonal';
	@override String get themeAuto => 'Automático';
	@override String get themeNone => 'Original';
	@override String get themeChristmas => 'Natal';
	@override String get themeHalloween => 'Halloween';
	@override String get showNames => 'Mostrar nomes dos agentes';
	@override String get bubbles => 'Balões de atividade';
	@override String get bubblesAll => 'Todos';
	@override String get bubblesImportant => 'Importantes';
	@override String get bubblesNone => 'Nenhum';
	@override String get movement => 'Movimento pelo escritório';
	@override String get movementCalm => 'Calmo';
	@override String get movementNormal => 'Normal';
	@override String get movementLively => 'Agitado';
	@override String get daylight => 'Ciclo dia/noite';
	@override String get sounds => 'Sons do escritório';
	@override String get soundVolume => 'Volume';
	@override String get soundAlerts => 'Avisos e tarefas concluídas';
	@override String get soundKeys => 'Teclado';
	@override String get soundElevator => 'Elevador';
	@override String get soundSocial => 'Pingue-pongue e fliperama';
	@override String get daylightAuto => 'Automático';
	@override String get daylightDay => 'Sempre dia';
	@override String get daylightNight => 'Sempre noite';
	@override String get socialLife => 'Vida social';
	@override String gameCoins({required Object count}) => '${count} moedinhas do escritório';
	@override String earnedWorking({required Object count}) => '${count} ganhos com atividades';
	@override String matchRecord({required Object wins, required Object losses}) => '${wins} vitórias · ${losses} derrotas';
	@override String get personality => 'Personalidade';
	@override String get friendships => 'Amizades';
	@override String get rivals => 'Rivalidades';
	@override String get socialLedger => 'Extrato de moedinhas';
	@override String get socialActivity => 'Vida social do escritório';
	@override String delegatedBy({required Object name}) => 'Delegado por ${name}';
	@override String get shellWaiting => 'Esperando um comando';
	@override String get socialEconomy => 'Jogo do escritório — sem valor monetário real';
}

// Path: orkest.confirmDialog
class _Translations$orkest$confirmDialog$pt_BR extends Translations$orkest$confirmDialog$en {
	_Translations$orkest$confirmDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get unsavedChangesTitle => 'Alterações não salvas';
	@override String unsavedChangesMessage({required Object fileName}) => '“${fileName}” tem alterações não salvas. Salvar antes de fechar?';
	@override String get dontSave => 'Não salvar';
	@override String get saveAndClose => 'Salvar e fechar';
}

// Path: orkest.neovim
class _Translations$orkest$neovim$pt_BR extends Translations$orkest$neovim$en {
	_Translations$orkest$neovim$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get unavailable => 'O Neovim não está disponível. Abrindo no Orkest Code.';
	@override String get openFailed => 'Não foi possível acessar o Neovim. Abrindo no Orkest Code.';
	@override String get unsavedTitle => 'Buffers não salvos no Neovim';
	@override String get unsavedMessage => 'O Neovim tem buffers modificados. Fechar a aba e descartar essas alterações?';
	@override String get closeAnyway => 'Fechar mesmo assim';
}

// Path: orkest.worktreeCreateDialog
class _Translations$orkest$worktreeCreateDialog$pt_BR extends Translations$orkest$worktreeCreateDialog$en {
	_Translations$orkest$worktreeCreateDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get forkTitle => 'Fork da worktree';
	@override String get createTitle => 'Criar worktree';
	@override String forkSubtitle({required Object root}) => 'Nova worktree ramificada a partir de ${root}.';
	@override String createSubtitle({required Object root}) => 'Nova feature em ${root} — novo branch a partir do HEAD atual.';
	@override String get namePlaceholder => 'feat/minha-feature';
	@override String get errorWhitespace => 'Sem espaços no nome.';
	@override String get errorInvalidChar => 'Caractere inválido para nome de branch.';
	@override String get errorInvalidSequence => 'Sequência inválida (ex.: "..", "//", começar/terminar com "/").';
	@override String get errorReserved => 'Posição reservada (não comece com "-"/"." nem termine com ".lock").';
	@override String get errorDuplicateBranch => 'Já existe um branch com esse nome.';
	@override String get errorDuplicateWorktree => 'Já existe uma worktree com esse nome.';
	@override String errorBranchHierarchyConflict({required Object target, required Object existing}) => 'Não é possível criar o branch \'${target}\' porque ele conflita com o branch \'${existing}\' já existente.';
	@override String get errorBranchHierarchicalConflictGeneral => 'Já existe um branch com uma hierarquia conflitante.';
	@override String get fork => 'Fork';
	@override String get postCheckoutHint => 'Este repositório tem um hook post-checkout.';
	@override String get running => 'Executando…';
	@override String get advancedSettings => 'Configurações Avançadas';
	@override String get copyIgnored => 'Copiar arquivos ignorados (.gitignore)';
	@override String get copyIgnoredDesc => 'Copia arquivos ignorados pelo .gitignore (ex: .env, chaves locais) para a nova pasta.';
	@override String get copyUntracked => 'Copiar arquivos não rastreados';
	@override String get copyUntrackedDesc => 'Copia arquivos novos ou modificados que ainda não foram adicionados ao stage.';
	@override String get baseBranch => 'Branch base';
	@override String get baseBranchDesc => 'O branch de onde a nova worktree e branch serão ramificados.';
	@override String get fetchRemote => 'Sincronizar branch remota (fetch)';
	@override String get fetchRemoteDesc => 'Roda git fetch para garantir que a branch base esteja confirmada antes de criar a worktree.';
	@override String get searchBranch => 'Buscar branch...';
	@override String get back => 'Voltar';
}

// Path: orkest.commitMessageDialog
class _Translations$orkest$commitMessageDialog$pt_BR extends Translations$orkest$commitMessageDialog$en {
	_Translations$orkest$commitMessageDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get commitTitle => 'Commit';
	@override String get stageAndCommitTitle => 'Stage e Commit';
	@override String scopeNote({required Object fileName}) => 'Commit apenas de "${fileName}".';
	@override String get placeholder => 'fix: resumo curto da mudança';
	@override String get errorEmptySubject => 'A primeira linha (assunto) não pode ficar vazia.';
	@override String errorTooShort({required Object min}) => 'Assunto muito curto (mín. ${min} caracteres).';
	@override String errorTooLong({required Object max}) => 'Assunto muito longo (máx. ${max} caracteres).';
	@override String get errorTrailingPeriod => 'O assunto não deve terminar com ponto.';
	@override String get errorControlChars => 'O assunto contém caracteres de controle.';
	@override String get errorBlankSecondLine => 'Deixe a segunda linha em branco (separador entre assunto e corpo do git).';
	@override String get generate => 'Gerar mensagem de commit';
	@override String generateWith({required Object harness}) => 'Gerar com ${harness}';
	@override String get generating => 'Gerando…';
	@override String get cancelGeneration => 'Cancelar geração';
}

// Path: orkest.tasksPanel
class _Translations$orkest$tasksPanel$pt_BR extends Translations$orkest$tasksPanel$en {
	_Translations$orkest$tasksPanel$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get reloadTasksTooltip => 'Recarregar tasks';
	@override String get restartTooltip => 'Reiniciar';
	@override String get stopTooltip => 'Parar';
	@override String get runTooltip => 'Executar';
	@override String sendsKeyTooltip({required Object label, required Object key}) => '${label} (envia \'${key}\')';
	@override String get startingTooltip => 'Iniciando…';
	@override String get stoppingTooltip => 'Parando…';
	@override String get switchProfileTooltip => 'Trocar perfil';
	@override String get moreKeysTooltip => 'Mais teclas';
	@override String get sectionTasks => 'TAREFAS';
	@override String get noTasks => 'Nenhuma tarefa detectada neste projeto.';
	@override String get createTasksJson => 'Criar tasks.json';
	@override String get generateComposeTasks => 'Gerar tasks do Compose';
	@override String get selectComposeEngine => 'Escolha uma engine Compose';
	@override String get noComposeEngine => 'Docker Compose ou Podman Compose não foi encontrado.';
	@override String get invalidComposeFile => 'O arquivo ativo não é um Compose válido com services.';
	@override String get invalidTasksJson => 'tasks.json é inválido. Nenhuma alteração foi gravada.';
	@override String composeConflicts({required Object labels}) => 'Tasks não Compose com rótulos conflitantes foram mantidas: ${labels}';
}

// Path: orkest.orkestPage
class _Translations$orkest$orkestPage$pt_BR extends Translations$orkest$orkestPage$en {
	_Translations$orkest$orkestPage$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get chooseProjectFolderDialogTitle => 'Escolha a pasta do projeto';
	@override String get chooseWorkspaceFolderDialogTitle => 'Escolha a pasta do workspace';
	@override String get workspaceRenamedTitle => 'Workspace renomeado';
	@override String workspaceRenamedMessage({required Object name}) => 'O novo nome "${name}" só será enviado aos agentes após reiniciar o workspace ou o aplicativo.';
	@override String syncTitle({required Object label}) => 'Sync — ${label}';
	@override String pullTitle({required Object label}) => 'Pull — ${label}';
	@override String pushTitle({required Object label}) => 'Push — ${label}';
	@override String updateFromParentTitle({required Object name}) => 'Atualizar a partir do Pai — ${name}';
	@override String mergeToParentTitle({required Object name}) => 'Merge para o Pai — ${name}';
	@override String get worktreeMergedAndRemoved => 'Worktree mesclada e removida.';
	@override String get nothingWasChanged => 'Nada foi alterado.';
	@override String get newRealmTitle => 'Novo realm';
	@override String get closeWorkspaceTitle => 'Fechar workspace';
	@override String closeWorkspaceMessage({required Object name}) => 'Fechar "${name}"? Os agentes deste workspace serão encerrados. A pasta no disco é mantida.';
	@override String get closeAction => 'Fechar';
	@override String get removeWorktreeTitle => 'Remover worktree';
	@override String removeWorktreeMessage({required Object name, required Object warn}) => 'Remover "${name}"? A pasta da worktree e o branch serão excluídos e os agentes deste fork serão encerrados.${warn}';
	@override String removeWorktreeWarning({required Object name}) => '\n\nAviso: o branch "${name}" ainda não foi mesclado — removê-lo (git branch -D) descarta o trabalho não mesclado.';
	@override String get failedToRemoveWorktreeTitle => 'Falha ao remover a worktree';
	@override String get openLayoutTitle => 'Abrir layout';
	@override String get replaceLayoutTitle => 'Substituir o layout atual?';
	@override String replaceLayoutMessage({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 aba será fechada, e ela tem um processo em execução.',
		other: '${n} abas serão fechadas, inclusive as com processos em execução.',
	);
	@override String get replaceLayoutConfirm => 'Substituir';
	@override String get restartServerTooltip => 'Reiniciar servidor';
	@override String get noLspAvailable => 'Nenhum LSP disponível';
	@override String get lspRunning => 'em execução';
	@override String get lspStopped => 'parado';
}

// Path: orkest.branchPicker
class _Translations$orkest$branchPicker$pt_BR extends Translations$orkest$branchPicker$en {
	_Translations$orkest$branchPicker$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trocar branch';
	@override String tooltip({required Object branch}) => 'Branch atual: ${branch}';
	@override String get worktreeFixed => 'Esta branch é fixa para esta worktree.';
	@override String get worktreeFixedShort => 'worktree';
	@override String get usedByWorktree => 'A branch já está em uso por uma worktree.';
	@override String get searchPlaceholder => 'Buscar branches';
	@override String get newBranchPlaceholder => 'Nome da nova branch';
	@override String get createBranch => 'Criar branch';
	@override String get noBranches => 'Nenhuma branch encontrada.';
	@override String get fetch => 'Buscar';
	@override String get pull => 'Pull';
	@override String get push => 'Push';
	@override String get refresh => 'Atualizar controle de código-fonte';
	@override String fetchTitle({required Object label}) => 'Buscar — ${label}';
	@override String listFailed({required Object detail}) => 'Não foi possível listar branches: ${detail}';
	@override String get invalidName => 'Informe um nome de branch válido.';
	@override String get alreadyExists => 'Já existe uma branch com esse nome.';
	@override String get dirtyWorktree => 'Faça commit, stash ou descarte as mudanças locais antes de trocar de branch.';
	@override String checkoutFailed({required Object detail}) => 'Não foi possível trocar a branch: ${detail}';
	@override String createFailed({required Object detail}) => 'Não foi possível criar a branch: ${detail}';
}

// Path: orkest.welcomeView
class _Translations$orkest$welcomeView$pt_BR extends Translations$orkest$welcomeView$en {
	_Translations$orkest$welcomeView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bem-vindo ao Orkest Code';
	@override String get subtitle => 'Abra uma pasta ou conecte a um host remoto para começar.';
	@override String get createWorkspace => 'Criar workspace';
	@override String get openLocalFolder => 'Abrir pasta local';
	@override String get connectHost => 'Conectar a um host';
	@override String get configureHost => 'Configurar host';
	@override String get addWorkspace => 'Adicionar workspace';
}

// Path: orkest.paneView
class _Translations$orkest$paneView$pt_BR extends Translations$orkest$paneView$en {
	_Translations$orkest$paneView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get closePaneTitle => 'Fechar painel?';
	@override String closePaneMessage({required Object count}) => 'Isso fecha todas as ${count} aba(s) deste painel e encerra os agentes/terminais nele.';
	@override String get close => 'Fechar';
	@override String get closeOtherTabs => 'Fechar as outras';
	@override String get closeTabsToTheRight => 'Fechar à direita';
	@override String get closeAllTabs => 'Fechar todas';
	@override String get closeTabsTitle => 'Fechar abas?';
	@override String closeTabsMessage({required Object count}) => 'Isso fecha ${count} aba(s) e encerra os agentes/terminais nelas.';
	@override String get allTabs => 'Todas as abas';
	@override String get pinTab => 'Fixar aba';
	@override String get openInNewWindow => 'Abrir em nova janela';
	@override String get rename => 'Renomear';
	@override String get openAsMarkdown => 'Abrir como markdown';
	@override String get openAsBoard => 'Abrir como quadro';
	@override String get resetTitle => 'Redefinir título';
	@override String get copyId => 'Copiar Id';
	@override String get restartTab => 'Reiniciar';
	@override String get newTab => 'Nova aba';
	@override String get newTerminal => 'Novo terminal…';
	@override String get splitRight => 'Dividir à direita';
	@override String get splitDown => 'Dividir abaixo';
	@override String get closePane => 'Fechar painel';
	@override String get dropHereToMove => 'Solte aqui para mover a aba';
	@override String get dockAsTab => 'Encaixar como aba';
	@override String get openBrowser => 'Abrir navegador';
	@override String get openTerminal => 'Abrir terminal';
	@override String get openAsLayout => 'Abrir como layout';
	@override String get openAsYaml => 'Abrir como YAML';
	@override String get openAsPanel => 'Abrir como painel';
	@override String get openAsHtml => 'Abrir como HTML';
}

// Path: orkest.fileTreePanel
class _Translations$orkest$fileTreePanel$pt_BR extends Translations$orkest$fileTreePanel$en {
	_Translations$orkest$fileTreePanel$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get viewDiff => 'Ver Diff';
	@override String get commit => 'Commit';
	@override String get stageAndCommit => 'Stage e Commit';
	@override String get unstage => 'Tirar do stage';
	@override String get stageChanges => 'Colocar no stage';
	@override String get discardChanges => 'Descartar alterações';
	@override String get enterCommitMessage => 'Digite uma mensagem de commit.';
	@override String get commitUnavailable => 'Commit indisponível para este workspace.';
	@override String get gitErrorTitle => 'Erro do Git';
	@override String get deleteNewFileTitle => 'Excluir arquivo novo?';
	@override String get discardChangesTitle => 'Descartar alterações?';
	@override String deleteNewFileMessage({required Object name}) => '"${name}" é um arquivo novo e não pode ser restaurado. Excluir?';
	@override String discardOneMessage({required Object name}) => 'Descartar todas as alterações em "${name}"? Arquivos excluídos serão restaurados.';
	@override String get discard => 'Descartar';
	@override String get deleteAllNewFilesTitle => 'Excluir todos os arquivos novos?';
	@override String allNewFilesMessage({required Object count}) => 'Todos os ${count} arquivos são novos e serão excluídos. Isso não pode ser desfeito.';
	@override String discardTrackedMessage({required Object count, required Object extra}) => 'Descartar alterações em ${count} arquivo(s) rastreado(s)?${extra}';
	@override String discardTrackedExtra({required Object count}) => ' ${count} arquivo(s) novo(s) será(ão) mantido(s).';
	@override String get deleteAll => 'Excluir tudo';
	@override String get deleteQuestionTitle => 'Excluir?';
	@override String moveToTrash({required Object name}) => 'Mover “${name}” para a Lixeira?';
	@override String permanentlyDelete({required Object name}) => 'Excluir “${name}” permanentemente? Isso não pode ser desfeito.';
	@override String get couldNotDeleteTitle => 'Não foi possível excluir';
	@override String get moveQuestionTitle => 'Mover?';
	@override String moveMessage({required Object name, required Object dest}) => 'Mover “${name}” para “${dest}”?';
	@override String get moveAction => 'Mover';
	@override String get couldNotMoveTitle => 'Não foi possível mover';
	@override String get couldNotPasteTitle => 'Não foi possível colar';
	@override String get filesTooltip => 'Arquivos';
	@override String get searchTooltip => 'Buscar';
	@override String get sourceControlTooltip => 'Controle de versão';
	@override String get databaseTooltip => 'Banco de dados';
	@override String get sectionFiles => 'ARQUIVOS';
	@override String get newFile => 'Novo arquivo';
	@override String get newFolder => 'Nova pasta';
	@override String get refreshTooltip => 'Atualizar';
	@override String get collapseAll => 'Recolher todas as pastas';
	@override String get sectionSourceControl => 'CONTROLE DE VERSÃO';
	@override String get viewAsList => 'Ver como lista';
	@override String get viewAsTree => 'Ver como árvore';
	@override String get noFolderMessage => 'Nenhuma pasta — abra um workspace.';
	@override String get amend => 'Amend';
	@override String get commitMessagePlaceholder => 'Mensagem do commit';
	@override String get amendCommit => 'Amend do commit';
	@override String get lastCommit => 'último commit';
	@override String get openInFinder => 'Abrir no Finder';
	@override String get openInExplorer => 'Abrir no Explorer';
	@override String get openInFileManager => 'Abrir no gerenciador de arquivos';
	@override String get open => 'Abrir';
	@override String get openWith => 'Abrir com';
	@override String get openInNewWindow => 'Abrir em nova janela';
	@override String get openLayout => 'Abrir layout';
	@override String get openAsMarkdown => 'Abrir como markdown';
	@override String get showGitDiff => 'Mostrar diff do git';
	@override String get createTerminal => 'Abrir no terminal';
	@override String get rename => 'Renomear';
	@override String get copy => 'Copiar';
	@override String get cut => 'Recortar';
	@override String get paste => 'Colar';
	@override String get copyRelativePath => 'Copiar caminho relativo';
	@override String get copyAbsolutePath => 'Copiar caminho absoluto';
	@override String get renameFailed => 'Falha ao renomear.';
	@override String get noChanges => 'Nenhuma alteração.';
	@override String stagedChangesHeader({required Object count}) => 'ALTERAÇÕES EM STAGE (${count})';
	@override String changesHeader({required Object count}) => 'ALTERAÇÕES (${count})';
	@override String get discardAllChanges => 'Descartar todas as alterações';
	@override String get unstageAllChanges => 'Tirar tudo do stage';
	@override String get stageAllChanges => 'Colocar tudo no stage';
	@override String get discardFolderChanges => 'Descartar alterações da pasta';
	@override String get unstageFolderChanges => 'Tirar pasta do stage';
	@override String get stageFolderChanges => 'Colocar pasta no stage';
	@override String get generateCommitMessage => 'Gerar mensagem de commit';
	@override String generateWith({required Object harness}) => 'Gerar com ${harness}';
	@override String get generateUnavailableWhileAmending => 'Indisponível durante o amend de um commit';
	@override String get cancelGeneration => 'Cancelar geração';
	@override String get changes => 'Alteracoes';
	@override String get history => 'Historico';
	@override String get historyRepository => 'Repositorio';
	@override String get historyNoRepository => 'Nenhum repositorio Git disponivel.';
	@override String get historyEmpty => 'Nenhum commit encontrado.';
	@override String get historyLoadFailed => 'Nao foi possivel carregar o historico Git.';
	@override String get historyUntitledCommit => 'Commit sem titulo';
	@override String get historyNow => 'agora';
	@override String historyMinutesAgo({required Object count}) => 'ha ${count} min';
	@override String historyHoursAgo({required Object count}) => 'ha ${count} h';
	@override String get historyYesterday => 'ontem';
	@override String get historyDayAgo => 'ha 1 dia';
	@override String historyDaysAgo({required Object count}) => 'ha ${count} dias';
	@override String get historyFiles => 'Arquivos alterados';
	@override String get historyFilesEmpty => 'Nenhum arquivo alterado.';
	@override String get historyFilesLoadFailed => 'Nao foi possivel carregar os arquivos alterados.';
	@override String get historyCopyHash => 'Copiar hash do commit';
	@override String get historyRevertCommit => 'Reverter commit';
	@override String get historyUndoLastCommit => 'Desfazer último commit';
	@override String historyRevertConfirm({required Object hash}) => 'Reverter o commit ${hash}? O Git criará um novo commit que desfaz suas alterações.';
	@override String historyUndoConfirm({required Object hash}) => 'Desfazer o commit ${hash}? As alterações permanecerão no diretório de trabalho.';
	@override String get historyGitActionFailed => 'Não foi possível concluir a operação Git.';
	@override String get pullPushMenu => 'Pull, Push';
	@override String get branchMenu => 'Branch';
	@override String get mergeBranch => 'Mesclar branch…';
	@override String get rebaseBranch => 'Rebase da branch…';
	@override String get renameBranch => 'Renomear branch…';
	@override String get deleteBranch => 'Excluir branch…';
	@override String get publishBranch => 'Publicar branch';
	@override String get stashMenu => 'Stash';
	@override String get stashChanges => 'Guardar alterações…';
	@override String get stashPop => 'Aplicar último stash';
	@override String get tagsMenu => 'Tags';
	@override String get createTag => 'Criar tag…';
	@override String get deleteTag => 'Excluir tag…';
	@override String get branchReferencePlaceholder => 'Branch ou referência';
	@override String get branchNamePlaceholder => 'Novo nome da branch';
	@override String get stashMessagePlaceholder => 'Mensagem (opcional)';
	@override String get tagNamePlaceholder => 'Nome da tag';
	@override String get diffEmptyTree => 'Arvore vazia';
	@override String diffOriginal({required Object ref}) => 'Original ${ref}';
	@override String diffModified({required Object ref}) => 'Modificado ${ref}';
	@override String get diffWorkingTree => 'Diretorio de trabalho';
	@override String get diffBinaryFile => 'Arquivo binario - sem diff de texto.';
	@override String get diffNoChanges => 'Sem alteracoes.';
	@override String diffError({required Object detail}) => 'Não foi possível ler o diff: ${detail}';
	@override String get galleryTooltip => 'Galeria';
	@override String get sectionGallery => 'GALERIA';
	@override String get openAsHtml => 'Abrir como HTML';
	@override String get importQuestionTitle => 'Copiar aqui?';
	@override String importMessage({required Object count, required Object dest}) => 'Copiar ${count} itens para “${dest}”?';
	@override String get importAction => 'Copiar';
	@override String get couldNotImportTitle => 'Não foi possível copiar';
	@override String openInAgent({required Object harness}) => 'Abrir no ${harness}';
}

// Path: orkest.fileViewer
class _Translations$orkest$fileViewer$pt_BR extends Translations$orkest$fileViewer$en {
	_Translations$orkest$fileViewer$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get cantOpen => 'Não é possível abrir este arquivo.';
	@override String get couldNotLoadImage => 'Não foi possível carregar a imagem.';
	@override String get preview => 'Pré-visualização';
	@override String get source => 'Código-fonte';
	@override String get reload => 'Recarregar';
}

// Path: orkest.workspaceSettingsDialog
class _Translations$orkest$workspaceSettingsDialog$pt_BR extends Translations$orkest$workspaceSettingsDialog$en {
	_Translations$orkest$workspaceSettingsDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get choosePhotoTitle => 'Escolher foto do workspace';
	@override String get title => 'Configurações do workspace';
	@override String get namePlaceholder => 'Nome do workspace';
	@override String get addPhoto => 'Adicionar foto';
	@override String get changePhoto => 'Alterar foto';
	@override String get remove => 'Remover';
	@override String get color => 'Cor';
	@override String get host => 'Host';
	@override String get folder => 'Pasta';
}

// Path: orkest.realmDialogs
class _Translations$orkest$realmDialogs$pt_BR extends Translations$orkest$realmDialogs$en {
	_Translations$orkest$realmDialogs$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get namePlaceholder => 'Nome do realm';
	@override String get duplicateName => 'Já existe um realm com esse nome.';
	@override String get newRealmTitle => 'Novo realm';
	@override String get renameRealmTitle => 'Renomear realm';
	@override String get rename => 'Renomear';
	@override String get deleteRealmTitle => 'Excluir realm';
	@override String deleteMessage({required Object name, required Object suffix}) => 'Excluir "${name}"? Nenhum workspace é excluído — só a lista de pastas muda.${suffix}';
	@override String get deleteSuffixOne => ' O workspace dele irá para o Padrão.';
	@override String deleteSuffixMany({required Object count}) => ' Os ${count} workspaces dele irão para o Padrão.';
	@override String get manageRealmsTitle => 'Gerenciar realms';
	@override String workspaceCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 workspace',
		other: '${n} workspaces',
	);
}

// Path: orkest.dbRedisTable
class _Translations$orkest$dbRedisTable$pt_BR extends Translations$orkest$dbRedisTable$en {
	_Translations$orkest$dbRedisTable$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get deleteKeyTitle => 'Excluir chave';
	@override String deleteKeyMessage({required Object key}) => 'Excluir "${key}" deste banco Redis?';
	@override String get refresh => 'Atualizar';
	@override String get newKey => 'Nova chave';
	@override String get columnKey => 'CHAVE';
	@override String get columnValue => 'VALOR';
	@override String get columnType => 'TIPO';
	@override String get columnTtl => 'TTL';
	@override String keyCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 chave',
		other: '${n} chaves',
	);
	@override String get noKeys => 'Nenhuma chave neste banco de dados.';
	@override String noKeysMatch({required Object pattern}) => 'Nenhuma chave corresponde a "${pattern}".';
	@override String get loadMore => 'Carregar mais';
	@override String get loadingFullValue => 'Carregando valor completo…';
	@override String get ttlMustBeNumber => 'TTL deve ser um número de segundos.';
	@override String get addKey => 'Adicionar chave';
	@override String get keyFieldHint => 'chave';
	@override String get ttlFieldHint => 'ttl (s, opcional)';
	@override String get valueFieldHint => 'valor';
	@override String get searchHint => 'Buscar — padrão, ex.: user:*';
}

// Path: orkest.dbQueryView
class _Translations$orkest$dbQueryView$pt_BR extends Translations$orkest$dbQueryView$en {
	_Translations$orkest$dbQueryView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get saveQueryAs => 'Salvar query como';
	@override String get couldNotSave => 'Não foi possível salvar';
	@override String get selectDatabase => 'Selecionar banco de dados';
	@override String get noSqlConnections => 'Nenhuma conexão SQL';
	@override String get running => 'Executando…';
	@override String get runSelection => 'Executar seleção';
	@override String get run => 'Executar';
	@override String get pickDatabaseHint => 'Escolha um banco de dados acima e depois Executar (⌘↵).';
	@override String get runQueryHint => 'Execute a query (⌘↵) para ver os resultados aqui.';
	@override String get noRows => 'Nenhuma linha.';
	@override String rowsAffected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 linha afetada',
		other: '${n} linhas afetadas',
	);
	@override String rowsFooter({required Object n}) => '${n} linhas';
	@override String get truncatedSuffix => ' · truncado (aumente -- limit)';
	@override String get table => 'Tabela';
	@override String get json => 'JSON';
	@override String get unsaved => 'não salvo';
	@override String get saved => 'salvo';
	@override String get copied => 'Copiado';
	@override String get copy => 'Copiar';
}

// Path: orkest.httpView
class _Translations$orkest$httpView$pt_BR extends Translations$orkest$httpView$en {
	_Translations$orkest$httpView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get saveRequestAs => 'Salvar request como';
	@override String get couldNotSave => 'Não foi possível salvar';
	@override String get run => 'Executar';
	@override String get running => 'Executando…';
	@override String get noRequests => 'Nenhum request neste arquivo — escreva um, ex.: GET https://example.com';
	@override String get selectRequest => 'Selecionar request';
	@override String requestCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 request',
		other: '${n} requests',
	);
	@override String get runHint => 'Execute o request (⌘↵) para ver a resposta aqui.';
	@override String get emptyBody => 'Corpo da resposta vazio.';
	@override String get body => 'JSON';
	@override String get headers => 'Headers';
	@override String get raw => 'Text';
	@override String get truncatedSuffix => ' · truncado (resposta grande demais)';
	@override late final _Translations$orkest$httpView$error$pt_BR error = _Translations$orkest$httpView$error$pt_BR._(_root);
}

// Path: orkest.kanbanView
class _Translations$orkest$kanbanView$pt_BR extends Translations$orkest$kanbanView$en {
	_Translations$orkest$kanbanView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get filter => 'Filtrar';
	@override String get filterTitlePlaceholder => 'Buscar por título';
	@override String get filterLabels => 'Marcadores';
	@override String get filterClear => 'Limpar';
	@override String get filterDependencies => 'Dependências';
	@override String get filterBlocked => 'Bloqueado';
	@override String get filterReady => 'Pronto';
	@override String get blockedBy => 'Bloqueado por';
	@override String get addBlocker => 'Adicionar card bloqueador';
	@override String get searchCards => 'Buscar cards';
	@override String get unknownCard => 'desconhecido';
	@override String get boardView => 'Quadro';
	@override String get listView => 'Lista';
	@override String get refresh => 'Atualizar do disco';
	@override String get manageLabels => 'Marcadores';
	@override String get labelsTitle => 'Marcadores deste quadro';
	@override String get labelNamePlaceholder => 'nome do marcador';
	@override String labelUsage({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 card',
		other: '${n} cards',
	);
	@override String get deleteLabel => 'Apagar marcador';
	@override String get newCard => 'novo card';
	@override String get newCardTitle => 'Novo card';
	@override String get newColumn => 'Nova coluna';
	@override String get columnNameTitle => 'Nome da coluna';
	@override String get dragColumn => 'Arrastar coluna';
	@override String get columnOptions => 'Opções da coluna';
	@override String get renameColumn => 'Renomear coluna';
	@override String get moveColumnLeft => 'Mover pra esquerda';
	@override String get moveColumnRight => 'Mover pra direita';
	@override String get deleteColumn => 'Apagar coluna';
	@override String get newCardHere => 'Novo card aqui';
	@override String get duplicateCard => 'Duplicar';
	@override String get cardLabels => 'Marcadores';
	@override String get deleteCard => 'Apagar card';
	@override String get advance => 'Passar pra próxima coluna';
	@override String get advanceHold => 'Mover para a próxima coluna (segurar: mover para a última)';
	@override String get advanceBack => 'Voltar uma coluna';
	@override String get emptyColumn => 'Sem cards';
	@override String cardCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 card',
		other: '${n} cards',
	);
	@override String get notes => 'Nota';
	@override String get notesPlaceholder => 'Escreva uma nota';
	@override String get comments => 'Comentários';
	@override String get addComment => 'Adicionar comentário';
	@override String get commentPlaceholder => 'Escreva um comentário';
	@override String get noComments => 'Nenhum comentário ainda';
	@override String get closeDetail => 'Fechar';
	@override String get notABoard => 'Este arquivo ainda não tem colunas ## — ele abre como markdown.';
	@override String get startBoard => 'Começar um quadro';
	@override String get couldNotSave => 'Não deu pra salvar o quadro';
	@override String get unrecognizedBlock => 'Não reconhecido pelo parser — arrasta inteiro, sem edição inline.';
	@override late final _Translations$orkest$kanbanView$deleteColumnDialog$pt_BR deleteColumnDialog = _Translations$orkest$kanbanView$deleteColumnDialog$pt_BR._(_root);
}

// Path: orkest.dbPanel
class _Translations$orkest$dbPanel$pt_BR extends Translations$orkest$dbPanel$en {
	_Translations$orkest$dbPanel$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionDatabase => 'BANCO DE DADOS';
	@override String get edit => 'Editar…';
	@override String get copyName => 'Copiar nome';
	@override String get newQuery => 'Nova query';
	@override String get browseKeys => 'Ver chaves';
	@override String get deleteConnectionTitle => 'Excluir conexão';
	@override String deleteConnectionMessage({required Object name}) => 'Remover "${name}" deste workspace? Qualquer senha salva será descartada. Arquivos .dbq que fazem referência a ela não são afetados.';
	@override String footer({required Object n}) => '.orkest/databases.json · ${n} conexões';
	@override String get footerOne => '.orkest/databases.json · 1 conexão';
	@override String get noConnections => 'Nenhuma conexão ainda.';
	@override String get passwordRequired => 'Senha não encontrada no host. Abra esta conexão e digite-a de novo — ela fica salva na máquina que executa o banco, não nesta.';
}

// Path: orkest.dbMongoView
class _Translations$orkest$dbMongoView$pt_BR extends Translations$orkest$dbMongoView$en {
	_Translations$orkest$dbMongoView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get deleteDocumentTitle => 'Excluir documento';
	@override String deleteDocumentMessage({required Object id, required Object collection}) => 'Excluir o documento com _id ${id} de "${collection}"?';
	@override String get filterHint => 'Filtro — JSON, ex.: {"status": "active"}';
	@override String docCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 doc',
		other: '${n} docs',
	);
	@override String get refresh => 'Atualizar';
	@override String get insertDocument => 'Inserir documento';
	@override String get noDocuments => 'Nenhum documento nesta coleção.';
	@override String get noDocumentsMatch => 'Nenhum documento corresponde a este filtro.';
	@override String get loadMore => 'Carregar mais';
	@override String get edit => 'Editar';
	@override String get insert => 'Inserir';
}

// Path: orkest.dbConnectionDialog
class _Translations$orkest$dbConnectionDialog$pt_BR extends Translations$orkest$dbConnectionDialog$en {
	_Translations$orkest$dbConnectionDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get chooseFileTitle => 'Escolher banco SQLite';
	@override String get file => 'Arquivo';
	@override String get chooseFilePlaceholder => 'Escolha um arquivo SQLite…';
	@override String get name => 'Nome';
	@override String get password => 'Senha';
	@override String get savePassword => 'Salvar senha';
	@override String get allowWrites => 'Permitir escrita (agentes)';
	@override String get allowWritesHint => 'desligado = agentes só leem via CLI';
	@override String get visibleToAgents => 'Visível para agentes';
	@override String get visibleToAgentsHint => 'desligado = oculto da CLI, só na GUI';
	@override String get testing => 'Testando conexão…';
	@override String get connectionOk => 'Conexão OK';
	@override String get connectionFailed => 'Falha na conexão';
	@override String get editTitle => 'Editar conexão';
	@override String get newTitle => 'Nova conexão';
	@override String get connectionString => 'Connection string';
	@override String get invalidUrl => 'URL de conexão inválida.';
	@override String get sshTunnel => 'Túnel SSH';
	@override String get sshHost => 'Host SSH';
	@override String get sshPort => 'Porta SSH';
	@override String get sshUser => 'Usuário SSH';
	@override String get privateKey => 'Chave privada';
	@override String get choosePrivateKeyPlaceholder => 'Escolha uma chave privada…';
	@override String get choosePrivateKeyDialogTitle => 'Escolher chave privada SSH';
	@override String get keyPassphrase => 'Senha da chave';
	@override String get savePassphrase => 'Salvar senha da chave';
	@override String get passwordOnHost => 'A senha fica salva no host, não nesta máquina.';
}

// Path: orkest.sshPrompts
class _Translations$orkest$sshPrompts$pt_BR extends Translations$orkest$sshPrompts$en {
	_Translations$orkest$sshPrompts$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get unknownSshHostTitle => 'Host SSH desconhecido';
	@override String neverConnected({required Object endpoint}) => 'O Orkest Code nunca se conectou a ${endpoint} antes.';
	@override String get trustHint => 'Confie apenas se esta fingerprint corresponder ao servidor. Você pode verificar no servidor com:';
	@override String get trust => 'Confiar';
	@override String get sshKeyPassphraseTitle => 'Senha da chave SSH';
	@override String unlockMessage({required Object keyPath, required Object connectionName}) => 'Desbloqueie ${keyPath} para conectar "${connectionName}".';
	@override String get keptInMemoryHint => 'Mantida em memória até o Orkest Code fechar. Para permitir que agentes usem esta conexão, ative "Salvar senha da chave" na conexão.';
	@override String get unlock => 'Desbloquear';
}

// Path: orkest.projectsRail
class _Translations$orkest$projectsRail$pt_BR extends Translations$orkest$projectsRail$en {
	_Translations$orkest$projectsRail$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get workspaces => 'Workspaces';
	@override String get keepAwakeOn => 'Mantendo este computador acordado para acesso remoto. Clique para deixá-lo dormir de novo.';
	@override String get keepAwakeOff => 'Manter este computador acordado para acesso remoto. Desliga sozinho quando o Orkest Code reinicia.';
	@override String get keepAwakeBattery => 'Acordado na bateria. Isso consome a bateria.';
	@override String get keepAwakeLid => 'Fechar a tampa do notebook continua colocando-o para dormir.';
	@override String get newWorkspace => 'Novo workspace';
	@override String get settings => 'Configurações';
	@override String get mergeToParent => 'Mesclar no pai';
	@override String get updateFromParent => 'Atualizar a partir do pai';
	@override String get forkWorktree => 'Criar worktree derivada';
	@override String get copyBranch => 'Copiar branch';
	@override String get remove => 'Remover';
	@override String get moveToRealm => 'Mover para realm';
	@override String get copyWorkspaceId => 'Copiar id do workspace';
	@override String get rename => 'Renomear';
	@override String get close => 'Fechar';
	@override String get newRealm => 'Novo realm…';
	@override String get manageRealms => 'Gerenciar realms…';
	@override String get noWorkspaces => 'Nenhum workspace ainda.';
	@override String get sync => 'Sincronizar';
	@override String get pull => 'Pull';
	@override String get push => 'Push';
	@override String get createWorktree => 'Criar worktree';
	@override String worktreeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n,
		one: '1 worktree',
		other: '${n} worktrees',
	);
	@override String get expandWorktrees => 'Expandir worktrees';
	@override String get collapseWorktrees => 'Recolher worktrees';
}

// Path: orkest.findBar
class _Translations$orkest$findBar$pt_BR extends Translations$orkest$findBar$en {
	_Translations$orkest$findBar$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get find => 'Buscar';
	@override String get matchCase => 'Diferenciar maiúsculas';
	@override String get wholeWord => 'Palavra inteira';
	@override String get useRegex => 'Usar expressão regular';
	@override String get previous => 'Anterior (⇧⏎)';
	@override String get next => 'Próximo (⏎)';
	@override String get close => 'Fechar (Esc)';
	@override String get badPattern => 'Padrão inválido';
	@override String counter({required Object current, required Object total}) => '${current} de ${total}';
	@override String get noResults => 'Nenhum resultado';
}

// Path: orkest.contentSearch
class _Translations$orkest$contentSearch$pt_BR extends Translations$orkest$contentSearch$en {
	_Translations$orkest$contentSearch$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionSearch => 'BUSCA';
	@override String get searchInFiles => 'Buscar nos arquivos';
	@override String get matchCase => 'Diferenciar maiúsculas';
	@override String get wholeWord => 'Palavra inteira';
	@override String get useRegex => 'Usar expressão regular';
	@override String get invalidRegex => 'Expressão regular inválida.';
	@override String get typeToSearch => 'Digite para buscar em todos os arquivos.';
	@override String get searching => 'Buscando…';
	@override String get noResults => 'Nenhum resultado.';
}

// Path: orkest.topbar
class _Translations$orkest$topbar$pt_BR extends Translations$orkest$topbar$en {
	_Translations$orkest$topbar$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get collapseSidebar => 'Recolher barra lateral';
	@override String get toggleFiles => 'Mostrar/ocultar arquivos';
	@override String get filesUnavailable => 'Arquivos indisponíveis no Orkest Code';
	@override String get hideKeyboard => 'Baixar teclado';
	@override String get showOffice => 'Mostrar escritório';
	@override String get showTerminals => 'Mostrar terminais';
}

// Path: orkest.tasks
class _Translations$orkest$tasks$pt_BR extends Translations$orkest$tasks$en {
	_Translations$orkest$tasks$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get hotReload => 'Hot reload';
	@override String get hotRestart => 'Hot restart';
	@override String get toggleDebugPaint => 'Alternar debug paint';
	@override String get togglePlatform => 'Alternar plataforma';
	@override String get quit => 'Sair';
}

// Path: orkest.notifications
class _Translations$orkest$notifications$pt_BR extends Translations$orkest$notifications$en {
	_Translations$orkest$notifications$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get agentFinished => 'Agente terminou';
	@override String get open => 'Abrir';
	@override String get agentNeedsAction => 'Agente precisa de você';
}

// Path: orkest.terminalLink
class _Translations$orkest$terminalLink$pt_BR extends Translations$orkest$terminalLink$en {
	_Translations$orkest$terminalLink$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get open => 'Abrir';
	@override String get revealFinder => 'Mostrar no Finder';
	@override String get revealExplorer => 'Mostrar no Explorer';
	@override String get revealFolder => 'Abrir pasta';
	@override String get copyPath => 'Copiar caminho';
	@override String get openLink => 'Abrir link';
	@override String get copyLink => 'Copiar link';
}

// Path: orkest.terminal
class _Translations$orkest$terminal$pt_BR extends Translations$orkest$terminal$en {
	_Translations$orkest$terminal$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String cwdFallbackWarning({required Object requested, required Object path}) => 'Aviso: a pasta "${requested}" não existe. Este terminal abriu em "${path}".';
	@override String workspaceEnvTracked({required Object keys}) => 'Aviso: o .env.orkest está rastreado pelo git (veio com o repositório). Injetado: ${keys}';
}

// Path: orkest.remoteHost
class _Translations$orkest$remoteHost$pt_BR extends Translations$orkest$remoteHost$en {
	_Translations$orkest$remoteHost$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get addHost => 'Adicionar host remoto';
	@override String get hostName => 'Nome';
	@override String get sshTarget => 'Destino SSH (usuário@host)';
	@override String connecting({required Object host}) => 'Conectando a ${host}…';
	@override String get openingTunnel => 'Túnel SSH';
	@override String get installingServer => 'Instalando servidor';
	@override String handshake({required Object version}) => 'Servidor ${version}';
	@override String get loadingWorkspace => 'Carregando workspace…';
	@override String reconnecting({required Object host}) => 'Reconectando a ${host}…';
	@override String offline({required Object host}) => '${host} offline';
	@override String get remove => 'Remover';
	@override String get reconnect => 'Reconectar';
	@override String get installServer => 'Instalar servidor';
	@override String errSshUnreachable({required Object host}) => 'Não foi possível alcançar ${host} via SSH. Está ligado e com o Login Remoto ativado?';
	@override String errInstallFailed({required Object host}) => 'Não foi possível instalar o servidor em ${host}.';
	@override String get errVersionMismatch => 'Versão do servidor incompatível; atualize-o.';
	@override String errDetail({required Object detail}) => 'Detalhes: ${detail}';
	@override String pickFolderTitle({required Object host}) => 'Abrir pasta em ${host}';
	@override String get openHere => 'Abrir aqui';
	@override String get emptyFolder => 'Sem subpastas';
	@override String get newLocal => 'Local';
	@override String get newRemote => 'Remoto';
	@override String get chooseHost => 'Escolher um host';
	@override String get newHostEntry => 'Novo host…';
	@override String get editHost => 'Editar host';
	@override String get userLabel => 'Usuário';
	@override String get hostLabel => 'Host / IP';
	@override String get portLabel => 'Porta';
	@override String get authLabel => 'Autenticação';
	@override String get authKey => 'Chave SSH';
	@override String get authPassword => 'Senha';
	@override String get passwordLabel => 'Senha';
	@override String get passwordKeep => 'Deixe em branco para manter a atual';
	@override String get errUser => 'Usuário obrigatório';
	@override String get errHost => 'Host obrigatório';
	@override String get errPassword => 'Senha obrigatória';
	@override String get identityChoose => 'Escolher…';
	@override String get identityEmpty => 'Nenhuma chave selecionada';
	@override String get identityDialogTitle => 'Selecione a chave privada SSH';
	@override String get errIdentity => 'Escolha a chave privada para autenticar.';
	@override String errHostKeyUnknown({required Object host}) => 'O Orkest Code ainda não confia em ${host}. Conecte de novo e confirme o fingerprint.';
	@override String errHostKeyChanged({required Object host}) => '${host} está apresentando uma chave SSH diferente da guardada. Se você não reinstalou essa máquina, pare e verifique — se reinstalou, remova a entrada antiga do ~/.ssh/known_hosts.';
	@override String errHostBundleMissing({required Object host}) => '${host} é Windows mas não tem o Orkest Code instalado. O servidor remoto é instalado a partir do bundle do Orkest Code que já está naquela máquina — instale o Orkest Code lá e tente de novo.';
	@override String errHostUnknownOs({required Object host}) => 'Não foi possível identificar o sistema de ${host}. A conta pode ter shell restrito, ou nenhum shell.';
	@override String get errIdentityPublic => 'Só a chave pública está aqui. Isso só funciona se a privada estiver no seu agente SSH; senão, escolha a privada (mesmo nome, sem .pub).';
	@override String get errIdentityNotKey => 'Esse arquivo não parece uma chave privada.';
	@override String get errIdentityMissingFile => 'Esse arquivo não existe mais.';
	@override String get errIdentityUnreadable => 'Não foi possível ler esse arquivo.';
}

// Path: orkest.browserPane
class _Translations$orkest$browserPane$pt_BR extends Translations$orkest$browserPane$en {
	_Translations$orkest$browserPane$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get back => 'Voltar';
	@override String get forward => 'Avançar';
	@override String get reload => 'Recarregar';
	@override String get urlHint => 'Digite a URL ou endereço';
	@override String get go => 'Ir';
}

// Path: orkest.documentWindow
class _Translations$orkest$documentWindow$pt_BR extends Translations$orkest$documentWindow$en {
	_Translations$orkest$documentWindow$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get mediaNotSupported => 'Áudio e vídeo abrem na janela principal do Orkest Code.';
	@override String fileNotFound({required Object path}) => 'Arquivo não encontrado: ${path}';
}

// Path: orkest.gallery
class _Translations$orkest$gallery$pt_BR extends Translations$orkest$gallery$en {
	_Translations$orkest$gallery$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get intro => 'Documentos especiais do Orkest Code para que você tenha o visual do que o agente de IA esteja fazendo.';
	@override String get createErrorTitle => 'Não foi possível criar o arquivo';
	@override late final _Translations$orkest$gallery$dbQuery$pt_BR dbQuery = _Translations$orkest$gallery$dbQuery$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$kanban$pt_BR kanban = _Translations$orkest$gallery$kanban$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$layout$pt_BR layout = _Translations$orkest$gallery$layout$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$httpRequest$pt_BR httpRequest = _Translations$orkest$gallery$httpRequest$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$html$pt_BR html = _Translations$orkest$gallery$html$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$tasks$pt_BR tasks = _Translations$orkest$gallery$tasks$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$notebook$pt_BR notebook = _Translations$orkest$gallery$notebook$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$workspaceEnv$pt_BR workspaceEnv = _Translations$orkest$gallery$workspaceEnv$pt_BR._(_root);
	@override late final _Translations$orkest$gallery$panel$pt_BR panel = _Translations$orkest$gallery$panel$pt_BR._(_root);
}

// Path: orkest.notebook
class _Translations$orkest$notebook$pt_BR extends Translations$orkest$notebook$en {
	_Translations$orkest$notebook$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get notes => 'Notas';
	@override String get newNote => 'Nova nota';
	@override String get searchPlaceholder => 'Buscar notas';
	@override String get empty => 'Nenhuma nota ainda. Crie uma, ou peça pro agente escrever aqui.';
	@override String get noMatch => 'Nenhuma nota bate com o filtro.';
	@override String get selectNote => 'Selecione uma nota';
	@override String get reload => 'Recarregar do disco';
	@override String get untagged => 'sem tag';
	@override String get saveFailed => 'Não foi possível salvar a nota';
	@override String get createFailed => 'Não foi possível criar a nota';
	@override String get addTag => 'adicionar tag';
	@override String get untitled => 'Sem título';
	@override String get deleteNote => 'Apagar nota';
	@override String deleteConfirm({required Object name}) => 'Mover “${name}” pra lixeira?';
	@override String get imageFailed => 'Não foi possível salvar a imagem';
	@override late final _Translations$orkest$notebook$format$pt_BR format = _Translations$orkest$notebook$format$pt_BR._(_root);
	@override String get backlinks => 'Citada em';
	@override String get renameTag => 'Renomear tag';
	@override String get deleteTag => 'Apagar tag';
	@override String deleteTagConfirm({required Object name, required Object count}) => 'Remover “${name}” de ${count} notas? As notas ficam.';
	@override String get showList => 'Mostrar lista de notas';
	@override String get hideList => 'Ocultar lista de notas';
}

// Path: orkest.layoutPreview
class _Translations$orkest$layoutPreview$pt_BR extends Translations$orkest$layoutPreview$en {
	_Translations$orkest$layoutPreview$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get applyFailedTitle => 'Não foi possível aplicar o layout';
	@override String get applyInOrkest => 'Aplicar no Orkest Code';
	@override String get applyNewWorkspace => 'Abrir como novo workspace';
	@override String applyTo({required Object workspace}) => 'Aplicar em ${workspace}';
	@override String get autorunWorktree => 'autorun: worktree. Este layout também é aplicado sozinho quando você cria uma worktree do workspace onde ele está.';
	@override String get command => 'Comando';
	@override String get folder => 'Pasta';
	@override String get noCommand => 'sem comando, abre um shell';
	@override String get replaceConfirm => 'Substituir layout';
	@override String replaceMessage({required Object n}) => '${n} abas abertas deste workspace serão fechadas, inclusive as com trabalho em andamento.';
	@override String replaceTitle({required Object workspace}) => 'Substituir o layout de ${workspace}?';
	@override String get skippedTitle => 'Não criados neste sistema';
	@override String get splitDown => 'divide abaixo';
	@override String get splitRight => 'divide à direita';
	@override String get splitTab => 'aba';
	@override String subtitle({required Object n}) => 'Este layout abre ${n} terminais. Leia os comandos antes de aplicar.';
}

// Path: orkest.telemetry
class _Translations$orkest$telemetry$pt_BR extends Translations$orkest$telemetry$en {
	_Translations$orkest$telemetry$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Telemetria';
	@override String get title => 'Telemetria';
	@override String liveRuns({required Object n}) => '${n} ativos';
	@override String get noWorkspace => 'Abra um workspace para ver a telemetria dele.';
	@override String get empty => 'Nada aqui ainda.';
	@override String get emptyFiltered => 'Nada aqui ainda.';
	@override String get searchHint => 'Filtrar casos';
	@override String get chipOpen => 'Abertos';
	@override String get chipNew => 'Novos';
	@override String get chipResolved => 'Resolvidos';
	@override String get chipIgnored => 'Ignorados';
	@override String get chipWarnings => 'Avisos';
	@override String get tagNew => 'novo';
	@override String get tagRegression => 'regressão';
	@override String get tagResolved => 'resolvido';
	@override String get tagIgnored => 'ignorado';
	@override String get srcTask => 'task';
	@override String get srcWrapper => 'orkest telemetry';
	@override String run({required Object id}) => 'run ${id}';
	@override String get resolve => 'Marcar resolvido';
	@override String get ignore => 'Ignorar (some para os agentes também)';
	@override String get reopen => 'Reabrir';
	@override String get clear => 'Limpar ocorrências';
	@override String get clearRun => 'Limpar este run';
	@override String get clearProject => 'Limpar projeto';
	@override String openFile({required Object location}) => 'Abrir ${location}';
	@override String get showInTerminal => 'Ver no terminal';
	@override String get copyCommand => 'Copiar comando da CLI';
	@override String get copied => 'Copiado';
	@override String get statusOpen => 'Aberto';
	@override String get statusResolved => 'Resolvido';
	@override String get statusIgnored => 'Ignorado';
	@override String get occurrences => 'Ocorrências';
	@override String inRuns({required Object n}) => 'em ${n} runs';
	@override String get first => 'Primeira';
	@override String get last => 'Última';
	@override String get origin => 'Origem';
	@override String get sectionStack => 'Stack';
	@override String get stackHint => 'frames do projeto em destaque · clique abre o arquivo';
	@override String get sectionCorrelated => 'Log correlacionado';
	@override String get correlatedHint => 'o JSON mais próximo antes do erro, no mesmo run';
	@override String get none => 'nenhum';
	@override String get sectionRuns => 'Ocorrências por run';
	@override String get runsHint => 'mesma chave (cwd, comando): é assim que novo e regressão são calculados';
	@override String get sectionContext => 'Contexto cru';
	@override String get contextHint => 'linhas do terminal ao redor da última ocorrência';
	@override String get current => 'atual';
	@override String fingerprintHint({required Object location}) => 'fingerprint = tipo + mensagem normalizada + ${location}';
	@override String get blameUncommitted => 'alterado no working tree';
	@override String blameCommit({required Object ago, required Object sha}) => 'alterado ${ago} (${sha})';
	@override String get justNow => 'agora';
	@override String minutesAgo({required Object n}) => 'há ${n} min';
	@override String hoursAgo({required Object n}) => 'há ${n} h';
	@override String daysAgo({required Object n}) => 'há ${n} d';
	@override String get resolvedToast => 'Resolvido. Se voltar num run futuro, reaparece como regressão.';
	@override String get ignoredToast => 'Ignorado. Os agentes não veem mais (salvo --include-ignored).';
	@override String get clearedToast => 'Ocorrências apagadas. As regras de triagem ficam.';
	@override String get byHuman => 'por você';
	@override String get byAgent => 'pelo agente';
	@override String caseTabTitle({required Object type, required Object file}) => '${type} · ${file}';
	@override String get srcApp => 'App';
	@override String get chipApp => 'Orkest Code';
}

// Path: orkest.panelView
class _Translations$orkest$panelView$pt_BR extends Translations$orkest$panelView$en {
	_Translations$orkest$panelView$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get unavailable => 'Painéis precisam da web view embutida, que ainda não existe no Linux.';
	@override String get openInBrowser => 'Abrir no navegador';
	@override String get openAsHtml => 'Abrir como HTML';
}

// Path: settings.language
class _Translations$settings$language$pt_BR extends Translations$settings$language$en {
	_Translations$settings$language$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Idioma';
	@override String get system => 'Sistema';
	@override String get english => 'Inglês';
	@override String get portugueseBr => 'Português (BR)';
	@override String get spanish => 'Espanhol';
}

// Path: settings.page
class _Translations$settings$page$pt_BR extends Translations$settings$page$en {
	_Translations$settings$page$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$page$header$pt_BR header = _Translations$settings$page$header$pt_BR._(_root);
	@override late final _Translations$settings$page$nav$pt_BR nav = _Translations$settings$page$nav$pt_BR._(_root);
	@override late final _Translations$settings$page$general$pt_BR general = _Translations$settings$page$general$pt_BR._(_root);
	@override late final _Translations$settings$page$diagnostics$pt_BR diagnostics = _Translations$settings$page$diagnostics$pt_BR._(_root);
	@override late final _Translations$settings$page$storage$pt_BR storage = _Translations$settings$page$storage$pt_BR._(_root);
	@override late final _Translations$settings$page$terminal$pt_BR terminal = _Translations$settings$page$terminal$pt_BR._(_root);
	@override late final _Translations$settings$page$appearance$pt_BR appearance = _Translations$settings$page$appearance$pt_BR._(_root);
	@override late final _Translations$settings$page$notifications$pt_BR notifications = _Translations$settings$page$notifications$pt_BR._(_root);
	@override late final _Translations$settings$page$shortcuts$pt_BR shortcuts = _Translations$settings$page$shortcuts$pt_BR._(_root);
	@override late final _Translations$settings$page$languages$pt_BR languages = _Translations$settings$page$languages$pt_BR._(_root);
	@override late final _Translations$settings$page$automations$pt_BR automations = _Translations$settings$page$automations$pt_BR._(_root);
}

// Path: settings.remoteHosts
class _Translations$settings$remoteHosts$pt_BR extends Translations$settings$remoteHosts$en {
	_Translations$settings$remoteHosts$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hosts remotos';
	@override String get description => 'Máquinas que você acessa por SSH. Adicionar um host aqui é o mesmo que adicionar pelo menu "+" do workspace.';
	@override String get empty => 'Nenhum host remoto ainda.';
	@override String get add => 'Adicionar host';
	@override String get edit => 'Editar';
	@override String get reconnect => 'Reconectar';
	@override String get remove => 'Remover';
	@override String get removeTitle => 'Remover host';
	@override String removeMessage({required Object name}) => 'Remover "${name}" e todos os workspaces dele? Nada é apagado no host.';
	@override String workspacesCount({required Object count}) => '${count} workspace(s)';
	@override String get deviceKeyTitle => 'Chave deste dispositivo';
	@override String get deviceKeyDesc => 'Adicione esta chave pública ao ~/.ssh/authorized_keys do host para este dispositivo poder conectar.';
	@override String get deviceKeyCopy => 'Copiar chave pública';
	@override String get deviceKeyCopied => 'Chave pública copiada';
	@override String get statusConnected => 'Conectado';
	@override String get statusConnecting => 'Conectando…';
	@override String get statusReconnecting => 'Reconectando…';
	@override String get statusOffline => 'Offline';
	@override String get statusIdle => 'Não conectado';
	@override String get helpTitle => 'Como funciona';
	@override String get helpBody => 'O Orkest Code conecta na sua máquina por SSH e fala com um servidor pequeno que roda os terminais, arquivos e git lá. O host precisa ter o Orkest Code (desktop) ou o orkest-server instalado e rodando, e a chave pública deste dispositivo adicionada no ~/.ssh/authorized_keys dele.';
}

// Path: automation.error
class _Translations$automation$error$pt_BR extends Translations$automation$error$en {
	_Translations$automation$error$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String unavailable({required Object harness}) => '${harness} não está instalado ou não está no PATH.';
	@override String modelUnavailable({required Object model, required Object harness}) => 'O modelo "${model}" não está disponível para ${harness}. Escolha outro modelo em Configurações.';
	@override String authentication({required Object harness, required Object detail}) => '${harness}: ${detail}';
	@override String timeout({required Object harness, required Object seconds}) => '${harness} não respondeu em ${seconds} segundos.';
	@override String get cancelled => 'A geração da mensagem de commit foi cancelada.';
	@override String process({required Object harness, required Object detail}) => '${harness}: ${detail}';
	@override String processNoDetail({required Object harness}) => '${harness} não conseguiu gerar uma mensagem de commit.';
	@override String get invalidResponse => 'A automação devolveu uma mensagem de commit vazia.';
	@override String get busy => 'Já há uma mensagem de commit sendo gerada.';
	@override String get unknown => 'A automação não conseguiu gerar uma mensagem de commit.';
	@override String get noWorkspace => 'Nenhum workspace selecionado.';
	@override String get fileOutsideWorkspace => 'O arquivo está fora das raízes do workspace.';
	@override String fileUnreadable({required Object detail}) => 'Não foi possível ler o arquivo: ${detail}';
	@override String get binaryFile => 'Não é possível gerar mensagem de commit para um arquivo binário.';
	@override String get noFileChanges => 'Não há mudanças a descrever neste arquivo.';
	@override String get noStagedChanges => 'Não há mudanças no stage a descrever.';
	@override String get multipleRepositories => 'As mudanças no stage pertencem a repositórios diferentes. Gere uma de cada vez.';
	@override String get diffUnavailable => 'Não foi possível ler o diff.';
	@override String get notConfigured => 'Configure um harness de mensagem de commit em Configurações.';
}

// Path: fileOperation.error
class _Translations$fileOperation$error$pt_BR extends Translations$fileOperation$error$en {
	_Translations$fileOperation$error$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String alreadyExists({required Object name}) => 'Já existe: “${name}”.';
	@override String notFound({required Object name}) => 'Não encontrado: “${name}”.';
	@override String get invalidPath => 'Caminho inválido.';
	@override String get emptyName => 'O nome não pode ficar vazio.';
	@override String get noWorkspace => 'Nenhum workspace selecionado.';
	@override String get cannotMoveIntoItself => 'Não é possível mover uma pasta para dentro dela mesma.';
	@override String get clipboardEmpty => 'A área de transferência está vazia.';
	@override String get notScratchTab => 'Esta aba não é um arquivo temporário.';
	@override String get writeFailed => 'Não foi possível gravar o arquivo.';
	@override String get formatterEmptyCommand => 'Comando de formatação vazio.';
	@override String get formatterMissingPlaceholder => 'O comando de formatação precisa incluir o placeholder %FILE%.';
	@override String get formatterTimeout => 'O formatador excedeu o tempo limite.';
	@override String formatterExitCode({required Object code}) => 'O formatador saiu com código ${code}.';
	@override String get formatterFailed => 'Não foi possível executar o formatador.';
	@override String osFailure({required Object detail}) => '${detail}';
	@override String get nameHasSlash => 'O nome não pode conter “/”.';
	@override String get invalidName => 'Nome inválido.';
	@override String get remoteDropUnsupported => 'Soltar arquivos num workspace remoto ainda não é suportado.';
}

// Path: theme.error
class _Translations$theme$error$pt_BR extends Translations$theme$error$en {
	_Translations$theme$error$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get io => 'Não foi possível ler ou gravar o arquivo do tema.';
	@override String ioDetail({required Object detail}) => 'Não foi possível ler ou gravar o arquivo do tema: ${detail}';
	@override String malformedJson({required Object detail}) => 'Este arquivo não é um JSON válido: ${detail}';
	@override String get invalidTheme => 'Este arquivo não é um tema válido.';
	@override String get reservedId => 'Este tema usa o id de um tema nativo. Mude o "id" no arquivo e importe de novo.';
	@override String notAnObject({required Object field}) => 'Esperava um objeto em "${field}".';
	@override String missingField({required Object field}) => 'Falta o campo obrigatório "${field}".';
	@override String badColor({required Object value, required Object field}) => '"${value}" em "${field}" não é uma cor. Use #RGB, #RRGGBB ou #RRGGBBAA.';
	@override String unknownBase({required Object value}) => 'Tema base "${value}" desconhecido em "extends".';
	@override String get noVariants => 'O tema não declara nenhum variant. Adicione "dark", "light" ou os dois em "variants".';
}

// Path: orkest.httpView.error
class _Translations$orkest$httpView$error$pt_BR extends Translations$orkest$httpView$error$en {
	_Translations$orkest$httpView$error$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Falha no request';
	@override String get noRequest => 'Nenhum request encontrado na posição do cursor.';
	@override String invalidUrl({required Object url}) => 'URL inválida: ${url}';
	@override String unresolvedVariable({required Object name}) => 'A variável {{${name}}} não tem valor. Declare com @${name} = … neste arquivo.';
	@override String bodyFileMissing({required Object path}) => 'Arquivo de corpo não encontrado: ${path}';
	@override String bodyFileUnreadable({required Object path, required Object detail}) => 'Não foi possível ler o arquivo de corpo ${path}: ${detail}';
	@override String connectionFailed({required Object detail}) => 'Não foi possível alcançar o servidor: ${detail}';
	@override String get connectionFailedNoDetail => 'Não foi possível alcançar o servidor.';
	@override String timeout({required Object seconds}) => 'O request estourou o tempo limite de ${seconds}s.';
	@override String responseTooLarge({required Object bytes}) => 'A resposta passou do limite de ${bytes} bytes.';
}

// Path: orkest.kanbanView.deleteColumnDialog
class _Translations$orkest$kanbanView$deleteColumnDialog$pt_BR extends Translations$orkest$kanbanView$deleteColumnDialog$en {
	_Translations$orkest$kanbanView$deleteColumnDialog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String title({required Object name}) => 'Apagar “${name}”?';
	@override String message({required Object count}) => 'Esta coluna tem ${count}. Escolha o que acontece com eles.';
	@override String get moveCards => 'Mover pra coluna anterior';
	@override String get deleteAll => 'Apagar junto com a coluna';
	@override String get emptyMessage => 'Esta coluna está vazia.';
}

// Path: orkest.gallery.dbQuery
class _Translations$orkest$gallery$dbQuery$pt_BR extends Translations$orkest$gallery$dbQuery$en {
	_Translations$orkest$gallery$dbQuery$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consulta de banco';
	@override String get description => 'Editor SQL com grid de resultado, usando uma das conexões registradas.';
}

// Path: orkest.gallery.kanban
class _Translations$orkest$gallery$kanban$pt_BR extends Translations$orkest$gallery$kanban$en {
	_Translations$orkest$gallery$kanban$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Quadro kanban';
	@override String get description => 'Colunas e cards gravados como markdown puro. Arraste, edite e comente.';
}

// Path: orkest.gallery.layout
class _Translations$orkest$gallery$layout$pt_BR extends Translations$orkest$gallery$layout$en {
	_Translations$orkest$gallery$layout$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layout de panes';
	@override String get description => 'Terminais e splits para abrir de uma vez, estilo tmuxinator. Pode rodar sozinho em worktrees novas.';
}

// Path: orkest.gallery.httpRequest
class _Translations$orkest$gallery$httpRequest$pt_BR extends Translations$orkest$gallery$httpRequest$en {
	_Translations$orkest$gallery$httpRequest$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Requests HTTP';
	@override String get description => 'Escreva requests num arquivo e execute com a resposta ao lado.';
}

// Path: orkest.gallery.html
class _Translations$orkest$gallery$html$pt_BR extends Translations$orkest$gallery$html$en {
	_Translations$orkest$gallery$html$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Visual HTML';
	@override String get description => 'Uma página que o agente escreve e o Orkest Code renderiza direto: mapa mental, diagrama, gráfico, o que precisar.';
}

// Path: orkest.gallery.tasks
class _Translations$orkest$gallery$tasks$pt_BR extends Translations$orkest$gallery$tasks$en {
	_Translations$orkest$gallery$tasks$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tarefas';
	@override String get description => 'Comandos para rodar pelo painel de Tasks, como dev server, testes e build. Fica em .orkest/tasks.json.';
}

// Path: orkest.gallery.notebook
class _Translations$orkest$gallery$notebook$pt_BR extends Translations$orkest$gallery$notebook$en {
	_Translations$orkest$gallery$notebook$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Caderno';
	@override String get description => 'Uma pasta de notas curtas com tags. O agente escreve, você lê e edita. Abre no Obsidian também.';
}

// Path: orkest.gallery.workspaceEnv
class _Translations$orkest$gallery$workspaceEnv$pt_BR extends Translations$orkest$gallery$workspaceEnv$en {
	_Translations$orkest$gallery$workspaceEnv$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Env do workspace';
	@override String get description => 'Variáveis injetadas em todo terminal deste workspace. Coloque tokens ou logins de API aqui em vez de colar no prompt do agente. Fica fora do git.';
}

// Path: orkest.gallery.panel
class _Translations$orkest$gallery$panel$pt_BR extends Translations$orkest$gallery$panel$en {
	_Translations$orkest$gallery$panel$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Painel';
	@override String get description => 'Uma página HTML com ponte para o app: os botões rodam comandos da CLI do Orkest Code e do shell nesta máquina. Um playground para dashboards rápidos.';
}

// Path: orkest.notebook.format
class _Translations$orkest$notebook$format$pt_BR extends Translations$orkest$notebook$format$en {
	_Translations$orkest$notebook$format$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get bold => 'Negrito (⌘B)';
	@override String get italic => 'Itálico (⌘I)';
	@override String get strike => 'Riscado';
	@override String get heading1 => 'Título 1';
	@override String get heading2 => 'Título 2';
	@override String get heading3 => 'Título 3';
	@override String get bullets => 'Lista';
	@override String get numbered => 'Lista numerada';
	@override String get checklist => 'Checklist';
	@override String get quote => 'Citação';
	@override String get code => 'Código inline (⌘E)';
	@override String get codeBlock => 'Bloco de código';
	@override String get link => 'Link (⌘K)';
	@override String get rule => 'Divisor';
	@override String get noteLink => 'Link pra uma nota ([[…]])';
	@override String get noteLinkSearch => 'Buscar notas';
	@override String get image => 'Inserir imagem…';
}

// Path: settings.page.header
class _Translations$settings$page$header$pt_BR extends Translations$settings$page$header$en {
	_Translations$settings$page$header$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get back => 'Voltar';
	@override String get title => 'Configurações';
}

// Path: settings.page.nav
class _Translations$settings$page$nav$pt_BR extends Translations$settings$page$nav$en {
	_Translations$settings$page$nav$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get general => 'Geral';
	@override String get appearance => 'Aparência';
	@override String get terminal => 'Terminal';
	@override String get language => 'Linguagem';
	@override String get shortcuts => 'Atalhos';
	@override String get notifications => 'Notificações';
	@override String get automations => 'Automações';
	@override String get remoteHosts => 'Hosts remotos';
}

// Path: settings.page.general
class _Translations$settings$page$general$pt_BR extends Translations$settings$page$general$en {
	_Translations$settings$page$general$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionEditor => 'Editor';
	@override String get editorEngineTitle => 'Motor';
	@override String get editorEngineOrkest => 'Orkest Code (padrão)';
	@override String get editorEngineNeovim => 'Neovim';
	@override String get neovimChecking => 'Procurando o Neovim…';
	@override String get neovimNotFound => 'O Neovim não foi encontrado na PATH do seu shell.';
	@override String get neovimRefresh => 'Verificar novamente';
	@override String get showOrkestTitle => 'Mostrar terminal do Orkest Code';
	@override String get showOrkestDesc => 'Mantém um workspace sem pasta, só de terminal, fixado no topo da barra lateral. Desligar fecha seus terminais.';
	@override String get launchAtStartupTitle => 'Iniciar ao ligar';
	@override String get launchAtStartupDesc => 'Inicia o Orkest Code automaticamente quando você faz login no computador.';
	@override String get sectionUpdates => 'Atualizações';
	@override String get checkUpdatesTitle => 'Verificar atualizações';
	@override String get checkUpdatesDesc => 'Com que frequência o Orkest Code deve procurar novas versões.';
	@override late final _Translations$settings$page$general$updateFrequency$pt_BR updateFrequency = _Translations$settings$page$general$updateFrequency$pt_BR._(_root);
	@override String get developerModeTitle => 'Modo desenvolvedor';
	@override String get developerModeDesc => 'Registra os erros e avisos do próprio Orkest Code numa base separada da Telemetria (chip “Orkest Code”) e liga as métricas de performance. Só serve a quem mantém o app.';
}

// Path: settings.page.diagnostics
class _Translations$settings$page$diagnostics$pt_BR extends Translations$settings$page$diagnostics$en {
	_Translations$settings$page$diagnostics$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Diagnóstico';
	@override String get logFileTitle => 'Arquivo de log';
	@override String logFileDesc({required Object days, required Object path}) => 'Erros e eventos de inicialização são registrados aqui, mantidos por ${days} dias.\n${path}';
	@override String get unavailable => 'indisponível';
	@override String get reveal => 'Revelar';
	@override String get reportTitle => 'Reportar um problema';
	@override String get reportDesc => 'Abre uma issue pré-preenchida com sua versão, SO e log recente. Nada é enviado automaticamente — você revisa antes.';
	@override String get reportButton => 'Reportar…';
	@override String get reportDialogTitle => 'Relatório de problema';
	@override String get reportDialogError => 'Reportado manualmente pelas Configurações.';
	@override String get reportDialogDescription => 'Descreva o que deu errado na issue. O log recente está incluído abaixo e em "Copiar detalhes".';
}

// Path: settings.page.storage
class _Translations$settings$page$storage$pt_BR extends Translations$settings$page$storage$en {
	_Translations$settings$page$storage$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Armazenamento';
	@override String get locationTitle => 'Local de armazenamento';
	@override String locationDesc({required Object root}) => 'O Orkest Code guarda seus projetos, layouts e configurações aqui. Aponte para uma pasta sincronizada para fazer backup.\n${root}';
	@override String get useDefault => 'Usar padrão';
	@override String get working => 'Trabalhando…';
	@override String get change => 'Alterar…';
	@override String get resetTitle => 'Redefinir o Orkest Code';
	@override String get resetDesc => 'Exclui todos os dados locais — projetos, layouts, configurações e histórico do terminal — e volta ao local padrão.';
	@override String get resetButton => 'Redefinir…';
	@override String get resetConfirm => 'Redefinir';
	@override String get resetDialogTitle => 'Redefinir o Orkest Code?';
	@override String get resetDialogContent => 'Isso exclui permanentemente todos os dados locais do Orkest Code — projetos, layouts, configurações e histórico do terminal. Isso não pode ser desfeito. O Orkest Code será fechado para você começar do zero.';
	@override String get restartRequiredTitle => 'Reinicialização necessária';
	@override String restartChangeFolderMessage({required Object path}) => 'O Orkest Code usará esta pasta a partir da próxima abertura:\n${path}';
	@override String get restartUseDefaultMessage => 'O Orkest Code usará o local padrão do sistema a partir da próxima abertura. Seus dados na pasta personalizada permanecem intactos.';
	@override String get restartResetMessage => 'Todos os dados do Orkest Code foram apagados. Reinicie para começar do zero.';
	@override String get later => 'Mais tarde';
	@override String get quitOrkest => 'Sair do Orkest Code';
	@override String get chooseFolderDialogTitle => 'Escolha uma pasta para os dados do Orkest Code';
}

// Path: settings.page.terminal
class _Translations$settings$page$terminal$pt_BR extends Translations$settings$page$terminal$en {
	_Translations$settings$page$terminal$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionDefaultTerminal => 'Terminal padrão';
	@override String get engineTitle => 'Motor';
	@override String get engineDesc => 'Usado por novas abas de terminal e buffers de saída de tasks. Abas abertas mantêm o motor atual.';
	@override String get shellTitle => 'Shell';
	@override String get shellDesc => 'Qual shell novas abas de terminal abrem. A seta ao lado do + ainda abre qualquer outro, só para aquela aba.';
	@override String get noWslMessage => 'Nenhuma distro WSL encontrada. Instale uma (wsl.exe --install) e reinicie o Orkest Code para vê-la listada aqui.';
	@override String get sectionBehavior => 'Comportamento';
	@override String get closeOnExitTitle => 'Fechar a aba quando o shell encerrar';
	@override String get closeOnExitDesc => 'Quando um shell termina sozinho (exit, Ctrl-D), fecha a aba em vez de deixar um terminal morto.';
}

// Path: settings.page.appearance
class _Translations$settings$page$appearance$pt_BR extends Translations$settings$page$appearance$en {
	_Translations$settings$page$appearance$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionTheme => 'Tema';
	@override String get themeTitle => 'Tema';
	@override String get themeDesc => 'Cores do app, realce de código e paleta do terminal.';
	@override String get modeTitle => 'Modo';
	@override String get modeDesc => 'Qual variante do tema usar.';
	@override String modeOnlyDark({required Object theme}) => '"${theme}" só traz a variante escura, então isto não tem efeito.';
	@override String modeOnlyLight({required Object theme}) => '"${theme}" só traz a variante clara, então isto não tem efeito.';
	@override String get themeFileTitle => 'Arquivo de tema';
	@override String get themeFileDesc => 'Importe um tema de um arquivo JSON, ou exporte o tema ativo.';
	@override String get previewCode => 'Código';
	@override String get previewTerminal => 'Terminal';
	@override String get themeSystem => 'Sistema';
	@override String get themeLight => 'Claro';
	@override String get themeDark => 'Escuro';
	@override String get sectionFonts => 'Fontes';
	@override String get interfaceFontTitle => 'Fonte da interface';
	@override String get interfaceFontDesc => 'Usada em todo o aplicativo. Vazio = padrão do sistema.';
	@override String get interfaceSizeTitle => 'Tamanho da interface';
	@override String get codeFontTitle => 'Fonte do código';
	@override String get codeFontDesc => 'Código e diffs. Vazio = padrão do sistema.';
	@override String get codeSizeTitle => 'Tamanho do código';
	@override String get terminalFontTitle => 'Fonte do terminal';
	@override String get terminalFontDesc => 'Só o terminal. Vazio = padrão do sistema.';
	@override String get terminalSizeTitle => 'Tamanho do terminal';
	@override String get terminalSizeDesc => 'Desligado = segue o tamanho do código.';
	@override String get terminalSizeInherit => 'Seguir o código';
	@override String get terminalWeightTitle => 'Peso do terminal';
	@override String get terminalWeightDesc => 'Telas de baixa densidade engrossam os traços. O automático afina só nelas e não mexe no Retina.';
	@override String get terminalWeightAuto => 'Automático (pela tela)';
	@override String get terminalWeightLight => 'Fino';
	@override String get terminalWeightNormal => 'Normal';
	@override String get terminalWeightMedium => 'Médio';
	@override String get terminalWeightSemiBold => 'Seminegrito';
	@override String get sectionConversation => 'Conversa';
	@override String get pinUserMessageTitle => 'Fixar mensagem do usuário';
	@override String get pinUserMessageDesc => 'A pergunta fica fixa no topo enquanto a resposta rola.';
	@override String get importTheme => 'Importar…';
	@override String get exportTheme => 'Exportar…';
	@override String get deleteTheme => 'Remover';
	@override String get importThemeDialog => 'Escolha um arquivo de tema';
	@override String get exportThemeDialog => 'Salvar tema como';
	@override String themeImported({required Object name}) => 'Tema "${name}" importado.';
	@override String get themeExported => 'Tema salvo.';
	@override String get themeDeleted => 'Tema removido.';
	@override String get fontPickerTitle => 'Escolher uma fonte';
	@override String get fontPickerSearch => 'Buscar fontes';
	@override String get fontPickerEmpty => 'Nenhuma fonte correspondente nesta máquina.';
	@override String get fontPickerBundled => 'inclusa';
	@override String get fontPickerCustom => 'Não está na lista? Digite o nome exato da família.';
	@override String get fontPickerCustomHint => 'Nome da família';
	@override String get fontPickerUse => 'Usar';
	@override String get fontPickerDefault => 'Padrão';
	@override String get fontMissing => 'Não encontrada nesta máquina — usando o fallback.';
	@override String get sectionLayout => 'Layout';
	@override String get swapPanelsTitle => 'Inverter panes';
	@override String get swapPanelsDesc => 'Coloca os workspaces à direita e arquivos, busca, git e banco à esquerda.';
}

// Path: settings.page.notifications
class _Translations$settings$page$notifications$pt_BR extends Translations$settings$page$notifications$en {
	_Translations$settings$page$notifications$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Notificações';
	@override String get enableTitle => 'Ativar notificações';
	@override String get enableDesc => 'Avisar quando um agente terminar uma resposta e a janela não estiver em foco.';
	@override String get systemPermissionTitle => 'Permissão do sistema';
	@override String get grantedDesc => 'O Orkest Code tem permissão para enviar notificações.';
	@override String get notGrantedDesc => 'O macOS ainda não concedeu acesso a notificações.';
	@override String get granted => 'Concedido';
	@override String get requestPermission => 'Solicitar permissão';
	@override String get soundsTitle => 'Sons';
	@override String get soundVolumeTitle => 'Volume';
	@override String get soundTurnDone => 'Turno concluído';
	@override String get soundTurnDoneDesc => 'Um agente terminou o turno.';
	@override String get soundActionRequired => 'Ação necessária';
	@override String get soundActionRequiredDesc => 'Um agente está esperando sua aprovação ou resposta.';
	@override String get soundDefault => 'Padrão';
	@override String soundCustom({required Object name}) => 'Personalizado: ${name}';
	@override String get soundChooseFile => 'Escolher arquivo';
	@override String get soundReset => 'Voltar ao padrão';
	@override String get soundOnActiveTab => 'Tocar também com a aba ativa';
	@override String get soundPreview => 'Ouvir';
}

// Path: settings.page.shortcuts
class _Translations$settings$page$shortcuts$pt_BR extends Translations$settings$page$shortcuts$en {
	_Translations$settings$page$shortcuts$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get notCustomizable => 'Os atalhos de teclado ainda não são personalizáveis.';
}

// Path: settings.page.languages
class _Translations$settings$page$languages$pt_BR extends Translations$settings$page$languages$en {
	_Translations$settings$page$languages$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionFormatting => 'FORMATAÇÃO';
	@override String get formatOnSaveTitle => 'Formatar ao salvar';
	@override String get formatOnSaveDesc => 'Formata o arquivo automaticamente ao salvar (⌘S).';
	@override String get sectionLanguageServers => 'SERVIDORES DE LINGUAGEM';
	@override String get footerNote => 'Erros e formatação usam o language server de cada linguagem. O Orkest Code não instala servidores — ele usa o que já está na sua máquina. ● responde · ○ não encontrado ou comando inválido (instale o servidor ou ajuste o comando).';
	@override String get serverCommandLabel => 'Comando do language server';
	@override String get formatterCommandLabel => 'Comando do formatador (opcional)';
	@override String get formatterHint => 'Formatador externo com o placeholder %FILE%. Tem prioridade sobre o formatador do LSP quando definido.';
	@override String get resetToDefault => 'Redefinir para o padrão';
	@override String get saveAndRestart => 'Salvar e reiniciar';
	@override String get statusResponds => 'Servidor responde';
	@override String get statusNotFound => 'Servidor não encontrado ou comando inválido';
}

// Path: settings.page.automations
class _Translations$settings$page$automations$pt_BR extends Translations$settings$page$automations$en {
	_Translations$settings$page$automations$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get sectionCommitMessages => 'Mensagens de commit';
	@override String get harness => 'Harness';
	@override String get harnessDiscovering => 'Procurando harnesses de linha de comando instalados…';
	@override String get harnessNoneFound => 'Nenhum harness compatível foi encontrado no PATH.';
	@override String harnessConfiguredUnavailable({required Object harness}) => '${harness} está configurado, mas indisponível.';
	@override String get harnessChoose => 'Escolha a CLI usada para gerar mensagens de commit.';
	@override String get harnessRefresh => 'Atualizar harnesses instalados';
	@override String get notConfigured => 'Não configurado';
	@override String get model => 'Modelo';
	@override String get modelUnavailable => 'A lista de modelos fica indisponível até o harness ser encontrado.';
	@override String get modelCliOnly => 'Este harness usa o modelo padrão da própria CLI.';
	@override String get modelCliDefault => 'Padrão da CLI';
	@override String get modelAuto => 'Auto';
	@override String modelSearch({required Object count}) => 'Buscar entre ${count} modelos…';
	@override String get modelAutoRouted => 'Este harness escolhe o modelo automaticamente.';
	@override String get modelAccountOnly => 'Só aparecem os modelos liberados na sua conta.';
	@override String get generateFromSourceControl => 'Gerar pelo Controle de Versão';
	@override String get generateFromSourceControlDescription => 'O Orkest Code envia apenas o diff selecionado e os assuntos dos commits recentes. Padrões comuns de credenciais e arquivos sensíveis são redigidos antes de o harness rodar.';
	@override String get discoveryFailed => 'Não foi possível descobrir os harnesses de automação instalados.';
	@override String staleModel({required Object model, required Object harness}) => 'O modelo "${model}" não está mais disponível para ${harness}. Usando o padrão da CLI; escolha outro modelo em Configurações se precisar.';
	@override String get recommendedSuffix => 'Recomendado';
}

// Path: settings.page.general.updateFrequency
class _Translations$settings$page$general$updateFrequency$pt_BR extends Translations$settings$page$general$updateFrequency$en {
	_Translations$settings$page$general$updateFrequency$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get daily => 'Diariamente';
	@override String get weekly => 'Semanalmente';
	@override String get monthly => 'Mensalmente';
	@override String get never => 'Nunca';
}

/// The flat map containing all translations for locale <pt-BR>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPtBr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'core.bootstrapError.title' => 'Falha ao inicializar o Orkest Code',
			'core.bootstrapError.retry' => 'Tentar novamente',
			'core.macosNotifications.title' => 'Ativar notificações no macOS',
			'core.macosNotifications.intro' => 'As notificações estão desativadas nas configurações do sistema. Siga os passos abaixo para ativá-las:',
			'core.macosNotifications.step1' => 'Abra as Configurações do Sistema no seu Mac.',
			'core.macosNotifications.step2' => 'Acesse a seção Notificações na barra lateral esquerda.',
			'core.macosNotifications.step3' => 'Encontre e selecione o aplicativo Orkest Code na lista.',
			'core.macosNotifications.step4' => 'Ative a opção Permitir Notificações.',
			'core.macosNotifications.tip' => 'Dica: se o aplicativo não aparecer na lista, feche e reabra-o para acionar seu registro no sistema.',
			'core.macosNotifications.gotIt' => 'Entendi',
			'core.appErrorView.renderFailed' => 'Esta parte do aplicativo falhou ao renderizar',
			'core.appErrorView.details' => 'Detalhes',
			'core.appErrorView.renderErrorTitle' => 'Erro de renderização',
			'core.errorReportDialog.defaultDescription' => 'Algo deu errado. Os detalhes abaixo foram salvos no log — você pode reportá-los para que isso seja corrigido.',
			'core.errorReportDialog.copyDetails' => 'Copiar detalhes',
			'core.errorReportDialog.reportIssue' => 'Reportar problema',
			'core.windowControls.minimize' => 'Minimizar',
			'core.windowControls.maximize' => 'Maximizar',
			'core.windowControls.close' => 'Fechar',
			'core.crash.title' => 'Encerramento inesperado',
			'core.crash.bannerTitle' => 'O Orkest Code fechou inesperadamente',
			'core.crash.report' => 'Reportar',
			'core.crash.dismiss' => 'Dispensar',
			'core.crash.crashMessage' => ({required Object version}) => 'A sessão anterior (versão ${version}) terminou sem encerrar corretamente. Quer reportar? O log vai junto e você pode revisar tudo antes de enviar.',
			'core.crash.crashError' => ({required Object startedAt, required Object pid}) => 'A sessão iniciada em ${startedAt} (pid ${pid}) terminou sem encerramento limpo.',
			'core.crash.crashDescription' => 'Nenhum erro foi capturado: o app foi encerrado pelo sistema. O log abaixo é dessa sessão e é a parte mais útil.',
			'core.menu.settings' => 'Configurações…',
			'core.menu.checkForUpdates' => 'Verificar Atualizações…',
			'core.menu.file' => 'Arquivo',
			'core.menu.newTerminal' => 'Novo Terminal',
			'core.menu.openWorkspace' => 'Abrir Workspace',
			'core.menu.goToFile' => 'Ir para Arquivo…',
			'core.menu.save' => 'Salvar',
			'core.menu.discard' => 'Descartar',
			'core.menu.format' => 'Formatar',
			'core.menu.view' => 'Exibir',
			'core.menu.toggleWorkspacePanel' => 'Alternar Painel de Workspaces',
			'core.menu.toggleFiles' => 'Alternar Arquivos',
			'core.menu.splitRight' => 'Dividir à Direita',
			'core.menu.splitDown' => 'Dividir Abaixo',
			'core.menu.focusPane' => 'Focar Painel',
			'core.menu.focusLeft' => 'Esquerda  (⌘⌥←)',
			'core.menu.focusRight' => 'Direita  (⌘⌥→)',
			'core.menu.focusUp' => 'Acima  (⌘⌥↑)',
			'core.menu.focusDown' => 'Abaixo  (⌘⌥↓)',
			'core.menu.selectTab' => 'Selecionar Aba',
			'core.menu.tabN' => ({required Object n}) => 'Aba ${n}',
			'core.menu.lastTab' => 'Última Aba',
			'core.menu.previousWorkspace' => 'Workspace Anterior',
			'core.menu.nextWorkspace' => 'Próximo Workspace',
			'core.menu.zoomIn' => 'Aumentar Zoom',
			'core.menu.zoomOut' => 'Diminuir Zoom',
			'core.menu.actualSize' => 'Tamanho Real',
			'core.menu.window' => 'Janela',
			'core.menu.quit' => 'Sair',
			'core.menu.minimize' => 'Minimizar',
			'core.menu.zoom' => 'Zoom',
			'common.cancel' => 'Cancelar',
			'common.confirm' => 'Confirmar',
			'common.create' => 'Criar',
			'common.gotIt' => 'Entendi',
			'common.save' => 'Salvar',
			'common.close' => 'Fechar',
			'common.delete' => 'Excluir',
			'common.done' => 'Concluído',
			'common.add' => 'Adicionar',
			'common.test' => 'Testar',
			'common.ok' => 'OK',
			'common.loading' => 'Carregando…',
			'common.checking' => 'Verificando…',
			'common.remove' => 'Remover',
			'common.restart' => 'Reiniciar',
			'common.settings' => 'Configurações',
			'common.send' => 'Enviar',
			'common.open' => 'Abrir',
			'common.dismiss' => 'Dispensar',
			'common.report' => 'Reportar',
			'common.copyCode' => 'Copiar código',
			'common.search' => 'Buscar',
			'common.noResults' => 'Nenhum resultado',
			'orkest.officeWorld.reception' => 'Recepção',
			'orkest.officeWorld.cafe' => 'Copa',
			'orkest.officeWorld.restrooms' => 'Banheiros',
			'orkest.officeWorld.lounge' => 'Lounge',
			'orkest.officeWorld.rosterTitle' => 'Agentes do escritório',
			'orkest.officeWorld.rosterSearch' => 'Buscar agentes ou projetos',
			'orkest.officeWorld.rosterEmpty' => 'Nenhum agente ativo encontrado',
			'orkest.officeWorld.activityFeed' => 'Atividade',
			'orkest.officeWorld.activityEmpty' => 'As atividades observadas aparecerão aqui.',
			'orkest.officeWorld.collapseRoster' => 'Recolher lista de agentes',
			'orkest.officeWorld.collapseFeed' => 'Recolher atividades',
			'orkest.officeWorld.reopenRoster' => 'Agentes',
			'orkest.officeWorld.reopenFeed' => 'Atividade',
			'orkest.officeWorld.working' => 'Trabalhando',
			'orkest.officeWorld.waiting' => 'Aguardando',
			'orkest.officeWorld.idle' => 'Disponível',
			'orkest.officeWorld.agentProfile' => 'Perfil do agente',
			'orkest.officeWorld.project' => 'Projeto',
			'orkest.officeWorld.provider' => 'Agente',
			'orkest.officeWorld.currentStatus' => 'Status atual',
			'orkest.officeWorld.followAgent' => 'Seguir personagem',
			'orkest.officeWorld.stopFollowingAgent' => 'Parar de seguir',
			'orkest.officeWorld.centerAgent' => 'Centralizar personagem',
			'orkest.officeWorld.sessionDuration' => 'Sessão atual no Orkest Code',
			'orkest.officeWorld.workingDirectory' => 'Diretório de trabalho',
			'orkest.officeWorld.statsPending' => 'O Orkest Code ainda não coleta estatísticas de modelo, tokens e ferramentas.',
			'orkest.officeWorld.recentActivity' => 'Atividade recente nesta execução',
			'orkest.officeWorld.promptReceived' => 'Recebeu um pedido',
			'orkest.officeWorld.agentThinking' => 'Pensando',
			'orkest.officeWorld.agentResponded' => 'Resposta enviada',
			'orkest.officeWorld.activityError' => 'Algo deu errado',
			'orkest.officeWorld.readingFile' => 'Lendo arquivo',
			'orkest.officeWorld.searchingCode' => 'Buscando no código',
			'orkest.officeWorld.editingFile' => 'Editando arquivo',
			'orkest.officeWorld.writingFile' => 'Escrevendo arquivo',
			'orkest.officeWorld.runningCommand' => 'Comando no terminal',
			'orkest.officeWorld.runningTests' => 'Rodando testes',
			'orkest.officeWorld.browsingWeb' => 'Pesquisando na web',
			'orkest.officeWorld.organizingTasks' => 'Organizando tarefas',
			'orkest.officeWorld.callingSubagents' => 'Chamando subagentes',
			'orkest.officeWorld.toolCompleted' => 'Concluiu uma ferramenta',
			'orkest.officeWorld.usingTool' => 'Usando ferramenta',
			'orkest.officeWorld.editAgentName' => 'Editar nome do agente',
			'orkest.officeWorld.agentName' => 'Nome do agente',
			'orkest.officeWorld.workingInTerminal' => 'Trabalhando no terminal',
			'orkest.officeWorld.waitingInTerminal' => 'Precisa de você no terminal',
			'orkest.officeWorld.waitingBubble' => 'Responder no terminal',
			'orkest.officeWorld.respond' => 'Responder',
			'orkest.officeWorld.dismissNotification' => 'Dispensar aviso',
			'orkest.officeWorld.editAppearance' => 'Editar personagem',
			'orkest.officeWorld.randomizeAppearance' => 'Sortear',
			'orkest.officeWorld.resetAppearance' => 'Voltar ao sorteio',
			'orkest.officeWorld.skin' => 'Pele',
			'orkest.officeWorld.hair' => 'Cabelo',
			'orkest.officeWorld.beard' => 'Barba',
			'orkest.officeWorld.eyes' => 'Olhos',
			'orkest.officeWorld.top' => 'Parte de cima',
			'orkest.officeWorld.bottom' => 'Parte de baixo',
			'orkest.officeWorld.shoes' => 'Sapatos',
			'orkest.officeWorld.accessory' => 'Acessório',
			'orkest.officeWorld.turnCompleted' => 'Turno concluído',
			'orkest.officeWorld.subagentFailed' => 'Subagente falhou',
			'orkest.officeWorld.subagentInterrupted' => 'Subagente interrompido',
			'orkest.officeWorld.openTerminal' => 'Abrir terminal',
			'orkest.officeWorld.interactInOffice' => 'Interagir no Office',
			'orkest.officeWorld.liveTerminal' => 'Terminal ao vivo',
			'orkest.officeWorld.terminalInputPlaceholder' => 'Digite no terminal…',
			'orkest.officeWorld.terminalOfficeHint' => 'A entrada vai para a sessão original. Use as opções de resposta que o agente mostrar neste terminal.',
			'orkest.officeWorld.appearance' => 'Aparência do escritório',
			'orkest.officeWorld.officeTheme' => 'Tema sazonal',
			'orkest.officeWorld.themeAuto' => 'Automático',
			'orkest.officeWorld.themeNone' => 'Original',
			'orkest.officeWorld.themeChristmas' => 'Natal',
			'orkest.officeWorld.themeHalloween' => 'Halloween',
			'orkest.officeWorld.showNames' => 'Mostrar nomes dos agentes',
			'orkest.officeWorld.bubbles' => 'Balões de atividade',
			'orkest.officeWorld.bubblesAll' => 'Todos',
			'orkest.officeWorld.bubblesImportant' => 'Importantes',
			'orkest.officeWorld.bubblesNone' => 'Nenhum',
			'orkest.officeWorld.movement' => 'Movimento pelo escritório',
			'orkest.officeWorld.movementCalm' => 'Calmo',
			'orkest.officeWorld.movementNormal' => 'Normal',
			'orkest.officeWorld.movementLively' => 'Agitado',
			'orkest.officeWorld.daylight' => 'Ciclo dia/noite',
			'orkest.officeWorld.sounds' => 'Sons do escritório',
			'orkest.officeWorld.soundVolume' => 'Volume',
			'orkest.officeWorld.soundAlerts' => 'Avisos e tarefas concluídas',
			'orkest.officeWorld.soundKeys' => 'Teclado',
			'orkest.officeWorld.soundElevator' => 'Elevador',
			'orkest.officeWorld.soundSocial' => 'Pingue-pongue e fliperama',
			'orkest.officeWorld.daylightAuto' => 'Automático',
			'orkest.officeWorld.daylightDay' => 'Sempre dia',
			'orkest.officeWorld.daylightNight' => 'Sempre noite',
			'orkest.officeWorld.socialLife' => 'Vida social',
			'orkest.officeWorld.gameCoins' => ({required Object count}) => '${count} moedinhas do escritório',
			'orkest.officeWorld.earnedWorking' => ({required Object count}) => '${count} ganhos com atividades',
			'orkest.officeWorld.matchRecord' => ({required Object wins, required Object losses}) => '${wins} vitórias · ${losses} derrotas',
			'orkest.officeWorld.personality' => 'Personalidade',
			'orkest.officeWorld.friendships' => 'Amizades',
			'orkest.officeWorld.rivals' => 'Rivalidades',
			'orkest.officeWorld.socialLedger' => 'Extrato de moedinhas',
			'orkest.officeWorld.socialActivity' => 'Vida social do escritório',
			'orkest.officeWorld.delegatedBy' => ({required Object name}) => 'Delegado por ${name}',
			'orkest.officeWorld.shellWaiting' => 'Esperando um comando',
			'orkest.officeWorld.socialEconomy' => 'Jogo do escritório — sem valor monetário real',
			'orkest.confirmDialog.unsavedChangesTitle' => 'Alterações não salvas',
			'orkest.confirmDialog.unsavedChangesMessage' => ({required Object fileName}) => '“${fileName}” tem alterações não salvas. Salvar antes de fechar?',
			'orkest.confirmDialog.dontSave' => 'Não salvar',
			'orkest.confirmDialog.saveAndClose' => 'Salvar e fechar',
			'orkest.neovim.unavailable' => 'O Neovim não está disponível. Abrindo no Orkest Code.',
			'orkest.neovim.openFailed' => 'Não foi possível acessar o Neovim. Abrindo no Orkest Code.',
			'orkest.neovim.unsavedTitle' => 'Buffers não salvos no Neovim',
			'orkest.neovim.unsavedMessage' => 'O Neovim tem buffers modificados. Fechar a aba e descartar essas alterações?',
			'orkest.neovim.closeAnyway' => 'Fechar mesmo assim',
			'orkest.worktreeCreateDialog.forkTitle' => 'Fork da worktree',
			'orkest.worktreeCreateDialog.createTitle' => 'Criar worktree',
			'orkest.worktreeCreateDialog.forkSubtitle' => ({required Object root}) => 'Nova worktree ramificada a partir de ${root}.',
			'orkest.worktreeCreateDialog.createSubtitle' => ({required Object root}) => 'Nova feature em ${root} — novo branch a partir do HEAD atual.',
			'orkest.worktreeCreateDialog.namePlaceholder' => 'feat/minha-feature',
			'orkest.worktreeCreateDialog.errorWhitespace' => 'Sem espaços no nome.',
			'orkest.worktreeCreateDialog.errorInvalidChar' => 'Caractere inválido para nome de branch.',
			'orkest.worktreeCreateDialog.errorInvalidSequence' => 'Sequência inválida (ex.: "..", "//", começar/terminar com "/").',
			'orkest.worktreeCreateDialog.errorReserved' => 'Posição reservada (não comece com "-"/"." nem termine com ".lock").',
			'orkest.worktreeCreateDialog.errorDuplicateBranch' => 'Já existe um branch com esse nome.',
			'orkest.worktreeCreateDialog.errorDuplicateWorktree' => 'Já existe uma worktree com esse nome.',
			'orkest.worktreeCreateDialog.errorBranchHierarchyConflict' => ({required Object target, required Object existing}) => 'Não é possível criar o branch \'${target}\' porque ele conflita com o branch \'${existing}\' já existente.',
			'orkest.worktreeCreateDialog.errorBranchHierarchicalConflictGeneral' => 'Já existe um branch com uma hierarquia conflitante.',
			'orkest.worktreeCreateDialog.fork' => 'Fork',
			'orkest.worktreeCreateDialog.postCheckoutHint' => 'Este repositório tem um hook post-checkout.',
			'orkest.worktreeCreateDialog.running' => 'Executando…',
			'orkest.worktreeCreateDialog.advancedSettings' => 'Configurações Avançadas',
			'orkest.worktreeCreateDialog.copyIgnored' => 'Copiar arquivos ignorados (.gitignore)',
			'orkest.worktreeCreateDialog.copyIgnoredDesc' => 'Copia arquivos ignorados pelo .gitignore (ex: .env, chaves locais) para a nova pasta.',
			'orkest.worktreeCreateDialog.copyUntracked' => 'Copiar arquivos não rastreados',
			'orkest.worktreeCreateDialog.copyUntrackedDesc' => 'Copia arquivos novos ou modificados que ainda não foram adicionados ao stage.',
			'orkest.worktreeCreateDialog.baseBranch' => 'Branch base',
			'orkest.worktreeCreateDialog.baseBranchDesc' => 'O branch de onde a nova worktree e branch serão ramificados.',
			'orkest.worktreeCreateDialog.fetchRemote' => 'Sincronizar branch remota (fetch)',
			'orkest.worktreeCreateDialog.fetchRemoteDesc' => 'Roda git fetch para garantir que a branch base esteja confirmada antes de criar a worktree.',
			'orkest.worktreeCreateDialog.searchBranch' => 'Buscar branch...',
			'orkest.worktreeCreateDialog.back' => 'Voltar',
			'orkest.commitMessageDialog.commitTitle' => 'Commit',
			'orkest.commitMessageDialog.stageAndCommitTitle' => 'Stage e Commit',
			'orkest.commitMessageDialog.scopeNote' => ({required Object fileName}) => 'Commit apenas de "${fileName}".',
			'orkest.commitMessageDialog.placeholder' => 'fix: resumo curto da mudança',
			'orkest.commitMessageDialog.errorEmptySubject' => 'A primeira linha (assunto) não pode ficar vazia.',
			'orkest.commitMessageDialog.errorTooShort' => ({required Object min}) => 'Assunto muito curto (mín. ${min} caracteres).',
			'orkest.commitMessageDialog.errorTooLong' => ({required Object max}) => 'Assunto muito longo (máx. ${max} caracteres).',
			'orkest.commitMessageDialog.errorTrailingPeriod' => 'O assunto não deve terminar com ponto.',
			'orkest.commitMessageDialog.errorControlChars' => 'O assunto contém caracteres de controle.',
			'orkest.commitMessageDialog.errorBlankSecondLine' => 'Deixe a segunda linha em branco (separador entre assunto e corpo do git).',
			'orkest.commitMessageDialog.generate' => 'Gerar mensagem de commit',
			'orkest.commitMessageDialog.generateWith' => ({required Object harness}) => 'Gerar com ${harness}',
			'orkest.commitMessageDialog.generating' => 'Gerando…',
			'orkest.commitMessageDialog.cancelGeneration' => 'Cancelar geração',
			'orkest.tasksPanel.reloadTasksTooltip' => 'Recarregar tasks',
			'orkest.tasksPanel.restartTooltip' => 'Reiniciar',
			'orkest.tasksPanel.stopTooltip' => 'Parar',
			'orkest.tasksPanel.runTooltip' => 'Executar',
			'orkest.tasksPanel.sendsKeyTooltip' => ({required Object label, required Object key}) => '${label} (envia \'${key}\')',
			'orkest.tasksPanel.startingTooltip' => 'Iniciando…',
			'orkest.tasksPanel.stoppingTooltip' => 'Parando…',
			'orkest.tasksPanel.switchProfileTooltip' => 'Trocar perfil',
			'orkest.tasksPanel.moreKeysTooltip' => 'Mais teclas',
			'orkest.tasksPanel.sectionTasks' => 'TAREFAS',
			'orkest.tasksPanel.noTasks' => 'Nenhuma tarefa detectada neste projeto.',
			'orkest.tasksPanel.createTasksJson' => 'Criar tasks.json',
			'orkest.tasksPanel.generateComposeTasks' => 'Gerar tasks do Compose',
			'orkest.tasksPanel.selectComposeEngine' => 'Escolha uma engine Compose',
			'orkest.tasksPanel.noComposeEngine' => 'Docker Compose ou Podman Compose não foi encontrado.',
			'orkest.tasksPanel.invalidComposeFile' => 'O arquivo ativo não é um Compose válido com services.',
			'orkest.tasksPanel.invalidTasksJson' => 'tasks.json é inválido. Nenhuma alteração foi gravada.',
			'orkest.tasksPanel.composeConflicts' => ({required Object labels}) => 'Tasks não Compose com rótulos conflitantes foram mantidas: ${labels}',
			'orkest.orkestPage.chooseProjectFolderDialogTitle' => 'Escolha a pasta do projeto',
			'orkest.orkestPage.chooseWorkspaceFolderDialogTitle' => 'Escolha a pasta do workspace',
			'orkest.orkestPage.workspaceRenamedTitle' => 'Workspace renomeado',
			'orkest.orkestPage.workspaceRenamedMessage' => ({required Object name}) => 'O novo nome "${name}" só será enviado aos agentes após reiniciar o workspace ou o aplicativo.',
			'orkest.orkestPage.syncTitle' => ({required Object label}) => 'Sync — ${label}',
			'orkest.orkestPage.pullTitle' => ({required Object label}) => 'Pull — ${label}',
			'orkest.orkestPage.pushTitle' => ({required Object label}) => 'Push — ${label}',
			'orkest.orkestPage.updateFromParentTitle' => ({required Object name}) => 'Atualizar a partir do Pai — ${name}',
			'orkest.orkestPage.mergeToParentTitle' => ({required Object name}) => 'Merge para o Pai — ${name}',
			'orkest.orkestPage.worktreeMergedAndRemoved' => 'Worktree mesclada e removida.',
			'orkest.orkestPage.nothingWasChanged' => 'Nada foi alterado.',
			'orkest.orkestPage.newRealmTitle' => 'Novo realm',
			'orkest.orkestPage.closeWorkspaceTitle' => 'Fechar workspace',
			'orkest.orkestPage.closeWorkspaceMessage' => ({required Object name}) => 'Fechar "${name}"? Os agentes deste workspace serão encerrados. A pasta no disco é mantida.',
			'orkest.orkestPage.closeAction' => 'Fechar',
			'orkest.orkestPage.removeWorktreeTitle' => 'Remover worktree',
			'orkest.orkestPage.removeWorktreeMessage' => ({required Object name, required Object warn}) => 'Remover "${name}"? A pasta da worktree e o branch serão excluídos e os agentes deste fork serão encerrados.${warn}',
			'orkest.orkestPage.removeWorktreeWarning' => ({required Object name}) => '\n\nAviso: o branch "${name}" ainda não foi mesclado — removê-lo (git branch -D) descarta o trabalho não mesclado.',
			'orkest.orkestPage.failedToRemoveWorktreeTitle' => 'Falha ao remover a worktree',
			'orkest.orkestPage.openLayoutTitle' => 'Abrir layout',
			'orkest.orkestPage.replaceLayoutTitle' => 'Substituir o layout atual?',
			'orkest.orkestPage.replaceLayoutMessage' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 aba será fechada, e ela tem um processo em execução.', other: '${n} abas serão fechadas, inclusive as com processos em execução.', ), 
			'orkest.orkestPage.replaceLayoutConfirm' => 'Substituir',
			'orkest.orkestPage.restartServerTooltip' => 'Reiniciar servidor',
			'orkest.orkestPage.noLspAvailable' => 'Nenhum LSP disponível',
			'orkest.orkestPage.lspRunning' => 'em execução',
			'orkest.orkestPage.lspStopped' => 'parado',
			'orkest.branchPicker.title' => 'Trocar branch',
			'orkest.branchPicker.tooltip' => ({required Object branch}) => 'Branch atual: ${branch}',
			'orkest.branchPicker.worktreeFixed' => 'Esta branch é fixa para esta worktree.',
			'orkest.branchPicker.worktreeFixedShort' => 'worktree',
			'orkest.branchPicker.usedByWorktree' => 'A branch já está em uso por uma worktree.',
			'orkest.branchPicker.searchPlaceholder' => 'Buscar branches',
			'orkest.branchPicker.newBranchPlaceholder' => 'Nome da nova branch',
			'orkest.branchPicker.createBranch' => 'Criar branch',
			'orkest.branchPicker.noBranches' => 'Nenhuma branch encontrada.',
			'orkest.branchPicker.fetch' => 'Buscar',
			'orkest.branchPicker.pull' => 'Pull',
			'orkest.branchPicker.push' => 'Push',
			'orkest.branchPicker.refresh' => 'Atualizar controle de código-fonte',
			'orkest.branchPicker.fetchTitle' => ({required Object label}) => 'Buscar — ${label}',
			'orkest.branchPicker.listFailed' => ({required Object detail}) => 'Não foi possível listar branches: ${detail}',
			'orkest.branchPicker.invalidName' => 'Informe um nome de branch válido.',
			'orkest.branchPicker.alreadyExists' => 'Já existe uma branch com esse nome.',
			'orkest.branchPicker.dirtyWorktree' => 'Faça commit, stash ou descarte as mudanças locais antes de trocar de branch.',
			'orkest.branchPicker.checkoutFailed' => ({required Object detail}) => 'Não foi possível trocar a branch: ${detail}',
			'orkest.branchPicker.createFailed' => ({required Object detail}) => 'Não foi possível criar a branch: ${detail}',
			'orkest.welcomeView.title' => 'Bem-vindo ao Orkest Code',
			'orkest.welcomeView.subtitle' => 'Abra uma pasta ou conecte a um host remoto para começar.',
			'orkest.welcomeView.createWorkspace' => 'Criar workspace',
			'orkest.welcomeView.openLocalFolder' => 'Abrir pasta local',
			'orkest.welcomeView.connectHost' => 'Conectar a um host',
			'orkest.welcomeView.configureHost' => 'Configurar host',
			'orkest.welcomeView.addWorkspace' => 'Adicionar workspace',
			'orkest.paneView.closePaneTitle' => 'Fechar painel?',
			'orkest.paneView.closePaneMessage' => ({required Object count}) => 'Isso fecha todas as ${count} aba(s) deste painel e encerra os agentes/terminais nele.',
			'orkest.paneView.close' => 'Fechar',
			'orkest.paneView.closeOtherTabs' => 'Fechar as outras',
			'orkest.paneView.closeTabsToTheRight' => 'Fechar à direita',
			'orkest.paneView.closeAllTabs' => 'Fechar todas',
			'orkest.paneView.closeTabsTitle' => 'Fechar abas?',
			'orkest.paneView.closeTabsMessage' => ({required Object count}) => 'Isso fecha ${count} aba(s) e encerra os agentes/terminais nelas.',
			'orkest.paneView.allTabs' => 'Todas as abas',
			'orkest.paneView.pinTab' => 'Fixar aba',
			'orkest.paneView.openInNewWindow' => 'Abrir em nova janela',
			'orkest.paneView.rename' => 'Renomear',
			'orkest.paneView.openAsMarkdown' => 'Abrir como markdown',
			'orkest.paneView.openAsBoard' => 'Abrir como quadro',
			'orkest.paneView.resetTitle' => 'Redefinir título',
			'orkest.paneView.copyId' => 'Copiar Id',
			'orkest.paneView.restartTab' => 'Reiniciar',
			'orkest.paneView.newTab' => 'Nova aba',
			'orkest.paneView.newTerminal' => 'Novo terminal…',
			'orkest.paneView.splitRight' => 'Dividir à direita',
			'orkest.paneView.splitDown' => 'Dividir abaixo',
			'orkest.paneView.closePane' => 'Fechar painel',
			'orkest.paneView.dropHereToMove' => 'Solte aqui para mover a aba',
			'orkest.paneView.dockAsTab' => 'Encaixar como aba',
			'orkest.paneView.openBrowser' => 'Abrir navegador',
			'orkest.paneView.openTerminal' => 'Abrir terminal',
			'orkest.paneView.openAsLayout' => 'Abrir como layout',
			'orkest.paneView.openAsYaml' => 'Abrir como YAML',
			'orkest.paneView.openAsPanel' => 'Abrir como painel',
			'orkest.paneView.openAsHtml' => 'Abrir como HTML',
			'orkest.fileTreePanel.viewDiff' => 'Ver Diff',
			'orkest.fileTreePanel.commit' => 'Commit',
			'orkest.fileTreePanel.stageAndCommit' => 'Stage e Commit',
			'orkest.fileTreePanel.unstage' => 'Tirar do stage',
			'orkest.fileTreePanel.stageChanges' => 'Colocar no stage',
			'orkest.fileTreePanel.discardChanges' => 'Descartar alterações',
			'orkest.fileTreePanel.enterCommitMessage' => 'Digite uma mensagem de commit.',
			'orkest.fileTreePanel.commitUnavailable' => 'Commit indisponível para este workspace.',
			'orkest.fileTreePanel.gitErrorTitle' => 'Erro do Git',
			'orkest.fileTreePanel.deleteNewFileTitle' => 'Excluir arquivo novo?',
			'orkest.fileTreePanel.discardChangesTitle' => 'Descartar alterações?',
			'orkest.fileTreePanel.deleteNewFileMessage' => ({required Object name}) => '"${name}" é um arquivo novo e não pode ser restaurado. Excluir?',
			'orkest.fileTreePanel.discardOneMessage' => ({required Object name}) => 'Descartar todas as alterações em "${name}"? Arquivos excluídos serão restaurados.',
			'orkest.fileTreePanel.discard' => 'Descartar',
			'orkest.fileTreePanel.deleteAllNewFilesTitle' => 'Excluir todos os arquivos novos?',
			'orkest.fileTreePanel.allNewFilesMessage' => ({required Object count}) => 'Todos os ${count} arquivos são novos e serão excluídos. Isso não pode ser desfeito.',
			'orkest.fileTreePanel.discardTrackedMessage' => ({required Object count, required Object extra}) => 'Descartar alterações em ${count} arquivo(s) rastreado(s)?${extra}',
			'orkest.fileTreePanel.discardTrackedExtra' => ({required Object count}) => ' ${count} arquivo(s) novo(s) será(ão) mantido(s).',
			'orkest.fileTreePanel.deleteAll' => 'Excluir tudo',
			'orkest.fileTreePanel.deleteQuestionTitle' => 'Excluir?',
			'orkest.fileTreePanel.moveToTrash' => ({required Object name}) => 'Mover “${name}” para a Lixeira?',
			'orkest.fileTreePanel.permanentlyDelete' => ({required Object name}) => 'Excluir “${name}” permanentemente? Isso não pode ser desfeito.',
			'orkest.fileTreePanel.couldNotDeleteTitle' => 'Não foi possível excluir',
			'orkest.fileTreePanel.moveQuestionTitle' => 'Mover?',
			'orkest.fileTreePanel.moveMessage' => ({required Object name, required Object dest}) => 'Mover “${name}” para “${dest}”?',
			'orkest.fileTreePanel.moveAction' => 'Mover',
			'orkest.fileTreePanel.couldNotMoveTitle' => 'Não foi possível mover',
			'orkest.fileTreePanel.couldNotPasteTitle' => 'Não foi possível colar',
			'orkest.fileTreePanel.filesTooltip' => 'Arquivos',
			'orkest.fileTreePanel.searchTooltip' => 'Buscar',
			'orkest.fileTreePanel.sourceControlTooltip' => 'Controle de versão',
			'orkest.fileTreePanel.databaseTooltip' => 'Banco de dados',
			'orkest.fileTreePanel.sectionFiles' => 'ARQUIVOS',
			'orkest.fileTreePanel.newFile' => 'Novo arquivo',
			'orkest.fileTreePanel.newFolder' => 'Nova pasta',
			'orkest.fileTreePanel.refreshTooltip' => 'Atualizar',
			'orkest.fileTreePanel.collapseAll' => 'Recolher todas as pastas',
			'orkest.fileTreePanel.sectionSourceControl' => 'CONTROLE DE VERSÃO',
			'orkest.fileTreePanel.viewAsList' => 'Ver como lista',
			'orkest.fileTreePanel.viewAsTree' => 'Ver como árvore',
			'orkest.fileTreePanel.noFolderMessage' => 'Nenhuma pasta — abra um workspace.',
			'orkest.fileTreePanel.amend' => 'Amend',
			'orkest.fileTreePanel.commitMessagePlaceholder' => 'Mensagem do commit',
			'orkest.fileTreePanel.amendCommit' => 'Amend do commit',
			'orkest.fileTreePanel.lastCommit' => 'último commit',
			'orkest.fileTreePanel.openInFinder' => 'Abrir no Finder',
			'orkest.fileTreePanel.openInExplorer' => 'Abrir no Explorer',
			'orkest.fileTreePanel.openInFileManager' => 'Abrir no gerenciador de arquivos',
			'orkest.fileTreePanel.open' => 'Abrir',
			'orkest.fileTreePanel.openWith' => 'Abrir com',
			'orkest.fileTreePanel.openInNewWindow' => 'Abrir em nova janela',
			'orkest.fileTreePanel.openLayout' => 'Abrir layout',
			'orkest.fileTreePanel.openAsMarkdown' => 'Abrir como markdown',
			'orkest.fileTreePanel.showGitDiff' => 'Mostrar diff do git',
			'orkest.fileTreePanel.createTerminal' => 'Abrir no terminal',
			'orkest.fileTreePanel.rename' => 'Renomear',
			'orkest.fileTreePanel.copy' => 'Copiar',
			'orkest.fileTreePanel.cut' => 'Recortar',
			'orkest.fileTreePanel.paste' => 'Colar',
			'orkest.fileTreePanel.copyRelativePath' => 'Copiar caminho relativo',
			'orkest.fileTreePanel.copyAbsolutePath' => 'Copiar caminho absoluto',
			'orkest.fileTreePanel.renameFailed' => 'Falha ao renomear.',
			'orkest.fileTreePanel.noChanges' => 'Nenhuma alteração.',
			'orkest.fileTreePanel.stagedChangesHeader' => ({required Object count}) => 'ALTERAÇÕES EM STAGE (${count})',
			'orkest.fileTreePanel.changesHeader' => ({required Object count}) => 'ALTERAÇÕES (${count})',
			'orkest.fileTreePanel.discardAllChanges' => 'Descartar todas as alterações',
			'orkest.fileTreePanel.unstageAllChanges' => 'Tirar tudo do stage',
			'orkest.fileTreePanel.stageAllChanges' => 'Colocar tudo no stage',
			'orkest.fileTreePanel.discardFolderChanges' => 'Descartar alterações da pasta',
			'orkest.fileTreePanel.unstageFolderChanges' => 'Tirar pasta do stage',
			'orkest.fileTreePanel.stageFolderChanges' => 'Colocar pasta no stage',
			'orkest.fileTreePanel.generateCommitMessage' => 'Gerar mensagem de commit',
			'orkest.fileTreePanel.generateWith' => ({required Object harness}) => 'Gerar com ${harness}',
			'orkest.fileTreePanel.generateUnavailableWhileAmending' => 'Indisponível durante o amend de um commit',
			'orkest.fileTreePanel.cancelGeneration' => 'Cancelar geração',
			'orkest.fileTreePanel.changes' => 'Alteracoes',
			'orkest.fileTreePanel.history' => 'Historico',
			'orkest.fileTreePanel.historyRepository' => 'Repositorio',
			'orkest.fileTreePanel.historyNoRepository' => 'Nenhum repositorio Git disponivel.',
			'orkest.fileTreePanel.historyEmpty' => 'Nenhum commit encontrado.',
			'orkest.fileTreePanel.historyLoadFailed' => 'Nao foi possivel carregar o historico Git.',
			'orkest.fileTreePanel.historyUntitledCommit' => 'Commit sem titulo',
			'orkest.fileTreePanel.historyNow' => 'agora',
			'orkest.fileTreePanel.historyMinutesAgo' => ({required Object count}) => 'ha ${count} min',
			'orkest.fileTreePanel.historyHoursAgo' => ({required Object count}) => 'ha ${count} h',
			'orkest.fileTreePanel.historyYesterday' => 'ontem',
			'orkest.fileTreePanel.historyDayAgo' => 'ha 1 dia',
			'orkest.fileTreePanel.historyDaysAgo' => ({required Object count}) => 'ha ${count} dias',
			'orkest.fileTreePanel.historyFiles' => 'Arquivos alterados',
			'orkest.fileTreePanel.historyFilesEmpty' => 'Nenhum arquivo alterado.',
			'orkest.fileTreePanel.historyFilesLoadFailed' => 'Nao foi possivel carregar os arquivos alterados.',
			'orkest.fileTreePanel.historyCopyHash' => 'Copiar hash do commit',
			'orkest.fileTreePanel.historyRevertCommit' => 'Reverter commit',
			'orkest.fileTreePanel.historyUndoLastCommit' => 'Desfazer último commit',
			'orkest.fileTreePanel.historyRevertConfirm' => ({required Object hash}) => 'Reverter o commit ${hash}? O Git criará um novo commit que desfaz suas alterações.',
			'orkest.fileTreePanel.historyUndoConfirm' => ({required Object hash}) => 'Desfazer o commit ${hash}? As alterações permanecerão no diretório de trabalho.',
			'orkest.fileTreePanel.historyGitActionFailed' => 'Não foi possível concluir a operação Git.',
			'orkest.fileTreePanel.pullPushMenu' => 'Pull, Push',
			'orkest.fileTreePanel.branchMenu' => 'Branch',
			'orkest.fileTreePanel.mergeBranch' => 'Mesclar branch…',
			'orkest.fileTreePanel.rebaseBranch' => 'Rebase da branch…',
			'orkest.fileTreePanel.renameBranch' => 'Renomear branch…',
			'orkest.fileTreePanel.deleteBranch' => 'Excluir branch…',
			'orkest.fileTreePanel.publishBranch' => 'Publicar branch',
			'orkest.fileTreePanel.stashMenu' => 'Stash',
			'orkest.fileTreePanel.stashChanges' => 'Guardar alterações…',
			'orkest.fileTreePanel.stashPop' => 'Aplicar último stash',
			'orkest.fileTreePanel.tagsMenu' => 'Tags',
			'orkest.fileTreePanel.createTag' => 'Criar tag…',
			'orkest.fileTreePanel.deleteTag' => 'Excluir tag…',
			'orkest.fileTreePanel.branchReferencePlaceholder' => 'Branch ou referência',
			'orkest.fileTreePanel.branchNamePlaceholder' => 'Novo nome da branch',
			'orkest.fileTreePanel.stashMessagePlaceholder' => 'Mensagem (opcional)',
			'orkest.fileTreePanel.tagNamePlaceholder' => 'Nome da tag',
			'orkest.fileTreePanel.diffEmptyTree' => 'Arvore vazia',
			'orkest.fileTreePanel.diffOriginal' => ({required Object ref}) => 'Original ${ref}',
			'orkest.fileTreePanel.diffModified' => ({required Object ref}) => 'Modificado ${ref}',
			'orkest.fileTreePanel.diffWorkingTree' => 'Diretorio de trabalho',
			'orkest.fileTreePanel.diffBinaryFile' => 'Arquivo binario - sem diff de texto.',
			'orkest.fileTreePanel.diffNoChanges' => 'Sem alteracoes.',
			'orkest.fileTreePanel.diffError' => ({required Object detail}) => 'Não foi possível ler o diff: ${detail}',
			'orkest.fileTreePanel.galleryTooltip' => 'Galeria',
			'orkest.fileTreePanel.sectionGallery' => 'GALERIA',
			'orkest.fileTreePanel.openAsHtml' => 'Abrir como HTML',
			'orkest.fileTreePanel.importQuestionTitle' => 'Copiar aqui?',
			'orkest.fileTreePanel.importMessage' => ({required Object count, required Object dest}) => 'Copiar ${count} itens para “${dest}”?',
			'orkest.fileTreePanel.importAction' => 'Copiar',
			'orkest.fileTreePanel.couldNotImportTitle' => 'Não foi possível copiar',
			'orkest.fileTreePanel.openInAgent' => ({required Object harness}) => 'Abrir no ${harness}',
			'orkest.fileViewer.cantOpen' => 'Não é possível abrir este arquivo.',
			'orkest.fileViewer.couldNotLoadImage' => 'Não foi possível carregar a imagem.',
			'orkest.fileViewer.preview' => 'Pré-visualização',
			'orkest.fileViewer.source' => 'Código-fonte',
			'orkest.fileViewer.reload' => 'Recarregar',
			'orkest.workspaceSettingsDialog.choosePhotoTitle' => 'Escolher foto do workspace',
			'orkest.workspaceSettingsDialog.title' => 'Configurações do workspace',
			'orkest.workspaceSettingsDialog.namePlaceholder' => 'Nome do workspace',
			'orkest.workspaceSettingsDialog.addPhoto' => 'Adicionar foto',
			'orkest.workspaceSettingsDialog.changePhoto' => 'Alterar foto',
			'orkest.workspaceSettingsDialog.remove' => 'Remover',
			'orkest.workspaceSettingsDialog.color' => 'Cor',
			'orkest.workspaceSettingsDialog.host' => 'Host',
			'orkest.workspaceSettingsDialog.folder' => 'Pasta',
			'orkest.realmDialogs.namePlaceholder' => 'Nome do realm',
			'orkest.realmDialogs.duplicateName' => 'Já existe um realm com esse nome.',
			'orkest.realmDialogs.newRealmTitle' => 'Novo realm',
			'orkest.realmDialogs.renameRealmTitle' => 'Renomear realm',
			'orkest.realmDialogs.rename' => 'Renomear',
			'orkest.realmDialogs.deleteRealmTitle' => 'Excluir realm',
			'orkest.realmDialogs.deleteMessage' => ({required Object name, required Object suffix}) => 'Excluir "${name}"? Nenhum workspace é excluído — só a lista de pastas muda.${suffix}',
			'orkest.realmDialogs.deleteSuffixOne' => ' O workspace dele irá para o Padrão.',
			'orkest.realmDialogs.deleteSuffixMany' => ({required Object count}) => ' Os ${count} workspaces dele irão para o Padrão.',
			'orkest.realmDialogs.manageRealmsTitle' => 'Gerenciar realms',
			'orkest.realmDialogs.workspaceCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 workspace', other: '${n} workspaces', ), 
			'orkest.dbRedisTable.deleteKeyTitle' => 'Excluir chave',
			'orkest.dbRedisTable.deleteKeyMessage' => ({required Object key}) => 'Excluir "${key}" deste banco Redis?',
			'orkest.dbRedisTable.refresh' => 'Atualizar',
			'orkest.dbRedisTable.newKey' => 'Nova chave',
			'orkest.dbRedisTable.columnKey' => 'CHAVE',
			'orkest.dbRedisTable.columnValue' => 'VALOR',
			'orkest.dbRedisTable.columnType' => 'TIPO',
			'orkest.dbRedisTable.columnTtl' => 'TTL',
			'orkest.dbRedisTable.keyCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 chave', other: '${n} chaves', ), 
			'orkest.dbRedisTable.noKeys' => 'Nenhuma chave neste banco de dados.',
			'orkest.dbRedisTable.noKeysMatch' => ({required Object pattern}) => 'Nenhuma chave corresponde a "${pattern}".',
			'orkest.dbRedisTable.loadMore' => 'Carregar mais',
			'orkest.dbRedisTable.loadingFullValue' => 'Carregando valor completo…',
			'orkest.dbRedisTable.ttlMustBeNumber' => 'TTL deve ser um número de segundos.',
			'orkest.dbRedisTable.addKey' => 'Adicionar chave',
			'orkest.dbRedisTable.keyFieldHint' => 'chave',
			'orkest.dbRedisTable.ttlFieldHint' => 'ttl (s, opcional)',
			'orkest.dbRedisTable.valueFieldHint' => 'valor',
			'orkest.dbRedisTable.searchHint' => 'Buscar — padrão, ex.: user:*',
			'orkest.dbQueryView.saveQueryAs' => 'Salvar query como',
			'orkest.dbQueryView.couldNotSave' => 'Não foi possível salvar',
			_ => null,
		} ?? switch (path) {
			'orkest.dbQueryView.selectDatabase' => 'Selecionar banco de dados',
			'orkest.dbQueryView.noSqlConnections' => 'Nenhuma conexão SQL',
			'orkest.dbQueryView.running' => 'Executando…',
			'orkest.dbQueryView.runSelection' => 'Executar seleção',
			'orkest.dbQueryView.run' => 'Executar',
			'orkest.dbQueryView.pickDatabaseHint' => 'Escolha um banco de dados acima e depois Executar (⌘↵).',
			'orkest.dbQueryView.runQueryHint' => 'Execute a query (⌘↵) para ver os resultados aqui.',
			'orkest.dbQueryView.noRows' => 'Nenhuma linha.',
			'orkest.dbQueryView.rowsAffected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 linha afetada', other: '${n} linhas afetadas', ), 
			'orkest.dbQueryView.rowsFooter' => ({required Object n}) => '${n} linhas',
			'orkest.dbQueryView.truncatedSuffix' => ' · truncado (aumente -- limit)',
			'orkest.dbQueryView.table' => 'Tabela',
			'orkest.dbQueryView.json' => 'JSON',
			'orkest.dbQueryView.unsaved' => 'não salvo',
			'orkest.dbQueryView.saved' => 'salvo',
			'orkest.dbQueryView.copied' => 'Copiado',
			'orkest.dbQueryView.copy' => 'Copiar',
			'orkest.httpView.saveRequestAs' => 'Salvar request como',
			'orkest.httpView.couldNotSave' => 'Não foi possível salvar',
			'orkest.httpView.run' => 'Executar',
			'orkest.httpView.running' => 'Executando…',
			'orkest.httpView.noRequests' => 'Nenhum request neste arquivo — escreva um, ex.: GET https://example.com',
			'orkest.httpView.selectRequest' => 'Selecionar request',
			'orkest.httpView.requestCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 request', other: '${n} requests', ), 
			'orkest.httpView.runHint' => 'Execute o request (⌘↵) para ver a resposta aqui.',
			'orkest.httpView.emptyBody' => 'Corpo da resposta vazio.',
			'orkest.httpView.body' => 'JSON',
			'orkest.httpView.headers' => 'Headers',
			'orkest.httpView.raw' => 'Text',
			'orkest.httpView.truncatedSuffix' => ' · truncado (resposta grande demais)',
			'orkest.httpView.error.title' => 'Falha no request',
			'orkest.httpView.error.noRequest' => 'Nenhum request encontrado na posição do cursor.',
			'orkest.httpView.error.invalidUrl' => ({required Object url}) => 'URL inválida: ${url}',
			'orkest.httpView.error.unresolvedVariable' => ({required Object name}) => 'A variável {{${name}}} não tem valor. Declare com @${name} = … neste arquivo.',
			'orkest.httpView.error.bodyFileMissing' => ({required Object path}) => 'Arquivo de corpo não encontrado: ${path}',
			'orkest.httpView.error.bodyFileUnreadable' => ({required Object path, required Object detail}) => 'Não foi possível ler o arquivo de corpo ${path}: ${detail}',
			'orkest.httpView.error.connectionFailed' => ({required Object detail}) => 'Não foi possível alcançar o servidor: ${detail}',
			'orkest.httpView.error.connectionFailedNoDetail' => 'Não foi possível alcançar o servidor.',
			'orkest.httpView.error.timeout' => ({required Object seconds}) => 'O request estourou o tempo limite de ${seconds}s.',
			'orkest.httpView.error.responseTooLarge' => ({required Object bytes}) => 'A resposta passou do limite de ${bytes} bytes.',
			'orkest.kanbanView.filter' => 'Filtrar',
			'orkest.kanbanView.filterTitlePlaceholder' => 'Buscar por título',
			'orkest.kanbanView.filterLabels' => 'Marcadores',
			'orkest.kanbanView.filterClear' => 'Limpar',
			'orkest.kanbanView.filterDependencies' => 'Dependências',
			'orkest.kanbanView.filterBlocked' => 'Bloqueado',
			'orkest.kanbanView.filterReady' => 'Pronto',
			'orkest.kanbanView.blockedBy' => 'Bloqueado por',
			'orkest.kanbanView.addBlocker' => 'Adicionar card bloqueador',
			'orkest.kanbanView.searchCards' => 'Buscar cards',
			'orkest.kanbanView.unknownCard' => 'desconhecido',
			'orkest.kanbanView.boardView' => 'Quadro',
			'orkest.kanbanView.listView' => 'Lista',
			'orkest.kanbanView.refresh' => 'Atualizar do disco',
			'orkest.kanbanView.manageLabels' => 'Marcadores',
			'orkest.kanbanView.labelsTitle' => 'Marcadores deste quadro',
			'orkest.kanbanView.labelNamePlaceholder' => 'nome do marcador',
			'orkest.kanbanView.labelUsage' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 card', other: '${n} cards', ), 
			'orkest.kanbanView.deleteLabel' => 'Apagar marcador',
			'orkest.kanbanView.newCard' => 'novo card',
			'orkest.kanbanView.newCardTitle' => 'Novo card',
			'orkest.kanbanView.newColumn' => 'Nova coluna',
			'orkest.kanbanView.columnNameTitle' => 'Nome da coluna',
			'orkest.kanbanView.dragColumn' => 'Arrastar coluna',
			'orkest.kanbanView.columnOptions' => 'Opções da coluna',
			'orkest.kanbanView.renameColumn' => 'Renomear coluna',
			'orkest.kanbanView.moveColumnLeft' => 'Mover pra esquerda',
			'orkest.kanbanView.moveColumnRight' => 'Mover pra direita',
			'orkest.kanbanView.deleteColumn' => 'Apagar coluna',
			'orkest.kanbanView.newCardHere' => 'Novo card aqui',
			'orkest.kanbanView.duplicateCard' => 'Duplicar',
			'orkest.kanbanView.cardLabels' => 'Marcadores',
			'orkest.kanbanView.deleteCard' => 'Apagar card',
			'orkest.kanbanView.advance' => 'Passar pra próxima coluna',
			'orkest.kanbanView.advanceHold' => 'Mover para a próxima coluna (segurar: mover para a última)',
			'orkest.kanbanView.advanceBack' => 'Voltar uma coluna',
			'orkest.kanbanView.emptyColumn' => 'Sem cards',
			'orkest.kanbanView.cardCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 card', other: '${n} cards', ), 
			'orkest.kanbanView.notes' => 'Nota',
			'orkest.kanbanView.notesPlaceholder' => 'Escreva uma nota',
			'orkest.kanbanView.comments' => 'Comentários',
			'orkest.kanbanView.addComment' => 'Adicionar comentário',
			'orkest.kanbanView.commentPlaceholder' => 'Escreva um comentário',
			'orkest.kanbanView.noComments' => 'Nenhum comentário ainda',
			'orkest.kanbanView.closeDetail' => 'Fechar',
			'orkest.kanbanView.notABoard' => 'Este arquivo ainda não tem colunas ## — ele abre como markdown.',
			'orkest.kanbanView.startBoard' => 'Começar um quadro',
			'orkest.kanbanView.couldNotSave' => 'Não deu pra salvar o quadro',
			'orkest.kanbanView.unrecognizedBlock' => 'Não reconhecido pelo parser — arrasta inteiro, sem edição inline.',
			'orkest.kanbanView.deleteColumnDialog.title' => ({required Object name}) => 'Apagar “${name}”?',
			'orkest.kanbanView.deleteColumnDialog.message' => ({required Object count}) => 'Esta coluna tem ${count}. Escolha o que acontece com eles.',
			'orkest.kanbanView.deleteColumnDialog.moveCards' => 'Mover pra coluna anterior',
			'orkest.kanbanView.deleteColumnDialog.deleteAll' => 'Apagar junto com a coluna',
			'orkest.kanbanView.deleteColumnDialog.emptyMessage' => 'Esta coluna está vazia.',
			'orkest.dbPanel.sectionDatabase' => 'BANCO DE DADOS',
			'orkest.dbPanel.edit' => 'Editar…',
			'orkest.dbPanel.copyName' => 'Copiar nome',
			'orkest.dbPanel.newQuery' => 'Nova query',
			'orkest.dbPanel.browseKeys' => 'Ver chaves',
			'orkest.dbPanel.deleteConnectionTitle' => 'Excluir conexão',
			'orkest.dbPanel.deleteConnectionMessage' => ({required Object name}) => 'Remover "${name}" deste workspace? Qualquer senha salva será descartada. Arquivos .dbq que fazem referência a ela não são afetados.',
			'orkest.dbPanel.footer' => ({required Object n}) => '.orkest/databases.json · ${n} conexões',
			'orkest.dbPanel.footerOne' => '.orkest/databases.json · 1 conexão',
			'orkest.dbPanel.noConnections' => 'Nenhuma conexão ainda.',
			'orkest.dbPanel.passwordRequired' => 'Senha não encontrada no host. Abra esta conexão e digite-a de novo — ela fica salva na máquina que executa o banco, não nesta.',
			'orkest.dbMongoView.deleteDocumentTitle' => 'Excluir documento',
			'orkest.dbMongoView.deleteDocumentMessage' => ({required Object id, required Object collection}) => 'Excluir o documento com _id ${id} de "${collection}"?',
			'orkest.dbMongoView.filterHint' => 'Filtro — JSON, ex.: {"status": "active"}',
			'orkest.dbMongoView.docCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 doc', other: '${n} docs', ), 
			'orkest.dbMongoView.refresh' => 'Atualizar',
			'orkest.dbMongoView.insertDocument' => 'Inserir documento',
			'orkest.dbMongoView.noDocuments' => 'Nenhum documento nesta coleção.',
			'orkest.dbMongoView.noDocumentsMatch' => 'Nenhum documento corresponde a este filtro.',
			'orkest.dbMongoView.loadMore' => 'Carregar mais',
			'orkest.dbMongoView.edit' => 'Editar',
			'orkest.dbMongoView.insert' => 'Inserir',
			'orkest.dbConnectionDialog.chooseFileTitle' => 'Escolher banco SQLite',
			'orkest.dbConnectionDialog.file' => 'Arquivo',
			'orkest.dbConnectionDialog.chooseFilePlaceholder' => 'Escolha um arquivo SQLite…',
			'orkest.dbConnectionDialog.name' => 'Nome',
			'orkest.dbConnectionDialog.password' => 'Senha',
			'orkest.dbConnectionDialog.savePassword' => 'Salvar senha',
			'orkest.dbConnectionDialog.allowWrites' => 'Permitir escrita (agentes)',
			'orkest.dbConnectionDialog.allowWritesHint' => 'desligado = agentes só leem via CLI',
			'orkest.dbConnectionDialog.visibleToAgents' => 'Visível para agentes',
			'orkest.dbConnectionDialog.visibleToAgentsHint' => 'desligado = oculto da CLI, só na GUI',
			'orkest.dbConnectionDialog.testing' => 'Testando conexão…',
			'orkest.dbConnectionDialog.connectionOk' => 'Conexão OK',
			'orkest.dbConnectionDialog.connectionFailed' => 'Falha na conexão',
			'orkest.dbConnectionDialog.editTitle' => 'Editar conexão',
			'orkest.dbConnectionDialog.newTitle' => 'Nova conexão',
			'orkest.dbConnectionDialog.connectionString' => 'Connection string',
			'orkest.dbConnectionDialog.invalidUrl' => 'URL de conexão inválida.',
			'orkest.dbConnectionDialog.sshTunnel' => 'Túnel SSH',
			'orkest.dbConnectionDialog.sshHost' => 'Host SSH',
			'orkest.dbConnectionDialog.sshPort' => 'Porta SSH',
			'orkest.dbConnectionDialog.sshUser' => 'Usuário SSH',
			'orkest.dbConnectionDialog.privateKey' => 'Chave privada',
			'orkest.dbConnectionDialog.choosePrivateKeyPlaceholder' => 'Escolha uma chave privada…',
			'orkest.dbConnectionDialog.choosePrivateKeyDialogTitle' => 'Escolher chave privada SSH',
			'orkest.dbConnectionDialog.keyPassphrase' => 'Senha da chave',
			'orkest.dbConnectionDialog.savePassphrase' => 'Salvar senha da chave',
			'orkest.dbConnectionDialog.passwordOnHost' => 'A senha fica salva no host, não nesta máquina.',
			'orkest.sshPrompts.unknownSshHostTitle' => 'Host SSH desconhecido',
			'orkest.sshPrompts.neverConnected' => ({required Object endpoint}) => 'O Orkest Code nunca se conectou a ${endpoint} antes.',
			'orkest.sshPrompts.trustHint' => 'Confie apenas se esta fingerprint corresponder ao servidor. Você pode verificar no servidor com:',
			'orkest.sshPrompts.trust' => 'Confiar',
			'orkest.sshPrompts.sshKeyPassphraseTitle' => 'Senha da chave SSH',
			'orkest.sshPrompts.unlockMessage' => ({required Object keyPath, required Object connectionName}) => 'Desbloqueie ${keyPath} para conectar "${connectionName}".',
			'orkest.sshPrompts.keptInMemoryHint' => 'Mantida em memória até o Orkest Code fechar. Para permitir que agentes usem esta conexão, ative "Salvar senha da chave" na conexão.',
			'orkest.sshPrompts.unlock' => 'Desbloquear',
			'orkest.projectsRail.workspaces' => 'Workspaces',
			'orkest.projectsRail.keepAwakeOn' => 'Mantendo este computador acordado para acesso remoto. Clique para deixá-lo dormir de novo.',
			'orkest.projectsRail.keepAwakeOff' => 'Manter este computador acordado para acesso remoto. Desliga sozinho quando o Orkest Code reinicia.',
			'orkest.projectsRail.keepAwakeBattery' => 'Acordado na bateria. Isso consome a bateria.',
			'orkest.projectsRail.keepAwakeLid' => 'Fechar a tampa do notebook continua colocando-o para dormir.',
			'orkest.projectsRail.newWorkspace' => 'Novo workspace',
			'orkest.projectsRail.settings' => 'Configurações',
			'orkest.projectsRail.mergeToParent' => 'Mesclar no pai',
			'orkest.projectsRail.updateFromParent' => 'Atualizar a partir do pai',
			'orkest.projectsRail.forkWorktree' => 'Criar worktree derivada',
			'orkest.projectsRail.copyBranch' => 'Copiar branch',
			'orkest.projectsRail.remove' => 'Remover',
			'orkest.projectsRail.moveToRealm' => 'Mover para realm',
			'orkest.projectsRail.copyWorkspaceId' => 'Copiar id do workspace',
			'orkest.projectsRail.rename' => 'Renomear',
			'orkest.projectsRail.close' => 'Fechar',
			'orkest.projectsRail.newRealm' => 'Novo realm…',
			'orkest.projectsRail.manageRealms' => 'Gerenciar realms…',
			'orkest.projectsRail.noWorkspaces' => 'Nenhum workspace ainda.',
			'orkest.projectsRail.sync' => 'Sincronizar',
			'orkest.projectsRail.pull' => 'Pull',
			'orkest.projectsRail.push' => 'Push',
			'orkest.projectsRail.createWorktree' => 'Criar worktree',
			'orkest.projectsRail.worktreeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(n, one: '1 worktree', other: '${n} worktrees', ), 
			'orkest.projectsRail.expandWorktrees' => 'Expandir worktrees',
			'orkest.projectsRail.collapseWorktrees' => 'Recolher worktrees',
			'orkest.findBar.find' => 'Buscar',
			'orkest.findBar.matchCase' => 'Diferenciar maiúsculas',
			'orkest.findBar.wholeWord' => 'Palavra inteira',
			'orkest.findBar.useRegex' => 'Usar expressão regular',
			'orkest.findBar.previous' => 'Anterior (⇧⏎)',
			'orkest.findBar.next' => 'Próximo (⏎)',
			'orkest.findBar.close' => 'Fechar (Esc)',
			'orkest.findBar.badPattern' => 'Padrão inválido',
			'orkest.findBar.counter' => ({required Object current, required Object total}) => '${current} de ${total}',
			'orkest.findBar.noResults' => 'Nenhum resultado',
			'orkest.contentSearch.sectionSearch' => 'BUSCA',
			'orkest.contentSearch.searchInFiles' => 'Buscar nos arquivos',
			'orkest.contentSearch.matchCase' => 'Diferenciar maiúsculas',
			'orkest.contentSearch.wholeWord' => 'Palavra inteira',
			'orkest.contentSearch.useRegex' => 'Usar expressão regular',
			'orkest.contentSearch.invalidRegex' => 'Expressão regular inválida.',
			'orkest.contentSearch.typeToSearch' => 'Digite para buscar em todos os arquivos.',
			'orkest.contentSearch.searching' => 'Buscando…',
			'orkest.contentSearch.noResults' => 'Nenhum resultado.',
			'orkest.topbar.collapseSidebar' => 'Recolher barra lateral',
			'orkest.topbar.toggleFiles' => 'Mostrar/ocultar arquivos',
			'orkest.topbar.filesUnavailable' => 'Arquivos indisponíveis no Orkest Code',
			'orkest.topbar.hideKeyboard' => 'Baixar teclado',
			'orkest.topbar.showOffice' => 'Mostrar escritório',
			'orkest.topbar.showTerminals' => 'Mostrar terminais',
			'orkest.tasks.hotReload' => 'Hot reload',
			'orkest.tasks.hotRestart' => 'Hot restart',
			'orkest.tasks.toggleDebugPaint' => 'Alternar debug paint',
			'orkest.tasks.togglePlatform' => 'Alternar plataforma',
			'orkest.tasks.quit' => 'Sair',
			'orkest.notifications.agentFinished' => 'Agente terminou',
			'orkest.notifications.open' => 'Abrir',
			'orkest.notifications.agentNeedsAction' => 'Agente precisa de você',
			'orkest.terminalLink.open' => 'Abrir',
			'orkest.terminalLink.revealFinder' => 'Mostrar no Finder',
			'orkest.terminalLink.revealExplorer' => 'Mostrar no Explorer',
			'orkest.terminalLink.revealFolder' => 'Abrir pasta',
			'orkest.terminalLink.copyPath' => 'Copiar caminho',
			'orkest.terminalLink.openLink' => 'Abrir link',
			'orkest.terminalLink.copyLink' => 'Copiar link',
			'orkest.terminal.cwdFallbackWarning' => ({required Object requested, required Object path}) => 'Aviso: a pasta "${requested}" não existe. Este terminal abriu em "${path}".',
			'orkest.terminal.workspaceEnvTracked' => ({required Object keys}) => 'Aviso: o .env.orkest está rastreado pelo git (veio com o repositório). Injetado: ${keys}',
			'orkest.remoteHost.addHost' => 'Adicionar host remoto',
			'orkest.remoteHost.hostName' => 'Nome',
			'orkest.remoteHost.sshTarget' => 'Destino SSH (usuário@host)',
			'orkest.remoteHost.connecting' => ({required Object host}) => 'Conectando a ${host}…',
			'orkest.remoteHost.openingTunnel' => 'Túnel SSH',
			'orkest.remoteHost.installingServer' => 'Instalando servidor',
			'orkest.remoteHost.handshake' => ({required Object version}) => 'Servidor ${version}',
			'orkest.remoteHost.loadingWorkspace' => 'Carregando workspace…',
			'orkest.remoteHost.reconnecting' => ({required Object host}) => 'Reconectando a ${host}…',
			'orkest.remoteHost.offline' => ({required Object host}) => '${host} offline',
			'orkest.remoteHost.remove' => 'Remover',
			'orkest.remoteHost.reconnect' => 'Reconectar',
			'orkest.remoteHost.installServer' => 'Instalar servidor',
			'orkest.remoteHost.errSshUnreachable' => ({required Object host}) => 'Não foi possível alcançar ${host} via SSH. Está ligado e com o Login Remoto ativado?',
			'orkest.remoteHost.errInstallFailed' => ({required Object host}) => 'Não foi possível instalar o servidor em ${host}.',
			'orkest.remoteHost.errVersionMismatch' => 'Versão do servidor incompatível; atualize-o.',
			'orkest.remoteHost.errDetail' => ({required Object detail}) => 'Detalhes: ${detail}',
			'orkest.remoteHost.pickFolderTitle' => ({required Object host}) => 'Abrir pasta em ${host}',
			'orkest.remoteHost.openHere' => 'Abrir aqui',
			'orkest.remoteHost.emptyFolder' => 'Sem subpastas',
			'orkest.remoteHost.newLocal' => 'Local',
			'orkest.remoteHost.newRemote' => 'Remoto',
			'orkest.remoteHost.chooseHost' => 'Escolher um host',
			'orkest.remoteHost.newHostEntry' => 'Novo host…',
			'orkest.remoteHost.editHost' => 'Editar host',
			'orkest.remoteHost.userLabel' => 'Usuário',
			'orkest.remoteHost.hostLabel' => 'Host / IP',
			'orkest.remoteHost.portLabel' => 'Porta',
			'orkest.remoteHost.authLabel' => 'Autenticação',
			'orkest.remoteHost.authKey' => 'Chave SSH',
			'orkest.remoteHost.authPassword' => 'Senha',
			'orkest.remoteHost.passwordLabel' => 'Senha',
			'orkest.remoteHost.passwordKeep' => 'Deixe em branco para manter a atual',
			'orkest.remoteHost.errUser' => 'Usuário obrigatório',
			'orkest.remoteHost.errHost' => 'Host obrigatório',
			'orkest.remoteHost.errPassword' => 'Senha obrigatória',
			'orkest.remoteHost.identityChoose' => 'Escolher…',
			'orkest.remoteHost.identityEmpty' => 'Nenhuma chave selecionada',
			'orkest.remoteHost.identityDialogTitle' => 'Selecione a chave privada SSH',
			'orkest.remoteHost.errIdentity' => 'Escolha a chave privada para autenticar.',
			'orkest.remoteHost.errHostKeyUnknown' => ({required Object host}) => 'O Orkest Code ainda não confia em ${host}. Conecte de novo e confirme o fingerprint.',
			'orkest.remoteHost.errHostKeyChanged' => ({required Object host}) => '${host} está apresentando uma chave SSH diferente da guardada. Se você não reinstalou essa máquina, pare e verifique — se reinstalou, remova a entrada antiga do ~/.ssh/known_hosts.',
			'orkest.remoteHost.errHostBundleMissing' => ({required Object host}) => '${host} é Windows mas não tem o Orkest Code instalado. O servidor remoto é instalado a partir do bundle do Orkest Code que já está naquela máquina — instale o Orkest Code lá e tente de novo.',
			'orkest.remoteHost.errHostUnknownOs' => ({required Object host}) => 'Não foi possível identificar o sistema de ${host}. A conta pode ter shell restrito, ou nenhum shell.',
			'orkest.remoteHost.errIdentityPublic' => 'Só a chave pública está aqui. Isso só funciona se a privada estiver no seu agente SSH; senão, escolha a privada (mesmo nome, sem .pub).',
			'orkest.remoteHost.errIdentityNotKey' => 'Esse arquivo não parece uma chave privada.',
			'orkest.remoteHost.errIdentityMissingFile' => 'Esse arquivo não existe mais.',
			'orkest.remoteHost.errIdentityUnreadable' => 'Não foi possível ler esse arquivo.',
			'orkest.browserPane.back' => 'Voltar',
			'orkest.browserPane.forward' => 'Avançar',
			'orkest.browserPane.reload' => 'Recarregar',
			'orkest.browserPane.urlHint' => 'Digite a URL ou endereço',
			'orkest.browserPane.go' => 'Ir',
			'orkest.documentWindow.mediaNotSupported' => 'Áudio e vídeo abrem na janela principal do Orkest Code.',
			'orkest.documentWindow.fileNotFound' => ({required Object path}) => 'Arquivo não encontrado: ${path}',
			'orkest.gallery.intro' => 'Documentos especiais do Orkest Code para que você tenha o visual do que o agente de IA esteja fazendo.',
			'orkest.gallery.createErrorTitle' => 'Não foi possível criar o arquivo',
			'orkest.gallery.dbQuery.title' => 'Consulta de banco',
			'orkest.gallery.dbQuery.description' => 'Editor SQL com grid de resultado, usando uma das conexões registradas.',
			'orkest.gallery.kanban.title' => 'Quadro kanban',
			'orkest.gallery.kanban.description' => 'Colunas e cards gravados como markdown puro. Arraste, edite e comente.',
			'orkest.gallery.layout.title' => 'Layout de panes',
			'orkest.gallery.layout.description' => 'Terminais e splits para abrir de uma vez, estilo tmuxinator. Pode rodar sozinho em worktrees novas.',
			'orkest.gallery.httpRequest.title' => 'Requests HTTP',
			'orkest.gallery.httpRequest.description' => 'Escreva requests num arquivo e execute com a resposta ao lado.',
			'orkest.gallery.html.title' => 'Visual HTML',
			'orkest.gallery.html.description' => 'Uma página que o agente escreve e o Orkest Code renderiza direto: mapa mental, diagrama, gráfico, o que precisar.',
			'orkest.gallery.tasks.title' => 'Tarefas',
			'orkest.gallery.tasks.description' => 'Comandos para rodar pelo painel de Tasks, como dev server, testes e build. Fica em .orkest/tasks.json.',
			'orkest.gallery.notebook.title' => 'Caderno',
			'orkest.gallery.notebook.description' => 'Uma pasta de notas curtas com tags. O agente escreve, você lê e edita. Abre no Obsidian também.',
			'orkest.gallery.workspaceEnv.title' => 'Env do workspace',
			'orkest.gallery.workspaceEnv.description' => 'Variáveis injetadas em todo terminal deste workspace. Coloque tokens ou logins de API aqui em vez de colar no prompt do agente. Fica fora do git.',
			'orkest.gallery.panel.title' => 'Painel',
			'orkest.gallery.panel.description' => 'Uma página HTML com ponte para o app: os botões rodam comandos da CLI do Orkest Code e do shell nesta máquina. Um playground para dashboards rápidos.',
			'orkest.notebook.notes' => 'Notas',
			'orkest.notebook.newNote' => 'Nova nota',
			'orkest.notebook.searchPlaceholder' => 'Buscar notas',
			'orkest.notebook.empty' => 'Nenhuma nota ainda. Crie uma, ou peça pro agente escrever aqui.',
			'orkest.notebook.noMatch' => 'Nenhuma nota bate com o filtro.',
			'orkest.notebook.selectNote' => 'Selecione uma nota',
			'orkest.notebook.reload' => 'Recarregar do disco',
			'orkest.notebook.untagged' => 'sem tag',
			'orkest.notebook.saveFailed' => 'Não foi possível salvar a nota',
			'orkest.notebook.createFailed' => 'Não foi possível criar a nota',
			'orkest.notebook.addTag' => 'adicionar tag',
			'orkest.notebook.untitled' => 'Sem título',
			'orkest.notebook.deleteNote' => 'Apagar nota',
			'orkest.notebook.deleteConfirm' => ({required Object name}) => 'Mover “${name}” pra lixeira?',
			'orkest.notebook.imageFailed' => 'Não foi possível salvar a imagem',
			'orkest.notebook.format.bold' => 'Negrito (⌘B)',
			'orkest.notebook.format.italic' => 'Itálico (⌘I)',
			'orkest.notebook.format.strike' => 'Riscado',
			'orkest.notebook.format.heading1' => 'Título 1',
			'orkest.notebook.format.heading2' => 'Título 2',
			'orkest.notebook.format.heading3' => 'Título 3',
			'orkest.notebook.format.bullets' => 'Lista',
			'orkest.notebook.format.numbered' => 'Lista numerada',
			'orkest.notebook.format.checklist' => 'Checklist',
			'orkest.notebook.format.quote' => 'Citação',
			'orkest.notebook.format.code' => 'Código inline (⌘E)',
			'orkest.notebook.format.codeBlock' => 'Bloco de código',
			'orkest.notebook.format.link' => 'Link (⌘K)',
			'orkest.notebook.format.rule' => 'Divisor',
			'orkest.notebook.format.noteLink' => 'Link pra uma nota ([[…]])',
			'orkest.notebook.format.noteLinkSearch' => 'Buscar notas',
			'orkest.notebook.format.image' => 'Inserir imagem…',
			'orkest.notebook.backlinks' => 'Citada em',
			'orkest.notebook.renameTag' => 'Renomear tag',
			'orkest.notebook.deleteTag' => 'Apagar tag',
			'orkest.notebook.deleteTagConfirm' => ({required Object name, required Object count}) => 'Remover “${name}” de ${count} notas? As notas ficam.',
			'orkest.notebook.showList' => 'Mostrar lista de notas',
			'orkest.notebook.hideList' => 'Ocultar lista de notas',
			'orkest.layoutPreview.applyFailedTitle' => 'Não foi possível aplicar o layout',
			'orkest.layoutPreview.applyInOrkest' => 'Aplicar no Orkest Code',
			'orkest.layoutPreview.applyNewWorkspace' => 'Abrir como novo workspace',
			'orkest.layoutPreview.applyTo' => ({required Object workspace}) => 'Aplicar em ${workspace}',
			'orkest.layoutPreview.autorunWorktree' => 'autorun: worktree. Este layout também é aplicado sozinho quando você cria uma worktree do workspace onde ele está.',
			'orkest.layoutPreview.command' => 'Comando',
			'orkest.layoutPreview.folder' => 'Pasta',
			'orkest.layoutPreview.noCommand' => 'sem comando, abre um shell',
			'orkest.layoutPreview.replaceConfirm' => 'Substituir layout',
			'orkest.layoutPreview.replaceMessage' => ({required Object n}) => '${n} abas abertas deste workspace serão fechadas, inclusive as com trabalho em andamento.',
			'orkest.layoutPreview.replaceTitle' => ({required Object workspace}) => 'Substituir o layout de ${workspace}?',
			'orkest.layoutPreview.skippedTitle' => 'Não criados neste sistema',
			'orkest.layoutPreview.splitDown' => 'divide abaixo',
			'orkest.layoutPreview.splitRight' => 'divide à direita',
			'orkest.layoutPreview.splitTab' => 'aba',
			'orkest.layoutPreview.subtitle' => ({required Object n}) => 'Este layout abre ${n} terminais. Leia os comandos antes de aplicar.',
			'orkest.telemetry.tooltip' => 'Telemetria',
			'orkest.telemetry.title' => 'Telemetria',
			'orkest.telemetry.liveRuns' => ({required Object n}) => '${n} ativos',
			'orkest.telemetry.noWorkspace' => 'Abra um workspace para ver a telemetria dele.',
			'orkest.telemetry.empty' => 'Nada aqui ainda.',
			'orkest.telemetry.emptyFiltered' => 'Nada aqui ainda.',
			'orkest.telemetry.searchHint' => 'Filtrar casos',
			'orkest.telemetry.chipOpen' => 'Abertos',
			'orkest.telemetry.chipNew' => 'Novos',
			'orkest.telemetry.chipResolved' => 'Resolvidos',
			'orkest.telemetry.chipIgnored' => 'Ignorados',
			'orkest.telemetry.chipWarnings' => 'Avisos',
			'orkest.telemetry.tagNew' => 'novo',
			'orkest.telemetry.tagRegression' => 'regressão',
			'orkest.telemetry.tagResolved' => 'resolvido',
			'orkest.telemetry.tagIgnored' => 'ignorado',
			'orkest.telemetry.srcTask' => 'task',
			'orkest.telemetry.srcWrapper' => 'orkest telemetry',
			'orkest.telemetry.run' => ({required Object id}) => 'run ${id}',
			'orkest.telemetry.resolve' => 'Marcar resolvido',
			'orkest.telemetry.ignore' => 'Ignorar (some para os agentes também)',
			'orkest.telemetry.reopen' => 'Reabrir',
			'orkest.telemetry.clear' => 'Limpar ocorrências',
			'orkest.telemetry.clearRun' => 'Limpar este run',
			'orkest.telemetry.clearProject' => 'Limpar projeto',
			'orkest.telemetry.openFile' => ({required Object location}) => 'Abrir ${location}',
			'orkest.telemetry.showInTerminal' => 'Ver no terminal',
			'orkest.telemetry.copyCommand' => 'Copiar comando da CLI',
			'orkest.telemetry.copied' => 'Copiado',
			'orkest.telemetry.statusOpen' => 'Aberto',
			'orkest.telemetry.statusResolved' => 'Resolvido',
			'orkest.telemetry.statusIgnored' => 'Ignorado',
			'orkest.telemetry.occurrences' => 'Ocorrências',
			'orkest.telemetry.inRuns' => ({required Object n}) => 'em ${n} runs',
			'orkest.telemetry.first' => 'Primeira',
			'orkest.telemetry.last' => 'Última',
			'orkest.telemetry.origin' => 'Origem',
			'orkest.telemetry.sectionStack' => 'Stack',
			'orkest.telemetry.stackHint' => 'frames do projeto em destaque · clique abre o arquivo',
			'orkest.telemetry.sectionCorrelated' => 'Log correlacionado',
			'orkest.telemetry.correlatedHint' => 'o JSON mais próximo antes do erro, no mesmo run',
			'orkest.telemetry.none' => 'nenhum',
			'orkest.telemetry.sectionRuns' => 'Ocorrências por run',
			'orkest.telemetry.runsHint' => 'mesma chave (cwd, comando): é assim que novo e regressão são calculados',
			'orkest.telemetry.sectionContext' => 'Contexto cru',
			'orkest.telemetry.contextHint' => 'linhas do terminal ao redor da última ocorrência',
			'orkest.telemetry.current' => 'atual',
			'orkest.telemetry.fingerprintHint' => ({required Object location}) => 'fingerprint = tipo + mensagem normalizada + ${location}',
			'orkest.telemetry.blameUncommitted' => 'alterado no working tree',
			'orkest.telemetry.blameCommit' => ({required Object ago, required Object sha}) => 'alterado ${ago} (${sha})',
			'orkest.telemetry.justNow' => 'agora',
			'orkest.telemetry.minutesAgo' => ({required Object n}) => 'há ${n} min',
			'orkest.telemetry.hoursAgo' => ({required Object n}) => 'há ${n} h',
			'orkest.telemetry.daysAgo' => ({required Object n}) => 'há ${n} d',
			'orkest.telemetry.resolvedToast' => 'Resolvido. Se voltar num run futuro, reaparece como regressão.',
			'orkest.telemetry.ignoredToast' => 'Ignorado. Os agentes não veem mais (salvo --include-ignored).',
			'orkest.telemetry.clearedToast' => 'Ocorrências apagadas. As regras de triagem ficam.',
			'orkest.telemetry.byHuman' => 'por você',
			'orkest.telemetry.byAgent' => 'pelo agente',
			'orkest.telemetry.caseTabTitle' => ({required Object type, required Object file}) => '${type} · ${file}',
			'orkest.telemetry.srcApp' => 'App',
			'orkest.telemetry.chipApp' => 'Orkest Code',
			'orkest.panelView.unavailable' => 'Painéis precisam da web view embutida, que ainda não existe no Linux.',
			'orkest.panelView.openInBrowser' => 'Abrir no navegador',
			'orkest.panelView.openAsHtml' => 'Abrir como HTML',
			'settings.language.title' => 'Idioma',
			'settings.language.system' => 'Sistema',
			'settings.language.english' => 'Inglês',
			'settings.language.portugueseBr' => 'Português (BR)',
			'settings.language.spanish' => 'Espanhol',
			'settings.page.header.back' => 'Voltar',
			'settings.page.header.title' => 'Configurações',
			'settings.page.nav.general' => 'Geral',
			'settings.page.nav.appearance' => 'Aparência',
			'settings.page.nav.terminal' => 'Terminal',
			'settings.page.nav.language' => 'Linguagem',
			'settings.page.nav.shortcuts' => 'Atalhos',
			'settings.page.nav.notifications' => 'Notificações',
			'settings.page.nav.automations' => 'Automações',
			'settings.page.nav.remoteHosts' => 'Hosts remotos',
			'settings.page.general.sectionEditor' => 'Editor',
			'settings.page.general.editorEngineTitle' => 'Motor',
			'settings.page.general.editorEngineOrkest' => 'Orkest Code (padrão)',
			'settings.page.general.editorEngineNeovim' => 'Neovim',
			'settings.page.general.neovimChecking' => 'Procurando o Neovim…',
			'settings.page.general.neovimNotFound' => 'O Neovim não foi encontrado na PATH do seu shell.',
			'settings.page.general.neovimRefresh' => 'Verificar novamente',
			'settings.page.general.showOrkestTitle' => 'Mostrar terminal do Orkest Code',
			'settings.page.general.showOrkestDesc' => 'Mantém um workspace sem pasta, só de terminal, fixado no topo da barra lateral. Desligar fecha seus terminais.',
			'settings.page.general.launchAtStartupTitle' => 'Iniciar ao ligar',
			'settings.page.general.launchAtStartupDesc' => 'Inicia o Orkest Code automaticamente quando você faz login no computador.',
			'settings.page.general.sectionUpdates' => 'Atualizações',
			'settings.page.general.checkUpdatesTitle' => 'Verificar atualizações',
			'settings.page.general.checkUpdatesDesc' => 'Com que frequência o Orkest Code deve procurar novas versões.',
			'settings.page.general.updateFrequency.daily' => 'Diariamente',
			'settings.page.general.updateFrequency.weekly' => 'Semanalmente',
			'settings.page.general.updateFrequency.monthly' => 'Mensalmente',
			'settings.page.general.updateFrequency.never' => 'Nunca',
			'settings.page.general.developerModeTitle' => 'Modo desenvolvedor',
			'settings.page.general.developerModeDesc' => 'Registra os erros e avisos do próprio Orkest Code numa base separada da Telemetria (chip “Orkest Code”) e liga as métricas de performance. Só serve a quem mantém o app.',
			'settings.page.diagnostics.sectionTitle' => 'Diagnóstico',
			'settings.page.diagnostics.logFileTitle' => 'Arquivo de log',
			'settings.page.diagnostics.logFileDesc' => ({required Object days, required Object path}) => 'Erros e eventos de inicialização são registrados aqui, mantidos por ${days} dias.\n${path}',
			'settings.page.diagnostics.unavailable' => 'indisponível',
			'settings.page.diagnostics.reveal' => 'Revelar',
			'settings.page.diagnostics.reportTitle' => 'Reportar um problema',
			'settings.page.diagnostics.reportDesc' => 'Abre uma issue pré-preenchida com sua versão, SO e log recente. Nada é enviado automaticamente — você revisa antes.',
			'settings.page.diagnostics.reportButton' => 'Reportar…',
			'settings.page.diagnostics.reportDialogTitle' => 'Relatório de problema',
			'settings.page.diagnostics.reportDialogError' => 'Reportado manualmente pelas Configurações.',
			'settings.page.diagnostics.reportDialogDescription' => 'Descreva o que deu errado na issue. O log recente está incluído abaixo e em "Copiar detalhes".',
			'settings.page.storage.sectionTitle' => 'Armazenamento',
			'settings.page.storage.locationTitle' => 'Local de armazenamento',
			'settings.page.storage.locationDesc' => ({required Object root}) => 'O Orkest Code guarda seus projetos, layouts e configurações aqui. Aponte para uma pasta sincronizada para fazer backup.\n${root}',
			'settings.page.storage.useDefault' => 'Usar padrão',
			'settings.page.storage.working' => 'Trabalhando…',
			'settings.page.storage.change' => 'Alterar…',
			'settings.page.storage.resetTitle' => 'Redefinir o Orkest Code',
			'settings.page.storage.resetDesc' => 'Exclui todos os dados locais — projetos, layouts, configurações e histórico do terminal — e volta ao local padrão.',
			'settings.page.storage.resetButton' => 'Redefinir…',
			'settings.page.storage.resetConfirm' => 'Redefinir',
			'settings.page.storage.resetDialogTitle' => 'Redefinir o Orkest Code?',
			'settings.page.storage.resetDialogContent' => 'Isso exclui permanentemente todos os dados locais do Orkest Code — projetos, layouts, configurações e histórico do terminal. Isso não pode ser desfeito. O Orkest Code será fechado para você começar do zero.',
			'settings.page.storage.restartRequiredTitle' => 'Reinicialização necessária',
			'settings.page.storage.restartChangeFolderMessage' => ({required Object path}) => 'O Orkest Code usará esta pasta a partir da próxima abertura:\n${path}',
			'settings.page.storage.restartUseDefaultMessage' => 'O Orkest Code usará o local padrão do sistema a partir da próxima abertura. Seus dados na pasta personalizada permanecem intactos.',
			'settings.page.storage.restartResetMessage' => 'Todos os dados do Orkest Code foram apagados. Reinicie para começar do zero.',
			'settings.page.storage.later' => 'Mais tarde',
			'settings.page.storage.quitOrkest' => 'Sair do Orkest Code',
			'settings.page.storage.chooseFolderDialogTitle' => 'Escolha uma pasta para os dados do Orkest Code',
			'settings.page.terminal.sectionDefaultTerminal' => 'Terminal padrão',
			'settings.page.terminal.engineTitle' => 'Motor',
			'settings.page.terminal.engineDesc' => 'Usado por novas abas de terminal e buffers de saída de tasks. Abas abertas mantêm o motor atual.',
			'settings.page.terminal.shellTitle' => 'Shell',
			'settings.page.terminal.shellDesc' => 'Qual shell novas abas de terminal abrem. A seta ao lado do + ainda abre qualquer outro, só para aquela aba.',
			'settings.page.terminal.noWslMessage' => 'Nenhuma distro WSL encontrada. Instale uma (wsl.exe --install) e reinicie o Orkest Code para vê-la listada aqui.',
			'settings.page.terminal.sectionBehavior' => 'Comportamento',
			'settings.page.terminal.closeOnExitTitle' => 'Fechar a aba quando o shell encerrar',
			'settings.page.terminal.closeOnExitDesc' => 'Quando um shell termina sozinho (exit, Ctrl-D), fecha a aba em vez de deixar um terminal morto.',
			'settings.page.appearance.sectionTheme' => 'Tema',
			'settings.page.appearance.themeTitle' => 'Tema',
			'settings.page.appearance.themeDesc' => 'Cores do app, realce de código e paleta do terminal.',
			'settings.page.appearance.modeTitle' => 'Modo',
			'settings.page.appearance.modeDesc' => 'Qual variante do tema usar.',
			'settings.page.appearance.modeOnlyDark' => ({required Object theme}) => '"${theme}" só traz a variante escura, então isto não tem efeito.',
			'settings.page.appearance.modeOnlyLight' => ({required Object theme}) => '"${theme}" só traz a variante clara, então isto não tem efeito.',
			'settings.page.appearance.themeFileTitle' => 'Arquivo de tema',
			'settings.page.appearance.themeFileDesc' => 'Importe um tema de um arquivo JSON, ou exporte o tema ativo.',
			'settings.page.appearance.previewCode' => 'Código',
			'settings.page.appearance.previewTerminal' => 'Terminal',
			'settings.page.appearance.themeSystem' => 'Sistema',
			'settings.page.appearance.themeLight' => 'Claro',
			'settings.page.appearance.themeDark' => 'Escuro',
			'settings.page.appearance.sectionFonts' => 'Fontes',
			'settings.page.appearance.interfaceFontTitle' => 'Fonte da interface',
			'settings.page.appearance.interfaceFontDesc' => 'Usada em todo o aplicativo. Vazio = padrão do sistema.',
			'settings.page.appearance.interfaceSizeTitle' => 'Tamanho da interface',
			'settings.page.appearance.codeFontTitle' => 'Fonte do código',
			'settings.page.appearance.codeFontDesc' => 'Código e diffs. Vazio = padrão do sistema.',
			'settings.page.appearance.codeSizeTitle' => 'Tamanho do código',
			'settings.page.appearance.terminalFontTitle' => 'Fonte do terminal',
			'settings.page.appearance.terminalFontDesc' => 'Só o terminal. Vazio = padrão do sistema.',
			'settings.page.appearance.terminalSizeTitle' => 'Tamanho do terminal',
			'settings.page.appearance.terminalSizeDesc' => 'Desligado = segue o tamanho do código.',
			_ => null,
		} ?? switch (path) {
			'settings.page.appearance.terminalSizeInherit' => 'Seguir o código',
			'settings.page.appearance.terminalWeightTitle' => 'Peso do terminal',
			'settings.page.appearance.terminalWeightDesc' => 'Telas de baixa densidade engrossam os traços. O automático afina só nelas e não mexe no Retina.',
			'settings.page.appearance.terminalWeightAuto' => 'Automático (pela tela)',
			'settings.page.appearance.terminalWeightLight' => 'Fino',
			'settings.page.appearance.terminalWeightNormal' => 'Normal',
			'settings.page.appearance.terminalWeightMedium' => 'Médio',
			'settings.page.appearance.terminalWeightSemiBold' => 'Seminegrito',
			'settings.page.appearance.sectionConversation' => 'Conversa',
			'settings.page.appearance.pinUserMessageTitle' => 'Fixar mensagem do usuário',
			'settings.page.appearance.pinUserMessageDesc' => 'A pergunta fica fixa no topo enquanto a resposta rola.',
			'settings.page.appearance.importTheme' => 'Importar…',
			'settings.page.appearance.exportTheme' => 'Exportar…',
			'settings.page.appearance.deleteTheme' => 'Remover',
			'settings.page.appearance.importThemeDialog' => 'Escolha um arquivo de tema',
			'settings.page.appearance.exportThemeDialog' => 'Salvar tema como',
			'settings.page.appearance.themeImported' => ({required Object name}) => 'Tema "${name}" importado.',
			'settings.page.appearance.themeExported' => 'Tema salvo.',
			'settings.page.appearance.themeDeleted' => 'Tema removido.',
			'settings.page.appearance.fontPickerTitle' => 'Escolher uma fonte',
			'settings.page.appearance.fontPickerSearch' => 'Buscar fontes',
			'settings.page.appearance.fontPickerEmpty' => 'Nenhuma fonte correspondente nesta máquina.',
			'settings.page.appearance.fontPickerBundled' => 'inclusa',
			'settings.page.appearance.fontPickerCustom' => 'Não está na lista? Digite o nome exato da família.',
			'settings.page.appearance.fontPickerCustomHint' => 'Nome da família',
			'settings.page.appearance.fontPickerUse' => 'Usar',
			'settings.page.appearance.fontPickerDefault' => 'Padrão',
			'settings.page.appearance.fontMissing' => 'Não encontrada nesta máquina — usando o fallback.',
			'settings.page.appearance.sectionLayout' => 'Layout',
			'settings.page.appearance.swapPanelsTitle' => 'Inverter panes',
			'settings.page.appearance.swapPanelsDesc' => 'Coloca os workspaces à direita e arquivos, busca, git e banco à esquerda.',
			'settings.page.notifications.sectionTitle' => 'Notificações',
			'settings.page.notifications.enableTitle' => 'Ativar notificações',
			'settings.page.notifications.enableDesc' => 'Avisar quando um agente terminar uma resposta e a janela não estiver em foco.',
			'settings.page.notifications.systemPermissionTitle' => 'Permissão do sistema',
			'settings.page.notifications.grantedDesc' => 'O Orkest Code tem permissão para enviar notificações.',
			'settings.page.notifications.notGrantedDesc' => 'O macOS ainda não concedeu acesso a notificações.',
			'settings.page.notifications.granted' => 'Concedido',
			'settings.page.notifications.requestPermission' => 'Solicitar permissão',
			'settings.page.notifications.soundsTitle' => 'Sons',
			'settings.page.notifications.soundVolumeTitle' => 'Volume',
			'settings.page.notifications.soundTurnDone' => 'Turno concluído',
			'settings.page.notifications.soundTurnDoneDesc' => 'Um agente terminou o turno.',
			'settings.page.notifications.soundActionRequired' => 'Ação necessária',
			'settings.page.notifications.soundActionRequiredDesc' => 'Um agente está esperando sua aprovação ou resposta.',
			'settings.page.notifications.soundDefault' => 'Padrão',
			'settings.page.notifications.soundCustom' => ({required Object name}) => 'Personalizado: ${name}',
			'settings.page.notifications.soundChooseFile' => 'Escolher arquivo',
			'settings.page.notifications.soundReset' => 'Voltar ao padrão',
			'settings.page.notifications.soundOnActiveTab' => 'Tocar também com a aba ativa',
			'settings.page.notifications.soundPreview' => 'Ouvir',
			'settings.page.shortcuts.notCustomizable' => 'Os atalhos de teclado ainda não são personalizáveis.',
			'settings.page.languages.sectionFormatting' => 'FORMATAÇÃO',
			'settings.page.languages.formatOnSaveTitle' => 'Formatar ao salvar',
			'settings.page.languages.formatOnSaveDesc' => 'Formata o arquivo automaticamente ao salvar (⌘S).',
			'settings.page.languages.sectionLanguageServers' => 'SERVIDORES DE LINGUAGEM',
			'settings.page.languages.footerNote' => 'Erros e formatação usam o language server de cada linguagem. O Orkest Code não instala servidores — ele usa o que já está na sua máquina. ● responde · ○ não encontrado ou comando inválido (instale o servidor ou ajuste o comando).',
			'settings.page.languages.serverCommandLabel' => 'Comando do language server',
			'settings.page.languages.formatterCommandLabel' => 'Comando do formatador (opcional)',
			'settings.page.languages.formatterHint' => 'Formatador externo com o placeholder %FILE%. Tem prioridade sobre o formatador do LSP quando definido.',
			'settings.page.languages.resetToDefault' => 'Redefinir para o padrão',
			'settings.page.languages.saveAndRestart' => 'Salvar e reiniciar',
			'settings.page.languages.statusResponds' => 'Servidor responde',
			'settings.page.languages.statusNotFound' => 'Servidor não encontrado ou comando inválido',
			'settings.page.automations.sectionCommitMessages' => 'Mensagens de commit',
			'settings.page.automations.harness' => 'Harness',
			'settings.page.automations.harnessDiscovering' => 'Procurando harnesses de linha de comando instalados…',
			'settings.page.automations.harnessNoneFound' => 'Nenhum harness compatível foi encontrado no PATH.',
			'settings.page.automations.harnessConfiguredUnavailable' => ({required Object harness}) => '${harness} está configurado, mas indisponível.',
			'settings.page.automations.harnessChoose' => 'Escolha a CLI usada para gerar mensagens de commit.',
			'settings.page.automations.harnessRefresh' => 'Atualizar harnesses instalados',
			'settings.page.automations.notConfigured' => 'Não configurado',
			'settings.page.automations.model' => 'Modelo',
			'settings.page.automations.modelUnavailable' => 'A lista de modelos fica indisponível até o harness ser encontrado.',
			'settings.page.automations.modelCliOnly' => 'Este harness usa o modelo padrão da própria CLI.',
			'settings.page.automations.modelCliDefault' => 'Padrão da CLI',
			'settings.page.automations.modelAuto' => 'Auto',
			'settings.page.automations.modelSearch' => ({required Object count}) => 'Buscar entre ${count} modelos…',
			'settings.page.automations.modelAutoRouted' => 'Este harness escolhe o modelo automaticamente.',
			'settings.page.automations.modelAccountOnly' => 'Só aparecem os modelos liberados na sua conta.',
			'settings.page.automations.generateFromSourceControl' => 'Gerar pelo Controle de Versão',
			'settings.page.automations.generateFromSourceControlDescription' => 'O Orkest Code envia apenas o diff selecionado e os assuntos dos commits recentes. Padrões comuns de credenciais e arquivos sensíveis são redigidos antes de o harness rodar.',
			'settings.page.automations.discoveryFailed' => 'Não foi possível descobrir os harnesses de automação instalados.',
			'settings.page.automations.staleModel' => ({required Object model, required Object harness}) => 'O modelo "${model}" não está mais disponível para ${harness}. Usando o padrão da CLI; escolha outro modelo em Configurações se precisar.',
			'settings.page.automations.recommendedSuffix' => 'Recomendado',
			'settings.remoteHosts.title' => 'Hosts remotos',
			'settings.remoteHosts.description' => 'Máquinas que você acessa por SSH. Adicionar um host aqui é o mesmo que adicionar pelo menu "+" do workspace.',
			'settings.remoteHosts.empty' => 'Nenhum host remoto ainda.',
			'settings.remoteHosts.add' => 'Adicionar host',
			'settings.remoteHosts.edit' => 'Editar',
			'settings.remoteHosts.reconnect' => 'Reconectar',
			'settings.remoteHosts.remove' => 'Remover',
			'settings.remoteHosts.removeTitle' => 'Remover host',
			'settings.remoteHosts.removeMessage' => ({required Object name}) => 'Remover "${name}" e todos os workspaces dele? Nada é apagado no host.',
			'settings.remoteHosts.workspacesCount' => ({required Object count}) => '${count} workspace(s)',
			'settings.remoteHosts.deviceKeyTitle' => 'Chave deste dispositivo',
			'settings.remoteHosts.deviceKeyDesc' => 'Adicione esta chave pública ao ~/.ssh/authorized_keys do host para este dispositivo poder conectar.',
			'settings.remoteHosts.deviceKeyCopy' => 'Copiar chave pública',
			'settings.remoteHosts.deviceKeyCopied' => 'Chave pública copiada',
			'settings.remoteHosts.statusConnected' => 'Conectado',
			'settings.remoteHosts.statusConnecting' => 'Conectando…',
			'settings.remoteHosts.statusReconnecting' => 'Reconectando…',
			'settings.remoteHosts.statusOffline' => 'Offline',
			'settings.remoteHosts.statusIdle' => 'Não conectado',
			'settings.remoteHosts.helpTitle' => 'Como funciona',
			'settings.remoteHosts.helpBody' => 'O Orkest Code conecta na sua máquina por SSH e fala com um servidor pequeno que roda os terminais, arquivos e git lá. O host precisa ter o Orkest Code (desktop) ou o orkest-server instalado e rodando, e a chave pública deste dispositivo adicionada no ~/.ssh/authorized_keys dele.',
			'automation.error.unavailable' => ({required Object harness}) => '${harness} não está instalado ou não está no PATH.',
			'automation.error.modelUnavailable' => ({required Object model, required Object harness}) => 'O modelo "${model}" não está disponível para ${harness}. Escolha outro modelo em Configurações.',
			'automation.error.authentication' => ({required Object harness, required Object detail}) => '${harness}: ${detail}',
			'automation.error.timeout' => ({required Object harness, required Object seconds}) => '${harness} não respondeu em ${seconds} segundos.',
			'automation.error.cancelled' => 'A geração da mensagem de commit foi cancelada.',
			'automation.error.process' => ({required Object harness, required Object detail}) => '${harness}: ${detail}',
			'automation.error.processNoDetail' => ({required Object harness}) => '${harness} não conseguiu gerar uma mensagem de commit.',
			'automation.error.invalidResponse' => 'A automação devolveu uma mensagem de commit vazia.',
			'automation.error.busy' => 'Já há uma mensagem de commit sendo gerada.',
			'automation.error.unknown' => 'A automação não conseguiu gerar uma mensagem de commit.',
			'automation.error.noWorkspace' => 'Nenhum workspace selecionado.',
			'automation.error.fileOutsideWorkspace' => 'O arquivo está fora das raízes do workspace.',
			'automation.error.fileUnreadable' => ({required Object detail}) => 'Não foi possível ler o arquivo: ${detail}',
			'automation.error.binaryFile' => 'Não é possível gerar mensagem de commit para um arquivo binário.',
			'automation.error.noFileChanges' => 'Não há mudanças a descrever neste arquivo.',
			'automation.error.noStagedChanges' => 'Não há mudanças no stage a descrever.',
			'automation.error.multipleRepositories' => 'As mudanças no stage pertencem a repositórios diferentes. Gere uma de cada vez.',
			'automation.error.diffUnavailable' => 'Não foi possível ler o diff.',
			'automation.error.notConfigured' => 'Configure um harness de mensagem de commit em Configurações.',
			'fileOperation.error.alreadyExists' => ({required Object name}) => 'Já existe: “${name}”.',
			'fileOperation.error.notFound' => ({required Object name}) => 'Não encontrado: “${name}”.',
			'fileOperation.error.invalidPath' => 'Caminho inválido.',
			'fileOperation.error.emptyName' => 'O nome não pode ficar vazio.',
			'fileOperation.error.noWorkspace' => 'Nenhum workspace selecionado.',
			'fileOperation.error.cannotMoveIntoItself' => 'Não é possível mover uma pasta para dentro dela mesma.',
			'fileOperation.error.clipboardEmpty' => 'A área de transferência está vazia.',
			'fileOperation.error.notScratchTab' => 'Esta aba não é um arquivo temporário.',
			'fileOperation.error.writeFailed' => 'Não foi possível gravar o arquivo.',
			'fileOperation.error.formatterEmptyCommand' => 'Comando de formatação vazio.',
			'fileOperation.error.formatterMissingPlaceholder' => 'O comando de formatação precisa incluir o placeholder %FILE%.',
			'fileOperation.error.formatterTimeout' => 'O formatador excedeu o tempo limite.',
			'fileOperation.error.formatterExitCode' => ({required Object code}) => 'O formatador saiu com código ${code}.',
			'fileOperation.error.formatterFailed' => 'Não foi possível executar o formatador.',
			'fileOperation.error.osFailure' => ({required Object detail}) => '${detail}',
			'fileOperation.error.nameHasSlash' => 'O nome não pode conter “/”.',
			'fileOperation.error.invalidName' => 'Nome inválido.',
			'fileOperation.error.remoteDropUnsupported' => 'Soltar arquivos num workspace remoto ainda não é suportado.',
			'theme.error.io' => 'Não foi possível ler ou gravar o arquivo do tema.',
			'theme.error.ioDetail' => ({required Object detail}) => 'Não foi possível ler ou gravar o arquivo do tema: ${detail}',
			'theme.error.malformedJson' => ({required Object detail}) => 'Este arquivo não é um JSON válido: ${detail}',
			'theme.error.invalidTheme' => 'Este arquivo não é um tema válido.',
			'theme.error.reservedId' => 'Este tema usa o id de um tema nativo. Mude o "id" no arquivo e importe de novo.',
			'theme.error.notAnObject' => ({required Object field}) => 'Esperava um objeto em "${field}".',
			'theme.error.missingField' => ({required Object field}) => 'Falta o campo obrigatório "${field}".',
			'theme.error.badColor' => ({required Object value, required Object field}) => '"${value}" em "${field}" não é uma cor. Use #RGB, #RRGGBB ou #RRGGBBAA.',
			'theme.error.unknownBase' => ({required Object value}) => 'Tema base "${value}" desconhecido em "extends".',
			'theme.error.noVariants' => 'O tema não declara nenhum variant. Adicione "dark", "light" ou os dois em "variants".',
			_ => null,
		};
	}
}
