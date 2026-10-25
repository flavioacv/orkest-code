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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsEs _root = this; // ignore: unused_field

	@override
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$core$es core = _Translations$core$es._(_root);
	@override late final _Translations$common$es common = _Translations$common$es._(_root);
	@override late final _Translations$orkest$es orkest = _Translations$orkest$es._(_root);
	@override late final _Translations$settings$es settings = _Translations$settings$es._(_root);
	@override late final _Translations$automation$es automation = _Translations$automation$es._(_root);
	@override late final _Translations$fileOperation$es fileOperation = _Translations$fileOperation$es._(_root);
	@override late final _Translations$theme$es theme = _Translations$theme$es._(_root);
}

// Path: core
class _Translations$core$es extends Translations$core$en {
	_Translations$core$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$core$bootstrapError$es bootstrapError = _Translations$core$bootstrapError$es._(_root);
	@override late final _Translations$core$macosNotifications$es macosNotifications = _Translations$core$macosNotifications$es._(_root);
	@override late final _Translations$core$appErrorView$es appErrorView = _Translations$core$appErrorView$es._(_root);
	@override late final _Translations$core$errorReportDialog$es errorReportDialog = _Translations$core$errorReportDialog$es._(_root);
	@override late final _Translations$core$windowControls$es windowControls = _Translations$core$windowControls$es._(_root);
	@override late final _Translations$core$crash$es crash = _Translations$core$crash$es._(_root);
	@override late final _Translations$core$menu$es menu = _Translations$core$menu$es._(_root);
}

// Path: common
class _Translations$common$es extends Translations$common$en {
	_Translations$common$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Confirmar';
	@override String get create => 'Crear';
	@override String get gotIt => 'Entendido';
	@override String get save => 'Guardar';
	@override String get close => 'Cerrar';
	@override String get delete => 'Eliminar';
	@override String get done => 'Listo';
	@override String get add => 'Añadir';
	@override String get test => 'Probar';
	@override String get ok => 'OK';
	@override String get loading => 'Cargando…';
	@override String get checking => 'Comprobando…';
	@override String get remove => 'Quitar';
	@override String get restart => 'Reiniciar';
	@override String get settings => 'Configuración';
	@override String get send => 'Enviar';
	@override String get open => 'Abrir';
	@override String get dismiss => 'Descartar';
	@override String get report => 'Reportar';
	@override String get copyCode => 'Copiar código';
	@override String get search => 'Buscar';
	@override String get noResults => 'Sin resultados';
}

// Path: orkest
class _Translations$orkest$es extends Translations$orkest$en {
	_Translations$orkest$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$orkest$officeWorld$es officeWorld = _Translations$orkest$officeWorld$es._(_root);
	@override late final _Translations$orkest$confirmDialog$es confirmDialog = _Translations$orkest$confirmDialog$es._(_root);
	@override late final _Translations$orkest$neovim$es neovim = _Translations$orkest$neovim$es._(_root);
	@override late final _Translations$orkest$worktreeCreateDialog$es worktreeCreateDialog = _Translations$orkest$worktreeCreateDialog$es._(_root);
	@override late final _Translations$orkest$commitMessageDialog$es commitMessageDialog = _Translations$orkest$commitMessageDialog$es._(_root);
	@override late final _Translations$orkest$tasksPanel$es tasksPanel = _Translations$orkest$tasksPanel$es._(_root);
	@override late final _Translations$orkest$orkestPage$es orkestPage = _Translations$orkest$orkestPage$es._(_root);
	@override late final _Translations$orkest$welcomeView$es welcomeView = _Translations$orkest$welcomeView$es._(_root);
	@override late final _Translations$orkest$paneView$es paneView = _Translations$orkest$paneView$es._(_root);
	@override late final _Translations$orkest$fileTreePanel$es fileTreePanel = _Translations$orkest$fileTreePanel$es._(_root);
	@override late final _Translations$orkest$fileViewer$es fileViewer = _Translations$orkest$fileViewer$es._(_root);
	@override late final _Translations$orkest$workspaceSettingsDialog$es workspaceSettingsDialog = _Translations$orkest$workspaceSettingsDialog$es._(_root);
	@override late final _Translations$orkest$realmDialogs$es realmDialogs = _Translations$orkest$realmDialogs$es._(_root);
	@override late final _Translations$orkest$dbRedisTable$es dbRedisTable = _Translations$orkest$dbRedisTable$es._(_root);
	@override late final _Translations$orkest$dbQueryView$es dbQueryView = _Translations$orkest$dbQueryView$es._(_root);
	@override late final _Translations$orkest$httpView$es httpView = _Translations$orkest$httpView$es._(_root);
	@override late final _Translations$orkest$kanbanView$es kanbanView = _Translations$orkest$kanbanView$es._(_root);
	@override late final _Translations$orkest$dbPanel$es dbPanel = _Translations$orkest$dbPanel$es._(_root);
	@override late final _Translations$orkest$dbMongoView$es dbMongoView = _Translations$orkest$dbMongoView$es._(_root);
	@override late final _Translations$orkest$dbConnectionDialog$es dbConnectionDialog = _Translations$orkest$dbConnectionDialog$es._(_root);
	@override late final _Translations$orkest$sshPrompts$es sshPrompts = _Translations$orkest$sshPrompts$es._(_root);
	@override late final _Translations$orkest$projectsRail$es projectsRail = _Translations$orkest$projectsRail$es._(_root);
	@override late final _Translations$orkest$findBar$es findBar = _Translations$orkest$findBar$es._(_root);
	@override late final _Translations$orkest$contentSearch$es contentSearch = _Translations$orkest$contentSearch$es._(_root);
	@override late final _Translations$orkest$topbar$es topbar = _Translations$orkest$topbar$es._(_root);
	@override late final _Translations$orkest$tasks$es tasks = _Translations$orkest$tasks$es._(_root);
	@override late final _Translations$orkest$notifications$es notifications = _Translations$orkest$notifications$es._(_root);
	@override late final _Translations$orkest$terminalLink$es terminalLink = _Translations$orkest$terminalLink$es._(_root);
	@override late final _Translations$orkest$terminal$es terminal = _Translations$orkest$terminal$es._(_root);
	@override late final _Translations$orkest$remoteHost$es remoteHost = _Translations$orkest$remoteHost$es._(_root);
	@override late final _Translations$orkest$browserPane$es browserPane = _Translations$orkest$browserPane$es._(_root);
	@override late final _Translations$orkest$documentWindow$es documentWindow = _Translations$orkest$documentWindow$es._(_root);
	@override late final _Translations$orkest$gallery$es gallery = _Translations$orkest$gallery$es._(_root);
	@override late final _Translations$orkest$notebook$es notebook = _Translations$orkest$notebook$es._(_root);
	@override late final _Translations$orkest$layoutPreview$es layoutPreview = _Translations$orkest$layoutPreview$es._(_root);
	@override late final _Translations$orkest$telemetry$es telemetry = _Translations$orkest$telemetry$es._(_root);
	@override late final _Translations$orkest$panelView$es panelView = _Translations$orkest$panelView$es._(_root);
}

// Path: settings
class _Translations$settings$es extends Translations$settings$en {
	_Translations$settings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$language$es language = _Translations$settings$language$es._(_root);
	@override late final _Translations$settings$page$es page = _Translations$settings$page$es._(_root);
	@override late final _Translations$settings$remoteHosts$es remoteHosts = _Translations$settings$remoteHosts$es._(_root);
}

// Path: automation
class _Translations$automation$es extends Translations$automation$en {
	_Translations$automation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$automation$error$es error = _Translations$automation$error$es._(_root);
}

// Path: fileOperation
class _Translations$fileOperation$es extends Translations$fileOperation$en {
	_Translations$fileOperation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$fileOperation$error$es error = _Translations$fileOperation$error$es._(_root);
}

// Path: theme
class _Translations$theme$es extends Translations$theme$en {
	_Translations$theme$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$theme$error$es error = _Translations$theme$error$es._(_root);
}

// Path: core.bootstrapError
class _Translations$core$bootstrapError$es extends Translations$core$bootstrapError$en {
	_Translations$core$bootstrapError$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'No se pudo inicializar Orkest Code';
	@override String get retry => 'Reintentar';
}

// Path: core.macosNotifications
class _Translations$core$macosNotifications$es extends Translations$core$macosNotifications$en {
	_Translations$core$macosNotifications$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Activar notificaciones en macOS';
	@override String get intro => 'Las notificaciones están desactivadas en la configuración del sistema. Sigue los pasos a continuación para activarlas:';
	@override String get step1 => 'Abre los Ajustes del Sistema en tu Mac.';
	@override String get step2 => 'Ve a la sección Notificaciones en la barra lateral izquierda.';
	@override String get step3 => 'Busca y selecciona la aplicación Orkest Code en la lista.';
	@override String get step4 => 'Activa el interruptor Permitir Notificaciones.';
	@override String get tip => 'Consejo: si la aplicación no aparece en la lista, ciérrala y vuelve a abrirla para activar su registro en el sistema.';
	@override String get gotIt => 'Entendido';
}

// Path: core.appErrorView
class _Translations$core$appErrorView$es extends Translations$core$appErrorView$en {
	_Translations$core$appErrorView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get renderFailed => 'Esta parte de la aplicación no se pudo renderizar';
	@override String get details => 'Detalles';
	@override String get renderErrorTitle => 'Error de renderizado';
}

// Path: core.errorReportDialog
class _Translations$core$errorReportDialog$es extends Translations$core$errorReportDialog$en {
	_Translations$core$errorReportDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get defaultDescription => 'Algo salió mal. Los detalles a continuación se guardaron en el registro — puedes reportarlos para que se solucione.';
	@override String get copyDetails => 'Copiar detalles';
	@override String get reportIssue => 'Reportar problema';
}

// Path: core.windowControls
class _Translations$core$windowControls$es extends Translations$core$windowControls$en {
	_Translations$core$windowControls$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get minimize => 'Minimizar';
	@override String get maximize => 'Maximizar';
	@override String get close => 'Cerrar';
}

// Path: core.crash
class _Translations$core$crash$es extends Translations$core$crash$en {
	_Translations$core$crash$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cierre inesperado';
	@override String get bannerTitle => 'Orkest Code se cerró inesperadamente';
	@override String get report => 'Reportar';
	@override String get dismiss => 'Descartar';
	@override String crashMessage({required Object version}) => 'La sesión anterior (versión ${version}) terminó sin cerrarse correctamente. ¿Quieres reportarlo? El log se incluye y puedes revisar todo antes de enviar.';
	@override String crashError({required Object startedAt, required Object pid}) => 'La sesión iniciada el ${startedAt} (pid ${pid}) terminó sin un cierre limpio.';
	@override String get crashDescription => 'No se capturó ningún error: el sistema terminó la app. El log de abajo es de esa sesión y es la parte más útil.';
}

// Path: core.menu
class _Translations$core$menu$es extends Translations$core$menu$en {
	_Translations$core$menu$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get settings => 'Configuración…';
	@override String get checkForUpdates => 'Buscar Actualizaciones…';
	@override String get file => 'Archivo';
	@override String get newTerminal => 'Nueva Terminal';
	@override String get openWorkspace => 'Abrir Workspace';
	@override String get goToFile => 'Ir a Archivo…';
	@override String get save => 'Guardar';
	@override String get discard => 'Descartar';
	@override String get format => 'Formatear';
	@override String get view => 'Ver';
	@override String get toggleWorkspacePanel => 'Alternar Panel de Workspaces';
	@override String get toggleFiles => 'Alternar Archivos';
	@override String get splitRight => 'Dividir a la Derecha';
	@override String get splitDown => 'Dividir Abajo';
	@override String get focusPane => 'Enfocar Panel';
	@override String get focusLeft => 'Izquierda  (⌘⌥←)';
	@override String get focusRight => 'Derecha  (⌘⌥→)';
	@override String get focusUp => 'Arriba  (⌘⌥↑)';
	@override String get focusDown => 'Abajo  (⌘⌥↓)';
	@override String get selectTab => 'Seleccionar Pestaña';
	@override String tabN({required Object n}) => 'Pestaña ${n}';
	@override String get lastTab => 'Última Pestaña';
	@override String get previousWorkspace => 'Workspace Anterior';
	@override String get nextWorkspace => 'Siguiente Workspace';
	@override String get zoomIn => 'Acercar';
	@override String get zoomOut => 'Alejar';
	@override String get actualSize => 'Tamaño Real';
	@override String get window => 'Ventana';
	@override String get quit => 'Salir';
	@override String get minimize => 'Minimizar';
	@override String get zoom => 'Zoom';
}

// Path: orkest.officeWorld
class _Translations$orkest$officeWorld$es extends Translations$orkest$officeWorld$en {
	_Translations$orkest$officeWorld$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get reception => 'Recepción';
	@override String get cafe => 'Cocina';
	@override String get restrooms => 'Baños';
	@override String get lounge => 'Sala de descanso';
	@override String get rosterTitle => 'Agentes de la oficina';
	@override String get rosterSearch => 'Buscar agentes o proyectos';
	@override String get rosterEmpty => 'No se encontraron agentes activos';
	@override String get activityFeed => 'Actividad';
	@override String get activityEmpty => 'La actividad observada aparecerá aquí.';
	@override String get collapseRoster => 'Contraer lista de agentes';
	@override String get collapseFeed => 'Contraer actividad';
	@override String get reopenRoster => 'Agentes';
	@override String get reopenFeed => 'Actividad';
	@override String get working => 'Trabajando';
	@override String get waiting => 'Esperando';
	@override String get idle => 'Disponible';
	@override String get agentProfile => 'Perfil del agente';
	@override String get project => 'Proyecto';
	@override String get provider => 'Agente';
	@override String get currentStatus => 'Estado actual';
	@override String get followAgent => 'Seguir personaje';
	@override String get stopFollowingAgent => 'Dejar de seguir';
	@override String get centerAgent => 'Centrar personaje';
	@override String get sessionDuration => 'Sesión actual en Orkest Code';
	@override String get workingDirectory => 'Directorio de trabajo';
	@override String get statsPending => 'Orkest Code todavía no recopila estadísticas de modelo, tokens y herramientas.';
	@override String get recentActivity => 'Actividad reciente en esta ejecución';
	@override String get promptReceived => 'Recibió una solicitud';
	@override String get agentThinking => 'Pensando';
	@override String get agentResponded => 'Respuesta enviada';
	@override String get activityError => 'Algo salió mal';
	@override String get readingFile => 'Leyendo archivo';
	@override String get searchingCode => 'Buscando en el código';
	@override String get editingFile => 'Editando archivo';
	@override String get writingFile => 'Escribiendo archivo';
	@override String get runningCommand => 'Comando en terminal';
	@override String get runningTests => 'Ejecutando pruebas';
	@override String get browsingWeb => 'Buscando en la web';
	@override String get organizingTasks => 'Organizando tareas';
	@override String get callingSubagents => 'Llamando subagentes';
	@override String get toolCompleted => 'Herramienta completada';
	@override String get usingTool => 'Usando herramienta';
	@override String get editAgentName => 'Editar nombre del agente';
	@override String get agentName => 'Nombre del agente';
	@override String get workingInTerminal => 'Trabajando en el terminal';
	@override String get waitingInTerminal => 'Te necesita en el terminal';
	@override String get waitingBubble => 'Responder en la terminal';
	@override String get respond => 'Responder';
	@override String get dismissNotification => 'Descartar aviso';
	@override String get editAppearance => 'Editar personaje';
	@override String get randomizeAppearance => 'Sortear';
	@override String get resetAppearance => 'Volver al sorteo';
	@override String get skin => 'Piel';
	@override String get hair => 'Cabello';
	@override String get beard => 'Barba';
	@override String get eyes => 'Ojos';
	@override String get top => 'Parte superior';
	@override String get bottom => 'Parte inferior';
	@override String get shoes => 'Zapatos';
	@override String get accessory => 'Accesorio';
	@override String get turnCompleted => 'Turno terminado';
	@override String get subagentFailed => 'El subagente falló';
	@override String get subagentInterrupted => 'Subagente interrumpido';
	@override String get openTerminal => 'Abrir terminal';
	@override String get interactInOffice => 'Interactuar en Office';
	@override String get liveTerminal => 'Terminal en vivo';
	@override String get terminalInputPlaceholder => 'Escribe en la terminal…';
	@override String get terminalOfficeHint => 'La entrada se envía a la sesión original. Usa las opciones de respuesta que el agente muestre en esta terminal.';
	@override String get appearance => 'Apariencia de la oficina';
	@override String get officeTheme => 'Tema estacional';
	@override String get themeAuto => 'Automático';
	@override String get themeNone => 'Original';
	@override String get themeChristmas => 'Navidad';
	@override String get themeHalloween => 'Halloween';
	@override String get showNames => 'Mostrar nombres de agentes';
	@override String get bubbles => 'Globos de actividad';
	@override String get bubblesAll => 'Todos';
	@override String get bubblesImportant => 'Importantes';
	@override String get bubblesNone => 'Ninguno';
	@override String get movement => 'Movimiento por la oficina';
	@override String get movementCalm => 'Tranquilo';
	@override String get movementNormal => 'Normal';
	@override String get movementLively => 'Animado';
	@override String get daylight => 'Ciclo día/noche';
	@override String get sounds => 'Sonidos de la oficina';
	@override String get soundVolume => 'Volumen';
	@override String get soundAlerts => 'Avisos y tareas completadas';
	@override String get soundKeys => 'Teclado';
	@override String get soundElevator => 'Ascensor';
	@override String get soundSocial => 'Ping-pong y arcade';
	@override String get daylightAuto => 'Automático';
	@override String get daylightDay => 'Siempre de día';
	@override String get daylightNight => 'Siempre de noche';
	@override String get socialLife => 'Vida social';
	@override String gameCoins({required Object count}) => '${count} monedas de la oficina';
	@override String earnedWorking({required Object count}) => '${count} ganadas con actividades';
	@override String matchRecord({required Object wins, required Object losses}) => '${wins} victorias · ${losses} derrotas';
	@override String get personality => 'Personalidad';
	@override String get friendships => 'Amistades';
	@override String get rivals => 'Rivalidades';
	@override String get socialLedger => 'Historial de monedas';
	@override String get socialActivity => 'Vida social de la oficina';
	@override String delegatedBy({required Object name}) => 'Delegado por ${name}';
	@override String get shellWaiting => 'Esperando un comando';
	@override String get socialEconomy => 'Juego de la oficina — sin valor monetario real';
}

// Path: orkest.confirmDialog
class _Translations$orkest$confirmDialog$es extends Translations$orkest$confirmDialog$en {
	_Translations$orkest$confirmDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get unsavedChangesTitle => 'Cambios sin guardar';
	@override String unsavedChangesMessage({required Object fileName}) => '“${fileName}” tiene cambios sin guardar. ¿Guardarlos antes de cerrar?';
	@override String get dontSave => 'No guardar';
	@override String get saveAndClose => 'Guardar y cerrar';
}

// Path: orkest.neovim
class _Translations$orkest$neovim$es extends Translations$orkest$neovim$en {
	_Translations$orkest$neovim$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get unavailable => 'Neovim no está disponible. Abriendo en Orkest Code.';
	@override String get openFailed => 'No se pudo acceder a Neovim. Abriendo en Orkest Code.';
	@override String get unsavedTitle => 'Búferes de Neovim sin guardar';
	@override String get unsavedMessage => 'Neovim tiene búferes modificados. ¿Cerrar la pestaña y descartar esos cambios?';
	@override String get closeAnyway => 'Cerrar de todos modos';
}

// Path: orkest.worktreeCreateDialog
class _Translations$orkest$worktreeCreateDialog$es extends Translations$orkest$worktreeCreateDialog$en {
	_Translations$orkest$worktreeCreateDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get forkTitle => 'Fork del worktree';
	@override String get createTitle => 'Crear worktree';
	@override String forkSubtitle({required Object root}) => 'Nueva worktree ramificada desde ${root}.';
	@override String createSubtitle({required Object root}) => 'Nueva feature en ${root} — nueva branch desde el HEAD actual.';
	@override String get namePlaceholder => 'feat/mi-feature';
	@override String get errorWhitespace => 'Sin espacios en el nombre.';
	@override String get errorInvalidChar => 'Carácter inválido para un nombre de branch.';
	@override String get errorInvalidSequence => 'Secuencia inválida (ej.: "..", "//", empezar/terminar con "/").';
	@override String get errorReserved => 'Posición reservada (no empieces con "-"/"." ni termines con ".lock").';
	@override String get errorDuplicateBranch => 'Ya existe una branch con ese nombre.';
	@override String get errorDuplicateWorktree => 'Ya existe un worktree con ese nombre.';
	@override String errorBranchHierarchyConflict({required Object target, required Object existing}) => 'No se puede crear la branch \'${target}\' porque entra en conflicto con la branch \'${existing}\' ya existente.';
	@override String get errorBranchHierarchicalConflictGeneral => 'Ya existe una branch con una jerarquía conflictiva.';
	@override String get fork => 'Fork';
	@override String get postCheckoutHint => 'Este repositorio tiene un hook post-checkout.';
	@override String get running => 'Ejecutando…';
	@override String get advancedSettings => 'Configuración Avanzada';
	@override String get copyIgnored => 'Copiar archivos ignorados (.gitignore)';
	@override String get copyIgnoredDesc => 'Copia los archivos ignorados por .gitignore (ej. .env, claves locales) al nuevo worktree.';
	@override String get copyUntracked => 'Copiar archivos no rastreados';
	@override String get copyUntrackedDesc => 'Copia los archivos nuevos o modificados que aún no se han agregado al stage.';
	@override String get baseBranch => 'Branch base';
	@override String get baseBranchDesc => 'La branch desde la cual se creará el nuevo worktree y branch.';
	@override String get fetchRemote => 'Sincronizar branch remota (fetch)';
	@override String get fetchRemoteDesc => 'Ejecuta git fetch para garantizar que la branch base esté confirmada antes de crear el worktree.';
	@override String get searchBranch => 'Buscar branch...';
	@override String get back => 'Atrás';
}

// Path: orkest.commitMessageDialog
class _Translations$orkest$commitMessageDialog$es extends Translations$orkest$commitMessageDialog$en {
	_Translations$orkest$commitMessageDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get commitTitle => 'Commit';
	@override String get stageAndCommitTitle => 'Stage y Commit';
	@override String scopeNote({required Object fileName}) => 'Commit solo de "${fileName}".';
	@override String get placeholder => 'fix: resumen breve del cambio';
	@override String get errorEmptySubject => 'La primera línea (asunto) no puede estar vacía.';
	@override String errorTooShort({required Object min}) => 'Asunto demasiado corto (mín. ${min} caracteres).';
	@override String errorTooLong({required Object max}) => 'Asunto demasiado largo (máx. ${max} caracteres).';
	@override String get errorTrailingPeriod => 'El asunto no debe terminar con un punto.';
	@override String get errorControlChars => 'El asunto contiene caracteres de control.';
	@override String get errorBlankSecondLine => 'Deja la segunda línea en blanco (separador entre asunto y cuerpo de git).';
	@override String get generate => 'Generar mensaje de commit';
	@override String generateWith({required Object harness}) => 'Generar con ${harness}';
	@override String get generating => 'Generando…';
	@override String get cancelGeneration => 'Cancelar generación';
}

// Path: orkest.tasksPanel
class _Translations$orkest$tasksPanel$es extends Translations$orkest$tasksPanel$en {
	_Translations$orkest$tasksPanel$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get reloadTasksTooltip => 'Recargar tasks';
	@override String get restartTooltip => 'Reiniciar';
	@override String get stopTooltip => 'Detener';
	@override String get runTooltip => 'Ejecutar';
	@override String sendsKeyTooltip({required Object label, required Object key}) => '${label} (envía \'${key}\')';
	@override String get startingTooltip => 'Iniciando…';
	@override String get stoppingTooltip => 'Deteniendo…';
	@override String get switchProfileTooltip => 'Cambiar perfil';
	@override String get moreKeysTooltip => 'Más teclas';
	@override String get sectionTasks => 'TAREAS';
	@override String get noTasks => 'No se detectaron tareas en este proyecto.';
	@override String get createTasksJson => 'Crear tasks.json';
	@override String get generateComposeTasks => 'Generar tareas de Compose';
	@override String get selectComposeEngine => 'Elige un motor de Compose';
	@override String get noComposeEngine => 'No se encontró Docker Compose ni Podman Compose.';
	@override String get invalidComposeFile => 'El archivo activo no es un Compose válido con servicios.';
	@override String get invalidTasksJson => 'tasks.json no es válido. No se guardaron cambios.';
	@override String composeConflicts({required Object labels}) => 'Se conservaron tareas que no son Compose con etiquetas en conflicto: ${labels}';
}

// Path: orkest.orkestPage
class _Translations$orkest$orkestPage$es extends Translations$orkest$orkestPage$en {
	_Translations$orkest$orkestPage$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get chooseProjectFolderDialogTitle => 'Elige la carpeta del proyecto';
	@override String get chooseWorkspaceFolderDialogTitle => 'Elige la carpeta del workspace';
	@override String get workspaceRenamedTitle => 'Workspace renombrado';
	@override String workspaceRenamedMessage({required Object name}) => 'El nuevo nombre "${name}" solo se enviará a los agentes tras reiniciar el workspace o la aplicación.';
	@override String syncTitle({required Object label}) => 'Sync — ${label}';
	@override String pullTitle({required Object label}) => 'Pull — ${label}';
	@override String pushTitle({required Object label}) => 'Push — ${label}';
	@override String updateFromParentTitle({required Object name}) => 'Actualizar desde el Padre — ${name}';
	@override String mergeToParentTitle({required Object name}) => 'Merge al Padre — ${name}';
	@override String get worktreeMergedAndRemoved => 'Worktree fusionado y eliminado.';
	@override String get nothingWasChanged => 'No se realizaron cambios.';
	@override String get newRealmTitle => 'Nuevo realm';
	@override String get closeWorkspaceTitle => 'Cerrar workspace';
	@override String closeWorkspaceMessage({required Object name}) => '¿Cerrar "${name}"? Los agentes de este workspace se cerrarán. La carpeta en el disco se conserva.';
	@override String get closeAction => 'Cerrar';
	@override String get removeWorktreeTitle => 'Quitar worktree';
	@override String removeWorktreeMessage({required Object name, required Object warn}) => '¿Quitar "${name}"? La carpeta del worktree y la branch se eliminarán y los agentes de este fork se cerrarán.${warn}';
	@override String removeWorktreeWarning({required Object name}) => '\n\nAdvertencia: la branch "${name}" aún no se ha fusionado — eliminarla (git branch -D) descarta el trabajo no fusionado.';
	@override String get failedToRemoveWorktreeTitle => 'No se pudo quitar el worktree';
	@override String get openLayoutTitle => 'Abrir layout';
	@override String get replaceLayoutTitle => '¿Reemplazar el layout actual?';
	@override String replaceLayoutMessage({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: 'Se cerrará 1 pestaña, y tiene un proceso en ejecución.',
		other: 'Se cerrarán ${n} pestañas, incluidas las que tienen procesos en ejecución.',
	);
	@override String get replaceLayoutConfirm => 'Reemplazar';
	@override String get restartServerTooltip => 'Reiniciar servidor';
	@override String get noLspAvailable => 'Ningún LSP disponible';
	@override String get lspRunning => 'en ejecución';
	@override String get lspStopped => 'detenido';
}

// Path: orkest.welcomeView
class _Translations$orkest$welcomeView$es extends Translations$orkest$welcomeView$en {
	_Translations$orkest$welcomeView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bienvenido a Orkest Code';
	@override String get subtitle => 'Abre una carpeta o conéctate a un host remoto para empezar.';
	@override String get createWorkspace => 'Crear workspace';
	@override String get openLocalFolder => 'Abrir carpeta local';
	@override String get connectHost => 'Conectar a un host';
	@override String get configureHost => 'Configurar host';
	@override String get addWorkspace => 'Añadir workspace';
}

// Path: orkest.paneView
class _Translations$orkest$paneView$es extends Translations$orkest$paneView$en {
	_Translations$orkest$paneView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get closePaneTitle => '¿Cerrar panel?';
	@override String closePaneMessage({required Object count}) => 'Esto cierra todas las ${count} pestaña(s) de este panel y finaliza los agentes/terminales en él.';
	@override String get close => 'Cerrar';
	@override String get closeOtherTabs => 'Cerrar las otras';
	@override String get closeTabsToTheRight => 'Cerrar a la derecha';
	@override String get closeAllTabs => 'Cerrar todas';
	@override String get closeTabsTitle => '¿Cerrar pestañas?';
	@override String closeTabsMessage({required Object count}) => 'Esto cierra ${count} pestaña(s) y finaliza los agentes/terminales en ellas.';
	@override String get allTabs => 'Todas las pestañas';
	@override String get pinTab => 'Fijar pestaña';
	@override String get openInNewWindow => 'Abrir en ventana nueva';
	@override String get rename => 'Renombrar';
	@override String get openAsMarkdown => 'Abrir como markdown';
	@override String get openAsBoard => 'Abrir como tablero';
	@override String get resetTitle => 'Restablecer título';
	@override String get copyId => 'Copiar Id';
	@override String get restartTab => 'Reiniciar';
	@override String get newTab => 'Nueva pestaña';
	@override String get newTerminal => 'Nueva terminal…';
	@override String get splitRight => 'Dividir a la derecha';
	@override String get splitDown => 'Dividir abajo';
	@override String get closePane => 'Cerrar panel';
	@override String get dropHereToMove => 'Suelta aquí para mover la pestaña';
	@override String get dockAsTab => 'Acoplar como pestaña';
	@override String get openBrowser => 'Abrir navegador';
	@override String get openTerminal => 'Abrir terminal';
	@override String get openAsLayout => 'Abrir como diseño';
	@override String get openAsYaml => 'Abrir como YAML';
	@override String get openAsPanel => 'Abrir como panel';
	@override String get openAsHtml => 'Abrir como HTML';
}

// Path: orkest.fileTreePanel
class _Translations$orkest$fileTreePanel$es extends Translations$orkest$fileTreePanel$en {
	_Translations$orkest$fileTreePanel$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get viewDiff => 'Ver Diff';
	@override String get commit => 'Commit';
	@override String get stageAndCommit => 'Stage y Commit';
	@override String get unstage => 'Quitar del stage';
	@override String get stageChanges => 'Poner en stage';
	@override String get discardChanges => 'Descartar cambios';
	@override String get enterCommitMessage => 'Escribe un mensaje de commit.';
	@override String get commitUnavailable => 'Commit no disponible para este workspace.';
	@override String get gitErrorTitle => 'Error de Git';
	@override String get deleteNewFileTitle => '¿Eliminar archivo nuevo?';
	@override String get discardChangesTitle => '¿Descartar cambios?';
	@override String deleteNewFileMessage({required Object name}) => '"${name}" es un archivo nuevo y no se puede restaurar. ¿Eliminarlo?';
	@override String discardOneMessage({required Object name}) => '¿Descartar todos los cambios en "${name}"? Los archivos eliminados se restaurarán.';
	@override String get discard => 'Descartar';
	@override String get deleteAllNewFilesTitle => '¿Eliminar todos los archivos nuevos?';
	@override String allNewFilesMessage({required Object count}) => 'Los ${count} archivos son nuevos y se eliminarán. Esto no se puede deshacer.';
	@override String discardTrackedMessage({required Object count, required Object extra}) => '¿Descartar cambios en ${count} archivo(s) rastreado(s)?${extra}';
	@override String discardTrackedExtra({required Object count}) => ' Se mantendrán ${count} archivo(s) nuevo(s).';
	@override String get deleteAll => 'Eliminar todo';
	@override String get deleteQuestionTitle => '¿Eliminar?';
	@override String moveToTrash({required Object name}) => '¿Mover “${name}” a la Papelera?';
	@override String permanentlyDelete({required Object name}) => '¿Eliminar “${name}” de forma permanente? Esto no se puede deshacer.';
	@override String get couldNotDeleteTitle => 'No se pudo eliminar';
	@override String get moveQuestionTitle => '¿Mover?';
	@override String moveMessage({required Object name, required Object dest}) => '¿Mover “${name}” a “${dest}”?';
	@override String get moveAction => 'Mover';
	@override String get couldNotMoveTitle => 'No se pudo mover';
	@override String get couldNotPasteTitle => 'No se pudo pegar';
	@override String get filesTooltip => 'Archivos';
	@override String get searchTooltip => 'Buscar';
	@override String get sourceControlTooltip => 'Control de versiones';
	@override String get databaseTooltip => 'Base de datos';
	@override String get sectionFiles => 'ARCHIVOS';
	@override String get newFile => 'Nuevo archivo';
	@override String get newFolder => 'Nueva carpeta';
	@override String get refreshTooltip => 'Actualizar';
	@override String get collapseAll => 'Contraer todas las carpetas';
	@override String get sectionSourceControl => 'CONTROL DE VERSIONES';
	@override String get viewAsList => 'Ver como lista';
	@override String get viewAsTree => 'Ver como árbol';
	@override String get noFolderMessage => 'Ninguna carpeta — abre un workspace.';
	@override String get amend => 'Amend';
	@override String get commitMessagePlaceholder => 'Mensaje del commit';
	@override String get amendCommit => 'Amend del commit';
	@override String get lastCommit => 'último commit';
	@override String get openInFinder => 'Abrir en Finder';
	@override String get openInExplorer => 'Abrir en el Explorador';
	@override String get openInFileManager => 'Abrir en el gestor de archivos';
	@override String get open => 'Abrir';
	@override String get openWith => 'Abrir con';
	@override String get openInNewWindow => 'Abrir en ventana nueva';
	@override String get openLayout => 'Abrir layout';
	@override String get openAsMarkdown => 'Abrir como markdown';
	@override String get showGitDiff => 'Mostrar diff de git';
	@override String get createTerminal => 'Abrir en terminal';
	@override String get rename => 'Renombrar';
	@override String get copy => 'Copiar';
	@override String get cut => 'Cortar';
	@override String get paste => 'Pegar';
	@override String get copyRelativePath => 'Copiar ruta relativa';
	@override String get copyAbsolutePath => 'Copiar ruta absoluta';
	@override String get renameFailed => 'No se pudo renombrar.';
	@override String get noChanges => 'Sin cambios.';
	@override String stagedChangesHeader({required Object count}) => 'CAMBIOS EN STAGE (${count})';
	@override String changesHeader({required Object count}) => 'CAMBIOS (${count})';
	@override String get discardAllChanges => 'Descartar todos los cambios';
	@override String get unstageAllChanges => 'Quitar todo del stage';
	@override String get stageAllChanges => 'Poner todo en stage';
	@override String get discardFolderChanges => 'Descartar cambios de la carpeta';
	@override String get unstageFolderChanges => 'Quitar carpeta del stage';
	@override String get stageFolderChanges => 'Poner carpeta en stage';
	@override String get generateCommitMessage => 'Generar mensaje de commit';
	@override String generateWith({required Object harness}) => 'Generar con ${harness}';
	@override String get generateUnavailableWhileAmending => 'No disponible mientras se enmienda un commit';
	@override String get cancelGeneration => 'Cancelar generación';
	@override String get changes => 'Cambios';
	@override String get history => 'Historial';
	@override String get historyRepository => 'Repositorio';
	@override String get historyNoRepository => 'No hay ningun repositorio Git disponible.';
	@override String get historyEmpty => 'No se encontraron commits.';
	@override String get historyLoadFailed => 'No se pudo cargar el historial de Git.';
	@override String get historyUntitledCommit => 'Commit sin titulo';
	@override String get historyNow => 'ahora';
	@override String historyMinutesAgo({required Object count}) => 'hace ${count} min';
	@override String historyHoursAgo({required Object count}) => 'hace ${count} h';
	@override String get historyYesterday => 'ayer';
	@override String get historyDayAgo => 'hace 1 dia';
	@override String historyDaysAgo({required Object count}) => 'hace ${count} dias';
	@override String get historyFiles => 'Archivos modificados';
	@override String get historyFilesEmpty => 'No hay archivos modificados.';
	@override String get historyFilesLoadFailed => 'No se pudieron cargar los archivos modificados.';
	@override String get diffEmptyTree => 'Arbol vacio';
	@override String diffOriginal({required Object ref}) => 'Original ${ref}';
	@override String diffModified({required Object ref}) => 'Modificado ${ref}';
	@override String get diffWorkingTree => 'Directorio de trabajo';
	@override String get diffBinaryFile => 'Archivo binario - sin diff de texto.';
	@override String get diffNoChanges => 'Sin cambios.';
	@override String diffError({required Object detail}) => 'No se pudo leer el diff: ${detail}';
	@override String get galleryTooltip => 'Galería';
	@override String get sectionGallery => 'GALERÍA';
	@override String get openAsHtml => 'Abrir como HTML';
	@override String get importQuestionTitle => '¿Copiar aquí?';
	@override String importMessage({required Object count, required Object dest}) => '¿Copiar ${count} elementos en “${dest}”?';
	@override String get importAction => 'Copiar';
	@override String get couldNotImportTitle => 'No se pudo copiar';
	@override String openInAgent({required Object harness}) => 'Abrir en ${harness}';
}

// Path: orkest.fileViewer
class _Translations$orkest$fileViewer$es extends Translations$orkest$fileViewer$en {
	_Translations$orkest$fileViewer$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get cantOpen => 'No se puede abrir este archivo.';
	@override String get couldNotLoadImage => 'No se pudo cargar la imagen.';
	@override String get preview => 'Vista previa';
	@override String get source => 'Código fuente';
	@override String get reload => 'Recargar';
}

// Path: orkest.workspaceSettingsDialog
class _Translations$orkest$workspaceSettingsDialog$es extends Translations$orkest$workspaceSettingsDialog$en {
	_Translations$orkest$workspaceSettingsDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get choosePhotoTitle => 'Elegir foto del workspace';
	@override String get title => 'Configuración del workspace';
	@override String get namePlaceholder => 'Nombre del workspace';
	@override String get addPhoto => 'Añadir foto';
	@override String get changePhoto => 'Cambiar foto';
	@override String get remove => 'Quitar';
	@override String get color => 'Color';
	@override String get host => 'Host';
	@override String get folder => 'Carpeta';
}

// Path: orkest.realmDialogs
class _Translations$orkest$realmDialogs$es extends Translations$orkest$realmDialogs$en {
	_Translations$orkest$realmDialogs$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get namePlaceholder => 'Nombre del realm';
	@override String get duplicateName => 'Ya existe un realm con ese nombre.';
	@override String get newRealmTitle => 'Nuevo realm';
	@override String get renameRealmTitle => 'Renombrar realm';
	@override String get rename => 'Renombrar';
	@override String get deleteRealmTitle => 'Eliminar realm';
	@override String deleteMessage({required Object name, required Object suffix}) => '¿Eliminar "${name}"? Ningún workspace se elimina — solo cambia la lista de carpetas.${suffix}';
	@override String get deleteSuffixOne => ' Su workspace se moverá a Predeterminado.';
	@override String deleteSuffixMany({required Object count}) => ' Sus ${count} workspaces se moverán a Predeterminado.';
	@override String get manageRealmsTitle => 'Gestionar realms';
	@override String workspaceCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 workspace',
		other: '${n} workspaces',
	);
}

// Path: orkest.dbRedisTable
class _Translations$orkest$dbRedisTable$es extends Translations$orkest$dbRedisTable$en {
	_Translations$orkest$dbRedisTable$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get deleteKeyTitle => 'Eliminar clave';
	@override String deleteKeyMessage({required Object key}) => '¿Eliminar "${key}" de esta base de datos Redis?';
	@override String get refresh => 'Actualizar';
	@override String get newKey => 'Nueva clave';
	@override String get columnKey => 'CLAVE';
	@override String get columnValue => 'VALOR';
	@override String get columnType => 'TIPO';
	@override String get columnTtl => 'TTL';
	@override String keyCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 clave',
		other: '${n} claves',
	);
	@override String get noKeys => 'No hay claves en esta base de datos.';
	@override String noKeysMatch({required Object pattern}) => 'Ninguna clave coincide con "${pattern}".';
	@override String get loadMore => 'Cargar más';
	@override String get loadingFullValue => 'Cargando valor completo…';
	@override String get ttlMustBeNumber => 'El TTL debe ser un número de segundos.';
	@override String get addKey => 'Añadir clave';
	@override String get keyFieldHint => 'clave';
	@override String get ttlFieldHint => 'ttl (s, opcional)';
	@override String get valueFieldHint => 'valor';
	@override String get searchHint => 'Buscar — patrón, ej.: user:*';
}

// Path: orkest.dbQueryView
class _Translations$orkest$dbQueryView$es extends Translations$orkest$dbQueryView$en {
	_Translations$orkest$dbQueryView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get saveQueryAs => 'Guardar query como';
	@override String get couldNotSave => 'No se pudo guardar';
	@override String get selectDatabase => 'Seleccionar base de datos';
	@override String get noSqlConnections => 'Sin conexiones SQL';
	@override String get running => 'Ejecutando…';
	@override String get runSelection => 'Ejecutar selección';
	@override String get run => 'Ejecutar';
	@override String get pickDatabaseHint => 'Elige una base de datos arriba y luego Ejecutar (⌘↵).';
	@override String get runQueryHint => 'Ejecuta la query (⌘↵) para ver los resultados aquí.';
	@override String get noRows => 'Sin filas.';
	@override String rowsAffected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 fila afectada',
		other: '${n} filas afectadas',
	);
	@override String rowsFooter({required Object n}) => '${n} filas';
	@override String get truncatedSuffix => ' · truncado (aumenta -- limit)';
	@override String get table => 'Tabla';
	@override String get json => 'JSON';
	@override String get unsaved => 'sin guardar';
	@override String get saved => 'guardado';
	@override String get copied => 'Copiado';
	@override String get copy => 'Copiar';
}

// Path: orkest.httpView
class _Translations$orkest$httpView$es extends Translations$orkest$httpView$en {
	_Translations$orkest$httpView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get saveRequestAs => 'Guardar request como';
	@override String get couldNotSave => 'No se pudo guardar';
	@override String get run => 'Ejecutar';
	@override String get running => 'Ejecutando…';
	@override String get noRequests => 'Ningún request en este archivo — escribe uno, p. ej.: GET https://example.com';
	@override String get selectRequest => 'Seleccionar request';
	@override String requestCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 request',
		other: '${n} requests',
	);
	@override String get runHint => 'Ejecuta el request (⌘↵) para ver la respuesta aquí.';
	@override String get emptyBody => 'Cuerpo de la respuesta vacío.';
	@override String get body => 'JSON';
	@override String get headers => 'Headers';
	@override String get raw => 'Text';
	@override String get truncatedSuffix => ' · truncado (respuesta demasiado grande)';
	@override late final _Translations$orkest$httpView$error$es error = _Translations$orkest$httpView$error$es._(_root);
}

// Path: orkest.kanbanView
class _Translations$orkest$kanbanView$es extends Translations$orkest$kanbanView$en {
	_Translations$orkest$kanbanView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get filter => 'Filtrar';
	@override String get filterTitlePlaceholder => 'Buscar por título';
	@override String get filterLabels => 'Etiquetas';
	@override String get filterClear => 'Limpiar';
	@override String get filterDependencies => 'Dependencias';
	@override String get filterBlocked => 'Bloqueado';
	@override String get filterReady => 'Listo';
	@override String get blockedBy => 'Bloqueado por';
	@override String get addBlocker => 'Agregar tarjeta bloqueante';
	@override String get searchCards => 'Buscar tarjetas';
	@override String get unknownCard => 'desconocida';
	@override String get boardView => 'Tablero';
	@override String get listView => 'Lista';
	@override String get refresh => 'Actualizar desde el disco';
	@override String get manageLabels => 'Etiquetas';
	@override String get labelsTitle => 'Etiquetas de este tablero';
	@override String get labelNamePlaceholder => 'nombre de la etiqueta';
	@override String labelUsage({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 tarjeta',
		other: '${n} tarjetas',
	);
	@override String get deleteLabel => 'Eliminar etiqueta';
	@override String get newCard => 'nueva tarjeta';
	@override String get newCardTitle => 'Nueva tarjeta';
	@override String get newColumn => 'Nueva columna';
	@override String get columnNameTitle => 'Nombre de la columna';
	@override String get dragColumn => 'Arrastrar columna';
	@override String get columnOptions => 'Opciones de la columna';
	@override String get renameColumn => 'Renombrar columna';
	@override String get moveColumnLeft => 'Mover a la izquierda';
	@override String get moveColumnRight => 'Mover a la derecha';
	@override String get deleteColumn => 'Eliminar columna';
	@override String get newCardHere => 'Nueva tarjeta aquí';
	@override String get duplicateCard => 'Duplicar';
	@override String get cardLabels => 'Etiquetas';
	@override String get deleteCard => 'Eliminar tarjeta';
	@override String get advance => 'Pasar a la siguiente columna';
	@override String get advanceHold => 'Mover a la siguiente columna (mantener: mover a la última)';
	@override String get advanceBack => 'Volver una columna';
	@override String get emptyColumn => 'Sin tarjetas';
	@override String cardCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 tarjeta',
		other: '${n} tarjetas',
	);
	@override String get notes => 'Nota';
	@override String get notesPlaceholder => 'Escribe una nota';
	@override String get comments => 'Comentarios';
	@override String get addComment => 'Añadir comentario';
	@override String get commentPlaceholder => 'Escribe un comentario';
	@override String get noComments => 'Aún no hay comentarios';
	@override String get closeDetail => 'Cerrar';
	@override String get notABoard => 'Este archivo aún no tiene columnas ## — se abre como markdown.';
	@override String get startBoard => 'Empezar un tablero';
	@override String get couldNotSave => 'No se pudo guardar el tablero';
	@override String get unrecognizedBlock => 'No reconocido por el analizador — se arrastra entero, sin edición en línea.';
	@override late final _Translations$orkest$kanbanView$deleteColumnDialog$es deleteColumnDialog = _Translations$orkest$kanbanView$deleteColumnDialog$es._(_root);
}

// Path: orkest.dbPanel
class _Translations$orkest$dbPanel$es extends Translations$orkest$dbPanel$en {
	_Translations$orkest$dbPanel$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionDatabase => 'BASE DE DATOS';
	@override String get edit => 'Editar…';
	@override String get copyName => 'Copiar nombre';
	@override String get newQuery => 'Nueva query';
	@override String get browseKeys => 'Ver claves';
	@override String get deleteConnectionTitle => 'Eliminar conexión';
	@override String deleteConnectionMessage({required Object name}) => '¿Quitar "${name}" de este workspace? Cualquier contraseña guardada se descartará. Los archivos .dbq que la referencian no se modifican.';
	@override String footer({required Object n}) => '.orkest/databases.json · ${n} conexiones';
	@override String get footerOne => '.orkest/databases.json · 1 conexión';
	@override String get noConnections => 'Aún no hay conexiones.';
	@override String get passwordRequired => 'Contraseña no encontrada en el host. Abre esta conexión y vuelve a escribirla — se guarda en la máquina que ejecuta la base de datos, no en esta.';
}

// Path: orkest.dbMongoView
class _Translations$orkest$dbMongoView$es extends Translations$orkest$dbMongoView$en {
	_Translations$orkest$dbMongoView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get deleteDocumentTitle => 'Eliminar documento';
	@override String deleteDocumentMessage({required Object id, required Object collection}) => '¿Eliminar el documento con _id ${id} de "${collection}"?';
	@override String get filterHint => 'Filtro — JSON, ej.: {"status": "active"}';
	@override String docCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 doc',
		other: '${n} docs',
	);
	@override String get refresh => 'Actualizar';
	@override String get insertDocument => 'Insertar documento';
	@override String get noDocuments => 'No hay documentos en esta colección.';
	@override String get noDocumentsMatch => 'Ningún documento coincide con este filtro.';
	@override String get loadMore => 'Cargar más';
	@override String get edit => 'Editar';
	@override String get insert => 'Insertar';
}

// Path: orkest.dbConnectionDialog
class _Translations$orkest$dbConnectionDialog$es extends Translations$orkest$dbConnectionDialog$en {
	_Translations$orkest$dbConnectionDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get chooseFileTitle => 'Elegir base de datos SQLite';
	@override String get file => 'Archivo';
	@override String get chooseFilePlaceholder => 'Elige un archivo SQLite…';
	@override String get name => 'Nombre';
	@override String get password => 'Contraseña';
	@override String get savePassword => 'Guardar contraseña';
	@override String get allowWrites => 'Permitir escritura (agentes)';
	@override String get allowWritesHint => 'desactivado = los agentes solo leen vía CLI';
	@override String get visibleToAgents => 'Visible para agentes';
	@override String get visibleToAgentsHint => 'desactivado = oculto en la CLI, solo en la GUI';
	@override String get testing => 'Probando conexión…';
	@override String get connectionOk => 'Conexión OK';
	@override String get connectionFailed => 'Fallo en la conexión';
	@override String get editTitle => 'Editar conexión';
	@override String get newTitle => 'Nueva conexión';
	@override String get connectionString => 'Connection string';
	@override String get invalidUrl => 'URL de conexión no válida.';
	@override String get sshTunnel => 'Túnel SSH';
	@override String get sshHost => 'Host SSH';
	@override String get sshPort => 'Puerto SSH';
	@override String get sshUser => 'Usuario SSH';
	@override String get privateKey => 'Clave privada';
	@override String get choosePrivateKeyPlaceholder => 'Elige una clave privada…';
	@override String get choosePrivateKeyDialogTitle => 'Elegir clave privada SSH';
	@override String get keyPassphrase => 'Frase de contraseña de la clave';
	@override String get savePassphrase => 'Guardar frase de contraseña';
	@override String get passwordOnHost => 'La contraseña se guarda en el host, no en esta máquina.';
}

// Path: orkest.sshPrompts
class _Translations$orkest$sshPrompts$es extends Translations$orkest$sshPrompts$en {
	_Translations$orkest$sshPrompts$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get unknownSshHostTitle => 'Host SSH desconocido';
	@override String neverConnected({required Object endpoint}) => 'Orkest Code nunca se ha conectado a ${endpoint} antes.';
	@override String get trustHint => 'Confía solo si esta fingerprint coincide con el servidor. Puedes verificarla en el servidor con:';
	@override String get trust => 'Confiar';
	@override String get sshKeyPassphraseTitle => 'Frase de contraseña de la clave SSH';
	@override String unlockMessage({required Object keyPath, required Object connectionName}) => 'Desbloquea ${keyPath} para conectar "${connectionName}".';
	@override String get keptInMemoryHint => 'Se mantiene en memoria hasta que Orkest Code se cierre. Para que los agentes usen esta conexión, activa "Guardar frase de contraseña" en la conexión.';
	@override String get unlock => 'Desbloquear';
}

// Path: orkest.projectsRail
class _Translations$orkest$projectsRail$es extends Translations$orkest$projectsRail$en {
	_Translations$orkest$projectsRail$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get workspaces => 'Workspaces';
	@override String get keepAwakeOn => 'Manteniendo este equipo despierto para acceso remoto. Haz clic para dejarlo dormir de nuevo.';
	@override String get keepAwakeOff => 'Mantener este equipo despierto para acceso remoto. Se apaga solo cuando Orkest Code se reinicia.';
	@override String get keepAwakeBattery => 'Despierto con batería. Esto consume la batería.';
	@override String get keepAwakeLid => 'Cerrar la tapa del portátil sigue poniéndolo a dormir.';
	@override String get newWorkspace => 'Nuevo workspace';
	@override String get settings => 'Configuración';
	@override String get mergeToParent => 'Fusionar en el padre';
	@override String get updateFromParent => 'Actualizar desde el padre';
	@override String get forkWorktree => 'Crear worktree derivada';
	@override String get copyBranch => 'Copiar branch';
	@override String get remove => 'Quitar';
	@override String get moveToRealm => 'Mover a realm';
	@override String get copyWorkspaceId => 'Copiar id del workspace';
	@override String get rename => 'Renombrar';
	@override String get close => 'Cerrar';
	@override String get newRealm => 'Nuevo realm…';
	@override String get manageRealms => 'Gestionar realms…';
	@override String get noWorkspaces => 'Aún no hay workspaces.';
	@override String get sync => 'Sincronizar';
	@override String get pull => 'Pull';
	@override String get push => 'Push';
	@override String get createWorktree => 'Crear worktree';
	@override String worktreeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n,
		one: '1 worktree',
		other: '${n} worktrees',
	);
	@override String get expandWorktrees => 'Expandir worktrees';
	@override String get collapseWorktrees => 'Contraer worktrees';
}

// Path: orkest.findBar
class _Translations$orkest$findBar$es extends Translations$orkest$findBar$en {
	_Translations$orkest$findBar$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get find => 'Buscar';
	@override String get matchCase => 'Coincidir mayúsculas';
	@override String get wholeWord => 'Palabra completa';
	@override String get useRegex => 'Usar expresión regular';
	@override String get previous => 'Anterior (⇧⏎)';
	@override String get next => 'Siguiente (⏎)';
	@override String get close => 'Cerrar (Esc)';
	@override String get badPattern => 'Patrón inválido';
	@override String counter({required Object current, required Object total}) => '${current} de ${total}';
	@override String get noResults => 'Sin resultados';
}

// Path: orkest.contentSearch
class _Translations$orkest$contentSearch$es extends Translations$orkest$contentSearch$en {
	_Translations$orkest$contentSearch$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionSearch => 'BÚSQUEDA';
	@override String get searchInFiles => 'Buscar en los archivos';
	@override String get matchCase => 'Coincidir mayúsculas';
	@override String get wholeWord => 'Palabra completa';
	@override String get useRegex => 'Usar expresión regular';
	@override String get invalidRegex => 'Expresión regular inválida.';
	@override String get typeToSearch => 'Escribe para buscar en todos los archivos.';
	@override String get searching => 'Buscando…';
	@override String get noResults => 'Sin resultados.';
}

// Path: orkest.topbar
class _Translations$orkest$topbar$es extends Translations$orkest$topbar$en {
	_Translations$orkest$topbar$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get collapseSidebar => 'Contraer barra lateral';
	@override String get toggleFiles => 'Mostrar/ocultar archivos';
	@override String get filesUnavailable => 'Archivos no disponibles en Orkest Code';
	@override String get hideKeyboard => 'Ocultar teclado';
	@override String get showOffice => 'Mostrar oficina';
	@override String get showTerminals => 'Mostrar terminales';
}

// Path: orkest.tasks
class _Translations$orkest$tasks$es extends Translations$orkest$tasks$en {
	_Translations$orkest$tasks$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get hotReload => 'Hot reload';
	@override String get hotRestart => 'Hot restart';
	@override String get toggleDebugPaint => 'Alternar debug paint';
	@override String get togglePlatform => 'Alternar plataforma';
	@override String get quit => 'Salir';
}

// Path: orkest.notifications
class _Translations$orkest$notifications$es extends Translations$orkest$notifications$en {
	_Translations$orkest$notifications$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get agentFinished => 'El agente terminó';
	@override String get open => 'Abrir';
	@override String get agentNeedsAction => 'El agente necesita tu acción';
}

// Path: orkest.terminalLink
class _Translations$orkest$terminalLink$es extends Translations$orkest$terminalLink$en {
	_Translations$orkest$terminalLink$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get open => 'Abrir';
	@override String get revealFinder => 'Mostrar en Finder';
	@override String get revealExplorer => 'Mostrar en el Explorador';
	@override String get revealFolder => 'Abrir carpeta contenedora';
	@override String get copyPath => 'Copiar ruta';
	@override String get openLink => 'Abrir enlace';
	@override String get copyLink => 'Copiar enlace';
}

// Path: orkest.terminal
class _Translations$orkest$terminal$es extends Translations$orkest$terminal$en {
	_Translations$orkest$terminal$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String cwdFallbackWarning({required Object requested, required Object path}) => 'Aviso: la carpeta "${requested}" no existe. Esta terminal se abrió en "${path}".';
	@override String workspaceEnvTracked({required Object keys}) => 'Aviso: el .env.orkest está rastreado por git (vino con el repositorio). Inyectado: ${keys}';
}

// Path: orkest.remoteHost
class _Translations$orkest$remoteHost$es extends Translations$orkest$remoteHost$en {
	_Translations$orkest$remoteHost$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get addHost => 'Añadir host remoto';
	@override String get hostName => 'Nombre';
	@override String get sshTarget => 'Destino SSH (usuario@host)';
	@override String connecting({required Object host}) => 'Conectando a ${host}…';
	@override String get openingTunnel => 'Túnel SSH';
	@override String get installingServer => 'Instalando servidor';
	@override String handshake({required Object version}) => 'Servidor ${version}';
	@override String get loadingWorkspace => 'Cargando workspace…';
	@override String reconnecting({required Object host}) => 'Reconectando a ${host}…';
	@override String offline({required Object host}) => '${host} sin conexión';
	@override String get remove => 'Quitar';
	@override String get reconnect => 'Reconectar';
	@override String get installServer => 'Instalar servidor';
	@override String errSshUnreachable({required Object host}) => 'No se puede llegar a ${host} por SSH. ¿Está encendido y con Inicio de sesión remoto activado?';
	@override String errInstallFailed({required Object host}) => 'No se pudo instalar el servidor en ${host}.';
	@override String get errVersionMismatch => 'Versión del servidor incompatible; actualízalo.';
	@override String errDetail({required Object detail}) => 'Detalles: ${detail}';
	@override String pickFolderTitle({required Object host}) => 'Abrir carpeta en ${host}';
	@override String get openHere => 'Abrir aquí';
	@override String get emptyFolder => 'Sin subcarpetas';
	@override String get newLocal => 'Local';
	@override String get newRemote => 'Remoto';
	@override String get chooseHost => 'Elegir un host';
	@override String get newHostEntry => 'Nuevo host…';
	@override String get editHost => 'Editar host';
	@override String get userLabel => 'Usuario';
	@override String get hostLabel => 'Host / IP';
	@override String get portLabel => 'Puerto';
	@override String get authLabel => 'Autenticación';
	@override String get authKey => 'Clave SSH';
	@override String get authPassword => 'Contraseña';
	@override String get passwordLabel => 'Contraseña';
	@override String get passwordKeep => 'Deja en blanco para mantener la actual';
	@override String get errUser => 'Usuario obligatorio';
	@override String get errHost => 'Host obligatorio';
	@override String get errPassword => 'Contraseña obligatoria';
	@override String get identityChoose => 'Elegir…';
	@override String get identityEmpty => 'Ninguna clave seleccionada';
	@override String get identityDialogTitle => 'Selecciona la clave privada SSH';
	@override String get errIdentity => 'Elige la clave privada para autenticarte.';
	@override String errHostKeyUnknown({required Object host}) => 'Orkest Code todavía no confía en ${host}. Conecta de nuevo y confirma la huella.';
	@override String errHostKeyChanged({required Object host}) => '${host} presenta una clave SSH distinta de la guardada. Si no reinstalaste esa máquina, detente y compruébalo; si la reinstalaste, elimina la entrada antigua de ~/.ssh/known_hosts.';
	@override String errHostBundleMissing({required Object host}) => '${host} es Windows pero no tiene Orkest Code instalado. El servidor remoto se instala desde el bundle de Orkest Code que ya está en esa máquina — instálalo allí e inténtalo de nuevo.';
	@override String errHostUnknownOs({required Object host}) => 'No se pudo identificar el sistema de ${host}. La cuenta puede tener un shell restringido, o ninguno.';
	@override String get errIdentityPublic => 'Solo está la clave pública. Eso funciona solo si la privada está en tu agente SSH; si no, elige la privada (mismo nombre, sin .pub).';
	@override String get errIdentityNotKey => 'Ese archivo no parece una clave privada.';
	@override String get errIdentityMissingFile => 'Ese archivo ya no existe.';
	@override String get errIdentityUnreadable => 'No se pudo leer ese archivo.';
}

// Path: orkest.browserPane
class _Translations$orkest$browserPane$es extends Translations$orkest$browserPane$en {
	_Translations$orkest$browserPane$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get back => 'Atrás';
	@override String get forward => 'Adelante';
	@override String get reload => 'Recargar';
	@override String get urlHint => 'Escribe la URL o dirección';
	@override String get go => 'Ir';
}

// Path: orkest.documentWindow
class _Translations$orkest$documentWindow$es extends Translations$orkest$documentWindow$en {
	_Translations$orkest$documentWindow$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mediaNotSupported => 'Audio y video se abren en la ventana principal de Orkest Code.';
	@override String fileNotFound({required Object path}) => 'Archivo no encontrado: ${path}';
}

// Path: orkest.gallery
class _Translations$orkest$gallery$es extends Translations$orkest$gallery$en {
	_Translations$orkest$gallery$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get intro => 'Documentos especiales de Orkest Code para que veas lo que el agente de IA está haciendo.';
	@override String get createErrorTitle => 'No se pudo crear el archivo';
	@override late final _Translations$orkest$gallery$dbQuery$es dbQuery = _Translations$orkest$gallery$dbQuery$es._(_root);
	@override late final _Translations$orkest$gallery$kanban$es kanban = _Translations$orkest$gallery$kanban$es._(_root);
	@override late final _Translations$orkest$gallery$layout$es layout = _Translations$orkest$gallery$layout$es._(_root);
	@override late final _Translations$orkest$gallery$httpRequest$es httpRequest = _Translations$orkest$gallery$httpRequest$es._(_root);
	@override late final _Translations$orkest$gallery$html$es html = _Translations$orkest$gallery$html$es._(_root);
	@override late final _Translations$orkest$gallery$tasks$es tasks = _Translations$orkest$gallery$tasks$es._(_root);
	@override late final _Translations$orkest$gallery$notebook$es notebook = _Translations$orkest$gallery$notebook$es._(_root);
	@override late final _Translations$orkest$gallery$workspaceEnv$es workspaceEnv = _Translations$orkest$gallery$workspaceEnv$es._(_root);
	@override late final _Translations$orkest$gallery$panel$es panel = _Translations$orkest$gallery$panel$es._(_root);
}

// Path: orkest.notebook
class _Translations$orkest$notebook$es extends Translations$orkest$notebook$en {
	_Translations$orkest$notebook$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get notes => 'Notas';
	@override String get newNote => 'Nueva nota';
	@override String get searchPlaceholder => 'Buscar notas';
	@override String get empty => 'Aún no hay notas. Crea una, o pídele al agente que escriba aquí.';
	@override String get noMatch => 'Ninguna nota coincide.';
	@override String get selectNote => 'Selecciona una nota';
	@override String get reload => 'Recargar del disco';
	@override String get untagged => 'sin tag';
	@override String get saveFailed => 'No se pudo guardar la nota';
	@override String get createFailed => 'No se pudo crear la nota';
	@override String get addTag => 'añadir tag';
	@override String get untitled => 'Sin título';
	@override String get deleteNote => 'Eliminar nota';
	@override String deleteConfirm({required Object name}) => '¿Mover “${name}” a la papelera?';
	@override String get imageFailed => 'No se pudo guardar la imagen';
	@override late final _Translations$orkest$notebook$format$es format = _Translations$orkest$notebook$format$es._(_root);
	@override String get backlinks => 'Enlazada desde';
	@override String get renameTag => 'Renombrar tag';
	@override String get deleteTag => 'Eliminar tag';
	@override String deleteTagConfirm({required Object name, required Object count}) => '¿Quitar “${name}” de ${count} notas? Las notas se conservan.';
	@override String get showList => 'Mostrar lista de notas';
	@override String get hideList => 'Ocultar lista de notas';
}

// Path: orkest.layoutPreview
class _Translations$orkest$layoutPreview$es extends Translations$orkest$layoutPreview$en {
	_Translations$orkest$layoutPreview$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get applyFailedTitle => 'No se pudo aplicar el diseño';
	@override String get applyInOrkest => 'Aplicar en Orkest Code';
	@override String get applyNewWorkspace => 'Abrir como nuevo espacio de trabajo';
	@override String applyTo({required Object workspace}) => 'Aplicar en ${workspace}';
	@override String get autorunWorktree => 'autorun: worktree. Este diseño también se aplica solo al crear un worktree del espacio de trabajo que lo contiene.';
	@override String get command => 'Comando';
	@override String get folder => 'Carpeta';
	@override String get noCommand => 'sin comando, abre un shell';
	@override String get replaceConfirm => 'Reemplazar diseño';
	@override String replaceMessage({required Object n}) => 'Se cerrarán ${n} pestañas abiertas de este espacio de trabajo, incluidas las que tienen trabajo en curso.';
	@override String replaceTitle({required Object workspace}) => '¿Reemplazar el diseño de ${workspace}?';
	@override String get skippedTitle => 'No se crean en este sistema';
	@override String get splitDown => 'divide abajo';
	@override String get splitRight => 'divide a la derecha';
	@override String get splitTab => 'pestaña';
	@override String subtitle({required Object n}) => 'Este diseño abre ${n} terminales. Lee los comandos antes de aplicarlo.';
}

// Path: orkest.telemetry
class _Translations$orkest$telemetry$es extends Translations$orkest$telemetry$en {
	_Translations$orkest$telemetry$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Telemetría';
	@override String get title => 'Telemetría';
	@override String liveRuns({required Object n}) => '${n} activos';
	@override String get noWorkspace => 'Abre un workspace para ver su telemetría.';
	@override String get empty => 'Nada por aquí todavía.';
	@override String get emptyFiltered => 'Nada por aquí todavía.';
	@override String get searchHint => 'Filtrar casos';
	@override String get chipOpen => 'Abiertos';
	@override String get chipNew => 'Nuevos';
	@override String get chipResolved => 'Resueltos';
	@override String get chipIgnored => 'Ignorados';
	@override String get chipWarnings => 'Avisos';
	@override String get tagNew => 'nuevo';
	@override String get tagRegression => 'regresión';
	@override String get tagResolved => 'resuelto';
	@override String get tagIgnored => 'ignorado';
	@override String get srcTask => 'task';
	@override String get srcWrapper => 'orkest telemetry';
	@override String run({required Object id}) => 'run ${id}';
	@override String get resolve => 'Marcar resuelto';
	@override String get ignore => 'Ignorar (también se oculta a los agentes)';
	@override String get reopen => 'Reabrir';
	@override String get clear => 'Limpiar ocurrencias';
	@override String get clearRun => 'Limpiar este run';
	@override String get clearProject => 'Limpiar proyecto';
	@override String openFile({required Object location}) => 'Abrir ${location}';
	@override String get showInTerminal => 'Ver en la terminal';
	@override String get copyCommand => 'Copiar comando de la CLI';
	@override String get copied => 'Copiado';
	@override String get statusOpen => 'Abierto';
	@override String get statusResolved => 'Resuelto';
	@override String get statusIgnored => 'Ignorado';
	@override String get occurrences => 'Ocurrencias';
	@override String inRuns({required Object n}) => 'en ${n} runs';
	@override String get first => 'Primera';
	@override String get last => 'Última';
	@override String get origin => 'Origen';
	@override String get sectionStack => 'Stack';
	@override String get stackHint => 'frames del proyecto destacados · clic abre el archivo';
	@override String get sectionCorrelated => 'Log correlacionado';
	@override String get correlatedHint => 'el JSON más cercano antes del error, en el mismo run';
	@override String get none => 'ninguno';
	@override String get sectionRuns => 'Ocurrencias por run';
	@override String get runsHint => 'misma clave (cwd, comando): así se calculan nuevo y regresión';
	@override String get sectionContext => 'Contexto crudo';
	@override String get contextHint => 'líneas de la terminal alrededor de la última ocurrencia';
	@override String get current => 'actual';
	@override String fingerprintHint({required Object location}) => 'fingerprint = tipo + mensaje normalizado + ${location}';
	@override String get blameUncommitted => 'cambiado en el working tree';
	@override String blameCommit({required Object ago, required Object sha}) => 'cambiado ${ago} (${sha})';
	@override String get justNow => 'ahora';
	@override String minutesAgo({required Object n}) => 'hace ${n} min';
	@override String hoursAgo({required Object n}) => 'hace ${n} h';
	@override String daysAgo({required Object n}) => 'hace ${n} d';
	@override String get resolvedToast => 'Resuelto. Si vuelve en un run futuro, reaparece como regresión.';
	@override String get ignoredToast => 'Ignorado. Los agentes ya no lo ven (salvo --include-ignored).';
	@override String get clearedToast => 'Ocurrencias borradas. Las reglas de triaje se mantienen.';
	@override String get byHuman => 'por ti';
	@override String get byAgent => 'por el agente';
	@override String caseTabTitle({required Object type, required Object file}) => '${type} · ${file}';
	@override String get srcApp => 'App';
	@override String get chipApp => 'Orkest Code';
}

// Path: orkest.panelView
class _Translations$orkest$panelView$es extends Translations$orkest$panelView$en {
	_Translations$orkest$panelView$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get unavailable => 'Los paneles necesitan la web view integrada, que todavía no existe en Linux.';
	@override String get openInBrowser => 'Abrir en el navegador';
	@override String get openAsHtml => 'Abrir como HTML';
}

// Path: settings.language
class _Translations$settings$language$es extends Translations$settings$language$en {
	_Translations$settings$language$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Idioma';
	@override String get system => 'Sistema';
	@override String get english => 'Inglés';
	@override String get portugueseBr => 'Portugués (BR)';
	@override String get spanish => 'Español';
}

// Path: settings.page
class _Translations$settings$page$es extends Translations$settings$page$en {
	_Translations$settings$page$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$settings$page$header$es header = _Translations$settings$page$header$es._(_root);
	@override late final _Translations$settings$page$nav$es nav = _Translations$settings$page$nav$es._(_root);
	@override late final _Translations$settings$page$general$es general = _Translations$settings$page$general$es._(_root);
	@override late final _Translations$settings$page$diagnostics$es diagnostics = _Translations$settings$page$diagnostics$es._(_root);
	@override late final _Translations$settings$page$storage$es storage = _Translations$settings$page$storage$es._(_root);
	@override late final _Translations$settings$page$terminal$es terminal = _Translations$settings$page$terminal$es._(_root);
	@override late final _Translations$settings$page$appearance$es appearance = _Translations$settings$page$appearance$es._(_root);
	@override late final _Translations$settings$page$notifications$es notifications = _Translations$settings$page$notifications$es._(_root);
	@override late final _Translations$settings$page$shortcuts$es shortcuts = _Translations$settings$page$shortcuts$es._(_root);
	@override late final _Translations$settings$page$languages$es languages = _Translations$settings$page$languages$es._(_root);
	@override late final _Translations$settings$page$automations$es automations = _Translations$settings$page$automations$es._(_root);
}

// Path: settings.remoteHosts
class _Translations$settings$remoteHosts$es extends Translations$settings$remoteHosts$en {
	_Translations$settings$remoteHosts$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Hosts remotos';
	@override String get description => 'Máquinas a las que accedes por SSH. Añadir un host aquí es lo mismo que hacerlo desde el menú "+" del workspace.';
	@override String get empty => 'Aún no hay hosts remotos.';
	@override String get add => 'Añadir host';
	@override String get edit => 'Editar';
	@override String get reconnect => 'Reconectar';
	@override String get remove => 'Eliminar';
	@override String get removeTitle => 'Eliminar host';
	@override String removeMessage({required Object name}) => '¿Eliminar "${name}" y todos sus workspaces? No se borra nada en el host.';
	@override String workspacesCount({required Object count}) => '${count} workspace(s)';
	@override String get deviceKeyTitle => 'Clave de este dispositivo';
	@override String get deviceKeyDesc => 'Añade esta clave pública a ~/.ssh/authorized_keys del host para que este dispositivo pueda conectarse.';
	@override String get deviceKeyCopy => 'Copiar clave pública';
	@override String get deviceKeyCopied => 'Clave pública copiada';
	@override String get statusConnected => 'Conectado';
	@override String get statusConnecting => 'Conectando…';
	@override String get statusReconnecting => 'Reconectando…';
	@override String get statusOffline => 'Sin conexión';
	@override String get statusIdle => 'No conectado';
	@override String get helpTitle => 'Cómo funciona';
	@override String get helpBody => 'Orkest Code se conecta a tu máquina por SSH y habla con un pequeño servidor que ejecuta las terminales, archivos y git allí. El host debe tener Orkest Code (escritorio) o el orkest-server instalado y en ejecución, y la clave pública de este dispositivo añadida en su ~/.ssh/authorized_keys.';
}

// Path: automation.error
class _Translations$automation$error$es extends Translations$automation$error$en {
	_Translations$automation$error$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String unavailable({required Object harness}) => '${harness} no está instalado o no está en el PATH.';
	@override String modelUnavailable({required Object model, required Object harness}) => 'El modelo "${model}" no está disponible para ${harness}. Elige otro modelo en Configuración.';
	@override String authentication({required Object harness, required Object detail}) => '${harness}: ${detail}';
	@override String timeout({required Object harness, required Object seconds}) => '${harness} no respondió en ${seconds} segundos.';
	@override String get cancelled => 'Se canceló la generación del mensaje de commit.';
	@override String process({required Object harness, required Object detail}) => '${harness}: ${detail}';
	@override String processNoDetail({required Object harness}) => '${harness} no pudo generar un mensaje de commit.';
	@override String get invalidResponse => 'La automatización devolvió un mensaje de commit vacío.';
	@override String get busy => 'Ya se está generando otro mensaje de commit.';
	@override String get unknown => 'La automatización no pudo generar un mensaje de commit.';
	@override String get noWorkspace => 'Ningún workspace seleccionado.';
	@override String get fileOutsideWorkspace => 'El archivo está fuera de las raíces del workspace.';
	@override String fileUnreadable({required Object detail}) => 'No se pudo leer el archivo: ${detail}';
	@override String get binaryFile => 'No se puede generar un mensaje de commit para un archivo binario.';
	@override String get noFileChanges => 'No hay cambios que describir en este archivo.';
	@override String get noStagedChanges => 'No hay cambios en stage que describir.';
	@override String get multipleRepositories => 'Los cambios en stage pertenecen a varios repositorios. Genéralos por separado.';
	@override String get diffUnavailable => 'No se pudo leer el diff.';
	@override String get notConfigured => 'Configura un harness de mensajes de commit en Configuración.';
}

// Path: fileOperation.error
class _Translations$fileOperation$error$es extends Translations$fileOperation$error$en {
	_Translations$fileOperation$error$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String alreadyExists({required Object name}) => 'Ya existe: “${name}”.';
	@override String notFound({required Object name}) => 'No se encontró: “${name}”.';
	@override String get invalidPath => 'Ruta inválida.';
	@override String get emptyName => 'El nombre no puede estar vacío.';
	@override String get noWorkspace => 'Ningún workspace seleccionado.';
	@override String get cannotMoveIntoItself => 'No se puede mover una carpeta dentro de sí misma.';
	@override String get clipboardEmpty => 'El portapapeles está vacío.';
	@override String get notScratchTab => 'Esta pestaña no es un archivo temporal.';
	@override String get writeFailed => 'No se pudo escribir el archivo.';
	@override String get formatterEmptyCommand => 'Comando de formato vacío.';
	@override String get formatterMissingPlaceholder => 'El comando de formato debe incluir el marcador %FILE%.';
	@override String get formatterTimeout => 'El formateador agotó el tiempo de espera.';
	@override String formatterExitCode({required Object code}) => 'El formateador terminó con el código ${code}.';
	@override String get formatterFailed => 'No se pudo ejecutar el formateador.';
	@override String osFailure({required Object detail}) => '${detail}';
	@override String get nameHasSlash => 'El nombre no puede contener “/”.';
	@override String get invalidName => 'Nombre inválido.';
	@override String get remoteDropUnsupported => 'Soltar archivos en un workspace remoto todavía no está soportado.';
}

// Path: theme.error
class _Translations$theme$error$es extends Translations$theme$error$en {
	_Translations$theme$error$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get io => 'No se pudo leer o escribir el archivo del tema.';
	@override String ioDetail({required Object detail}) => 'No se pudo leer o escribir el archivo del tema: ${detail}';
	@override String malformedJson({required Object detail}) => 'Este archivo no es JSON válido: ${detail}';
	@override String get invalidTheme => 'Este archivo no es un tema válido.';
	@override String get reservedId => 'Este tema usa el id de un tema nativo. Cambia el "id" en el archivo e impórtalo de nuevo.';
	@override String notAnObject({required Object field}) => 'Se esperaba un objeto en "${field}".';
	@override String missingField({required Object field}) => 'Falta el campo obligatorio "${field}".';
	@override String badColor({required Object value, required Object field}) => '"${value}" en "${field}" no es un color. Usa #RGB, #RRGGBB o #RRGGBBAA.';
	@override String unknownBase({required Object value}) => 'Tema base "${value}" desconocido en "extends".';
	@override String get noVariants => 'El tema no declara ningún variant. Añade "dark", "light" o ambos en "variants".';
}

// Path: orkest.httpView.error
class _Translations$orkest$httpView$error$es extends Translations$orkest$httpView$error$en {
	_Translations$orkest$httpView$error$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Falló el request';
	@override String get noRequest => 'No se encontró ningún request en la posición del cursor.';
	@override String invalidUrl({required Object url}) => 'URL inválida: ${url}';
	@override String unresolvedVariable({required Object name}) => 'La variable {{${name}}} no tiene valor. Declárala con @${name} = … en este archivo.';
	@override String bodyFileMissing({required Object path}) => 'Archivo de cuerpo no encontrado: ${path}';
	@override String bodyFileUnreadable({required Object path, required Object detail}) => 'No se pudo leer el archivo de cuerpo ${path}: ${detail}';
	@override String connectionFailed({required Object detail}) => 'No se pudo alcanzar el servidor: ${detail}';
	@override String get connectionFailedNoDetail => 'No se pudo alcanzar el servidor.';
	@override String timeout({required Object seconds}) => 'El request superó el tiempo límite de ${seconds}s.';
	@override String responseTooLarge({required Object bytes}) => 'La respuesta superó el límite de ${bytes} bytes.';
}

// Path: orkest.kanbanView.deleteColumnDialog
class _Translations$orkest$kanbanView$deleteColumnDialog$es extends Translations$orkest$kanbanView$deleteColumnDialog$en {
	_Translations$orkest$kanbanView$deleteColumnDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object name}) => '¿Eliminar «${name}»?';
	@override String message({required Object count}) => 'Esta columna tiene ${count}. Elige qué pasa con ellas.';
	@override String get moveCards => 'Mover a la columna anterior';
	@override String get deleteAll => 'Eliminar junto con la columna';
	@override String get emptyMessage => 'Esta columna está vacía.';
}

// Path: orkest.gallery.dbQuery
class _Translations$orkest$gallery$dbQuery$es extends Translations$orkest$gallery$dbQuery$en {
	_Translations$orkest$gallery$dbQuery$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consulta de base de datos';
	@override String get description => 'Editor SQL con grilla de resultados, usando una de las conexiones registradas.';
}

// Path: orkest.gallery.kanban
class _Translations$orkest$gallery$kanban$es extends Translations$orkest$gallery$kanban$en {
	_Translations$orkest$gallery$kanban$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tablero kanban';
	@override String get description => 'Columnas y tarjetas guardadas como markdown puro. Arrastra, edita y comenta.';
}

// Path: orkest.gallery.layout
class _Translations$orkest$gallery$layout$es extends Translations$orkest$gallery$layout$en {
	_Translations$orkest$gallery$layout$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layout de paneles';
	@override String get description => 'Terminales y splits para abrir de una vez, estilo tmuxinator. Puede ejecutarse solo en worktrees nuevos.';
}

// Path: orkest.gallery.httpRequest
class _Translations$orkest$gallery$httpRequest$es extends Translations$orkest$gallery$httpRequest$en {
	_Translations$orkest$gallery$httpRequest$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Requests HTTP';
	@override String get description => 'Escribe requests en un archivo y ejecútalos con la respuesta al lado.';
}

// Path: orkest.gallery.html
class _Translations$orkest$gallery$html$es extends Translations$orkest$gallery$html$en {
	_Translations$orkest$gallery$html$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vista HTML';
	@override String get description => 'Una página que el agente escribe y Orkest Code renderiza directo: mapa mental, diagrama, gráfico, lo que necesites.';
}

// Path: orkest.gallery.tasks
class _Translations$orkest$gallery$tasks$es extends Translations$orkest$gallery$tasks$en {
	_Translations$orkest$gallery$tasks$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tareas';
	@override String get description => 'Comandos para ejecutar desde el panel de Tasks, como dev server, tests y build. Vive en .orkest/tasks.json.';
}

// Path: orkest.gallery.notebook
class _Translations$orkest$gallery$notebook$es extends Translations$orkest$gallery$notebook$en {
	_Translations$orkest$gallery$notebook$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cuaderno';
	@override String get description => 'Una carpeta de notas cortas con tags. El agente escribe, tú lees y editas. También abre en Obsidian.';
}

// Path: orkest.gallery.workspaceEnv
class _Translations$orkest$gallery$workspaceEnv$es extends Translations$orkest$gallery$workspaceEnv$en {
	_Translations$orkest$gallery$workspaceEnv$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Env del workspace';
	@override String get description => 'Variables inyectadas en cada terminal de este workspace. Pon tokens o credenciales de API aquí en vez de pegarlos en el prompt del agente. Queda fuera de git.';
}

// Path: orkest.gallery.panel
class _Translations$orkest$gallery$panel$es extends Translations$orkest$gallery$panel$en {
	_Translations$orkest$gallery$panel$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Panel';
	@override String get description => 'Una página HTML con puente a la app: sus botones ejecutan comandos de la CLI de Orkest Code y del shell en esta máquina. Un playground para dashboards rápidos.';
}

// Path: orkest.notebook.format
class _Translations$orkest$notebook$format$es extends Translations$orkest$notebook$format$en {
	_Translations$orkest$notebook$format$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get bold => 'Negrita (⌘B)';
	@override String get italic => 'Cursiva (⌘I)';
	@override String get strike => 'Tachado';
	@override String get heading1 => 'Título 1';
	@override String get heading2 => 'Título 2';
	@override String get heading3 => 'Título 3';
	@override String get bullets => 'Lista';
	@override String get numbered => 'Lista numerada';
	@override String get checklist => 'Checklist';
	@override String get quote => 'Cita';
	@override String get code => 'Código inline (⌘E)';
	@override String get codeBlock => 'Bloque de código';
	@override String get link => 'Enlace (⌘K)';
	@override String get rule => 'Divisor';
	@override String get noteLink => 'Enlace a una nota ([[…]])';
	@override String get noteLinkSearch => 'Buscar notas';
	@override String get image => 'Insertar imagen…';
}

// Path: settings.page.header
class _Translations$settings$page$header$es extends Translations$settings$page$header$en {
	_Translations$settings$page$header$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get back => 'Atrás';
	@override String get title => 'Configuración';
}

// Path: settings.page.nav
class _Translations$settings$page$nav$es extends Translations$settings$page$nav$en {
	_Translations$settings$page$nav$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get general => 'General';
	@override String get appearance => 'Apariencia';
	@override String get terminal => 'Terminal';
	@override String get language => 'Lenguaje';
	@override String get shortcuts => 'Atajos';
	@override String get notifications => 'Notificaciones';
	@override String get automations => 'Automatizaciones';
	@override String get remoteHosts => 'Hosts remotos';
}

// Path: settings.page.general
class _Translations$settings$page$general$es extends Translations$settings$page$general$en {
	_Translations$settings$page$general$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionEditor => 'Editor';
	@override String get editorEngineTitle => 'Motor';
	@override String get editorEngineOrkest => 'Orkest Code (predeterminado)';
	@override String get editorEngineNeovim => 'Neovim';
	@override String get neovimChecking => 'Buscando Neovim…';
	@override String get neovimNotFound => 'Neovim no se encontró en la PATH de tu shell.';
	@override String get neovimRefresh => 'Comprobar de nuevo';
	@override String get showOrkestTitle => 'Mostrar terminal de Orkest Code';
	@override String get showOrkestDesc => 'Mantiene un workspace sin carpeta, solo de terminal, fijado en la parte superior de la barra lateral. Desactivarlo cierra sus terminales.';
	@override String get launchAtStartupTitle => 'Iniciar al arrancar';
	@override String get launchAtStartupDesc => 'Inicia Orkest Code automáticamente cuando inicias sesión en tu computadora.';
	@override String get sectionUpdates => 'Actualizaciones';
	@override String get checkUpdatesTitle => 'Buscar actualizaciones';
	@override String get checkUpdatesDesc => 'Con qué frecuencia Orkest Code debe buscar nuevas versiones.';
	@override late final _Translations$settings$page$general$updateFrequency$es updateFrequency = _Translations$settings$page$general$updateFrequency$es._(_root);
	@override String get developerModeTitle => 'Modo desarrollador';
	@override String get developerModeDesc => 'Registra los errores y avisos del propio Orkest Code en una base aparte de la Telemetría (chip “Orkest Code”) y activa las métricas de rendimiento. Solo sirve a quien mantiene la app.';
}

// Path: settings.page.diagnostics
class _Translations$settings$page$diagnostics$es extends Translations$settings$page$diagnostics$en {
	_Translations$settings$page$diagnostics$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Diagnóstico';
	@override String get logFileTitle => 'Archivo de registro';
	@override String logFileDesc({required Object days, required Object path}) => 'Los errores y eventos de inicio se registran aquí, y se conservan durante ${days} días.\n${path}';
	@override String get unavailable => 'no disponible';
	@override String get reveal => 'Mostrar';
	@override String get reportTitle => 'Reportar un problema';
	@override String get reportDesc => 'Abre un issue prellenado con tu versión, SO y registro reciente. Nada se envía automáticamente — lo revisas antes.';
	@override String get reportButton => 'Reportar…';
	@override String get reportDialogTitle => 'Informe de problema';
	@override String get reportDialogError => 'Reportado manualmente desde Configuración.';
	@override String get reportDialogDescription => 'Describe qué salió mal en el issue. El registro reciente está incluido abajo y en "Copiar detalles".';
}

// Path: settings.page.storage
class _Translations$settings$page$storage$es extends Translations$settings$page$storage$en {
	_Translations$settings$page$storage$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Almacenamiento';
	@override String get locationTitle => 'Ubicación de almacenamiento';
	@override String locationDesc({required Object root}) => 'Orkest Code guarda aquí sus proyectos, diseños y configuración. Apúntalo a una carpeta sincronizada para respaldarlo.\n${root}';
	@override String get useDefault => 'Usar predeterminado';
	@override String get working => 'Procesando…';
	@override String get change => 'Cambiar…';
	@override String get resetTitle => 'Restablecer Orkest Code';
	@override String get resetDesc => 'Elimina todos los datos locales — proyectos, diseños, configuración e historial de terminal — y vuelve a la ubicación predeterminada.';
	@override String get resetButton => 'Restablecer…';
	@override String get resetConfirm => 'Restablecer';
	@override String get resetDialogTitle => '¿Restablecer Orkest Code?';
	@override String get resetDialogContent => 'Esto elimina permanentemente todos los datos locales de Orkest Code — proyectos, diseños, configuración e historial de terminal. Esto no se puede deshacer. Orkest Code se cerrará para que puedas empezar de nuevo.';
	@override String get restartRequiredTitle => 'Reinicio necesario';
	@override String restartChangeFolderMessage({required Object path}) => 'Orkest Code usará esta carpeta a partir del próximo inicio:\n${path}';
	@override String get restartUseDefaultMessage => 'Orkest Code usará la ubicación predeterminada del sistema a partir del próximo inicio. Tus datos en la carpeta personalizada permanecen intactos.';
	@override String get restartResetMessage => 'Se borraron todos los datos de Orkest Code. Reinicia para empezar de nuevo.';
	@override String get later => 'Más tarde';
	@override String get quitOrkest => 'Salir de Orkest Code';
	@override String get chooseFolderDialogTitle => 'Elige una carpeta para los datos de Orkest Code';
}

// Path: settings.page.terminal
class _Translations$settings$page$terminal$es extends Translations$settings$page$terminal$en {
	_Translations$settings$page$terminal$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionDefaultTerminal => 'Terminal predeterminado';
	@override String get engineTitle => 'Motor';
	@override String get engineDesc => 'Usado por nuevas pestañas de terminal y buffers de salida de tasks. Las pestañas abiertas mantienen su motor actual.';
	@override String get shellTitle => 'Shell';
	@override String get shellDesc => 'Qué shell abren las nuevas pestañas de terminal. La flecha junto al + sigue abriendo cualquier otro, solo para esa pestaña.';
	@override String get noWslMessage => 'No se encontraron distros de WSL. Instala una (wsl.exe --install) y reinicia Orkest Code para verla listada aquí.';
	@override String get sectionBehavior => 'Comportamiento';
	@override String get closeOnExitTitle => 'Cerrar la pestaña cuando el shell termine';
	@override String get closeOnExitDesc => 'Cuando un shell termina por sí solo (exit, Ctrl-D), cierra su pestaña en lugar de dejar un terminal muerto.';
}

// Path: settings.page.appearance
class _Translations$settings$page$appearance$es extends Translations$settings$page$appearance$en {
	_Translations$settings$page$appearance$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTheme => 'Tema';
	@override String get themeTitle => 'Tema';
	@override String get themeDesc => 'Colores de la app, resaltado de código y paleta del terminal.';
	@override String get modeTitle => 'Modo';
	@override String get modeDesc => 'Qué variante del tema usar.';
	@override String modeOnlyDark({required Object theme}) => '"${theme}" solo trae la variante oscura, así que esto no tiene efecto.';
	@override String modeOnlyLight({required Object theme}) => '"${theme}" solo trae la variante clara, así que esto no tiene efecto.';
	@override String get themeFileTitle => 'Archivo de tema';
	@override String get themeFileDesc => 'Importa un tema desde un archivo JSON, o exporta el activo.';
	@override String get previewCode => 'Código';
	@override String get previewTerminal => 'Terminal';
	@override String get themeSystem => 'Sistema';
	@override String get themeLight => 'Claro';
	@override String get themeDark => 'Oscuro';
	@override String get sectionFonts => 'Fuentes';
	@override String get interfaceFontTitle => 'Fuente de la interfaz';
	@override String get interfaceFontDesc => 'Se usa en toda la aplicación. Vacío = predeterminado del sistema.';
	@override String get interfaceSizeTitle => 'Tamaño de la interfaz';
	@override String get codeFontTitle => 'Fuente del código';
	@override String get codeFontDesc => 'Código y diffs. Vacío = predeterminado del sistema.';
	@override String get codeSizeTitle => 'Tamaño del código';
	@override String get terminalFontTitle => 'Fuente del terminal';
	@override String get terminalFontDesc => 'Solo la terminal. Vacío = predeterminado del sistema.';
	@override String get terminalSizeTitle => 'Tamaño de la terminal';
	@override String get terminalSizeDesc => 'Apagado = sigue el tamaño del código.';
	@override String get terminalSizeInherit => 'Seguir el código';
	@override String get terminalWeightTitle => 'Grosor de la terminal';
	@override String get terminalWeightDesc => 'Las pantallas de baja densidad engrosan los trazos. El automático los afina solo ahí y no toca la Retina.';
	@override String get terminalWeightAuto => 'Automático (según la pantalla)';
	@override String get terminalWeightLight => 'Fino';
	@override String get terminalWeightNormal => 'Normal';
	@override String get terminalWeightMedium => 'Medio';
	@override String get terminalWeightSemiBold => 'Seminegrita';
	@override String get sectionConversation => 'Conversación';
	@override String get pinUserMessageTitle => 'Fijar mensaje del usuario';
	@override String get pinUserMessageDesc => 'La pregunta permanece fija arriba mientras la respuesta se desplaza.';
	@override String get importTheme => 'Importar…';
	@override String get exportTheme => 'Exportar…';
	@override String get deleteTheme => 'Eliminar';
	@override String get importThemeDialog => 'Elige un archivo de tema';
	@override String get exportThemeDialog => 'Guardar tema como';
	@override String themeImported({required Object name}) => 'Tema "${name}" importado.';
	@override String get themeExported => 'Tema guardado.';
	@override String get themeDeleted => 'Tema eliminado.';
	@override String get fontPickerTitle => 'Elegir una fuente';
	@override String get fontPickerSearch => 'Buscar fuentes';
	@override String get fontPickerEmpty => 'No hay ninguna fuente coincidente en esta máquina.';
	@override String get fontPickerBundled => 'incluida';
	@override String get fontPickerCustom => '¿No está en la lista? Escribe el nombre exacto de la familia.';
	@override String get fontPickerCustomHint => 'Nombre de la familia';
	@override String get fontPickerUse => 'Usar';
	@override String get fontPickerDefault => 'Predeterminada';
	@override String get fontMissing => 'No se encontró en esta máquina — usando el respaldo.';
	@override String get sectionLayout => 'Diseño';
	@override String get swapPanelsTitle => 'Invertir paneles';
	@override String get swapPanelsDesc => 'Coloca los workspaces a la derecha y archivos, búsqueda, git y base de datos a la izquierda.';
}

// Path: settings.page.notifications
class _Translations$settings$page$notifications$es extends Translations$settings$page$notifications$en {
	_Translations$settings$page$notifications$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Notificaciones';
	@override String get enableTitle => 'Activar notificaciones';
	@override String get enableDesc => 'Avisarme cuando un agente termine un turno y la ventana no esté enfocada.';
	@override String get systemPermissionTitle => 'Permiso del sistema';
	@override String get grantedDesc => 'Orkest Code tiene permiso para enviar notificaciones.';
	@override String get notGrantedDesc => 'macOS aún no ha concedido acceso a las notificaciones.';
	@override String get granted => 'Concedido';
	@override String get requestPermission => 'Solicitar permiso';
	@override String get soundsTitle => 'Sonidos';
	@override String get soundVolumeTitle => 'Volumen';
	@override String get soundTurnDone => 'Turno completado';
	@override String get soundTurnDoneDesc => 'Un agente terminó su turno.';
	@override String get soundActionRequired => 'Acción requerida';
	@override String get soundActionRequiredDesc => 'Un agente está esperando tu aprobación o respuesta.';
	@override String get soundDefault => 'Predeterminado';
	@override String soundCustom({required Object name}) => 'Personalizado: ${name}';
	@override String get soundChooseFile => 'Elegir archivo';
	@override String get soundReset => 'Volver al predeterminado';
	@override String get soundOnActiveTab => 'Reproducir también con la pestaña activa';
	@override String get soundPreview => 'Escuchar';
}

// Path: settings.page.shortcuts
class _Translations$settings$page$shortcuts$es extends Translations$settings$page$shortcuts$en {
	_Translations$settings$page$shortcuts$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get notCustomizable => 'Los atajos de teclado aún no se pueden personalizar.';
}

// Path: settings.page.languages
class _Translations$settings$page$languages$es extends Translations$settings$page$languages$en {
	_Translations$settings$page$languages$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionFormatting => 'FORMATO';
	@override String get formatOnSaveTitle => 'Formatear al guardar';
	@override String get formatOnSaveDesc => 'Formatea el archivo automáticamente al guardar (⌘S).';
	@override String get sectionLanguageServers => 'SERVIDORES DE LENGUAJE';
	@override String get footerNote => 'Los errores y el formato usan el language server de cada lenguaje. Orkest Code no instala servidores — usa lo que ya está en tu máquina. ● responde · ○ no encontrado o comando inválido (instala el servidor o ajusta el comando).';
	@override String get serverCommandLabel => 'Comando del language server';
	@override String get formatterCommandLabel => 'Comando del formateador (opcional)';
	@override String get formatterHint => 'Formateador externo con el marcador %FILE%. Tiene prioridad sobre el formateador del LSP cuando está definido.';
	@override String get resetToDefault => 'Restablecer al predeterminado';
	@override String get saveAndRestart => 'Guardar y reiniciar';
	@override String get statusResponds => 'El servidor responde';
	@override String get statusNotFound => 'Servidor no encontrado o comando inválido';
}

// Path: settings.page.automations
class _Translations$settings$page$automations$es extends Translations$settings$page$automations$en {
	_Translations$settings$page$automations$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get sectionCommitMessages => 'Mensajes de commit';
	@override String get harness => 'Harness';
	@override String get harnessDiscovering => 'Buscando harnesses de línea de comandos instalados…';
	@override String get harnessNoneFound => 'No se encontró ningún harness compatible en el PATH.';
	@override String harnessConfiguredUnavailable({required Object harness}) => '${harness} está configurado, pero no disponible.';
	@override String get harnessChoose => 'Elige la CLI usada para generar mensajes de commit.';
	@override String get harnessRefresh => 'Actualizar harnesses instalados';
	@override String get notConfigured => 'Sin configurar';
	@override String get model => 'Modelo';
	@override String get modelUnavailable => 'La lista de modelos no está disponible hasta encontrar el harness.';
	@override String get modelCliOnly => 'Este harness usa el modelo predeterminado de su CLI.';
	@override String get modelCliDefault => 'Predeterminado de la CLI';
	@override String get modelAuto => 'Auto';
	@override String modelSearch({required Object count}) => 'Buscar entre ${count} modelos…';
	@override String get modelAutoRouted => 'Este harness elige el modelo automáticamente.';
	@override String get modelAccountOnly => 'Solo se muestran los modelos disponibles en tu cuenta.';
	@override String get generateFromSourceControl => 'Generar desde Control de versiones';
	@override String get generateFromSourceControlDescription => 'Orkest Code envía solo el diff seleccionado y los asuntos de los commits recientes. Los patrones habituales de credenciales y los archivos sensibles se redactan antes de ejecutar el harness.';
	@override String get discoveryFailed => 'No se pudieron descubrir los harnesses de automatización instalados.';
	@override String staleModel({required Object model, required Object harness}) => 'El modelo "${model}" ya no está disponible para ${harness}. Se usará el predeterminado de la CLI; elige otro modelo en Configuración si lo necesitas.';
	@override String get recommendedSuffix => 'Recomendado';
}

// Path: settings.page.general.updateFrequency
class _Translations$settings$page$general$updateFrequency$es extends Translations$settings$page$general$updateFrequency$en {
	_Translations$settings$page$general$updateFrequency$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get daily => 'Diariamente';
	@override String get weekly => 'Semanalmente';
	@override String get monthly => 'Mensualmente';
	@override String get never => 'Nunca';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'core.bootstrapError.title' => 'No se pudo inicializar Orkest Code',
			'core.bootstrapError.retry' => 'Reintentar',
			'core.macosNotifications.title' => 'Activar notificaciones en macOS',
			'core.macosNotifications.intro' => 'Las notificaciones están desactivadas en la configuración del sistema. Sigue los pasos a continuación para activarlas:',
			'core.macosNotifications.step1' => 'Abre los Ajustes del Sistema en tu Mac.',
			'core.macosNotifications.step2' => 'Ve a la sección Notificaciones en la barra lateral izquierda.',
			'core.macosNotifications.step3' => 'Busca y selecciona la aplicación Orkest Code en la lista.',
			'core.macosNotifications.step4' => 'Activa el interruptor Permitir Notificaciones.',
			'core.macosNotifications.tip' => 'Consejo: si la aplicación no aparece en la lista, ciérrala y vuelve a abrirla para activar su registro en el sistema.',
			'core.macosNotifications.gotIt' => 'Entendido',
			'core.appErrorView.renderFailed' => 'Esta parte de la aplicación no se pudo renderizar',
			'core.appErrorView.details' => 'Detalles',
			'core.appErrorView.renderErrorTitle' => 'Error de renderizado',
			'core.errorReportDialog.defaultDescription' => 'Algo salió mal. Los detalles a continuación se guardaron en el registro — puedes reportarlos para que se solucione.',
			'core.errorReportDialog.copyDetails' => 'Copiar detalles',
			'core.errorReportDialog.reportIssue' => 'Reportar problema',
			'core.windowControls.minimize' => 'Minimizar',
			'core.windowControls.maximize' => 'Maximizar',
			'core.windowControls.close' => 'Cerrar',
			'core.crash.title' => 'Cierre inesperado',
			'core.crash.bannerTitle' => 'Orkest Code se cerró inesperadamente',
			'core.crash.report' => 'Reportar',
			'core.crash.dismiss' => 'Descartar',
			'core.crash.crashMessage' => ({required Object version}) => 'La sesión anterior (versión ${version}) terminó sin cerrarse correctamente. ¿Quieres reportarlo? El log se incluye y puedes revisar todo antes de enviar.',
			'core.crash.crashError' => ({required Object startedAt, required Object pid}) => 'La sesión iniciada el ${startedAt} (pid ${pid}) terminó sin un cierre limpio.',
			'core.crash.crashDescription' => 'No se capturó ningún error: el sistema terminó la app. El log de abajo es de esa sesión y es la parte más útil.',
			'core.menu.settings' => 'Configuración…',
			'core.menu.checkForUpdates' => 'Buscar Actualizaciones…',
			'core.menu.file' => 'Archivo',
			'core.menu.newTerminal' => 'Nueva Terminal',
			'core.menu.openWorkspace' => 'Abrir Workspace',
			'core.menu.goToFile' => 'Ir a Archivo…',
			'core.menu.save' => 'Guardar',
			'core.menu.discard' => 'Descartar',
			'core.menu.format' => 'Formatear',
			'core.menu.view' => 'Ver',
			'core.menu.toggleWorkspacePanel' => 'Alternar Panel de Workspaces',
			'core.menu.toggleFiles' => 'Alternar Archivos',
			'core.menu.splitRight' => 'Dividir a la Derecha',
			'core.menu.splitDown' => 'Dividir Abajo',
			'core.menu.focusPane' => 'Enfocar Panel',
			'core.menu.focusLeft' => 'Izquierda  (⌘⌥←)',
			'core.menu.focusRight' => 'Derecha  (⌘⌥→)',
			'core.menu.focusUp' => 'Arriba  (⌘⌥↑)',
			'core.menu.focusDown' => 'Abajo  (⌘⌥↓)',
			'core.menu.selectTab' => 'Seleccionar Pestaña',
			'core.menu.tabN' => ({required Object n}) => 'Pestaña ${n}',
			'core.menu.lastTab' => 'Última Pestaña',
			'core.menu.previousWorkspace' => 'Workspace Anterior',
			'core.menu.nextWorkspace' => 'Siguiente Workspace',
			'core.menu.zoomIn' => 'Acercar',
			'core.menu.zoomOut' => 'Alejar',
			'core.menu.actualSize' => 'Tamaño Real',
			'core.menu.window' => 'Ventana',
			'core.menu.quit' => 'Salir',
			'core.menu.minimize' => 'Minimizar',
			'core.menu.zoom' => 'Zoom',
			'common.cancel' => 'Cancelar',
			'common.confirm' => 'Confirmar',
			'common.create' => 'Crear',
			'common.gotIt' => 'Entendido',
			'common.save' => 'Guardar',
			'common.close' => 'Cerrar',
			'common.delete' => 'Eliminar',
			'common.done' => 'Listo',
			'common.add' => 'Añadir',
			'common.test' => 'Probar',
			'common.ok' => 'OK',
			'common.loading' => 'Cargando…',
			'common.checking' => 'Comprobando…',
			'common.remove' => 'Quitar',
			'common.restart' => 'Reiniciar',
			'common.settings' => 'Configuración',
			'common.send' => 'Enviar',
			'common.open' => 'Abrir',
			'common.dismiss' => 'Descartar',
			'common.report' => 'Reportar',
			'common.copyCode' => 'Copiar código',
			'common.search' => 'Buscar',
			'common.noResults' => 'Sin resultados',
			'orkest.officeWorld.reception' => 'Recepción',
			'orkest.officeWorld.cafe' => 'Cocina',
			'orkest.officeWorld.restrooms' => 'Baños',
			'orkest.officeWorld.lounge' => 'Sala de descanso',
			'orkest.officeWorld.rosterTitle' => 'Agentes de la oficina',
			'orkest.officeWorld.rosterSearch' => 'Buscar agentes o proyectos',
			'orkest.officeWorld.rosterEmpty' => 'No se encontraron agentes activos',
			'orkest.officeWorld.activityFeed' => 'Actividad',
			'orkest.officeWorld.activityEmpty' => 'La actividad observada aparecerá aquí.',
			'orkest.officeWorld.collapseRoster' => 'Contraer lista de agentes',
			'orkest.officeWorld.collapseFeed' => 'Contraer actividad',
			'orkest.officeWorld.reopenRoster' => 'Agentes',
			'orkest.officeWorld.reopenFeed' => 'Actividad',
			'orkest.officeWorld.working' => 'Trabajando',
			'orkest.officeWorld.waiting' => 'Esperando',
			'orkest.officeWorld.idle' => 'Disponible',
			'orkest.officeWorld.agentProfile' => 'Perfil del agente',
			'orkest.officeWorld.project' => 'Proyecto',
			'orkest.officeWorld.provider' => 'Agente',
			'orkest.officeWorld.currentStatus' => 'Estado actual',
			'orkest.officeWorld.followAgent' => 'Seguir personaje',
			'orkest.officeWorld.stopFollowingAgent' => 'Dejar de seguir',
			'orkest.officeWorld.centerAgent' => 'Centrar personaje',
			'orkest.officeWorld.sessionDuration' => 'Sesión actual en Orkest Code',
			'orkest.officeWorld.workingDirectory' => 'Directorio de trabajo',
			'orkest.officeWorld.statsPending' => 'Orkest Code todavía no recopila estadísticas de modelo, tokens y herramientas.',
			'orkest.officeWorld.recentActivity' => 'Actividad reciente en esta ejecución',
			'orkest.officeWorld.promptReceived' => 'Recibió una solicitud',
			'orkest.officeWorld.agentThinking' => 'Pensando',
			'orkest.officeWorld.agentResponded' => 'Respuesta enviada',
			'orkest.officeWorld.activityError' => 'Algo salió mal',
			'orkest.officeWorld.readingFile' => 'Leyendo archivo',
			'orkest.officeWorld.searchingCode' => 'Buscando en el código',
			'orkest.officeWorld.editingFile' => 'Editando archivo',
			'orkest.officeWorld.writingFile' => 'Escribiendo archivo',
			'orkest.officeWorld.runningCommand' => 'Comando en terminal',
			'orkest.officeWorld.runningTests' => 'Ejecutando pruebas',
			'orkest.officeWorld.browsingWeb' => 'Buscando en la web',
			'orkest.officeWorld.organizingTasks' => 'Organizando tareas',
			'orkest.officeWorld.callingSubagents' => 'Llamando subagentes',
			'orkest.officeWorld.toolCompleted' => 'Herramienta completada',
			'orkest.officeWorld.usingTool' => 'Usando herramienta',
			'orkest.officeWorld.editAgentName' => 'Editar nombre del agente',
			'orkest.officeWorld.agentName' => 'Nombre del agente',
			'orkest.officeWorld.workingInTerminal' => 'Trabajando en el terminal',
			'orkest.officeWorld.waitingInTerminal' => 'Te necesita en el terminal',
			'orkest.officeWorld.waitingBubble' => 'Responder en la terminal',
			'orkest.officeWorld.respond' => 'Responder',
			'orkest.officeWorld.dismissNotification' => 'Descartar aviso',
			'orkest.officeWorld.editAppearance' => 'Editar personaje',
			'orkest.officeWorld.randomizeAppearance' => 'Sortear',
			'orkest.officeWorld.resetAppearance' => 'Volver al sorteo',
			'orkest.officeWorld.skin' => 'Piel',
			'orkest.officeWorld.hair' => 'Cabello',
			'orkest.officeWorld.beard' => 'Barba',
			'orkest.officeWorld.eyes' => 'Ojos',
			'orkest.officeWorld.top' => 'Parte superior',
			'orkest.officeWorld.bottom' => 'Parte inferior',
			'orkest.officeWorld.shoes' => 'Zapatos',
			'orkest.officeWorld.accessory' => 'Accesorio',
			'orkest.officeWorld.turnCompleted' => 'Turno terminado',
			'orkest.officeWorld.subagentFailed' => 'El subagente falló',
			'orkest.officeWorld.subagentInterrupted' => 'Subagente interrumpido',
			'orkest.officeWorld.openTerminal' => 'Abrir terminal',
			'orkest.officeWorld.interactInOffice' => 'Interactuar en Office',
			'orkest.officeWorld.liveTerminal' => 'Terminal en vivo',
			'orkest.officeWorld.terminalInputPlaceholder' => 'Escribe en la terminal…',
			'orkest.officeWorld.terminalOfficeHint' => 'La entrada se envía a la sesión original. Usa las opciones de respuesta que el agente muestre en esta terminal.',
			'orkest.officeWorld.appearance' => 'Apariencia de la oficina',
			'orkest.officeWorld.officeTheme' => 'Tema estacional',
			'orkest.officeWorld.themeAuto' => 'Automático',
			'orkest.officeWorld.themeNone' => 'Original',
			'orkest.officeWorld.themeChristmas' => 'Navidad',
			'orkest.officeWorld.themeHalloween' => 'Halloween',
			'orkest.officeWorld.showNames' => 'Mostrar nombres de agentes',
			'orkest.officeWorld.bubbles' => 'Globos de actividad',
			'orkest.officeWorld.bubblesAll' => 'Todos',
			'orkest.officeWorld.bubblesImportant' => 'Importantes',
			'orkest.officeWorld.bubblesNone' => 'Ninguno',
			'orkest.officeWorld.movement' => 'Movimiento por la oficina',
			'orkest.officeWorld.movementCalm' => 'Tranquilo',
			'orkest.officeWorld.movementNormal' => 'Normal',
			'orkest.officeWorld.movementLively' => 'Animado',
			'orkest.officeWorld.daylight' => 'Ciclo día/noche',
			'orkest.officeWorld.sounds' => 'Sonidos de la oficina',
			'orkest.officeWorld.soundVolume' => 'Volumen',
			'orkest.officeWorld.soundAlerts' => 'Avisos y tareas completadas',
			'orkest.officeWorld.soundKeys' => 'Teclado',
			'orkest.officeWorld.soundElevator' => 'Ascensor',
			'orkest.officeWorld.soundSocial' => 'Ping-pong y arcade',
			'orkest.officeWorld.daylightAuto' => 'Automático',
			'orkest.officeWorld.daylightDay' => 'Siempre de día',
			'orkest.officeWorld.daylightNight' => 'Siempre de noche',
			'orkest.officeWorld.socialLife' => 'Vida social',
			'orkest.officeWorld.gameCoins' => ({required Object count}) => '${count} monedas de la oficina',
			'orkest.officeWorld.earnedWorking' => ({required Object count}) => '${count} ganadas con actividades',
			'orkest.officeWorld.matchRecord' => ({required Object wins, required Object losses}) => '${wins} victorias · ${losses} derrotas',
			'orkest.officeWorld.personality' => 'Personalidad',
			'orkest.officeWorld.friendships' => 'Amistades',
			'orkest.officeWorld.rivals' => 'Rivalidades',
			'orkest.officeWorld.socialLedger' => 'Historial de monedas',
			'orkest.officeWorld.socialActivity' => 'Vida social de la oficina',
			'orkest.officeWorld.delegatedBy' => ({required Object name}) => 'Delegado por ${name}',
			'orkest.officeWorld.shellWaiting' => 'Esperando un comando',
			'orkest.officeWorld.socialEconomy' => 'Juego de la oficina — sin valor monetario real',
			'orkest.confirmDialog.unsavedChangesTitle' => 'Cambios sin guardar',
			'orkest.confirmDialog.unsavedChangesMessage' => ({required Object fileName}) => '“${fileName}” tiene cambios sin guardar. ¿Guardarlos antes de cerrar?',
			'orkest.confirmDialog.dontSave' => 'No guardar',
			'orkest.confirmDialog.saveAndClose' => 'Guardar y cerrar',
			'orkest.neovim.unavailable' => 'Neovim no está disponible. Abriendo en Orkest Code.',
			'orkest.neovim.openFailed' => 'No se pudo acceder a Neovim. Abriendo en Orkest Code.',
			'orkest.neovim.unsavedTitle' => 'Búferes de Neovim sin guardar',
			'orkest.neovim.unsavedMessage' => 'Neovim tiene búferes modificados. ¿Cerrar la pestaña y descartar esos cambios?',
			'orkest.neovim.closeAnyway' => 'Cerrar de todos modos',
			'orkest.worktreeCreateDialog.forkTitle' => 'Fork del worktree',
			'orkest.worktreeCreateDialog.createTitle' => 'Crear worktree',
			'orkest.worktreeCreateDialog.forkSubtitle' => ({required Object root}) => 'Nueva worktree ramificada desde ${root}.',
			'orkest.worktreeCreateDialog.createSubtitle' => ({required Object root}) => 'Nueva feature en ${root} — nueva branch desde el HEAD actual.',
			'orkest.worktreeCreateDialog.namePlaceholder' => 'feat/mi-feature',
			'orkest.worktreeCreateDialog.errorWhitespace' => 'Sin espacios en el nombre.',
			'orkest.worktreeCreateDialog.errorInvalidChar' => 'Carácter inválido para un nombre de branch.',
			'orkest.worktreeCreateDialog.errorInvalidSequence' => 'Secuencia inválida (ej.: "..", "//", empezar/terminar con "/").',
			'orkest.worktreeCreateDialog.errorReserved' => 'Posición reservada (no empieces con "-"/"." ni termines con ".lock").',
			'orkest.worktreeCreateDialog.errorDuplicateBranch' => 'Ya existe una branch con ese nombre.',
			'orkest.worktreeCreateDialog.errorDuplicateWorktree' => 'Ya existe un worktree con ese nombre.',
			'orkest.worktreeCreateDialog.errorBranchHierarchyConflict' => ({required Object target, required Object existing}) => 'No se puede crear la branch \'${target}\' porque entra en conflicto con la branch \'${existing}\' ya existente.',
			'orkest.worktreeCreateDialog.errorBranchHierarchicalConflictGeneral' => 'Ya existe una branch con una jerarquía conflictiva.',
			'orkest.worktreeCreateDialog.fork' => 'Fork',
			'orkest.worktreeCreateDialog.postCheckoutHint' => 'Este repositorio tiene un hook post-checkout.',
			'orkest.worktreeCreateDialog.running' => 'Ejecutando…',
			'orkest.worktreeCreateDialog.advancedSettings' => 'Configuración Avanzada',
			'orkest.worktreeCreateDialog.copyIgnored' => 'Copiar archivos ignorados (.gitignore)',
			'orkest.worktreeCreateDialog.copyIgnoredDesc' => 'Copia los archivos ignorados por .gitignore (ej. .env, claves locales) al nuevo worktree.',
			'orkest.worktreeCreateDialog.copyUntracked' => 'Copiar archivos no rastreados',
			'orkest.worktreeCreateDialog.copyUntrackedDesc' => 'Copia los archivos nuevos o modificados que aún no se han agregado al stage.',
			'orkest.worktreeCreateDialog.baseBranch' => 'Branch base',
			'orkest.worktreeCreateDialog.baseBranchDesc' => 'La branch desde la cual se creará el nuevo worktree y branch.',
			'orkest.worktreeCreateDialog.fetchRemote' => 'Sincronizar branch remota (fetch)',
			'orkest.worktreeCreateDialog.fetchRemoteDesc' => 'Ejecuta git fetch para garantizar que la branch base esté confirmada antes de crear el worktree.',
			'orkest.worktreeCreateDialog.searchBranch' => 'Buscar branch...',
			'orkest.worktreeCreateDialog.back' => 'Atrás',
			'orkest.commitMessageDialog.commitTitle' => 'Commit',
			'orkest.commitMessageDialog.stageAndCommitTitle' => 'Stage y Commit',
			'orkest.commitMessageDialog.scopeNote' => ({required Object fileName}) => 'Commit solo de "${fileName}".',
			'orkest.commitMessageDialog.placeholder' => 'fix: resumen breve del cambio',
			'orkest.commitMessageDialog.errorEmptySubject' => 'La primera línea (asunto) no puede estar vacía.',
			'orkest.commitMessageDialog.errorTooShort' => ({required Object min}) => 'Asunto demasiado corto (mín. ${min} caracteres).',
			'orkest.commitMessageDialog.errorTooLong' => ({required Object max}) => 'Asunto demasiado largo (máx. ${max} caracteres).',
			'orkest.commitMessageDialog.errorTrailingPeriod' => 'El asunto no debe terminar con un punto.',
			'orkest.commitMessageDialog.errorControlChars' => 'El asunto contiene caracteres de control.',
			'orkest.commitMessageDialog.errorBlankSecondLine' => 'Deja la segunda línea en blanco (separador entre asunto y cuerpo de git).',
			'orkest.commitMessageDialog.generate' => 'Generar mensaje de commit',
			'orkest.commitMessageDialog.generateWith' => ({required Object harness}) => 'Generar con ${harness}',
			'orkest.commitMessageDialog.generating' => 'Generando…',
			'orkest.commitMessageDialog.cancelGeneration' => 'Cancelar generación',
			'orkest.tasksPanel.reloadTasksTooltip' => 'Recargar tasks',
			'orkest.tasksPanel.restartTooltip' => 'Reiniciar',
			'orkest.tasksPanel.stopTooltip' => 'Detener',
			'orkest.tasksPanel.runTooltip' => 'Ejecutar',
			'orkest.tasksPanel.sendsKeyTooltip' => ({required Object label, required Object key}) => '${label} (envía \'${key}\')',
			'orkest.tasksPanel.startingTooltip' => 'Iniciando…',
			'orkest.tasksPanel.stoppingTooltip' => 'Deteniendo…',
			'orkest.tasksPanel.switchProfileTooltip' => 'Cambiar perfil',
			'orkest.tasksPanel.moreKeysTooltip' => 'Más teclas',
			'orkest.tasksPanel.sectionTasks' => 'TAREAS',
			'orkest.tasksPanel.noTasks' => 'No se detectaron tareas en este proyecto.',
			'orkest.tasksPanel.createTasksJson' => 'Crear tasks.json',
			'orkest.tasksPanel.generateComposeTasks' => 'Generar tareas de Compose',
			'orkest.tasksPanel.selectComposeEngine' => 'Elige un motor de Compose',
			'orkest.tasksPanel.noComposeEngine' => 'No se encontró Docker Compose ni Podman Compose.',
			'orkest.tasksPanel.invalidComposeFile' => 'El archivo activo no es un Compose válido con servicios.',
			'orkest.tasksPanel.invalidTasksJson' => 'tasks.json no es válido. No se guardaron cambios.',
			'orkest.tasksPanel.composeConflicts' => ({required Object labels}) => 'Se conservaron tareas que no son Compose con etiquetas en conflicto: ${labels}',
			'orkest.orkestPage.chooseProjectFolderDialogTitle' => 'Elige la carpeta del proyecto',
			'orkest.orkestPage.chooseWorkspaceFolderDialogTitle' => 'Elige la carpeta del workspace',
			'orkest.orkestPage.workspaceRenamedTitle' => 'Workspace renombrado',
			'orkest.orkestPage.workspaceRenamedMessage' => ({required Object name}) => 'El nuevo nombre "${name}" solo se enviará a los agentes tras reiniciar el workspace o la aplicación.',
			'orkest.orkestPage.syncTitle' => ({required Object label}) => 'Sync — ${label}',
			'orkest.orkestPage.pullTitle' => ({required Object label}) => 'Pull — ${label}',
			'orkest.orkestPage.pushTitle' => ({required Object label}) => 'Push — ${label}',
			'orkest.orkestPage.updateFromParentTitle' => ({required Object name}) => 'Actualizar desde el Padre — ${name}',
			'orkest.orkestPage.mergeToParentTitle' => ({required Object name}) => 'Merge al Padre — ${name}',
			'orkest.orkestPage.worktreeMergedAndRemoved' => 'Worktree fusionado y eliminado.',
			'orkest.orkestPage.nothingWasChanged' => 'No se realizaron cambios.',
			'orkest.orkestPage.newRealmTitle' => 'Nuevo realm',
			'orkest.orkestPage.closeWorkspaceTitle' => 'Cerrar workspace',
			'orkest.orkestPage.closeWorkspaceMessage' => ({required Object name}) => '¿Cerrar "${name}"? Los agentes de este workspace se cerrarán. La carpeta en el disco se conserva.',
			'orkest.orkestPage.closeAction' => 'Cerrar',
			'orkest.orkestPage.removeWorktreeTitle' => 'Quitar worktree',
			'orkest.orkestPage.removeWorktreeMessage' => ({required Object name, required Object warn}) => '¿Quitar "${name}"? La carpeta del worktree y la branch se eliminarán y los agentes de este fork se cerrarán.${warn}',
			'orkest.orkestPage.removeWorktreeWarning' => ({required Object name}) => '\n\nAdvertencia: la branch "${name}" aún no se ha fusionado — eliminarla (git branch -D) descarta el trabajo no fusionado.',
			'orkest.orkestPage.failedToRemoveWorktreeTitle' => 'No se pudo quitar el worktree',
			'orkest.orkestPage.openLayoutTitle' => 'Abrir layout',
			'orkest.orkestPage.replaceLayoutTitle' => '¿Reemplazar el layout actual?',
			'orkest.orkestPage.replaceLayoutMessage' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: 'Se cerrará 1 pestaña, y tiene un proceso en ejecución.', other: 'Se cerrarán ${n} pestañas, incluidas las que tienen procesos en ejecución.', ),
			'orkest.orkestPage.replaceLayoutConfirm' => 'Reemplazar',
			'orkest.orkestPage.restartServerTooltip' => 'Reiniciar servidor',
			'orkest.orkestPage.noLspAvailable' => 'Ningún LSP disponible',
			'orkest.orkestPage.lspRunning' => 'en ejecución',
			'orkest.orkestPage.lspStopped' => 'detenido',
			'orkest.welcomeView.title' => 'Bienvenido a Orkest Code',
			'orkest.welcomeView.subtitle' => 'Abre una carpeta o conéctate a un host remoto para empezar.',
			'orkest.welcomeView.createWorkspace' => 'Crear workspace',
			'orkest.welcomeView.openLocalFolder' => 'Abrir carpeta local',
			'orkest.welcomeView.connectHost' => 'Conectar a un host',
			'orkest.welcomeView.configureHost' => 'Configurar host',
			'orkest.welcomeView.addWorkspace' => 'Añadir workspace',
			'orkest.paneView.closePaneTitle' => '¿Cerrar panel?',
			'orkest.paneView.closePaneMessage' => ({required Object count}) => 'Esto cierra todas las ${count} pestaña(s) de este panel y finaliza los agentes/terminales en él.',
			'orkest.paneView.close' => 'Cerrar',
			'orkest.paneView.closeOtherTabs' => 'Cerrar las otras',
			'orkest.paneView.closeTabsToTheRight' => 'Cerrar a la derecha',
			'orkest.paneView.closeAllTabs' => 'Cerrar todas',
			'orkest.paneView.closeTabsTitle' => '¿Cerrar pestañas?',
			'orkest.paneView.closeTabsMessage' => ({required Object count}) => 'Esto cierra ${count} pestaña(s) y finaliza los agentes/terminales en ellas.',
			'orkest.paneView.allTabs' => 'Todas las pestañas',
			'orkest.paneView.pinTab' => 'Fijar pestaña',
			'orkest.paneView.openInNewWindow' => 'Abrir en ventana nueva',
			'orkest.paneView.rename' => 'Renombrar',
			'orkest.paneView.openAsMarkdown' => 'Abrir como markdown',
			'orkest.paneView.openAsBoard' => 'Abrir como tablero',
			'orkest.paneView.resetTitle' => 'Restablecer título',
			'orkest.paneView.copyId' => 'Copiar Id',
			'orkest.paneView.restartTab' => 'Reiniciar',
			'orkest.paneView.newTab' => 'Nueva pestaña',
			'orkest.paneView.newTerminal' => 'Nueva terminal…',
			'orkest.paneView.splitRight' => 'Dividir a la derecha',
			'orkest.paneView.splitDown' => 'Dividir abajo',
			'orkest.paneView.closePane' => 'Cerrar panel',
			'orkest.paneView.dropHereToMove' => 'Suelta aquí para mover la pestaña',
			'orkest.paneView.dockAsTab' => 'Acoplar como pestaña',
			'orkest.paneView.openBrowser' => 'Abrir navegador',
			'orkest.paneView.openTerminal' => 'Abrir terminal',
			'orkest.paneView.openAsLayout' => 'Abrir como diseño',
			'orkest.paneView.openAsYaml' => 'Abrir como YAML',
			'orkest.paneView.openAsPanel' => 'Abrir como panel',
			'orkest.paneView.openAsHtml' => 'Abrir como HTML',
			'orkest.fileTreePanel.viewDiff' => 'Ver Diff',
			'orkest.fileTreePanel.commit' => 'Commit',
			'orkest.fileTreePanel.stageAndCommit' => 'Stage y Commit',
			'orkest.fileTreePanel.unstage' => 'Quitar del stage',
			'orkest.fileTreePanel.stageChanges' => 'Poner en stage',
			'orkest.fileTreePanel.discardChanges' => 'Descartar cambios',
			'orkest.fileTreePanel.enterCommitMessage' => 'Escribe un mensaje de commit.',
			'orkest.fileTreePanel.commitUnavailable' => 'Commit no disponible para este workspace.',
			'orkest.fileTreePanel.gitErrorTitle' => 'Error de Git',
			'orkest.fileTreePanel.deleteNewFileTitle' => '¿Eliminar archivo nuevo?',
			'orkest.fileTreePanel.discardChangesTitle' => '¿Descartar cambios?',
			'orkest.fileTreePanel.deleteNewFileMessage' => ({required Object name}) => '"${name}" es un archivo nuevo y no se puede restaurar. ¿Eliminarlo?',
			'orkest.fileTreePanel.discardOneMessage' => ({required Object name}) => '¿Descartar todos los cambios en "${name}"? Los archivos eliminados se restaurarán.',
			'orkest.fileTreePanel.discard' => 'Descartar',
			'orkest.fileTreePanel.deleteAllNewFilesTitle' => '¿Eliminar todos los archivos nuevos?',
			'orkest.fileTreePanel.allNewFilesMessage' => ({required Object count}) => 'Los ${count} archivos son nuevos y se eliminarán. Esto no se puede deshacer.',
			'orkest.fileTreePanel.discardTrackedMessage' => ({required Object count, required Object extra}) => '¿Descartar cambios en ${count} archivo(s) rastreado(s)?${extra}',
			'orkest.fileTreePanel.discardTrackedExtra' => ({required Object count}) => ' Se mantendrán ${count} archivo(s) nuevo(s).',
			'orkest.fileTreePanel.deleteAll' => 'Eliminar todo',
			'orkest.fileTreePanel.deleteQuestionTitle' => '¿Eliminar?',
			'orkest.fileTreePanel.moveToTrash' => ({required Object name}) => '¿Mover “${name}” a la Papelera?',
			'orkest.fileTreePanel.permanentlyDelete' => ({required Object name}) => '¿Eliminar “${name}” de forma permanente? Esto no se puede deshacer.',
			'orkest.fileTreePanel.couldNotDeleteTitle' => 'No se pudo eliminar',
			'orkest.fileTreePanel.moveQuestionTitle' => '¿Mover?',
			'orkest.fileTreePanel.moveMessage' => ({required Object name, required Object dest}) => '¿Mover “${name}” a “${dest}”?',
			'orkest.fileTreePanel.moveAction' => 'Mover',
			'orkest.fileTreePanel.couldNotMoveTitle' => 'No se pudo mover',
			'orkest.fileTreePanel.couldNotPasteTitle' => 'No se pudo pegar',
			'orkest.fileTreePanel.filesTooltip' => 'Archivos',
			'orkest.fileTreePanel.searchTooltip' => 'Buscar',
			'orkest.fileTreePanel.sourceControlTooltip' => 'Control de versiones',
			'orkest.fileTreePanel.databaseTooltip' => 'Base de datos',
			'orkest.fileTreePanel.sectionFiles' => 'ARCHIVOS',
			'orkest.fileTreePanel.newFile' => 'Nuevo archivo',
			'orkest.fileTreePanel.newFolder' => 'Nueva carpeta',
			'orkest.fileTreePanel.refreshTooltip' => 'Actualizar',
			'orkest.fileTreePanel.collapseAll' => 'Contraer todas las carpetas',
			'orkest.fileTreePanel.sectionSourceControl' => 'CONTROL DE VERSIONES',
			'orkest.fileTreePanel.viewAsList' => 'Ver como lista',
			'orkest.fileTreePanel.viewAsTree' => 'Ver como árbol',
			'orkest.fileTreePanel.noFolderMessage' => 'Ninguna carpeta — abre un workspace.',
			'orkest.fileTreePanel.amend' => 'Amend',
			'orkest.fileTreePanel.commitMessagePlaceholder' => 'Mensaje del commit',
			'orkest.fileTreePanel.amendCommit' => 'Amend del commit',
			'orkest.fileTreePanel.lastCommit' => 'último commit',
			'orkest.fileTreePanel.openInFinder' => 'Abrir en Finder',
			'orkest.fileTreePanel.openInExplorer' => 'Abrir en el Explorador',
			'orkest.fileTreePanel.openInFileManager' => 'Abrir en el gestor de archivos',
			'orkest.fileTreePanel.open' => 'Abrir',
			'orkest.fileTreePanel.openWith' => 'Abrir con',
			'orkest.fileTreePanel.openInNewWindow' => 'Abrir en ventana nueva',
			'orkest.fileTreePanel.openLayout' => 'Abrir layout',
			'orkest.fileTreePanel.openAsMarkdown' => 'Abrir como markdown',
			'orkest.fileTreePanel.showGitDiff' => 'Mostrar diff de git',
			'orkest.fileTreePanel.createTerminal' => 'Abrir en terminal',
			'orkest.fileTreePanel.rename' => 'Renombrar',
			'orkest.fileTreePanel.copy' => 'Copiar',
			'orkest.fileTreePanel.cut' => 'Cortar',
			'orkest.fileTreePanel.paste' => 'Pegar',
			'orkest.fileTreePanel.copyRelativePath' => 'Copiar ruta relativa',
			'orkest.fileTreePanel.copyAbsolutePath' => 'Copiar ruta absoluta',
			'orkest.fileTreePanel.renameFailed' => 'No se pudo renombrar.',
			'orkest.fileTreePanel.noChanges' => 'Sin cambios.',
			'orkest.fileTreePanel.stagedChangesHeader' => ({required Object count}) => 'CAMBIOS EN STAGE (${count})',
			'orkest.fileTreePanel.changesHeader' => ({required Object count}) => 'CAMBIOS (${count})',
			'orkest.fileTreePanel.discardAllChanges' => 'Descartar todos los cambios',
			'orkest.fileTreePanel.unstageAllChanges' => 'Quitar todo del stage',
			'orkest.fileTreePanel.stageAllChanges' => 'Poner todo en stage',
			'orkest.fileTreePanel.discardFolderChanges' => 'Descartar cambios de la carpeta',
			'orkest.fileTreePanel.unstageFolderChanges' => 'Quitar carpeta del stage',
			'orkest.fileTreePanel.stageFolderChanges' => 'Poner carpeta en stage',
			'orkest.fileTreePanel.generateCommitMessage' => 'Generar mensaje de commit',
			'orkest.fileTreePanel.generateWith' => ({required Object harness}) => 'Generar con ${harness}',
			'orkest.fileTreePanel.generateUnavailableWhileAmending' => 'No disponible mientras se enmienda un commit',
			'orkest.fileTreePanel.cancelGeneration' => 'Cancelar generación',
			'orkest.fileTreePanel.changes' => 'Cambios',
			'orkest.fileTreePanel.history' => 'Historial',
			'orkest.fileTreePanel.historyRepository' => 'Repositorio',
			'orkest.fileTreePanel.historyNoRepository' => 'No hay ningun repositorio Git disponible.',
			'orkest.fileTreePanel.historyEmpty' => 'No se encontraron commits.',
			'orkest.fileTreePanel.historyLoadFailed' => 'No se pudo cargar el historial de Git.',
			'orkest.fileTreePanel.historyUntitledCommit' => 'Commit sin titulo',
			'orkest.fileTreePanel.historyNow' => 'ahora',
			'orkest.fileTreePanel.historyMinutesAgo' => ({required Object count}) => 'hace ${count} min',
			'orkest.fileTreePanel.historyHoursAgo' => ({required Object count}) => 'hace ${count} h',
			'orkest.fileTreePanel.historyYesterday' => 'ayer',
			'orkest.fileTreePanel.historyDayAgo' => 'hace 1 dia',
			'orkest.fileTreePanel.historyDaysAgo' => ({required Object count}) => 'hace ${count} dias',
			'orkest.fileTreePanel.historyFiles' => 'Archivos modificados',
			'orkest.fileTreePanel.historyFilesEmpty' => 'No hay archivos modificados.',
			'orkest.fileTreePanel.historyFilesLoadFailed' => 'No se pudieron cargar los archivos modificados.',
			'orkest.fileTreePanel.diffEmptyTree' => 'Arbol vacio',
			'orkest.fileTreePanel.diffOriginal' => ({required Object ref}) => 'Original ${ref}',
			'orkest.fileTreePanel.diffModified' => ({required Object ref}) => 'Modificado ${ref}',
			'orkest.fileTreePanel.diffWorkingTree' => 'Directorio de trabajo',
			'orkest.fileTreePanel.diffBinaryFile' => 'Archivo binario - sin diff de texto.',
			'orkest.fileTreePanel.diffNoChanges' => 'Sin cambios.',
			'orkest.fileTreePanel.diffError' => ({required Object detail}) => 'No se pudo leer el diff: ${detail}',
			'orkest.fileTreePanel.galleryTooltip' => 'Galería',
			'orkest.fileTreePanel.sectionGallery' => 'GALERÍA',
			'orkest.fileTreePanel.openAsHtml' => 'Abrir como HTML',
			'orkest.fileTreePanel.importQuestionTitle' => '¿Copiar aquí?',
			'orkest.fileTreePanel.importMessage' => ({required Object count, required Object dest}) => '¿Copiar ${count} elementos en “${dest}”?',
			'orkest.fileTreePanel.importAction' => 'Copiar',
			'orkest.fileTreePanel.couldNotImportTitle' => 'No se pudo copiar',
			'orkest.fileTreePanel.openInAgent' => ({required Object harness}) => 'Abrir en ${harness}',
			'orkest.fileViewer.cantOpen' => 'No se puede abrir este archivo.',
			'orkest.fileViewer.couldNotLoadImage' => 'No se pudo cargar la imagen.',
			'orkest.fileViewer.preview' => 'Vista previa',
			'orkest.fileViewer.source' => 'Código fuente',
			'orkest.fileViewer.reload' => 'Recargar',
			'orkest.workspaceSettingsDialog.choosePhotoTitle' => 'Elegir foto del workspace',
			'orkest.workspaceSettingsDialog.title' => 'Configuración del workspace',
			'orkest.workspaceSettingsDialog.namePlaceholder' => 'Nombre del workspace',
			'orkest.workspaceSettingsDialog.addPhoto' => 'Añadir foto',
			'orkest.workspaceSettingsDialog.changePhoto' => 'Cambiar foto',
			'orkest.workspaceSettingsDialog.remove' => 'Quitar',
			'orkest.workspaceSettingsDialog.color' => 'Color',
			'orkest.workspaceSettingsDialog.host' => 'Host',
			'orkest.workspaceSettingsDialog.folder' => 'Carpeta',
			'orkest.realmDialogs.namePlaceholder' => 'Nombre del realm',
			'orkest.realmDialogs.duplicateName' => 'Ya existe un realm con ese nombre.',
			'orkest.realmDialogs.newRealmTitle' => 'Nuevo realm',
			'orkest.realmDialogs.renameRealmTitle' => 'Renombrar realm',
			'orkest.realmDialogs.rename' => 'Renombrar',
			'orkest.realmDialogs.deleteRealmTitle' => 'Eliminar realm',
			'orkest.realmDialogs.deleteMessage' => ({required Object name, required Object suffix}) => '¿Eliminar "${name}"? Ningún workspace se elimina — solo cambia la lista de carpetas.${suffix}',
			'orkest.realmDialogs.deleteSuffixOne' => ' Su workspace se moverá a Predeterminado.',
			'orkest.realmDialogs.deleteSuffixMany' => ({required Object count}) => ' Sus ${count} workspaces se moverán a Predeterminado.',
			'orkest.realmDialogs.manageRealmsTitle' => 'Gestionar realms',
			'orkest.realmDialogs.workspaceCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 workspace', other: '${n} workspaces', ),
			'orkest.dbRedisTable.deleteKeyTitle' => 'Eliminar clave',
			'orkest.dbRedisTable.deleteKeyMessage' => ({required Object key}) => '¿Eliminar "${key}" de esta base de datos Redis?',
			'orkest.dbRedisTable.refresh' => 'Actualizar',
			'orkest.dbRedisTable.newKey' => 'Nueva clave',
			'orkest.dbRedisTable.columnKey' => 'CLAVE',
			'orkest.dbRedisTable.columnValue' => 'VALOR',
			'orkest.dbRedisTable.columnType' => 'TIPO',
			'orkest.dbRedisTable.columnTtl' => 'TTL',
			'orkest.dbRedisTable.keyCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 clave', other: '${n} claves', ),
			'orkest.dbRedisTable.noKeys' => 'No hay claves en esta base de datos.',
			'orkest.dbRedisTable.noKeysMatch' => ({required Object pattern}) => 'Ninguna clave coincide con "${pattern}".',
			'orkest.dbRedisTable.loadMore' => 'Cargar más',
			'orkest.dbRedisTable.loadingFullValue' => 'Cargando valor completo…',
			'orkest.dbRedisTable.ttlMustBeNumber' => 'El TTL debe ser un número de segundos.',
			'orkest.dbRedisTable.addKey' => 'Añadir clave',
			'orkest.dbRedisTable.keyFieldHint' => 'clave',
			'orkest.dbRedisTable.ttlFieldHint' => 'ttl (s, opcional)',
			'orkest.dbRedisTable.valueFieldHint' => 'valor',
			'orkest.dbRedisTable.searchHint' => 'Buscar — patrón, ej.: user:*',
			'orkest.dbQueryView.saveQueryAs' => 'Guardar query como',
			'orkest.dbQueryView.couldNotSave' => 'No se pudo guardar',
			'orkest.dbQueryView.selectDatabase' => 'Seleccionar base de datos',
			'orkest.dbQueryView.noSqlConnections' => 'Sin conexiones SQL',
			'orkest.dbQueryView.running' => 'Ejecutando…',
			'orkest.dbQueryView.runSelection' => 'Ejecutar selección',
			'orkest.dbQueryView.run' => 'Ejecutar',
			'orkest.dbQueryView.pickDatabaseHint' => 'Elige una base de datos arriba y luego Ejecutar (⌘↵).',
			'orkest.dbQueryView.runQueryHint' => 'Ejecuta la query (⌘↵) para ver los resultados aquí.',
			'orkest.dbQueryView.noRows' => 'Sin filas.',
			'orkest.dbQueryView.rowsAffected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 fila afectada', other: '${n} filas afectadas', ),
			'orkest.dbQueryView.rowsFooter' => ({required Object n}) => '${n} filas',
			'orkest.dbQueryView.truncatedSuffix' => ' · truncado (aumenta -- limit)',
			'orkest.dbQueryView.table' => 'Tabla',
			'orkest.dbQueryView.json' => 'JSON',
			'orkest.dbQueryView.unsaved' => 'sin guardar',
			'orkest.dbQueryView.saved' => 'guardado',
			'orkest.dbQueryView.copied' => 'Copiado',
			'orkest.dbQueryView.copy' => 'Copiar',
			'orkest.httpView.saveRequestAs' => 'Guardar request como',
			'orkest.httpView.couldNotSave' => 'No se pudo guardar',
			'orkest.httpView.run' => 'Ejecutar',
			'orkest.httpView.running' => 'Ejecutando…',
			'orkest.httpView.noRequests' => 'Ningún request en este archivo — escribe uno, p. ej.: GET https://example.com',
			'orkest.httpView.selectRequest' => 'Seleccionar request',
			'orkest.httpView.requestCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 request', other: '${n} requests', ),
			'orkest.httpView.runHint' => 'Ejecuta el request (⌘↵) para ver la respuesta aquí.',
			'orkest.httpView.emptyBody' => 'Cuerpo de la respuesta vacío.',
			'orkest.httpView.body' => 'JSON',
			'orkest.httpView.headers' => 'Headers',
			'orkest.httpView.raw' => 'Text',
			'orkest.httpView.truncatedSuffix' => ' · truncado (respuesta demasiado grande)',
			'orkest.httpView.error.title' => 'Falló el request',
			'orkest.httpView.error.noRequest' => 'No se encontró ningún request en la posición del cursor.',
			'orkest.httpView.error.invalidUrl' => ({required Object url}) => 'URL inválida: ${url}',
			'orkest.httpView.error.unresolvedVariable' => ({required Object name}) => 'La variable {{${name}}} no tiene valor. Declárala con @${name} = … en este archivo.',
			'orkest.httpView.error.bodyFileMissing' => ({required Object path}) => 'Archivo de cuerpo no encontrado: ${path}',
			'orkest.httpView.error.bodyFileUnreadable' => ({required Object path, required Object detail}) => 'No se pudo leer el archivo de cuerpo ${path}: ${detail}',
			'orkest.httpView.error.connectionFailed' => ({required Object detail}) => 'No se pudo alcanzar el servidor: ${detail}',
			'orkest.httpView.error.connectionFailedNoDetail' => 'No se pudo alcanzar el servidor.',
			'orkest.httpView.error.timeout' => ({required Object seconds}) => 'El request superó el tiempo límite de ${seconds}s.',
			'orkest.httpView.error.responseTooLarge' => ({required Object bytes}) => 'La respuesta superó el límite de ${bytes} bytes.',
			'orkest.kanbanView.filter' => 'Filtrar',
			'orkest.kanbanView.filterTitlePlaceholder' => 'Buscar por título',
			'orkest.kanbanView.filterLabels' => 'Etiquetas',
			_ => null,
		} ?? switch (path) {
			'orkest.kanbanView.filterClear' => 'Limpiar',
			'orkest.kanbanView.filterDependencies' => 'Dependencias',
			'orkest.kanbanView.filterBlocked' => 'Bloqueado',
			'orkest.kanbanView.filterReady' => 'Listo',
			'orkest.kanbanView.blockedBy' => 'Bloqueado por',
			'orkest.kanbanView.addBlocker' => 'Agregar tarjeta bloqueante',
			'orkest.kanbanView.searchCards' => 'Buscar tarjetas',
			'orkest.kanbanView.unknownCard' => 'desconocida',
			'orkest.kanbanView.boardView' => 'Tablero',
			'orkest.kanbanView.listView' => 'Lista',
			'orkest.kanbanView.refresh' => 'Actualizar desde el disco',
			'orkest.kanbanView.manageLabels' => 'Etiquetas',
			'orkest.kanbanView.labelsTitle' => 'Etiquetas de este tablero',
			'orkest.kanbanView.labelNamePlaceholder' => 'nombre de la etiqueta',
			'orkest.kanbanView.labelUsage' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 tarjeta', other: '${n} tarjetas', ),
			'orkest.kanbanView.deleteLabel' => 'Eliminar etiqueta',
			'orkest.kanbanView.newCard' => 'nueva tarjeta',
			'orkest.kanbanView.newCardTitle' => 'Nueva tarjeta',
			'orkest.kanbanView.newColumn' => 'Nueva columna',
			'orkest.kanbanView.columnNameTitle' => 'Nombre de la columna',
			'orkest.kanbanView.dragColumn' => 'Arrastrar columna',
			'orkest.kanbanView.columnOptions' => 'Opciones de la columna',
			'orkest.kanbanView.renameColumn' => 'Renombrar columna',
			'orkest.kanbanView.moveColumnLeft' => 'Mover a la izquierda',
			'orkest.kanbanView.moveColumnRight' => 'Mover a la derecha',
			'orkest.kanbanView.deleteColumn' => 'Eliminar columna',
			'orkest.kanbanView.newCardHere' => 'Nueva tarjeta aquí',
			'orkest.kanbanView.duplicateCard' => 'Duplicar',
			'orkest.kanbanView.cardLabels' => 'Etiquetas',
			'orkest.kanbanView.deleteCard' => 'Eliminar tarjeta',
			'orkest.kanbanView.advance' => 'Pasar a la siguiente columna',
			'orkest.kanbanView.advanceHold' => 'Mover a la siguiente columna (mantener: mover a la última)',
			'orkest.kanbanView.advanceBack' => 'Volver una columna',
			'orkest.kanbanView.emptyColumn' => 'Sin tarjetas',
			'orkest.kanbanView.cardCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 tarjeta', other: '${n} tarjetas', ),
			'orkest.kanbanView.notes' => 'Nota',
			'orkest.kanbanView.notesPlaceholder' => 'Escribe una nota',
			'orkest.kanbanView.comments' => 'Comentarios',
			'orkest.kanbanView.addComment' => 'Añadir comentario',
			'orkest.kanbanView.commentPlaceholder' => 'Escribe un comentario',
			'orkest.kanbanView.noComments' => 'Aún no hay comentarios',
			'orkest.kanbanView.closeDetail' => 'Cerrar',
			'orkest.kanbanView.notABoard' => 'Este archivo aún no tiene columnas ## — se abre como markdown.',
			'orkest.kanbanView.startBoard' => 'Empezar un tablero',
			'orkest.kanbanView.couldNotSave' => 'No se pudo guardar el tablero',
			'orkest.kanbanView.unrecognizedBlock' => 'No reconocido por el analizador — se arrastra entero, sin edición en línea.',
			'orkest.kanbanView.deleteColumnDialog.title' => ({required Object name}) => '¿Eliminar «${name}»?',
			'orkest.kanbanView.deleteColumnDialog.message' => ({required Object count}) => 'Esta columna tiene ${count}. Elige qué pasa con ellas.',
			'orkest.kanbanView.deleteColumnDialog.moveCards' => 'Mover a la columna anterior',
			'orkest.kanbanView.deleteColumnDialog.deleteAll' => 'Eliminar junto con la columna',
			'orkest.kanbanView.deleteColumnDialog.emptyMessage' => 'Esta columna está vacía.',
			'orkest.dbPanel.sectionDatabase' => 'BASE DE DATOS',
			'orkest.dbPanel.edit' => 'Editar…',
			'orkest.dbPanel.copyName' => 'Copiar nombre',
			'orkest.dbPanel.newQuery' => 'Nueva query',
			'orkest.dbPanel.browseKeys' => 'Ver claves',
			'orkest.dbPanel.deleteConnectionTitle' => 'Eliminar conexión',
			'orkest.dbPanel.deleteConnectionMessage' => ({required Object name}) => '¿Quitar "${name}" de este workspace? Cualquier contraseña guardada se descartará. Los archivos .dbq que la referencian no se modifican.',
			'orkest.dbPanel.footer' => ({required Object n}) => '.orkest/databases.json · ${n} conexiones',
			'orkest.dbPanel.footerOne' => '.orkest/databases.json · 1 conexión',
			'orkest.dbPanel.noConnections' => 'Aún no hay conexiones.',
			'orkest.dbPanel.passwordRequired' => 'Contraseña no encontrada en el host. Abre esta conexión y vuelve a escribirla — se guarda en la máquina que ejecuta la base de datos, no en esta.',
			'orkest.dbMongoView.deleteDocumentTitle' => 'Eliminar documento',
			'orkest.dbMongoView.deleteDocumentMessage' => ({required Object id, required Object collection}) => '¿Eliminar el documento con _id ${id} de "${collection}"?',
			'orkest.dbMongoView.filterHint' => 'Filtro — JSON, ej.: {"status": "active"}',
			'orkest.dbMongoView.docCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 doc', other: '${n} docs', ),
			'orkest.dbMongoView.refresh' => 'Actualizar',
			'orkest.dbMongoView.insertDocument' => 'Insertar documento',
			'orkest.dbMongoView.noDocuments' => 'No hay documentos en esta colección.',
			'orkest.dbMongoView.noDocumentsMatch' => 'Ningún documento coincide con este filtro.',
			'orkest.dbMongoView.loadMore' => 'Cargar más',
			'orkest.dbMongoView.edit' => 'Editar',
			'orkest.dbMongoView.insert' => 'Insertar',
			'orkest.dbConnectionDialog.chooseFileTitle' => 'Elegir base de datos SQLite',
			'orkest.dbConnectionDialog.file' => 'Archivo',
			'orkest.dbConnectionDialog.chooseFilePlaceholder' => 'Elige un archivo SQLite…',
			'orkest.dbConnectionDialog.name' => 'Nombre',
			'orkest.dbConnectionDialog.password' => 'Contraseña',
			'orkest.dbConnectionDialog.savePassword' => 'Guardar contraseña',
			'orkest.dbConnectionDialog.allowWrites' => 'Permitir escritura (agentes)',
			'orkest.dbConnectionDialog.allowWritesHint' => 'desactivado = los agentes solo leen vía CLI',
			'orkest.dbConnectionDialog.visibleToAgents' => 'Visible para agentes',
			'orkest.dbConnectionDialog.visibleToAgentsHint' => 'desactivado = oculto en la CLI, solo en la GUI',
			'orkest.dbConnectionDialog.testing' => 'Probando conexión…',
			'orkest.dbConnectionDialog.connectionOk' => 'Conexión OK',
			'orkest.dbConnectionDialog.connectionFailed' => 'Fallo en la conexión',
			'orkest.dbConnectionDialog.editTitle' => 'Editar conexión',
			'orkest.dbConnectionDialog.newTitle' => 'Nueva conexión',
			'orkest.dbConnectionDialog.connectionString' => 'Connection string',
			'orkest.dbConnectionDialog.invalidUrl' => 'URL de conexión no válida.',
			'orkest.dbConnectionDialog.sshTunnel' => 'Túnel SSH',
			'orkest.dbConnectionDialog.sshHost' => 'Host SSH',
			'orkest.dbConnectionDialog.sshPort' => 'Puerto SSH',
			'orkest.dbConnectionDialog.sshUser' => 'Usuario SSH',
			'orkest.dbConnectionDialog.privateKey' => 'Clave privada',
			'orkest.dbConnectionDialog.choosePrivateKeyPlaceholder' => 'Elige una clave privada…',
			'orkest.dbConnectionDialog.choosePrivateKeyDialogTitle' => 'Elegir clave privada SSH',
			'orkest.dbConnectionDialog.keyPassphrase' => 'Frase de contraseña de la clave',
			'orkest.dbConnectionDialog.savePassphrase' => 'Guardar frase de contraseña',
			'orkest.dbConnectionDialog.passwordOnHost' => 'La contraseña se guarda en el host, no en esta máquina.',
			'orkest.sshPrompts.unknownSshHostTitle' => 'Host SSH desconocido',
			'orkest.sshPrompts.neverConnected' => ({required Object endpoint}) => 'Orkest Code nunca se ha conectado a ${endpoint} antes.',
			'orkest.sshPrompts.trustHint' => 'Confía solo si esta fingerprint coincide con el servidor. Puedes verificarla en el servidor con:',
			'orkest.sshPrompts.trust' => 'Confiar',
			'orkest.sshPrompts.sshKeyPassphraseTitle' => 'Frase de contraseña de la clave SSH',
			'orkest.sshPrompts.unlockMessage' => ({required Object keyPath, required Object connectionName}) => 'Desbloquea ${keyPath} para conectar "${connectionName}".',
			'orkest.sshPrompts.keptInMemoryHint' => 'Se mantiene en memoria hasta que Orkest Code se cierre. Para que los agentes usen esta conexión, activa "Guardar frase de contraseña" en la conexión.',
			'orkest.sshPrompts.unlock' => 'Desbloquear',
			'orkest.projectsRail.workspaces' => 'Workspaces',
			'orkest.projectsRail.keepAwakeOn' => 'Manteniendo este equipo despierto para acceso remoto. Haz clic para dejarlo dormir de nuevo.',
			'orkest.projectsRail.keepAwakeOff' => 'Mantener este equipo despierto para acceso remoto. Se apaga solo cuando Orkest Code se reinicia.',
			'orkest.projectsRail.keepAwakeBattery' => 'Despierto con batería. Esto consume la batería.',
			'orkest.projectsRail.keepAwakeLid' => 'Cerrar la tapa del portátil sigue poniéndolo a dormir.',
			'orkest.projectsRail.newWorkspace' => 'Nuevo workspace',
			'orkest.projectsRail.settings' => 'Configuración',
			'orkest.projectsRail.mergeToParent' => 'Fusionar en el padre',
			'orkest.projectsRail.updateFromParent' => 'Actualizar desde el padre',
			'orkest.projectsRail.forkWorktree' => 'Crear worktree derivada',
			'orkest.projectsRail.copyBranch' => 'Copiar branch',
			'orkest.projectsRail.remove' => 'Quitar',
			'orkest.projectsRail.moveToRealm' => 'Mover a realm',
			'orkest.projectsRail.copyWorkspaceId' => 'Copiar id del workspace',
			'orkest.projectsRail.rename' => 'Renombrar',
			'orkest.projectsRail.close' => 'Cerrar',
			'orkest.projectsRail.newRealm' => 'Nuevo realm…',
			'orkest.projectsRail.manageRealms' => 'Gestionar realms…',
			'orkest.projectsRail.noWorkspaces' => 'Aún no hay workspaces.',
			'orkest.projectsRail.sync' => 'Sincronizar',
			'orkest.projectsRail.pull' => 'Pull',
			'orkest.projectsRail.push' => 'Push',
			'orkest.projectsRail.createWorktree' => 'Crear worktree',
			'orkest.projectsRail.worktreeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('es'))(n, one: '1 worktree', other: '${n} worktrees', ),
			'orkest.projectsRail.expandWorktrees' => 'Expandir worktrees',
			'orkest.projectsRail.collapseWorktrees' => 'Contraer worktrees',
			'orkest.findBar.find' => 'Buscar',
			'orkest.findBar.matchCase' => 'Coincidir mayúsculas',
			'orkest.findBar.wholeWord' => 'Palabra completa',
			'orkest.findBar.useRegex' => 'Usar expresión regular',
			'orkest.findBar.previous' => 'Anterior (⇧⏎)',
			'orkest.findBar.next' => 'Siguiente (⏎)',
			'orkest.findBar.close' => 'Cerrar (Esc)',
			'orkest.findBar.badPattern' => 'Patrón inválido',
			'orkest.findBar.counter' => ({required Object current, required Object total}) => '${current} de ${total}',
			'orkest.findBar.noResults' => 'Sin resultados',
			'orkest.contentSearch.sectionSearch' => 'BÚSQUEDA',
			'orkest.contentSearch.searchInFiles' => 'Buscar en los archivos',
			'orkest.contentSearch.matchCase' => 'Coincidir mayúsculas',
			'orkest.contentSearch.wholeWord' => 'Palabra completa',
			'orkest.contentSearch.useRegex' => 'Usar expresión regular',
			'orkest.contentSearch.invalidRegex' => 'Expresión regular inválida.',
			'orkest.contentSearch.typeToSearch' => 'Escribe para buscar en todos los archivos.',
			'orkest.contentSearch.searching' => 'Buscando…',
			'orkest.contentSearch.noResults' => 'Sin resultados.',
			'orkest.topbar.collapseSidebar' => 'Contraer barra lateral',
			'orkest.topbar.toggleFiles' => 'Mostrar/ocultar archivos',
			'orkest.topbar.filesUnavailable' => 'Archivos no disponibles en Orkest Code',
			'orkest.topbar.hideKeyboard' => 'Ocultar teclado',
			'orkest.topbar.showOffice' => 'Mostrar oficina',
			'orkest.topbar.showTerminals' => 'Mostrar terminales',
			'orkest.tasks.hotReload' => 'Hot reload',
			'orkest.tasks.hotRestart' => 'Hot restart',
			'orkest.tasks.toggleDebugPaint' => 'Alternar debug paint',
			'orkest.tasks.togglePlatform' => 'Alternar plataforma',
			'orkest.tasks.quit' => 'Salir',
			'orkest.notifications.agentFinished' => 'El agente terminó',
			'orkest.notifications.open' => 'Abrir',
			'orkest.notifications.agentNeedsAction' => 'El agente necesita tu acción',
			'orkest.terminalLink.open' => 'Abrir',
			'orkest.terminalLink.revealFinder' => 'Mostrar en Finder',
			'orkest.terminalLink.revealExplorer' => 'Mostrar en el Explorador',
			'orkest.terminalLink.revealFolder' => 'Abrir carpeta contenedora',
			'orkest.terminalLink.copyPath' => 'Copiar ruta',
			'orkest.terminalLink.openLink' => 'Abrir enlace',
			'orkest.terminalLink.copyLink' => 'Copiar enlace',
			'orkest.terminal.cwdFallbackWarning' => ({required Object requested, required Object path}) => 'Aviso: la carpeta "${requested}" no existe. Esta terminal se abrió en "${path}".',
			'orkest.terminal.workspaceEnvTracked' => ({required Object keys}) => 'Aviso: el .env.orkest está rastreado por git (vino con el repositorio). Inyectado: ${keys}',
			'orkest.remoteHost.addHost' => 'Añadir host remoto',
			'orkest.remoteHost.hostName' => 'Nombre',
			'orkest.remoteHost.sshTarget' => 'Destino SSH (usuario@host)',
			'orkest.remoteHost.connecting' => ({required Object host}) => 'Conectando a ${host}…',
			'orkest.remoteHost.openingTunnel' => 'Túnel SSH',
			'orkest.remoteHost.installingServer' => 'Instalando servidor',
			'orkest.remoteHost.handshake' => ({required Object version}) => 'Servidor ${version}',
			'orkest.remoteHost.loadingWorkspace' => 'Cargando workspace…',
			'orkest.remoteHost.reconnecting' => ({required Object host}) => 'Reconectando a ${host}…',
			'orkest.remoteHost.offline' => ({required Object host}) => '${host} sin conexión',
			'orkest.remoteHost.remove' => 'Quitar',
			'orkest.remoteHost.reconnect' => 'Reconectar',
			'orkest.remoteHost.installServer' => 'Instalar servidor',
			'orkest.remoteHost.errSshUnreachable' => ({required Object host}) => 'No se puede llegar a ${host} por SSH. ¿Está encendido y con Inicio de sesión remoto activado?',
			'orkest.remoteHost.errInstallFailed' => ({required Object host}) => 'No se pudo instalar el servidor en ${host}.',
			'orkest.remoteHost.errVersionMismatch' => 'Versión del servidor incompatible; actualízalo.',
			'orkest.remoteHost.errDetail' => ({required Object detail}) => 'Detalles: ${detail}',
			'orkest.remoteHost.pickFolderTitle' => ({required Object host}) => 'Abrir carpeta en ${host}',
			'orkest.remoteHost.openHere' => 'Abrir aquí',
			'orkest.remoteHost.emptyFolder' => 'Sin subcarpetas',
			'orkest.remoteHost.newLocal' => 'Local',
			'orkest.remoteHost.newRemote' => 'Remoto',
			'orkest.remoteHost.chooseHost' => 'Elegir un host',
			'orkest.remoteHost.newHostEntry' => 'Nuevo host…',
			'orkest.remoteHost.editHost' => 'Editar host',
			'orkest.remoteHost.userLabel' => 'Usuario',
			'orkest.remoteHost.hostLabel' => 'Host / IP',
			'orkest.remoteHost.portLabel' => 'Puerto',
			'orkest.remoteHost.authLabel' => 'Autenticación',
			'orkest.remoteHost.authKey' => 'Clave SSH',
			'orkest.remoteHost.authPassword' => 'Contraseña',
			'orkest.remoteHost.passwordLabel' => 'Contraseña',
			'orkest.remoteHost.passwordKeep' => 'Deja en blanco para mantener la actual',
			'orkest.remoteHost.errUser' => 'Usuario obligatorio',
			'orkest.remoteHost.errHost' => 'Host obligatorio',
			'orkest.remoteHost.errPassword' => 'Contraseña obligatoria',
			'orkest.remoteHost.identityChoose' => 'Elegir…',
			'orkest.remoteHost.identityEmpty' => 'Ninguna clave seleccionada',
			'orkest.remoteHost.identityDialogTitle' => 'Selecciona la clave privada SSH',
			'orkest.remoteHost.errIdentity' => 'Elige la clave privada para autenticarte.',
			'orkest.remoteHost.errHostKeyUnknown' => ({required Object host}) => 'Orkest Code todavía no confía en ${host}. Conecta de nuevo y confirma la huella.',
			'orkest.remoteHost.errHostKeyChanged' => ({required Object host}) => '${host} presenta una clave SSH distinta de la guardada. Si no reinstalaste esa máquina, detente y compruébalo; si la reinstalaste, elimina la entrada antigua de ~/.ssh/known_hosts.',
			'orkest.remoteHost.errHostBundleMissing' => ({required Object host}) => '${host} es Windows pero no tiene Orkest Code instalado. El servidor remoto se instala desde el bundle de Orkest Code que ya está en esa máquina — instálalo allí e inténtalo de nuevo.',
			'orkest.remoteHost.errHostUnknownOs' => ({required Object host}) => 'No se pudo identificar el sistema de ${host}. La cuenta puede tener un shell restringido, o ninguno.',
			'orkest.remoteHost.errIdentityPublic' => 'Solo está la clave pública. Eso funciona solo si la privada está en tu agente SSH; si no, elige la privada (mismo nombre, sin .pub).',
			'orkest.remoteHost.errIdentityNotKey' => 'Ese archivo no parece una clave privada.',
			'orkest.remoteHost.errIdentityMissingFile' => 'Ese archivo ya no existe.',
			'orkest.remoteHost.errIdentityUnreadable' => 'No se pudo leer ese archivo.',
			'orkest.browserPane.back' => 'Atrás',
			'orkest.browserPane.forward' => 'Adelante',
			'orkest.browserPane.reload' => 'Recargar',
			'orkest.browserPane.urlHint' => 'Escribe la URL o dirección',
			'orkest.browserPane.go' => 'Ir',
			'orkest.documentWindow.mediaNotSupported' => 'Audio y video se abren en la ventana principal de Orkest Code.',
			'orkest.documentWindow.fileNotFound' => ({required Object path}) => 'Archivo no encontrado: ${path}',
			'orkest.gallery.intro' => 'Documentos especiales de Orkest Code para que veas lo que el agente de IA está haciendo.',
			'orkest.gallery.createErrorTitle' => 'No se pudo crear el archivo',
			'orkest.gallery.dbQuery.title' => 'Consulta de base de datos',
			'orkest.gallery.dbQuery.description' => 'Editor SQL con grilla de resultados, usando una de las conexiones registradas.',
			'orkest.gallery.kanban.title' => 'Tablero kanban',
			'orkest.gallery.kanban.description' => 'Columnas y tarjetas guardadas como markdown puro. Arrastra, edita y comenta.',
			'orkest.gallery.layout.title' => 'Layout de paneles',
			'orkest.gallery.layout.description' => 'Terminales y splits para abrir de una vez, estilo tmuxinator. Puede ejecutarse solo en worktrees nuevos.',
			'orkest.gallery.httpRequest.title' => 'Requests HTTP',
			'orkest.gallery.httpRequest.description' => 'Escribe requests en un archivo y ejecútalos con la respuesta al lado.',
			'orkest.gallery.html.title' => 'Vista HTML',
			'orkest.gallery.html.description' => 'Una página que el agente escribe y Orkest Code renderiza directo: mapa mental, diagrama, gráfico, lo que necesites.',
			'orkest.gallery.tasks.title' => 'Tareas',
			'orkest.gallery.tasks.description' => 'Comandos para ejecutar desde el panel de Tasks, como dev server, tests y build. Vive en .orkest/tasks.json.',
			'orkest.gallery.notebook.title' => 'Cuaderno',
			'orkest.gallery.notebook.description' => 'Una carpeta de notas cortas con tags. El agente escribe, tú lees y editas. También abre en Obsidian.',
			'orkest.gallery.workspaceEnv.title' => 'Env del workspace',
			'orkest.gallery.workspaceEnv.description' => 'Variables inyectadas en cada terminal de este workspace. Pon tokens o credenciales de API aquí en vez de pegarlos en el prompt del agente. Queda fuera de git.',
			'orkest.gallery.panel.title' => 'Panel',
			'orkest.gallery.panel.description' => 'Una página HTML con puente a la app: sus botones ejecutan comandos de la CLI de Orkest Code y del shell en esta máquina. Un playground para dashboards rápidos.',
			'orkest.notebook.notes' => 'Notas',
			'orkest.notebook.newNote' => 'Nueva nota',
			'orkest.notebook.searchPlaceholder' => 'Buscar notas',
			'orkest.notebook.empty' => 'Aún no hay notas. Crea una, o pídele al agente que escriba aquí.',
			'orkest.notebook.noMatch' => 'Ninguna nota coincide.',
			'orkest.notebook.selectNote' => 'Selecciona una nota',
			'orkest.notebook.reload' => 'Recargar del disco',
			'orkest.notebook.untagged' => 'sin tag',
			'orkest.notebook.saveFailed' => 'No se pudo guardar la nota',
			'orkest.notebook.createFailed' => 'No se pudo crear la nota',
			'orkest.notebook.addTag' => 'añadir tag',
			'orkest.notebook.untitled' => 'Sin título',
			'orkest.notebook.deleteNote' => 'Eliminar nota',
			'orkest.notebook.deleteConfirm' => ({required Object name}) => '¿Mover “${name}” a la papelera?',
			'orkest.notebook.imageFailed' => 'No se pudo guardar la imagen',
			'orkest.notebook.format.bold' => 'Negrita (⌘B)',
			'orkest.notebook.format.italic' => 'Cursiva (⌘I)',
			'orkest.notebook.format.strike' => 'Tachado',
			'orkest.notebook.format.heading1' => 'Título 1',
			'orkest.notebook.format.heading2' => 'Título 2',
			'orkest.notebook.format.heading3' => 'Título 3',
			'orkest.notebook.format.bullets' => 'Lista',
			'orkest.notebook.format.numbered' => 'Lista numerada',
			'orkest.notebook.format.checklist' => 'Checklist',
			'orkest.notebook.format.quote' => 'Cita',
			'orkest.notebook.format.code' => 'Código inline (⌘E)',
			'orkest.notebook.format.codeBlock' => 'Bloque de código',
			'orkest.notebook.format.link' => 'Enlace (⌘K)',
			'orkest.notebook.format.rule' => 'Divisor',
			'orkest.notebook.format.noteLink' => 'Enlace a una nota ([[…]])',
			'orkest.notebook.format.noteLinkSearch' => 'Buscar notas',
			'orkest.notebook.format.image' => 'Insertar imagen…',
			'orkest.notebook.backlinks' => 'Enlazada desde',
			'orkest.notebook.renameTag' => 'Renombrar tag',
			'orkest.notebook.deleteTag' => 'Eliminar tag',
			'orkest.notebook.deleteTagConfirm' => ({required Object name, required Object count}) => '¿Quitar “${name}” de ${count} notas? Las notas se conservan.',
			'orkest.notebook.showList' => 'Mostrar lista de notas',
			'orkest.notebook.hideList' => 'Ocultar lista de notas',
			'orkest.layoutPreview.applyFailedTitle' => 'No se pudo aplicar el diseño',
			'orkest.layoutPreview.applyInOrkest' => 'Aplicar en Orkest Code',
			'orkest.layoutPreview.applyNewWorkspace' => 'Abrir como nuevo espacio de trabajo',
			'orkest.layoutPreview.applyTo' => ({required Object workspace}) => 'Aplicar en ${workspace}',
			'orkest.layoutPreview.autorunWorktree' => 'autorun: worktree. Este diseño también se aplica solo al crear un worktree del espacio de trabajo que lo contiene.',
			'orkest.layoutPreview.command' => 'Comando',
			'orkest.layoutPreview.folder' => 'Carpeta',
			'orkest.layoutPreview.noCommand' => 'sin comando, abre un shell',
			'orkest.layoutPreview.replaceConfirm' => 'Reemplazar diseño',
			'orkest.layoutPreview.replaceMessage' => ({required Object n}) => 'Se cerrarán ${n} pestañas abiertas de este espacio de trabajo, incluidas las que tienen trabajo en curso.',
			'orkest.layoutPreview.replaceTitle' => ({required Object workspace}) => '¿Reemplazar el diseño de ${workspace}?',
			'orkest.layoutPreview.skippedTitle' => 'No se crean en este sistema',
			'orkest.layoutPreview.splitDown' => 'divide abajo',
			'orkest.layoutPreview.splitRight' => 'divide a la derecha',
			'orkest.layoutPreview.splitTab' => 'pestaña',
			'orkest.layoutPreview.subtitle' => ({required Object n}) => 'Este diseño abre ${n} terminales. Lee los comandos antes de aplicarlo.',
			'orkest.telemetry.tooltip' => 'Telemetría',
			'orkest.telemetry.title' => 'Telemetría',
			'orkest.telemetry.liveRuns' => ({required Object n}) => '${n} activos',
			'orkest.telemetry.noWorkspace' => 'Abre un workspace para ver su telemetría.',
			'orkest.telemetry.empty' => 'Nada por aquí todavía.',
			'orkest.telemetry.emptyFiltered' => 'Nada por aquí todavía.',
			'orkest.telemetry.searchHint' => 'Filtrar casos',
			'orkest.telemetry.chipOpen' => 'Abiertos',
			'orkest.telemetry.chipNew' => 'Nuevos',
			'orkest.telemetry.chipResolved' => 'Resueltos',
			'orkest.telemetry.chipIgnored' => 'Ignorados',
			'orkest.telemetry.chipWarnings' => 'Avisos',
			'orkest.telemetry.tagNew' => 'nuevo',
			'orkest.telemetry.tagRegression' => 'regresión',
			'orkest.telemetry.tagResolved' => 'resuelto',
			'orkest.telemetry.tagIgnored' => 'ignorado',
			'orkest.telemetry.srcTask' => 'task',
			'orkest.telemetry.srcWrapper' => 'orkest telemetry',
			'orkest.telemetry.run' => ({required Object id}) => 'run ${id}',
			'orkest.telemetry.resolve' => 'Marcar resuelto',
			'orkest.telemetry.ignore' => 'Ignorar (también se oculta a los agentes)',
			'orkest.telemetry.reopen' => 'Reabrir',
			'orkest.telemetry.clear' => 'Limpiar ocurrencias',
			'orkest.telemetry.clearRun' => 'Limpiar este run',
			'orkest.telemetry.clearProject' => 'Limpiar proyecto',
			'orkest.telemetry.openFile' => ({required Object location}) => 'Abrir ${location}',
			'orkest.telemetry.showInTerminal' => 'Ver en la terminal',
			'orkest.telemetry.copyCommand' => 'Copiar comando de la CLI',
			'orkest.telemetry.copied' => 'Copiado',
			'orkest.telemetry.statusOpen' => 'Abierto',
			'orkest.telemetry.statusResolved' => 'Resuelto',
			'orkest.telemetry.statusIgnored' => 'Ignorado',
			'orkest.telemetry.occurrences' => 'Ocurrencias',
			'orkest.telemetry.inRuns' => ({required Object n}) => 'en ${n} runs',
			'orkest.telemetry.first' => 'Primera',
			'orkest.telemetry.last' => 'Última',
			'orkest.telemetry.origin' => 'Origen',
			'orkest.telemetry.sectionStack' => 'Stack',
			'orkest.telemetry.stackHint' => 'frames del proyecto destacados · clic abre el archivo',
			'orkest.telemetry.sectionCorrelated' => 'Log correlacionado',
			'orkest.telemetry.correlatedHint' => 'el JSON más cercano antes del error, en el mismo run',
			'orkest.telemetry.none' => 'ninguno',
			'orkest.telemetry.sectionRuns' => 'Ocurrencias por run',
			'orkest.telemetry.runsHint' => 'misma clave (cwd, comando): así se calculan nuevo y regresión',
			'orkest.telemetry.sectionContext' => 'Contexto crudo',
			'orkest.telemetry.contextHint' => 'líneas de la terminal alrededor de la última ocurrencia',
			'orkest.telemetry.current' => 'actual',
			'orkest.telemetry.fingerprintHint' => ({required Object location}) => 'fingerprint = tipo + mensaje normalizado + ${location}',
			'orkest.telemetry.blameUncommitted' => 'cambiado en el working tree',
			'orkest.telemetry.blameCommit' => ({required Object ago, required Object sha}) => 'cambiado ${ago} (${sha})',
			'orkest.telemetry.justNow' => 'ahora',
			'orkest.telemetry.minutesAgo' => ({required Object n}) => 'hace ${n} min',
			'orkest.telemetry.hoursAgo' => ({required Object n}) => 'hace ${n} h',
			'orkest.telemetry.daysAgo' => ({required Object n}) => 'hace ${n} d',
			'orkest.telemetry.resolvedToast' => 'Resuelto. Si vuelve en un run futuro, reaparece como regresión.',
			'orkest.telemetry.ignoredToast' => 'Ignorado. Los agentes ya no lo ven (salvo --include-ignored).',
			'orkest.telemetry.clearedToast' => 'Ocurrencias borradas. Las reglas de triaje se mantienen.',
			'orkest.telemetry.byHuman' => 'por ti',
			'orkest.telemetry.byAgent' => 'por el agente',
			'orkest.telemetry.caseTabTitle' => ({required Object type, required Object file}) => '${type} · ${file}',
			'orkest.telemetry.srcApp' => 'App',
			'orkest.telemetry.chipApp' => 'Orkest Code',
			'orkest.panelView.unavailable' => 'Los paneles necesitan la web view integrada, que todavía no existe en Linux.',
			'orkest.panelView.openInBrowser' => 'Abrir en el navegador',
			'orkest.panelView.openAsHtml' => 'Abrir como HTML',
			'settings.language.title' => 'Idioma',
			'settings.language.system' => 'Sistema',
			'settings.language.english' => 'Inglés',
			'settings.language.portugueseBr' => 'Portugués (BR)',
			'settings.language.spanish' => 'Español',
			'settings.page.header.back' => 'Atrás',
			'settings.page.header.title' => 'Configuración',
			'settings.page.nav.general' => 'General',
			'settings.page.nav.appearance' => 'Apariencia',
			'settings.page.nav.terminal' => 'Terminal',
			'settings.page.nav.language' => 'Lenguaje',
			'settings.page.nav.shortcuts' => 'Atajos',
			'settings.page.nav.notifications' => 'Notificaciones',
			'settings.page.nav.automations' => 'Automatizaciones',
			'settings.page.nav.remoteHosts' => 'Hosts remotos',
			'settings.page.general.sectionEditor' => 'Editor',
			'settings.page.general.editorEngineTitle' => 'Motor',
			'settings.page.general.editorEngineOrkest' => 'Orkest Code (predeterminado)',
			'settings.page.general.editorEngineNeovim' => 'Neovim',
			'settings.page.general.neovimChecking' => 'Buscando Neovim…',
			'settings.page.general.neovimNotFound' => 'Neovim no se encontró en la PATH de tu shell.',
			'settings.page.general.neovimRefresh' => 'Comprobar de nuevo',
			'settings.page.general.showOrkestTitle' => 'Mostrar terminal de Orkest Code',
			'settings.page.general.showOrkestDesc' => 'Mantiene un workspace sin carpeta, solo de terminal, fijado en la parte superior de la barra lateral. Desactivarlo cierra sus terminales.',
			'settings.page.general.launchAtStartupTitle' => 'Iniciar al arrancar',
			'settings.page.general.launchAtStartupDesc' => 'Inicia Orkest Code automáticamente cuando inicias sesión en tu computadora.',
			'settings.page.general.sectionUpdates' => 'Actualizaciones',
			'settings.page.general.checkUpdatesTitle' => 'Buscar actualizaciones',
			'settings.page.general.checkUpdatesDesc' => 'Con qué frecuencia Orkest Code debe buscar nuevas versiones.',
			'settings.page.general.updateFrequency.daily' => 'Diariamente',
			'settings.page.general.updateFrequency.weekly' => 'Semanalmente',
			'settings.page.general.updateFrequency.monthly' => 'Mensualmente',
			'settings.page.general.updateFrequency.never' => 'Nunca',
			'settings.page.general.developerModeTitle' => 'Modo desarrollador',
			'settings.page.general.developerModeDesc' => 'Registra los errores y avisos del propio Orkest Code en una base aparte de la Telemetría (chip “Orkest Code”) y activa las métricas de rendimiento. Solo sirve a quien mantiene la app.',
			'settings.page.diagnostics.sectionTitle' => 'Diagnóstico',
			'settings.page.diagnostics.logFileTitle' => 'Archivo de registro',
			'settings.page.diagnostics.logFileDesc' => ({required Object days, required Object path}) => 'Los errores y eventos de inicio se registran aquí, y se conservan durante ${days} días.\n${path}',
			'settings.page.diagnostics.unavailable' => 'no disponible',
			'settings.page.diagnostics.reveal' => 'Mostrar',
			'settings.page.diagnostics.reportTitle' => 'Reportar un problema',
			'settings.page.diagnostics.reportDesc' => 'Abre un issue prellenado con tu versión, SO y registro reciente. Nada se envía automáticamente — lo revisas antes.',
			'settings.page.diagnostics.reportButton' => 'Reportar…',
			'settings.page.diagnostics.reportDialogTitle' => 'Informe de problema',
			'settings.page.diagnostics.reportDialogError' => 'Reportado manualmente desde Configuración.',
			'settings.page.diagnostics.reportDialogDescription' => 'Describe qué salió mal en el issue. El registro reciente está incluido abajo y en "Copiar detalles".',
			'settings.page.storage.sectionTitle' => 'Almacenamiento',
			'settings.page.storage.locationTitle' => 'Ubicación de almacenamiento',
			'settings.page.storage.locationDesc' => ({required Object root}) => 'Orkest Code guarda aquí sus proyectos, diseños y configuración. Apúntalo a una carpeta sincronizada para respaldarlo.\n${root}',
			'settings.page.storage.useDefault' => 'Usar predeterminado',
			'settings.page.storage.working' => 'Procesando…',
			'settings.page.storage.change' => 'Cambiar…',
			'settings.page.storage.resetTitle' => 'Restablecer Orkest Code',
			'settings.page.storage.resetDesc' => 'Elimina todos los datos locales — proyectos, diseños, configuración e historial de terminal — y vuelve a la ubicación predeterminada.',
			'settings.page.storage.resetButton' => 'Restablecer…',
			'settings.page.storage.resetConfirm' => 'Restablecer',
			'settings.page.storage.resetDialogTitle' => '¿Restablecer Orkest Code?',
			'settings.page.storage.resetDialogContent' => 'Esto elimina permanentemente todos los datos locales de Orkest Code — proyectos, diseños, configuración e historial de terminal. Esto no se puede deshacer. Orkest Code se cerrará para que puedas empezar de nuevo.',
			'settings.page.storage.restartRequiredTitle' => 'Reinicio necesario',
			'settings.page.storage.restartChangeFolderMessage' => ({required Object path}) => 'Orkest Code usará esta carpeta a partir del próximo inicio:\n${path}',
			'settings.page.storage.restartUseDefaultMessage' => 'Orkest Code usará la ubicación predeterminada del sistema a partir del próximo inicio. Tus datos en la carpeta personalizada permanecen intactos.',
			'settings.page.storage.restartResetMessage' => 'Se borraron todos los datos de Orkest Code. Reinicia para empezar de nuevo.',
			'settings.page.storage.later' => 'Más tarde',
			'settings.page.storage.quitOrkest' => 'Salir de Orkest Code',
			'settings.page.storage.chooseFolderDialogTitle' => 'Elige una carpeta para los datos de Orkest Code',
			'settings.page.terminal.sectionDefaultTerminal' => 'Terminal predeterminado',
			'settings.page.terminal.engineTitle' => 'Motor',
			'settings.page.terminal.engineDesc' => 'Usado por nuevas pestañas de terminal y buffers de salida de tasks. Las pestañas abiertas mantienen su motor actual.',
			'settings.page.terminal.shellTitle' => 'Shell',
			'settings.page.terminal.shellDesc' => 'Qué shell abren las nuevas pestañas de terminal. La flecha junto al + sigue abriendo cualquier otro, solo para esa pestaña.',
			'settings.page.terminal.noWslMessage' => 'No se encontraron distros de WSL. Instala una (wsl.exe --install) y reinicia Orkest Code para verla listada aquí.',
			'settings.page.terminal.sectionBehavior' => 'Comportamiento',
			'settings.page.terminal.closeOnExitTitle' => 'Cerrar la pestaña cuando el shell termine',
			'settings.page.terminal.closeOnExitDesc' => 'Cuando un shell termina por sí solo (exit, Ctrl-D), cierra su pestaña en lugar de dejar un terminal muerto.',
			'settings.page.appearance.sectionTheme' => 'Tema',
			'settings.page.appearance.themeTitle' => 'Tema',
			'settings.page.appearance.themeDesc' => 'Colores de la app, resaltado de código y paleta del terminal.',
			'settings.page.appearance.modeTitle' => 'Modo',
			'settings.page.appearance.modeDesc' => 'Qué variante del tema usar.',
			'settings.page.appearance.modeOnlyDark' => ({required Object theme}) => '"${theme}" solo trae la variante oscura, así que esto no tiene efecto.',
			'settings.page.appearance.modeOnlyLight' => ({required Object theme}) => '"${theme}" solo trae la variante clara, así que esto no tiene efecto.',
			'settings.page.appearance.themeFileTitle' => 'Archivo de tema',
			'settings.page.appearance.themeFileDesc' => 'Importa un tema desde un archivo JSON, o exporta el activo.',
			'settings.page.appearance.previewCode' => 'Código',
			'settings.page.appearance.previewTerminal' => 'Terminal',
			'settings.page.appearance.themeSystem' => 'Sistema',
			'settings.page.appearance.themeLight' => 'Claro',
			'settings.page.appearance.themeDark' => 'Oscuro',
			'settings.page.appearance.sectionFonts' => 'Fuentes',
			'settings.page.appearance.interfaceFontTitle' => 'Fuente de la interfaz',
			'settings.page.appearance.interfaceFontDesc' => 'Se usa en toda la aplicación. Vacío = predeterminado del sistema.',
			'settings.page.appearance.interfaceSizeTitle' => 'Tamaño de la interfaz',
			'settings.page.appearance.codeFontTitle' => 'Fuente del código',
			'settings.page.appearance.codeFontDesc' => 'Código y diffs. Vacío = predeterminado del sistema.',
			'settings.page.appearance.codeSizeTitle' => 'Tamaño del código',
			'settings.page.appearance.terminalFontTitle' => 'Fuente del terminal',
			'settings.page.appearance.terminalFontDesc' => 'Solo la terminal. Vacío = predeterminado del sistema.',
			'settings.page.appearance.terminalSizeTitle' => 'Tamaño de la terminal',
			'settings.page.appearance.terminalSizeDesc' => 'Apagado = sigue el tamaño del código.',
			'settings.page.appearance.terminalSizeInherit' => 'Seguir el código',
			'settings.page.appearance.terminalWeightTitle' => 'Grosor de la terminal',
			'settings.page.appearance.terminalWeightDesc' => 'Las pantallas de baja densidad engrosan los trazos. El automático los afina solo ahí y no toca la Retina.',
			'settings.page.appearance.terminalWeightAuto' => 'Automático (según la pantalla)',
			'settings.page.appearance.terminalWeightLight' => 'Fino',
			'settings.page.appearance.terminalWeightNormal' => 'Normal',
			'settings.page.appearance.terminalWeightMedium' => 'Medio',
			'settings.page.appearance.terminalWeightSemiBold' => 'Seminegrita',
			'settings.page.appearance.sectionConversation' => 'Conversación',
			'settings.page.appearance.pinUserMessageTitle' => 'Fijar mensaje del usuario',
			'settings.page.appearance.pinUserMessageDesc' => 'La pregunta permanece fija arriba mientras la respuesta se desplaza.',
			'settings.page.appearance.importTheme' => 'Importar…',
			'settings.page.appearance.exportTheme' => 'Exportar…',
			'settings.page.appearance.deleteTheme' => 'Eliminar',
			'settings.page.appearance.importThemeDialog' => 'Elige un archivo de tema',
			'settings.page.appearance.exportThemeDialog' => 'Guardar tema como',
			'settings.page.appearance.themeImported' => ({required Object name}) => 'Tema "${name}" importado.',
			'settings.page.appearance.themeExported' => 'Tema guardado.',
			'settings.page.appearance.themeDeleted' => 'Tema eliminado.',
			'settings.page.appearance.fontPickerTitle' => 'Elegir una fuente',
			'settings.page.appearance.fontPickerSearch' => 'Buscar fuentes',
			'settings.page.appearance.fontPickerEmpty' => 'No hay ninguna fuente coincidente en esta máquina.',
			'settings.page.appearance.fontPickerBundled' => 'incluida',
			'settings.page.appearance.fontPickerCustom' => '¿No está en la lista? Escribe el nombre exacto de la familia.',
			'settings.page.appearance.fontPickerCustomHint' => 'Nombre de la familia',
			'settings.page.appearance.fontPickerUse' => 'Usar',
			'settings.page.appearance.fontPickerDefault' => 'Predeterminada',
			'settings.page.appearance.fontMissing' => 'No se encontró en esta máquina — usando el respaldo.',
			'settings.page.appearance.sectionLayout' => 'Diseño',
			'settings.page.appearance.swapPanelsTitle' => 'Invertir paneles',
			'settings.page.appearance.swapPanelsDesc' => 'Coloca los workspaces a la derecha y archivos, búsqueda, git y base de datos a la izquierda.',
			'settings.page.notifications.sectionTitle' => 'Notificaciones',
			'settings.page.notifications.enableTitle' => 'Activar notificaciones',
			'settings.page.notifications.enableDesc' => 'Avisarme cuando un agente termine un turno y la ventana no esté enfocada.',
			'settings.page.notifications.systemPermissionTitle' => 'Permiso del sistema',
			'settings.page.notifications.grantedDesc' => 'Orkest Code tiene permiso para enviar notificaciones.',
			'settings.page.notifications.notGrantedDesc' => 'macOS aún no ha concedido acceso a las notificaciones.',
			'settings.page.notifications.granted' => 'Concedido',
			'settings.page.notifications.requestPermission' => 'Solicitar permiso',
			'settings.page.notifications.soundsTitle' => 'Sonidos',
			'settings.page.notifications.soundVolumeTitle' => 'Volumen',
			'settings.page.notifications.soundTurnDone' => 'Turno completado',
			'settings.page.notifications.soundTurnDoneDesc' => 'Un agente terminó su turno.',
			_ => null,
		} ?? switch (path) {
			'settings.page.notifications.soundActionRequired' => 'Acción requerida',
			'settings.page.notifications.soundActionRequiredDesc' => 'Un agente está esperando tu aprobación o respuesta.',
			'settings.page.notifications.soundDefault' => 'Predeterminado',
			'settings.page.notifications.soundCustom' => ({required Object name}) => 'Personalizado: ${name}',
			'settings.page.notifications.soundChooseFile' => 'Elegir archivo',
			'settings.page.notifications.soundReset' => 'Volver al predeterminado',
			'settings.page.notifications.soundOnActiveTab' => 'Reproducir también con la pestaña activa',
			'settings.page.notifications.soundPreview' => 'Escuchar',
			'settings.page.shortcuts.notCustomizable' => 'Los atajos de teclado aún no se pueden personalizar.',
			'settings.page.languages.sectionFormatting' => 'FORMATO',
			'settings.page.languages.formatOnSaveTitle' => 'Formatear al guardar',
			'settings.page.languages.formatOnSaveDesc' => 'Formatea el archivo automáticamente al guardar (⌘S).',
			'settings.page.languages.sectionLanguageServers' => 'SERVIDORES DE LENGUAJE',
			'settings.page.languages.footerNote' => 'Los errores y el formato usan el language server de cada lenguaje. Orkest Code no instala servidores — usa lo que ya está en tu máquina. ● responde · ○ no encontrado o comando inválido (instala el servidor o ajusta el comando).',
			'settings.page.languages.serverCommandLabel' => 'Comando del language server',
			'settings.page.languages.formatterCommandLabel' => 'Comando del formateador (opcional)',
			'settings.page.languages.formatterHint' => 'Formateador externo con el marcador %FILE%. Tiene prioridad sobre el formateador del LSP cuando está definido.',
			'settings.page.languages.resetToDefault' => 'Restablecer al predeterminado',
			'settings.page.languages.saveAndRestart' => 'Guardar y reiniciar',
			'settings.page.languages.statusResponds' => 'El servidor responde',
			'settings.page.languages.statusNotFound' => 'Servidor no encontrado o comando inválido',
			'settings.page.automations.sectionCommitMessages' => 'Mensajes de commit',
			'settings.page.automations.harness' => 'Harness',
			'settings.page.automations.harnessDiscovering' => 'Buscando harnesses de línea de comandos instalados…',
			'settings.page.automations.harnessNoneFound' => 'No se encontró ningún harness compatible en el PATH.',
			'settings.page.automations.harnessConfiguredUnavailable' => ({required Object harness}) => '${harness} está configurado, pero no disponible.',
			'settings.page.automations.harnessChoose' => 'Elige la CLI usada para generar mensajes de commit.',
			'settings.page.automations.harnessRefresh' => 'Actualizar harnesses instalados',
			'settings.page.automations.notConfigured' => 'Sin configurar',
			'settings.page.automations.model' => 'Modelo',
			'settings.page.automations.modelUnavailable' => 'La lista de modelos no está disponible hasta encontrar el harness.',
			'settings.page.automations.modelCliOnly' => 'Este harness usa el modelo predeterminado de su CLI.',
			'settings.page.automations.modelCliDefault' => 'Predeterminado de la CLI',
			'settings.page.automations.modelAuto' => 'Auto',
			'settings.page.automations.modelSearch' => ({required Object count}) => 'Buscar entre ${count} modelos…',
			'settings.page.automations.modelAutoRouted' => 'Este harness elige el modelo automáticamente.',
			'settings.page.automations.modelAccountOnly' => 'Solo se muestran los modelos disponibles en tu cuenta.',
			'settings.page.automations.generateFromSourceControl' => 'Generar desde Control de versiones',
			'settings.page.automations.generateFromSourceControlDescription' => 'Orkest Code envía solo el diff seleccionado y los asuntos de los commits recientes. Los patrones habituales de credenciales y los archivos sensibles se redactan antes de ejecutar el harness.',
			'settings.page.automations.discoveryFailed' => 'No se pudieron descubrir los harnesses de automatización instalados.',
			'settings.page.automations.staleModel' => ({required Object model, required Object harness}) => 'El modelo "${model}" ya no está disponible para ${harness}. Se usará el predeterminado de la CLI; elige otro modelo en Configuración si lo necesitas.',
			'settings.page.automations.recommendedSuffix' => 'Recomendado',
			'settings.remoteHosts.title' => 'Hosts remotos',
			'settings.remoteHosts.description' => 'Máquinas a las que accedes por SSH. Añadir un host aquí es lo mismo que hacerlo desde el menú "+" del workspace.',
			'settings.remoteHosts.empty' => 'Aún no hay hosts remotos.',
			'settings.remoteHosts.add' => 'Añadir host',
			'settings.remoteHosts.edit' => 'Editar',
			'settings.remoteHosts.reconnect' => 'Reconectar',
			'settings.remoteHosts.remove' => 'Eliminar',
			'settings.remoteHosts.removeTitle' => 'Eliminar host',
			'settings.remoteHosts.removeMessage' => ({required Object name}) => '¿Eliminar "${name}" y todos sus workspaces? No se borra nada en el host.',
			'settings.remoteHosts.workspacesCount' => ({required Object count}) => '${count} workspace(s)',
			'settings.remoteHosts.deviceKeyTitle' => 'Clave de este dispositivo',
			'settings.remoteHosts.deviceKeyDesc' => 'Añade esta clave pública a ~/.ssh/authorized_keys del host para que este dispositivo pueda conectarse.',
			'settings.remoteHosts.deviceKeyCopy' => 'Copiar clave pública',
			'settings.remoteHosts.deviceKeyCopied' => 'Clave pública copiada',
			'settings.remoteHosts.statusConnected' => 'Conectado',
			'settings.remoteHosts.statusConnecting' => 'Conectando…',
			'settings.remoteHosts.statusReconnecting' => 'Reconectando…',
			'settings.remoteHosts.statusOffline' => 'Sin conexión',
			'settings.remoteHosts.statusIdle' => 'No conectado',
			'settings.remoteHosts.helpTitle' => 'Cómo funciona',
			'settings.remoteHosts.helpBody' => 'Orkest Code se conecta a tu máquina por SSH y habla con un pequeño servidor que ejecuta las terminales, archivos y git allí. El host debe tener Orkest Code (escritorio) o el orkest-server instalado y en ejecución, y la clave pública de este dispositivo añadida en su ~/.ssh/authorized_keys.',
			'automation.error.unavailable' => ({required Object harness}) => '${harness} no está instalado o no está en el PATH.',
			'automation.error.modelUnavailable' => ({required Object model, required Object harness}) => 'El modelo "${model}" no está disponible para ${harness}. Elige otro modelo en Configuración.',
			'automation.error.authentication' => ({required Object harness, required Object detail}) => '${harness}: ${detail}',
			'automation.error.timeout' => ({required Object harness, required Object seconds}) => '${harness} no respondió en ${seconds} segundos.',
			'automation.error.cancelled' => 'Se canceló la generación del mensaje de commit.',
			'automation.error.process' => ({required Object harness, required Object detail}) => '${harness}: ${detail}',
			'automation.error.processNoDetail' => ({required Object harness}) => '${harness} no pudo generar un mensaje de commit.',
			'automation.error.invalidResponse' => 'La automatización devolvió un mensaje de commit vacío.',
			'automation.error.busy' => 'Ya se está generando otro mensaje de commit.',
			'automation.error.unknown' => 'La automatización no pudo generar un mensaje de commit.',
			'automation.error.noWorkspace' => 'Ningún workspace seleccionado.',
			'automation.error.fileOutsideWorkspace' => 'El archivo está fuera de las raíces del workspace.',
			'automation.error.fileUnreadable' => ({required Object detail}) => 'No se pudo leer el archivo: ${detail}',
			'automation.error.binaryFile' => 'No se puede generar un mensaje de commit para un archivo binario.',
			'automation.error.noFileChanges' => 'No hay cambios que describir en este archivo.',
			'automation.error.noStagedChanges' => 'No hay cambios en stage que describir.',
			'automation.error.multipleRepositories' => 'Los cambios en stage pertenecen a varios repositorios. Genéralos por separado.',
			'automation.error.diffUnavailable' => 'No se pudo leer el diff.',
			'automation.error.notConfigured' => 'Configura un harness de mensajes de commit en Configuración.',
			'fileOperation.error.alreadyExists' => ({required Object name}) => 'Ya existe: “${name}”.',
			'fileOperation.error.notFound' => ({required Object name}) => 'No se encontró: “${name}”.',
			'fileOperation.error.invalidPath' => 'Ruta inválida.',
			'fileOperation.error.emptyName' => 'El nombre no puede estar vacío.',
			'fileOperation.error.noWorkspace' => 'Ningún workspace seleccionado.',
			'fileOperation.error.cannotMoveIntoItself' => 'No se puede mover una carpeta dentro de sí misma.',
			'fileOperation.error.clipboardEmpty' => 'El portapapeles está vacío.',
			'fileOperation.error.notScratchTab' => 'Esta pestaña no es un archivo temporal.',
			'fileOperation.error.writeFailed' => 'No se pudo escribir el archivo.',
			'fileOperation.error.formatterEmptyCommand' => 'Comando de formato vacío.',
			'fileOperation.error.formatterMissingPlaceholder' => 'El comando de formato debe incluir el marcador %FILE%.',
			'fileOperation.error.formatterTimeout' => 'El formateador agotó el tiempo de espera.',
			'fileOperation.error.formatterExitCode' => ({required Object code}) => 'El formateador terminó con el código ${code}.',
			'fileOperation.error.formatterFailed' => 'No se pudo ejecutar el formateador.',
			'fileOperation.error.osFailure' => ({required Object detail}) => '${detail}',
			'fileOperation.error.nameHasSlash' => 'El nombre no puede contener “/”.',
			'fileOperation.error.invalidName' => 'Nombre inválido.',
			'fileOperation.error.remoteDropUnsupported' => 'Soltar archivos en un workspace remoto todavía no está soportado.',
			'theme.error.io' => 'No se pudo leer o escribir el archivo del tema.',
			'theme.error.ioDetail' => ({required Object detail}) => 'No se pudo leer o escribir el archivo del tema: ${detail}',
			'theme.error.malformedJson' => ({required Object detail}) => 'Este archivo no es JSON válido: ${detail}',
			'theme.error.invalidTheme' => 'Este archivo no es un tema válido.',
			'theme.error.reservedId' => 'Este tema usa el id de un tema nativo. Cambia el "id" en el archivo e impórtalo de nuevo.',
			'theme.error.notAnObject' => ({required Object field}) => 'Se esperaba un objeto en "${field}".',
			'theme.error.missingField' => ({required Object field}) => 'Falta el campo obligatorio "${field}".',
			'theme.error.badColor' => ({required Object value, required Object field}) => '"${value}" en "${field}" no es un color. Usa #RGB, #RRGGBB o #RRGGBBAA.',
			'theme.error.unknownBase' => ({required Object value}) => 'Tema base "${value}" desconocido en "extends".',
			'theme.error.noVariants' => 'El tema no declara ningún variant. Añade "dark", "light" o ambos en "variants".',
			_ => null,
		};
	}
}
