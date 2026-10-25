///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$core$en core = Translations$core$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$orkest$en orkest = Translations$orkest$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$automation$en automation = Translations$automation$en.internal(_root);
	late final Translations$fileOperation$en fileOperation = Translations$fileOperation$en.internal(_root);
	late final Translations$theme$en theme = Translations$theme$en.internal(_root);
}

// Path: core
class Translations$core$en {
	Translations$core$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$core$bootstrapError$en bootstrapError = Translations$core$bootstrapError$en.internal(_root);
	late final Translations$core$macosNotifications$en macosNotifications = Translations$core$macosNotifications$en.internal(_root);
	late final Translations$core$appErrorView$en appErrorView = Translations$core$appErrorView$en.internal(_root);
	late final Translations$core$errorReportDialog$en errorReportDialog = Translations$core$errorReportDialog$en.internal(_root);
	late final Translations$core$windowControls$en windowControls = Translations$core$windowControls$en.internal(_root);
	late final Translations$core$crash$en crash = Translations$core$crash$en.internal(_root);
	late final Translations$core$menu$en menu = Translations$core$menu$en.internal(_root);
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Create'
	String get create => 'Create';

	/// en: 'Got it'
	String get gotIt => 'Got it';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Test'
	String get test => 'Test';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: 'Loading…'
	String get loading => 'Loading…';

	/// en: 'Checking…'
	String get checking => 'Checking…';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Restart'
	String get restart => 'Restart';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Dismiss'
	String get dismiss => 'Dismiss';

	/// en: 'Report'
	String get report => 'Report';

	/// en: 'Copy code'
	String get copyCode => 'Copy code';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'No results'
	String get noResults => 'No results';
}

// Path: orkest
class Translations$orkest$en {
	Translations$orkest$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$orkest$officeWorld$en officeWorld = Translations$orkest$officeWorld$en.internal(_root);
	late final Translations$orkest$confirmDialog$en confirmDialog = Translations$orkest$confirmDialog$en.internal(_root);
	late final Translations$orkest$neovim$en neovim = Translations$orkest$neovim$en.internal(_root);
	late final Translations$orkest$worktreeCreateDialog$en worktreeCreateDialog = Translations$orkest$worktreeCreateDialog$en.internal(_root);
	late final Translations$orkest$commitMessageDialog$en commitMessageDialog = Translations$orkest$commitMessageDialog$en.internal(_root);
	late final Translations$orkest$tasksPanel$en tasksPanel = Translations$orkest$tasksPanel$en.internal(_root);
	late final Translations$orkest$orkestPage$en orkestPage = Translations$orkest$orkestPage$en.internal(_root);
	late final Translations$orkest$welcomeView$en welcomeView = Translations$orkest$welcomeView$en.internal(_root);
	late final Translations$orkest$paneView$en paneView = Translations$orkest$paneView$en.internal(_root);
	late final Translations$orkest$fileTreePanel$en fileTreePanel = Translations$orkest$fileTreePanel$en.internal(_root);
	late final Translations$orkest$fileViewer$en fileViewer = Translations$orkest$fileViewer$en.internal(_root);
	late final Translations$orkest$workspaceSettingsDialog$en workspaceSettingsDialog = Translations$orkest$workspaceSettingsDialog$en.internal(_root);
	late final Translations$orkest$realmDialogs$en realmDialogs = Translations$orkest$realmDialogs$en.internal(_root);
	late final Translations$orkest$dbRedisTable$en dbRedisTable = Translations$orkest$dbRedisTable$en.internal(_root);
	late final Translations$orkest$dbQueryView$en dbQueryView = Translations$orkest$dbQueryView$en.internal(_root);
	late final Translations$orkest$httpView$en httpView = Translations$orkest$httpView$en.internal(_root);
	late final Translations$orkest$kanbanView$en kanbanView = Translations$orkest$kanbanView$en.internal(_root);
	late final Translations$orkest$dbPanel$en dbPanel = Translations$orkest$dbPanel$en.internal(_root);
	late final Translations$orkest$dbMongoView$en dbMongoView = Translations$orkest$dbMongoView$en.internal(_root);
	late final Translations$orkest$dbConnectionDialog$en dbConnectionDialog = Translations$orkest$dbConnectionDialog$en.internal(_root);
	late final Translations$orkest$sshPrompts$en sshPrompts = Translations$orkest$sshPrompts$en.internal(_root);
	late final Translations$orkest$projectsRail$en projectsRail = Translations$orkest$projectsRail$en.internal(_root);
	late final Translations$orkest$findBar$en findBar = Translations$orkest$findBar$en.internal(_root);
	late final Translations$orkest$contentSearch$en contentSearch = Translations$orkest$contentSearch$en.internal(_root);
	late final Translations$orkest$topbar$en topbar = Translations$orkest$topbar$en.internal(_root);
	late final Translations$orkest$tasks$en tasks = Translations$orkest$tasks$en.internal(_root);
	late final Translations$orkest$notifications$en notifications = Translations$orkest$notifications$en.internal(_root);
	late final Translations$orkest$terminalLink$en terminalLink = Translations$orkest$terminalLink$en.internal(_root);
	late final Translations$orkest$terminal$en terminal = Translations$orkest$terminal$en.internal(_root);
	late final Translations$orkest$remoteHost$en remoteHost = Translations$orkest$remoteHost$en.internal(_root);
	late final Translations$orkest$browserPane$en browserPane = Translations$orkest$browserPane$en.internal(_root);
	late final Translations$orkest$documentWindow$en documentWindow = Translations$orkest$documentWindow$en.internal(_root);
	late final Translations$orkest$gallery$en gallery = Translations$orkest$gallery$en.internal(_root);
	late final Translations$orkest$notebook$en notebook = Translations$orkest$notebook$en.internal(_root);
	late final Translations$orkest$layoutPreview$en layoutPreview = Translations$orkest$layoutPreview$en.internal(_root);
	late final Translations$orkest$telemetry$en telemetry = Translations$orkest$telemetry$en.internal(_root);
	late final Translations$orkest$panelView$en panelView = Translations$orkest$panelView$en.internal(_root);
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$language$en language = Translations$settings$language$en.internal(_root);
	late final Translations$settings$page$en page = Translations$settings$page$en.internal(_root);
	late final Translations$settings$remoteHosts$en remoteHosts = Translations$settings$remoteHosts$en.internal(_root);
}

// Path: automation
class Translations$automation$en {
	Translations$automation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$automation$error$en error = Translations$automation$error$en.internal(_root);
}

// Path: fileOperation
class Translations$fileOperation$en {
	Translations$fileOperation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$fileOperation$error$en error = Translations$fileOperation$error$en.internal(_root);
}

// Path: theme
class Translations$theme$en {
	Translations$theme$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$theme$error$en error = Translations$theme$error$en.internal(_root);
}

// Path: core.bootstrapError
class Translations$core$bootstrapError$en {
	Translations$core$bootstrapError$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Failed to initialize Orkest Code'
	String get title => 'Failed to initialize Orkest Code';

	/// en: 'Retry'
	String get retry => 'Retry';
}

// Path: core.macosNotifications
class Translations$core$macosNotifications$en {
	Translations$core$macosNotifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Enable Notifications on macOS'
	String get title => 'Enable Notifications on macOS';

	/// en: 'Notifications are currently disabled in your system settings. Follow the steps below to enable them:'
	String get intro => 'Notifications are currently disabled in your system settings. Follow the steps below to enable them:';

	/// en: 'Open System Settings on your Mac.'
	String get step1 => 'Open System Settings on your Mac.';

	/// en: 'Navigate to the Notifications section in the left sidebar.'
	String get step2 => 'Navigate to the Notifications section in the left sidebar.';

	/// en: 'Find and select the Orkest Code application from the list.'
	String get step3 => 'Find and select the Orkest Code application from the list.';

	/// en: 'Toggle the Allow Notifications switch on.'
	String get step4 => 'Toggle the Allow Notifications switch on.';

	/// en: 'Tip: If the app does not appear in the list, close and reopen it to trigger its registration in the system.'
	String get tip => 'Tip: If the app does not appear in the list, close and reopen it to trigger its registration in the system.';

	/// en: 'Got it'
	String get gotIt => 'Got it';
}

// Path: core.appErrorView
class Translations$core$appErrorView$en {
	Translations$core$appErrorView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This part of the app failed to render'
	String get renderFailed => 'This part of the app failed to render';

	/// en: 'Details'
	String get details => 'Details';

	/// en: 'Render error'
	String get renderErrorTitle => 'Render error';
}

// Path: core.errorReportDialog
class Translations$core$errorReportDialog$en {
	Translations$core$errorReportDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Something went wrong. The details below were saved to the log — you can report them so it gets fixed.'
	String get defaultDescription => 'Something went wrong. The details below were saved to the log — you can report them so it gets fixed.';

	/// en: 'Copy details'
	String get copyDetails => 'Copy details';

	/// en: 'Report issue'
	String get reportIssue => 'Report issue';
}

// Path: core.windowControls
class Translations$core$windowControls$en {
	Translations$core$windowControls$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Minimize'
	String get minimize => 'Minimize';

	/// en: 'Maximize'
	String get maximize => 'Maximize';

	/// en: 'Close'
	String get close => 'Close';
}

// Path: core.crash
class Translations$core$crash$en {
	Translations$core$crash$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Unexpected shutdown'
	String get title => 'Unexpected shutdown';

	/// en: 'Orkest Code closed unexpectedly'
	String get bannerTitle => 'Orkest Code closed unexpectedly';

	/// en: 'Report'
	String get report => 'Report';

	/// en: 'Dismiss'
	String get dismiss => 'Dismiss';

	/// en: 'The previous session (version ${version}) ended without shutting down cleanly. Want to report it? The log is included and you can review everything before sending.'
	String crashMessage({required Object version}) => 'The previous session (version ${version}) ended without shutting down cleanly. Want to report it? The log is included and you can review everything before sending.';

	/// en: 'Session started at ${startedAt} (pid ${pid}) ended without a clean shutdown.'
	String crashError({required Object startedAt, required Object pid}) => 'Session started at ${startedAt} (pid ${pid}) ended without a clean shutdown.';

	/// en: 'No error was captured — the app was terminated by the system. The log below is from that session and is the most useful part.'
	String get crashDescription => 'No error was captured — the app was terminated by the system. The log below is from that session and is the most useful part.';
}

// Path: core.menu
class Translations$core$menu$en {
	Translations$core$menu$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings…'
	String get settings => 'Settings…';

	/// en: 'Check for Updates…'
	String get checkForUpdates => 'Check for Updates…';

	/// en: 'File'
	String get file => 'File';

	/// en: 'New Terminal'
	String get newTerminal => 'New Terminal';

	/// en: 'Open Workspace'
	String get openWorkspace => 'Open Workspace';

	/// en: 'Go to File…'
	String get goToFile => 'Go to File…';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Discard'
	String get discard => 'Discard';

	/// en: 'Format'
	String get format => 'Format';

	/// en: 'View'
	String get view => 'View';

	/// en: 'Toggle Workspace Panel'
	String get toggleWorkspacePanel => 'Toggle Workspace Panel';

	/// en: 'Toggle Files'
	String get toggleFiles => 'Toggle Files';

	/// en: 'Split Right'
	String get splitRight => 'Split Right';

	/// en: 'Split Down'
	String get splitDown => 'Split Down';

	/// en: 'Focus Pane'
	String get focusPane => 'Focus Pane';

	/// en: 'Left (⌘⌥←)'
	String get focusLeft => 'Left  (⌘⌥←)';

	/// en: 'Right (⌘⌥→)'
	String get focusRight => 'Right  (⌘⌥→)';

	/// en: 'Up (⌘⌥↑)'
	String get focusUp => 'Up  (⌘⌥↑)';

	/// en: 'Down (⌘⌥↓)'
	String get focusDown => 'Down  (⌘⌥↓)';

	/// en: 'Select Tab'
	String get selectTab => 'Select Tab';

	/// en: 'Tab ${n}'
	String tabN({required Object n}) => 'Tab ${n}';

	/// en: 'Last Tab'
	String get lastTab => 'Last Tab';

	/// en: 'Previous Workspace'
	String get previousWorkspace => 'Previous Workspace';

	/// en: 'Next Workspace'
	String get nextWorkspace => 'Next Workspace';

	/// en: 'Zoom In'
	String get zoomIn => 'Zoom In';

	/// en: 'Zoom Out'
	String get zoomOut => 'Zoom Out';

	/// en: 'Actual Size'
	String get actualSize => 'Actual Size';

	/// en: 'Window'
	String get window => 'Window';

	/// en: 'Quit'
	String get quit => 'Quit';

	/// en: 'Minimize'
	String get minimize => 'Minimize';

	/// en: 'Zoom'
	String get zoom => 'Zoom';
}

// Path: orkest.officeWorld
class Translations$orkest$officeWorld$en {
	Translations$orkest$officeWorld$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Reception'
	String get reception => 'Reception';

	/// en: 'Café'
	String get cafe => 'Café';

	/// en: 'Restrooms'
	String get restrooms => 'Restrooms';

	/// en: 'Lounge'
	String get lounge => 'Lounge';

	/// en: 'Office agents'
	String get rosterTitle => 'Office agents';

	/// en: 'Search agents or projects'
	String get rosterSearch => 'Search agents or projects';

	/// en: 'No active agents found'
	String get rosterEmpty => 'No active agents found';

	/// en: 'Activity'
	String get activityFeed => 'Activity';

	/// en: 'Observed activity will appear here.'
	String get activityEmpty => 'Observed activity will appear here.';

	/// en: 'Collapse agent list'
	String get collapseRoster => 'Collapse agent list';

	/// en: 'Collapse activity feed'
	String get collapseFeed => 'Collapse activity feed';

	/// en: 'Agents'
	String get reopenRoster => 'Agents';

	/// en: 'Activity'
	String get reopenFeed => 'Activity';

	/// en: 'Working'
	String get working => 'Working';

	/// en: 'Waiting'
	String get waiting => 'Waiting';

	/// en: 'Available'
	String get idle => 'Available';

	/// en: 'Agent profile'
	String get agentProfile => 'Agent profile';

	/// en: 'Project'
	String get project => 'Project';

	/// en: 'Agent'
	String get provider => 'Agent';

	/// en: 'Current status'
	String get currentStatus => 'Current status';

	/// en: 'Follow character'
	String get followAgent => 'Follow character';

	/// en: 'Stop following'
	String get stopFollowingAgent => 'Stop following';

	/// en: 'Center character'
	String get centerAgent => 'Center character';

	/// en: 'Current Orkest Code session'
	String get sessionDuration => 'Current Orkest Code session';

	/// en: 'Working directory'
	String get workingDirectory => 'Working directory';

	/// en: 'Model, token and tool statistics are not collected by Orkest Code yet.'
	String get statsPending => 'Model, token and tool statistics are not collected by Orkest Code yet.';

	/// en: 'Recent activity in this run'
	String get recentActivity => 'Recent activity in this run';

	/// en: 'Received a request'
	String get promptReceived => 'Received a request';

	/// en: 'Thinking'
	String get agentThinking => 'Thinking';

	/// en: 'Response sent'
	String get agentResponded => 'Response sent';

	/// en: 'Something went wrong'
	String get activityError => 'Something went wrong';

	/// en: 'Reading a file'
	String get readingFile => 'Reading a file';

	/// en: 'Searching the code'
	String get searchingCode => 'Searching the code';

	/// en: 'Editing a file'
	String get editingFile => 'Editing a file';

	/// en: 'Writing a file'
	String get writingFile => 'Writing a file';

	/// en: 'Terminal command'
	String get runningCommand => 'Terminal command';

	/// en: 'Running tests'
	String get runningTests => 'Running tests';

	/// en: 'Searching the web'
	String get browsingWeb => 'Searching the web';

	/// en: 'Organizing tasks'
	String get organizingTasks => 'Organizing tasks';

	/// en: 'Calling subagents'
	String get callingSubagents => 'Calling subagents';

	/// en: 'Tool completed'
	String get toolCompleted => 'Tool completed';

	/// en: 'Using tool'
	String get usingTool => 'Using tool';

	/// en: 'Edit agent name'
	String get editAgentName => 'Edit agent name';

	/// en: 'Agent name'
	String get agentName => 'Agent name';

	/// en: 'Working in terminal'
	String get workingInTerminal => 'Working in terminal';

	/// en: 'Needs you in terminal'
	String get waitingInTerminal => 'Needs you in terminal';

	/// en: 'Respond in terminal'
	String get waitingBubble => 'Respond in terminal';

	/// en: 'Respond'
	String get respond => 'Respond';

	/// en: 'Dismiss notification'
	String get dismissNotification => 'Dismiss notification';

	/// en: 'Edit character'
	String get editAppearance => 'Edit character';

	/// en: 'Randomize'
	String get randomizeAppearance => 'Randomize';

	/// en: 'Reset to random'
	String get resetAppearance => 'Reset to random';

	/// en: 'Skin'
	String get skin => 'Skin';

	/// en: 'Hair'
	String get hair => 'Hair';

	/// en: 'Facial hair'
	String get beard => 'Facial hair';

	/// en: 'Eyes'
	String get eyes => 'Eyes';

	/// en: 'Top'
	String get top => 'Top';

	/// en: 'Bottom'
	String get bottom => 'Bottom';

	/// en: 'Shoes'
	String get shoes => 'Shoes';

	/// en: 'Accessory'
	String get accessory => 'Accessory';

	/// en: 'Turn completed'
	String get turnCompleted => 'Turn completed';

	/// en: 'Subagent failed'
	String get subagentFailed => 'Subagent failed';

	/// en: 'Subagent interrupted'
	String get subagentInterrupted => 'Subagent interrupted';

	/// en: 'Open terminal'
	String get openTerminal => 'Open terminal';

	/// en: 'Interact in Office'
	String get interactInOffice => 'Interact in Office';

	/// en: 'Live terminal'
	String get liveTerminal => 'Live terminal';

	/// en: 'Type into the terminal…'
	String get terminalInputPlaceholder => 'Type into the terminal…';

	/// en: 'Input goes to the original session. Use the response options shown by the agent in this terminal.'
	String get terminalOfficeHint => 'Input goes to the original session. Use the response options shown by the agent in this terminal.';

	/// en: 'Office appearance'
	String get appearance => 'Office appearance';

	/// en: 'Seasonal theme'
	String get officeTheme => 'Seasonal theme';

	/// en: 'Automatic'
	String get themeAuto => 'Automatic';

	/// en: 'Original'
	String get themeNone => 'Original';

	/// en: 'Christmas'
	String get themeChristmas => 'Christmas';

	/// en: 'Halloween'
	String get themeHalloween => 'Halloween';

	/// en: 'Show agent names'
	String get showNames => 'Show agent names';

	/// en: 'Activity bubbles'
	String get bubbles => 'Activity bubbles';

	/// en: 'All'
	String get bubblesAll => 'All';

	/// en: 'Important'
	String get bubblesImportant => 'Important';

	/// en: 'None'
	String get bubblesNone => 'None';

	/// en: 'Office movement'
	String get movement => 'Office movement';

	/// en: 'Calm'
	String get movementCalm => 'Calm';

	/// en: 'Normal'
	String get movementNormal => 'Normal';

	/// en: 'Lively'
	String get movementLively => 'Lively';

	/// en: 'Day and night'
	String get daylight => 'Day and night';

	/// en: 'Office sounds'
	String get sounds => 'Office sounds';

	/// en: 'Volume'
	String get soundVolume => 'Volume';

	/// en: 'Alerts and completed tasks'
	String get soundAlerts => 'Alerts and completed tasks';

	/// en: 'Keyboard'
	String get soundKeys => 'Keyboard';

	/// en: 'Elevator'
	String get soundElevator => 'Elevator';

	/// en: 'Ping-pong and arcade'
	String get soundSocial => 'Ping-pong and arcade';

	/// en: 'Automatic'
	String get daylightAuto => 'Automatic';

	/// en: 'Always day'
	String get daylightDay => 'Always day';

	/// en: 'Always night'
	String get daylightNight => 'Always night';

	/// en: 'Social life'
	String get socialLife => 'Social life';

	/// en: '${count} office coins'
	String gameCoins({required Object count}) => '${count} office coins';

	/// en: '${count} earned through activity'
	String earnedWorking({required Object count}) => '${count} earned through activity';

	/// en: '${wins} wins · ${losses} losses'
	String matchRecord({required Object wins, required Object losses}) => '${wins} wins · ${losses} losses';

	/// en: 'Personality'
	String get personality => 'Personality';

	/// en: 'Friendships'
	String get friendships => 'Friendships';

	/// en: 'Rivalries'
	String get rivals => 'Rivalries';

	/// en: 'Coin history'
	String get socialLedger => 'Coin history';

	/// en: 'Office social life'
	String get socialActivity => 'Office social life';

	/// en: 'Delegated by ${name}'
	String delegatedBy({required Object name}) => 'Delegated by ${name}';

	/// en: 'Waiting for a command'
	String get shellWaiting => 'Waiting for a command';

	/// en: 'Office game — no real monetary value'
	String get socialEconomy => 'Office game — no real monetary value';
}

// Path: orkest.confirmDialog
class Translations$orkest$confirmDialog$en {
	Translations$orkest$confirmDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Unsaved changes'
	String get unsavedChangesTitle => 'Unsaved changes';

	/// en: '“${fileName}” has unsaved changes. Save them before closing?'
	String unsavedChangesMessage({required Object fileName}) => '“${fileName}” has unsaved changes. Save them before closing?';

	/// en: 'Don't save'
	String get dontSave => 'Don\'t save';

	/// en: 'Save & close'
	String get saveAndClose => 'Save & close';
}

// Path: orkest.neovim
class Translations$orkest$neovim$en {
	Translations$orkest$neovim$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Neovim is not available. Opening in Orkest Code instead.'
	String get unavailable => 'Neovim is not available. Opening in Orkest Code instead.';

	/// en: 'Could not reach Neovim. Opening in Orkest Code instead.'
	String get openFailed => 'Could not reach Neovim. Opening in Orkest Code instead.';

	/// en: 'Unsaved Neovim buffers'
	String get unsavedTitle => 'Unsaved Neovim buffers';

	/// en: 'Neovim has modified buffers. Close the tab and discard those changes?'
	String get unsavedMessage => 'Neovim has modified buffers. Close the tab and discard those changes?';

	/// en: 'Close anyway'
	String get closeAnyway => 'Close anyway';
}

// Path: orkest.worktreeCreateDialog
class Translations$orkest$worktreeCreateDialog$en {
	Translations$orkest$worktreeCreateDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Fork worktree'
	String get forkTitle => 'Fork worktree';

	/// en: 'Create worktree'
	String get createTitle => 'Create worktree';

	/// en: 'New worktree branched from ${root}.'
	String forkSubtitle({required Object root}) => 'New worktree branched from ${root}.';

	/// en: 'New feature in ${root} — new branch from the current HEAD.'
	String createSubtitle({required Object root}) => 'New feature in ${root} — new branch from the current HEAD.';

	/// en: 'feat/minha-feature'
	String get namePlaceholder => 'feat/minha-feature';

	/// en: 'No spaces in the name.'
	String get errorWhitespace => 'No spaces in the name.';

	/// en: 'Invalid character for a branch name.'
	String get errorInvalidChar => 'Invalid character for a branch name.';

	/// en: 'Invalid sequence (e.g. "..", "//", starting/ending with "/").'
	String get errorInvalidSequence => 'Invalid sequence (e.g. "..", "//", starting/ending with "/").';

	/// en: 'Reserved position (do not start with "-"/"." or end with ".lock").'
	String get errorReserved => 'Reserved position (do not start with "-"/"." or end with ".lock").';

	/// en: 'A branch with that name already exists.'
	String get errorDuplicateBranch => 'A branch with that name already exists.';

	/// en: 'A worktree with that name already exists.'
	String get errorDuplicateWorktree => 'A worktree with that name already exists.';

	/// en: 'Cannot create branch '${target}' because it conflicts with the existing branch '${existing}'.'
	String errorBranchHierarchyConflict({required Object target, required Object existing}) => 'Cannot create branch \'${target}\' because it conflicts with the existing branch \'${existing}\'.';

	/// en: 'A branch with a conflicting hierarchy already exists.'
	String get errorBranchHierarchicalConflictGeneral => 'A branch with a conflicting hierarchy already exists.';

	/// en: 'Fork'
	String get fork => 'Fork';

	/// en: 'This repository has a post-checkout hook.'
	String get postCheckoutHint => 'This repository has a post-checkout hook.';

	/// en: 'Running…'
	String get running => 'Running…';

	/// en: 'Advanced Settings'
	String get advancedSettings => 'Advanced Settings';

	/// en: 'Copy ignored files (.gitignore)'
	String get copyIgnored => 'Copy ignored files (.gitignore)';

	/// en: 'Copies files ignored by .gitignore (e.g. .env, local keys) to the new worktree.'
	String get copyIgnoredDesc => 'Copies files ignored by .gitignore (e.g. .env, local keys) to the new worktree.';

	/// en: 'Copy untracked files'
	String get copyUntracked => 'Copy untracked files';

	/// en: 'Copies new or modified files that haven't been staged yet.'
	String get copyUntrackedDesc => 'Copies new or modified files that haven\'t been staged yet.';

	/// en: 'Base branch'
	String get baseBranch => 'Base branch';

	/// en: 'The branch from which the new worktree and branch will be created.'
	String get baseBranchDesc => 'The branch from which the new worktree and branch will be created.';

	/// en: 'Fetch remote branch'
	String get fetchRemote => 'Fetch remote branch';

	/// en: 'Run git fetch to guarantee the base branch is confirmed before creating the worktree.'
	String get fetchRemoteDesc => 'Run git fetch to guarantee the base branch is confirmed before creating the worktree.';

	/// en: 'Search branch...'
	String get searchBranch => 'Search branch...';

	/// en: 'Back'
	String get back => 'Back';
}

// Path: orkest.commitMessageDialog
class Translations$orkest$commitMessageDialog$en {
	Translations$orkest$commitMessageDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Commit'
	String get commitTitle => 'Commit';

	/// en: 'Stage and Commit'
	String get stageAndCommitTitle => 'Stage and Commit';

	/// en: 'Commit "${fileName}" only.'
	String scopeNote({required Object fileName}) => 'Commit "${fileName}" only.';

	/// en: 'fix: short summary of the change'
	String get placeholder => 'fix: short summary of the change';

	/// en: 'The first line (subject) cannot be empty.'
	String get errorEmptySubject => 'The first line (subject) cannot be empty.';

	/// en: 'Subject too short (min ${min} characters).'
	String errorTooShort({required Object min}) => 'Subject too short (min ${min} characters).';

	/// en: 'Subject too long (max ${max} characters).'
	String errorTooLong({required Object max}) => 'Subject too long (max ${max} characters).';

	/// en: 'Subject should not end with a period.'
	String get errorTrailingPeriod => 'Subject should not end with a period.';

	/// en: 'Subject contains control characters.'
	String get errorControlChars => 'Subject contains control characters.';

	/// en: 'Leave the second line blank (git subject/body separator).'
	String get errorBlankSecondLine => 'Leave the second line blank (git subject/body separator).';

	/// en: 'Generate commit message'
	String get generate => 'Generate commit message';

	/// en: 'Generate with ${harness}'
	String generateWith({required Object harness}) => 'Generate with ${harness}';

	/// en: 'Generating…'
	String get generating => 'Generating…';

	/// en: 'Cancel generation'
	String get cancelGeneration => 'Cancel generation';
}

// Path: orkest.tasksPanel
class Translations$orkest$tasksPanel$en {
	Translations$orkest$tasksPanel$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Reload tasks'
	String get reloadTasksTooltip => 'Reload tasks';

	/// en: 'Restart'
	String get restartTooltip => 'Restart';

	/// en: 'Stop'
	String get stopTooltip => 'Stop';

	/// en: 'Run'
	String get runTooltip => 'Run';

	/// en: '${label} (sends '${key}')'
	String sendsKeyTooltip({required Object label, required Object key}) => '${label} (sends \'${key}\')';

	/// en: 'Starting…'
	String get startingTooltip => 'Starting…';

	/// en: 'Stopping…'
	String get stoppingTooltip => 'Stopping…';

	/// en: 'Switch profile'
	String get switchProfileTooltip => 'Switch profile';

	/// en: 'More keys'
	String get moreKeysTooltip => 'More keys';

	/// en: 'TASKS'
	String get sectionTasks => 'TASKS';

	/// en: 'No tasks detected in this project.'
	String get noTasks => 'No tasks detected in this project.';

	/// en: 'Create tasks.json'
	String get createTasksJson => 'Create tasks.json';

	/// en: 'Generate Compose tasks'
	String get generateComposeTasks => 'Generate Compose tasks';

	/// en: 'Choose a Compose engine'
	String get selectComposeEngine => 'Choose a Compose engine';

	/// en: 'Docker Compose or Podman Compose was not found.'
	String get noComposeEngine => 'Docker Compose or Podman Compose was not found.';

	/// en: 'The active file is not a valid Compose file with services.'
	String get invalidComposeFile => 'The active file is not a valid Compose file with services.';

	/// en: 'tasks.json is invalid. No changes were written.'
	String get invalidTasksJson => 'tasks.json is invalid. No changes were written.';

	/// en: 'Kept non-Compose tasks with conflicting labels: ${labels}'
	String composeConflicts({required Object labels}) => 'Kept non-Compose tasks with conflicting labels: ${labels}';
}

// Path: orkest.orkestPage
class Translations$orkest$orkestPage$en {
	Translations$orkest$orkestPage$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose the project folder'
	String get chooseProjectFolderDialogTitle => 'Choose the project folder';

	/// en: 'Choose the workspace folder'
	String get chooseWorkspaceFolderDialogTitle => 'Choose the workspace folder';

	/// en: 'Workspace renamed'
	String get workspaceRenamedTitle => 'Workspace renamed';

	/// en: 'The new name "${name}" will only be sent to agents after restarting the workspace or the application.'
	String workspaceRenamedMessage({required Object name}) => 'The new name "${name}" will only be sent to agents after restarting the workspace or the application.';

	/// en: 'Sync — ${label}'
	String syncTitle({required Object label}) => 'Sync — ${label}';

	/// en: 'Pull — ${label}'
	String pullTitle({required Object label}) => 'Pull — ${label}';

	/// en: 'Push — ${label}'
	String pushTitle({required Object label}) => 'Push — ${label}';

	/// en: 'Update from Parent — ${name}'
	String updateFromParentTitle({required Object name}) => 'Update from Parent — ${name}';

	/// en: 'Merge to Parent — ${name}'
	String mergeToParentTitle({required Object name}) => 'Merge to Parent — ${name}';

	/// en: 'Worktree merged and removed.'
	String get worktreeMergedAndRemoved => 'Worktree merged and removed.';

	/// en: 'Nothing was changed.'
	String get nothingWasChanged => 'Nothing was changed.';

	/// en: 'New realm'
	String get newRealmTitle => 'New realm';

	/// en: 'Close workspace'
	String get closeWorkspaceTitle => 'Close workspace';

	/// en: 'Close "${name}"? The agents in this workspace will be terminated. The folder on disk is kept.'
	String closeWorkspaceMessage({required Object name}) => 'Close "${name}"? The agents in this workspace will be terminated. The folder on disk is kept.';

	/// en: 'Close'
	String get closeAction => 'Close';

	/// en: 'Remove worktree'
	String get removeWorktreeTitle => 'Remove worktree';

	/// en: 'Remove "${name}"? The worktree folder and the branch will be deleted and the agents in this fork will be terminated.${warn}'
	String removeWorktreeMessage({required Object name, required Object warn}) => 'Remove "${name}"? The worktree folder and the branch will be deleted and the agents in this fork will be terminated.${warn}';

	/// en: ' Warning: the branch "${name}" has not been merged yet — removing it (git branch -D) discards the unmerged work.'
	String removeWorktreeWarning({required Object name}) => '\n\nWarning: the branch "${name}" has not been merged yet — removing it (git branch -D) discards the unmerged work.';

	/// en: 'Failed to remove worktree'
	String get failedToRemoveWorktreeTitle => 'Failed to remove worktree';

	/// en: 'Open layout'
	String get openLayoutTitle => 'Open layout';

	/// en: 'Replace the current layout?'
	String get replaceLayoutTitle => 'Replace the current layout?';

	/// en: '(one) {1 tab will be closed, including one with a running process.} (other) {${n} tabs will be closed, including ones with running processes.}'
	String replaceLayoutMessage({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 tab will be closed, including one with a running process.',
		other: '${n} tabs will be closed, including ones with running processes.',
	);

	/// en: 'Replace'
	String get replaceLayoutConfirm => 'Replace';

	/// en: 'Restart server'
	String get restartServerTooltip => 'Restart server';

	/// en: 'No LSP available'
	String get noLspAvailable => 'No LSP available';

	/// en: 'running'
	String get lspRunning => 'running';

	/// en: 'stopped'
	String get lspStopped => 'stopped';
}

// Path: orkest.welcomeView
class Translations$orkest$welcomeView$en {
	Translations$orkest$welcomeView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome to Orkest Code'
	String get title => 'Welcome to Orkest Code';

	/// en: 'Open a folder or connect to a remote host to start.'
	String get subtitle => 'Open a folder or connect to a remote host to start.';

	/// en: 'Create workspace'
	String get createWorkspace => 'Create workspace';

	/// en: 'Open local folder'
	String get openLocalFolder => 'Open local folder';

	/// en: 'Connect to host'
	String get connectHost => 'Connect to host';

	/// en: 'Configure host'
	String get configureHost => 'Configure host';

	/// en: 'Add workspace'
	String get addWorkspace => 'Add workspace';
}

// Path: orkest.paneView
class Translations$orkest$paneView$en {
	Translations$orkest$paneView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Close pane?'
	String get closePaneTitle => 'Close pane?';

	/// en: 'This closes all ${count} tab(s) in this pane and ends the agents/terminals in it.'
	String closePaneMessage({required Object count}) => 'This closes all ${count} tab(s) in this pane and ends the agents/terminals in it.';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Close others'
	String get closeOtherTabs => 'Close others';

	/// en: 'Close to the right'
	String get closeTabsToTheRight => 'Close to the right';

	/// en: 'Close all'
	String get closeAllTabs => 'Close all';

	/// en: 'Close tabs?'
	String get closeTabsTitle => 'Close tabs?';

	/// en: 'This closes ${count} tab(s) and ends the agents/terminals in them.'
	String closeTabsMessage({required Object count}) => 'This closes ${count} tab(s) and ends the agents/terminals in them.';

	/// en: 'All tabs'
	String get allTabs => 'All tabs';

	/// en: 'Pin tab'
	String get pinTab => 'Pin tab';

	/// en: 'Open in new window'
	String get openInNewWindow => 'Open in new window';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Open as markdown'
	String get openAsMarkdown => 'Open as markdown';

	/// en: 'Open as board'
	String get openAsBoard => 'Open as board';

	/// en: 'Reset Title'
	String get resetTitle => 'Reset Title';

	/// en: 'Copy Id'
	String get copyId => 'Copy Id';

	/// en: 'Restart'
	String get restartTab => 'Restart';

	/// en: 'New tab'
	String get newTab => 'New tab';

	/// en: 'New terminal…'
	String get newTerminal => 'New terminal…';

	/// en: 'Split right'
	String get splitRight => 'Split right';

	/// en: 'Split down'
	String get splitDown => 'Split down';

	/// en: 'Close pane'
	String get closePane => 'Close pane';

	/// en: 'Drop here to move the tab'
	String get dropHereToMove => 'Drop here to move the tab';

	/// en: 'Dock as tab'
	String get dockAsTab => 'Dock as tab';

	/// en: 'Open browser'
	String get openBrowser => 'Open browser';

	/// en: 'Open terminal'
	String get openTerminal => 'Open terminal';

	/// en: 'Open as layout'
	String get openAsLayout => 'Open as layout';

	/// en: 'Open as YAML'
	String get openAsYaml => 'Open as YAML';

	/// en: 'Open as panel'
	String get openAsPanel => 'Open as panel';

	/// en: 'Open as HTML'
	String get openAsHtml => 'Open as HTML';
}

// Path: orkest.fileTreePanel
class Translations$orkest$fileTreePanel$en {
	Translations$orkest$fileTreePanel$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'View Diff'
	String get viewDiff => 'View Diff';

	/// en: 'Commit'
	String get commit => 'Commit';

	/// en: 'Stage and Commit'
	String get stageAndCommit => 'Stage and Commit';

	/// en: 'Unstage'
	String get unstage => 'Unstage';

	/// en: 'Stage Changes'
	String get stageChanges => 'Stage Changes';

	/// en: 'Discard Changes'
	String get discardChanges => 'Discard Changes';

	/// en: 'Enter a commit message.'
	String get enterCommitMessage => 'Enter a commit message.';

	/// en: 'Commit is unavailable for this workspace.'
	String get commitUnavailable => 'Commit is unavailable for this workspace.';

	/// en: 'Git error'
	String get gitErrorTitle => 'Git error';

	/// en: 'Delete new file?'
	String get deleteNewFileTitle => 'Delete new file?';

	/// en: 'Discard changes?'
	String get discardChangesTitle => 'Discard changes?';

	/// en: '"${name}" is a new file and cannot be restored. Delete it?'
	String deleteNewFileMessage({required Object name}) => '"${name}" is a new file and cannot be restored. Delete it?';

	/// en: 'Discard all changes in "${name}"? Deleted files will be restored.'
	String discardOneMessage({required Object name}) => 'Discard all changes in "${name}"? Deleted files will be restored.';

	/// en: 'Discard'
	String get discard => 'Discard';

	/// en: 'Delete all new files?'
	String get deleteAllNewFilesTitle => 'Delete all new files?';

	/// en: 'All ${count} files are new and will be deleted. This cannot be undone.'
	String allNewFilesMessage({required Object count}) => 'All ${count} files are new and will be deleted. This cannot be undone.';

	/// en: 'Discard changes in ${count} tracked file(s)?${extra}'
	String discardTrackedMessage({required Object count, required Object extra}) => 'Discard changes in ${count} tracked file(s)?${extra}';

	/// en: ' ${count} new file(s) will be kept.'
	String discardTrackedExtra({required Object count}) => ' ${count} new file(s) will be kept.';

	/// en: 'Delete All'
	String get deleteAll => 'Delete All';

	/// en: 'Delete?'
	String get deleteQuestionTitle => 'Delete?';

	/// en: 'Move “${name}” to the Trash?'
	String moveToTrash({required Object name}) => 'Move “${name}” to the Trash?';

	/// en: 'Permanently delete “${name}”? This can’t be undone.'
	String permanentlyDelete({required Object name}) => 'Permanently delete “${name}”? This can’t be undone.';

	/// en: 'Could not delete'
	String get couldNotDeleteTitle => 'Could not delete';

	/// en: 'Move?'
	String get moveQuestionTitle => 'Move?';

	/// en: 'Move “${name}” to “${dest}”?'
	String moveMessage({required Object name, required Object dest}) => 'Move “${name}” to “${dest}”?';

	/// en: 'Move'
	String get moveAction => 'Move';

	/// en: 'Could not move'
	String get couldNotMoveTitle => 'Could not move';

	/// en: 'Could not paste'
	String get couldNotPasteTitle => 'Could not paste';

	/// en: 'Files'
	String get filesTooltip => 'Files';

	/// en: 'Search'
	String get searchTooltip => 'Search';

	/// en: 'Source Control'
	String get sourceControlTooltip => 'Source Control';

	/// en: 'Database'
	String get databaseTooltip => 'Database';

	/// en: 'FILES'
	String get sectionFiles => 'FILES';

	/// en: 'New file'
	String get newFile => 'New file';

	/// en: 'New folder'
	String get newFolder => 'New folder';

	/// en: 'Refresh'
	String get refreshTooltip => 'Refresh';

	/// en: 'Collapse all folders'
	String get collapseAll => 'Collapse all folders';

	/// en: 'SOURCE CONTROL'
	String get sectionSourceControl => 'SOURCE CONTROL';

	/// en: 'View as List'
	String get viewAsList => 'View as List';

	/// en: 'View as Tree'
	String get viewAsTree => 'View as Tree';

	/// en: 'No folder — open a workspace.'
	String get noFolderMessage => 'No folder — open a workspace.';

	/// en: 'Amend'
	String get amend => 'Amend';

	/// en: 'Commit Message'
	String get commitMessagePlaceholder => 'Commit Message';

	/// en: 'Amend Commit'
	String get amendCommit => 'Amend Commit';

	/// en: 'last commit'
	String get lastCommit => 'last commit';

	/// en: 'Open in Finder'
	String get openInFinder => 'Open in Finder';

	/// en: 'Open in Explorer'
	String get openInExplorer => 'Open in Explorer';

	/// en: 'Open in file manager'
	String get openInFileManager => 'Open in file manager';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Open with'
	String get openWith => 'Open with';

	/// en: 'Open in new window'
	String get openInNewWindow => 'Open in new window';

	/// en: 'Open layout'
	String get openLayout => 'Open layout';

	/// en: 'Open as markdown'
	String get openAsMarkdown => 'Open as markdown';

	/// en: 'Show git diff'
	String get showGitDiff => 'Show git diff';

	/// en: 'Open terminal'
	String get createTerminal => 'Open terminal';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Cut'
	String get cut => 'Cut';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Copy relative path'
	String get copyRelativePath => 'Copy relative path';

	/// en: 'Copy absolute path'
	String get copyAbsolutePath => 'Copy absolute path';

	/// en: 'Rename failed.'
	String get renameFailed => 'Rename failed.';

	/// en: 'No changes.'
	String get noChanges => 'No changes.';

	/// en: 'STAGED CHANGES (${count})'
	String stagedChangesHeader({required Object count}) => 'STAGED CHANGES (${count})';

	/// en: 'CHANGES (${count})'
	String changesHeader({required Object count}) => 'CHANGES (${count})';

	/// en: 'Discard All Changes'
	String get discardAllChanges => 'Discard All Changes';

	/// en: 'Unstage All Changes'
	String get unstageAllChanges => 'Unstage All Changes';

	/// en: 'Stage All Changes'
	String get stageAllChanges => 'Stage All Changes';

	/// en: 'Discard Folder Changes'
	String get discardFolderChanges => 'Discard Folder Changes';

	/// en: 'Unstage Folder Changes'
	String get unstageFolderChanges => 'Unstage Folder Changes';

	/// en: 'Stage Folder Changes'
	String get stageFolderChanges => 'Stage Folder Changes';

	/// en: 'Generate commit message'
	String get generateCommitMessage => 'Generate commit message';

	/// en: 'Generate with ${harness}'
	String generateWith({required Object harness}) => 'Generate with ${harness}';

	/// en: 'Unavailable while amending a commit'
	String get generateUnavailableWhileAmending => 'Unavailable while amending a commit';

	/// en: 'Cancel generation'
	String get cancelGeneration => 'Cancel generation';

	/// en: 'Changes'
	String get changes => 'Changes';

	/// en: 'History'
	String get history => 'History';

	/// en: 'Repository'
	String get historyRepository => 'Repository';

	/// en: 'No Git repository available.'
	String get historyNoRepository => 'No Git repository available.';

	/// en: 'No commits found.'
	String get historyEmpty => 'No commits found.';

	/// en: 'Could not load Git history.'
	String get historyLoadFailed => 'Could not load Git history.';

	/// en: 'Untitled commit'
	String get historyUntitledCommit => 'Untitled commit';

	/// en: 'now'
	String get historyNow => 'now';

	/// en: '${count}m ago'
	String historyMinutesAgo({required Object count}) => '${count}m ago';

	/// en: '${count}h ago'
	String historyHoursAgo({required Object count}) => '${count}h ago';

	/// en: 'yesterday'
	String get historyYesterday => 'yesterday';

	/// en: '1d ago'
	String get historyDayAgo => '1d ago';

	/// en: '${count}d ago'
	String historyDaysAgo({required Object count}) => '${count}d ago';

	/// en: 'Files changed'
	String get historyFiles => 'Files changed';

	/// en: 'No files changed.'
	String get historyFilesEmpty => 'No files changed.';

	/// en: 'Could not load changed files.'
	String get historyFilesLoadFailed => 'Could not load changed files.';

	/// en: 'Empty tree'
	String get diffEmptyTree => 'Empty tree';

	/// en: 'Original ${ref}'
	String diffOriginal({required Object ref}) => 'Original ${ref}';

	/// en: 'Modified ${ref}'
	String diffModified({required Object ref}) => 'Modified ${ref}';

	/// en: 'Working tree'
	String get diffWorkingTree => 'Working tree';

	/// en: 'Binary file - no text diff.'
	String get diffBinaryFile => 'Binary file - no text diff.';

	/// en: 'No changes.'
	String get diffNoChanges => 'No changes.';

	/// en: 'Could not read the diff: ${detail}'
	String diffError({required Object detail}) => 'Could not read the diff: ${detail}';

	/// en: 'Gallery'
	String get galleryTooltip => 'Gallery';

	/// en: 'GALLERY'
	String get sectionGallery => 'GALLERY';

	/// en: 'Open as HTML'
	String get openAsHtml => 'Open as HTML';

	/// en: 'Copy here?'
	String get importQuestionTitle => 'Copy here?';

	/// en: 'Copy ${count} items into “${dest}”?'
	String importMessage({required Object count, required Object dest}) => 'Copy ${count} items into “${dest}”?';

	/// en: 'Copy'
	String get importAction => 'Copy';

	/// en: 'Could not copy'
	String get couldNotImportTitle => 'Could not copy';

	/// en: 'Open in ${harness}'
	String openInAgent({required Object harness}) => 'Open in ${harness}';
}

// Path: orkest.fileViewer
class Translations$orkest$fileViewer$en {
	Translations$orkest$fileViewer$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Can't open this file.'
	String get cantOpen => 'Can\'t open this file.';

	/// en: 'Could not load the image.'
	String get couldNotLoadImage => 'Could not load the image.';

	/// en: 'Preview'
	String get preview => 'Preview';

	/// en: 'Source'
	String get source => 'Source';

	/// en: 'Reload'
	String get reload => 'Reload';
}

// Path: orkest.workspaceSettingsDialog
class Translations$orkest$workspaceSettingsDialog$en {
	Translations$orkest$workspaceSettingsDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose workspace photo'
	String get choosePhotoTitle => 'Choose workspace photo';

	/// en: 'Workspace settings'
	String get title => 'Workspace settings';

	/// en: 'Workspace name'
	String get namePlaceholder => 'Workspace name';

	/// en: 'Add photo'
	String get addPhoto => 'Add photo';

	/// en: 'Change photo'
	String get changePhoto => 'Change photo';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Color'
	String get color => 'Color';

	/// en: 'Host'
	String get host => 'Host';

	/// en: 'Folder'
	String get folder => 'Folder';
}

// Path: orkest.realmDialogs
class Translations$orkest$realmDialogs$en {
	Translations$orkest$realmDialogs$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Realm name'
	String get namePlaceholder => 'Realm name';

	/// en: 'A realm with this name already exists.'
	String get duplicateName => 'A realm with this name already exists.';

	/// en: 'New realm'
	String get newRealmTitle => 'New realm';

	/// en: 'Rename realm'
	String get renameRealmTitle => 'Rename realm';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Delete realm'
	String get deleteRealmTitle => 'Delete realm';

	/// en: 'Delete "${name}"? No workspace is deleted — the folder list just changes.${suffix}'
	String deleteMessage({required Object name, required Object suffix}) => 'Delete "${name}"? No workspace is deleted — the folder list just changes.${suffix}';

	/// en: ' Its workspace will move to Default.'
	String get deleteSuffixOne => ' Its workspace will move to Default.';

	/// en: ' Its ${count} workspaces will move to Default.'
	String deleteSuffixMany({required Object count}) => ' Its ${count} workspaces will move to Default.';

	/// en: 'Manage realms'
	String get manageRealmsTitle => 'Manage realms';

	/// en: '(one) {1 workspace} (other) {${n} workspaces}'
	String workspaceCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 workspace',
		other: '${n} workspaces',
	);
}

// Path: orkest.dbRedisTable
class Translations$orkest$dbRedisTable$en {
	Translations$orkest$dbRedisTable$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete key'
	String get deleteKeyTitle => 'Delete key';

	/// en: 'Delete "${key}" from this Redis database?'
	String deleteKeyMessage({required Object key}) => 'Delete "${key}" from this Redis database?';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'New key'
	String get newKey => 'New key';

	/// en: 'KEY'
	String get columnKey => 'KEY';

	/// en: 'VALUE'
	String get columnValue => 'VALUE';

	/// en: 'TYPE'
	String get columnType => 'TYPE';

	/// en: 'TTL'
	String get columnTtl => 'TTL';

	/// en: '(one) {1 key} (other) {${n} keys}'
	String keyCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 key',
		other: '${n} keys',
	);

	/// en: 'No keys in this database.'
	String get noKeys => 'No keys in this database.';

	/// en: 'No keys match "${pattern}".'
	String noKeysMatch({required Object pattern}) => 'No keys match "${pattern}".';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Loading full value…'
	String get loadingFullValue => 'Loading full value…';

	/// en: 'TTL must be a number of seconds.'
	String get ttlMustBeNumber => 'TTL must be a number of seconds.';

	/// en: 'Add key'
	String get addKey => 'Add key';

	/// en: 'key'
	String get keyFieldHint => 'key';

	/// en: 'ttl (s, optional)'
	String get ttlFieldHint => 'ttl (s, optional)';

	/// en: 'value'
	String get valueFieldHint => 'value';

	/// en: 'Search — pattern, e.g. user:*'
	String get searchHint => 'Search — pattern, e.g. user:*';
}

// Path: orkest.dbQueryView
class Translations$orkest$dbQueryView$en {
	Translations$orkest$dbQueryView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save query as'
	String get saveQueryAs => 'Save query as';

	/// en: 'Could not save'
	String get couldNotSave => 'Could not save';

	/// en: 'Select database'
	String get selectDatabase => 'Select database';

	/// en: 'No SQL connections'
	String get noSqlConnections => 'No SQL connections';

	/// en: 'Running…'
	String get running => 'Running…';

	/// en: 'Run selection'
	String get runSelection => 'Run selection';

	/// en: 'Run'
	String get run => 'Run';

	/// en: 'Pick a database above, then Run (⌘↵).'
	String get pickDatabaseHint => 'Pick a database above, then Run (⌘↵).';

	/// en: 'Run the query (⌘↵) to see results here.'
	String get runQueryHint => 'Run the query (⌘↵) to see results here.';

	/// en: 'No rows.'
	String get noRows => 'No rows.';

	/// en: '(one) {1 row affected} (other) {${n} rows affected}'
	String rowsAffected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 row affected',
		other: '${n} rows affected',
	);

	/// en: '${n} rows'
	String rowsFooter({required Object n}) => '${n} rows';

	/// en: ' · truncated (raise -- limit)'
	String get truncatedSuffix => ' · truncated (raise -- limit)';

	/// en: 'Table'
	String get table => 'Table';

	/// en: 'JSON'
	String get json => 'JSON';

	/// en: 'unsaved'
	String get unsaved => 'unsaved';

	/// en: 'saved'
	String get saved => 'saved';

	/// en: 'Copied'
	String get copied => 'Copied';

	/// en: 'Copy'
	String get copy => 'Copy';
}

// Path: orkest.httpView
class Translations$orkest$httpView$en {
	Translations$orkest$httpView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save request as'
	String get saveRequestAs => 'Save request as';

	/// en: 'Could not save'
	String get couldNotSave => 'Could not save';

	/// en: 'Run'
	String get run => 'Run';

	/// en: 'Running…'
	String get running => 'Running…';

	/// en: 'No request in this file — write one, e.g. GET https://example.com'
	String get noRequests => 'No request in this file — write one, e.g. GET https://example.com';

	/// en: 'Select request'
	String get selectRequest => 'Select request';

	/// en: '(one) {1 request} (other) {${n} requests}'
	String requestCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 request',
		other: '${n} requests',
	);

	/// en: 'Run the request (⌘↵) to see the response here.'
	String get runHint => 'Run the request (⌘↵) to see the response here.';

	/// en: 'Empty response body.'
	String get emptyBody => 'Empty response body.';

	/// en: 'JSON'
	String get body => 'JSON';

	/// en: 'Headers'
	String get headers => 'Headers';

	/// en: 'Text'
	String get raw => 'Text';

	/// en: ' · truncated (response too large)'
	String get truncatedSuffix => ' · truncated (response too large)';

	late final Translations$orkest$httpView$error$en error = Translations$orkest$httpView$error$en.internal(_root);
}

// Path: orkest.kanbanView
class Translations$orkest$kanbanView$en {
	Translations$orkest$kanbanView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Filter'
	String get filter => 'Filter';

	/// en: 'Search titles'
	String get filterTitlePlaceholder => 'Search titles';

	/// en: 'Labels'
	String get filterLabels => 'Labels';

	/// en: 'Clear'
	String get filterClear => 'Clear';

	/// en: 'Dependencies'
	String get filterDependencies => 'Dependencies';

	/// en: 'Blocked'
	String get filterBlocked => 'Blocked';

	/// en: 'Ready'
	String get filterReady => 'Ready';

	/// en: 'Blocked by'
	String get blockedBy => 'Blocked by';

	/// en: 'Add a blocking card'
	String get addBlocker => 'Add a blocking card';

	/// en: 'Search cards'
	String get searchCards => 'Search cards';

	/// en: 'unknown'
	String get unknownCard => 'unknown';

	/// en: 'Board'
	String get boardView => 'Board';

	/// en: 'List'
	String get listView => 'List';

	/// en: 'Refresh from disk'
	String get refresh => 'Refresh from disk';

	/// en: 'Labels'
	String get manageLabels => 'Labels';

	/// en: 'Labels in this board'
	String get labelsTitle => 'Labels in this board';

	/// en: 'label name'
	String get labelNamePlaceholder => 'label name';

	/// en: '(one) {1 card} (other) {${n} cards}'
	String labelUsage({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 card',
		other: '${n} cards',
	);

	/// en: 'Delete label'
	String get deleteLabel => 'Delete label';

	/// en: 'new card'
	String get newCard => 'new card';

	/// en: 'New card'
	String get newCardTitle => 'New card';

	/// en: 'New column'
	String get newColumn => 'New column';

	/// en: 'Column name'
	String get columnNameTitle => 'Column name';

	/// en: 'Drag column'
	String get dragColumn => 'Drag column';

	/// en: 'Column options'
	String get columnOptions => 'Column options';

	/// en: 'Rename column'
	String get renameColumn => 'Rename column';

	/// en: 'Move left'
	String get moveColumnLeft => 'Move left';

	/// en: 'Move right'
	String get moveColumnRight => 'Move right';

	/// en: 'Delete column'
	String get deleteColumn => 'Delete column';

	/// en: 'New card here'
	String get newCardHere => 'New card here';

	/// en: 'Duplicate'
	String get duplicateCard => 'Duplicate';

	/// en: 'Labels'
	String get cardLabels => 'Labels';

	/// en: 'Delete card'
	String get deleteCard => 'Delete card';

	/// en: 'Move to next column'
	String get advance => 'Move to next column';

	/// en: 'Move to next column (hold: move to last column)'
	String get advanceHold => 'Move to next column (hold: move to last column)';

	/// en: 'Move back a column'
	String get advanceBack => 'Move back a column';

	/// en: 'No cards'
	String get emptyColumn => 'No cards';

	/// en: '(one) {1 card} (other) {${n} cards}'
	String cardCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 card',
		other: '${n} cards',
	);

	/// en: 'Note'
	String get notes => 'Note';

	/// en: 'Write a note'
	String get notesPlaceholder => 'Write a note';

	/// en: 'Comments'
	String get comments => 'Comments';

	/// en: 'Add comment'
	String get addComment => 'Add comment';

	/// en: 'Write a comment'
	String get commentPlaceholder => 'Write a comment';

	/// en: 'No comments yet'
	String get noComments => 'No comments yet';

	/// en: 'Close'
	String get closeDetail => 'Close';

	/// en: 'This file has no ## columns yet — it opens as markdown.'
	String get notABoard => 'This file has no ## columns yet — it opens as markdown.';

	/// en: 'Start a board'
	String get startBoard => 'Start a board';

	/// en: 'Could not save the board'
	String get couldNotSave => 'Could not save the board';

	/// en: 'Not recognized by the parser — drags whole, no inline editing.'
	String get unrecognizedBlock => 'Not recognized by the parser — drags whole, no inline editing.';

	late final Translations$orkest$kanbanView$deleteColumnDialog$en deleteColumnDialog = Translations$orkest$kanbanView$deleteColumnDialog$en.internal(_root);
}

// Path: orkest.dbPanel
class Translations$orkest$dbPanel$en {
	Translations$orkest$dbPanel$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'DATABASE'
	String get sectionDatabase => 'DATABASE';

	/// en: 'Edit…'
	String get edit => 'Edit…';

	/// en: 'Copy name'
	String get copyName => 'Copy name';

	/// en: 'New query'
	String get newQuery => 'New query';

	/// en: 'Browse keys'
	String get browseKeys => 'Browse keys';

	/// en: 'Delete connection'
	String get deleteConnectionTitle => 'Delete connection';

	/// en: 'Remove "${name}" from this workspace? Any saved password is discarded. .dbq files that reference it are not touched.'
	String deleteConnectionMessage({required Object name}) => 'Remove "${name}" from this workspace? Any saved password is discarded. .dbq files that reference it are not touched.';

	/// en: '.orkest/databases.json · ${n} connections'
	String footer({required Object n}) => '.orkest/databases.json · ${n} connections';

	/// en: '.orkest/databases.json · 1 connection'
	String get footerOne => '.orkest/databases.json · 1 connection';

	/// en: 'No connections yet.'
	String get noConnections => 'No connections yet.';

	/// en: 'Password not found on the host. Open this connection and enter it again — it is saved on the machine that runs the database, not on this one.'
	String get passwordRequired => 'Password not found on the host. Open this connection and enter it again — it is saved on the machine that runs the database, not on this one.';
}

// Path: orkest.dbMongoView
class Translations$orkest$dbMongoView$en {
	Translations$orkest$dbMongoView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete document'
	String get deleteDocumentTitle => 'Delete document';

	/// en: 'Delete the document with _id ${id} from "${collection}"?'
	String deleteDocumentMessage({required Object id, required Object collection}) => 'Delete the document with _id ${id} from "${collection}"?';

	/// en: 'Filter — JSON, e.g. {"status": "active"}'
	String get filterHint => 'Filter — JSON, e.g. {"status": "active"}';

	/// en: '(one) {1 doc} (other) {${n} docs}'
	String docCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 doc',
		other: '${n} docs',
	);

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Insert document'
	String get insertDocument => 'Insert document';

	/// en: 'No documents in this collection.'
	String get noDocuments => 'No documents in this collection.';

	/// en: 'No documents match this filter.'
	String get noDocumentsMatch => 'No documents match this filter.';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Insert'
	String get insert => 'Insert';
}

// Path: orkest.dbConnectionDialog
class Translations$orkest$dbConnectionDialog$en {
	Translations$orkest$dbConnectionDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose SQLite database'
	String get chooseFileTitle => 'Choose SQLite database';

	/// en: 'File'
	String get file => 'File';

	/// en: 'Choose a SQLite file…'
	String get chooseFilePlaceholder => 'Choose a SQLite file…';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Save Password'
	String get savePassword => 'Save Password';

	/// en: 'Allow writes (agents)'
	String get allowWrites => 'Allow writes (agents)';

	/// en: 'off = agents can only read via CLI'
	String get allowWritesHint => 'off = agents can only read via CLI';

	/// en: 'Visible to agents'
	String get visibleToAgents => 'Visible to agents';

	/// en: 'off = hidden from the CLI, GUI only'
	String get visibleToAgentsHint => 'off = hidden from the CLI, GUI only';

	/// en: 'Testing connection…'
	String get testing => 'Testing connection…';

	/// en: 'Connection OK'
	String get connectionOk => 'Connection OK';

	/// en: 'Connection failed'
	String get connectionFailed => 'Connection failed';

	/// en: 'Edit connection'
	String get editTitle => 'Edit connection';

	/// en: 'New connection'
	String get newTitle => 'New connection';

	/// en: 'Connection string'
	String get connectionString => 'Connection string';

	/// en: 'Not a valid connection URL.'
	String get invalidUrl => 'Not a valid connection URL.';

	/// en: 'SSH Tunnel'
	String get sshTunnel => 'SSH Tunnel';

	/// en: 'SSH Host'
	String get sshHost => 'SSH Host';

	/// en: 'SSH Port'
	String get sshPort => 'SSH Port';

	/// en: 'SSH User'
	String get sshUser => 'SSH User';

	/// en: 'Private key'
	String get privateKey => 'Private key';

	/// en: 'Choose a private key…'
	String get choosePrivateKeyPlaceholder => 'Choose a private key…';

	/// en: 'Choose SSH private key'
	String get choosePrivateKeyDialogTitle => 'Choose SSH private key';

	/// en: 'Key passphrase'
	String get keyPassphrase => 'Key passphrase';

	/// en: 'Save passphrase'
	String get savePassphrase => 'Save passphrase';

	/// en: 'The password is stored on the host, not on this machine.'
	String get passwordOnHost => 'The password is stored on the host, not on this machine.';
}

// Path: orkest.sshPrompts
class Translations$orkest$sshPrompts$en {
	Translations$orkest$sshPrompts$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Unknown SSH host'
	String get unknownSshHostTitle => 'Unknown SSH host';

	/// en: 'Orkest Code has never connected to ${endpoint} before.'
	String neverConnected({required Object endpoint}) => 'Orkest Code has never connected to ${endpoint} before.';

	/// en: 'Trust it only if this fingerprint matches the server. You can check it on the server with:'
	String get trustHint => 'Trust it only if this fingerprint matches the server. You can check it on the server with:';

	/// en: 'Trust'
	String get trust => 'Trust';

	/// en: 'SSH key passphrase'
	String get sshKeyPassphraseTitle => 'SSH key passphrase';

	/// en: 'Unlock ${keyPath} to connect "${connectionName}".'
	String unlockMessage({required Object keyPath, required Object connectionName}) => 'Unlock ${keyPath} to connect "${connectionName}".';

	/// en: 'Kept in memory until Orkest Code quits. To let agents use this connection, enable "Save passphrase" in the connection.'
	String get keptInMemoryHint => 'Kept in memory until Orkest Code quits. To let agents use this connection, enable "Save passphrase" in the connection.';

	/// en: 'Unlock'
	String get unlock => 'Unlock';
}

// Path: orkest.projectsRail
class Translations$orkest$projectsRail$en {
	Translations$orkest$projectsRail$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workspaces'
	String get workspaces => 'Workspaces';

	/// en: 'Keeping this computer awake for remote access. Click to let it sleep again.'
	String get keepAwakeOn => 'Keeping this computer awake for remote access. Click to let it sleep again.';

	/// en: 'Keep this computer awake for remote access. Off again when Orkest Code restarts.'
	String get keepAwakeOff => 'Keep this computer awake for remote access. Off again when Orkest Code restarts.';

	/// en: 'Keeping awake on battery power. This drains the battery.'
	String get keepAwakeBattery => 'Keeping awake on battery power. This drains the battery.';

	/// en: 'Closing a laptop lid still puts it to sleep.'
	String get keepAwakeLid => 'Closing a laptop lid still puts it to sleep.';

	/// en: 'New workspace'
	String get newWorkspace => 'New workspace';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Merge to Parent'
	String get mergeToParent => 'Merge to Parent';

	/// en: 'Update from Parent'
	String get updateFromParent => 'Update from Parent';

	/// en: 'Fork Worktree'
	String get forkWorktree => 'Fork Worktree';

	/// en: 'Copy branch'
	String get copyBranch => 'Copy branch';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Move to realm'
	String get moveToRealm => 'Move to realm';

	/// en: 'Copy workspace id'
	String get copyWorkspaceId => 'Copy workspace id';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'New realm…'
	String get newRealm => 'New realm…';

	/// en: 'Manage realms…'
	String get manageRealms => 'Manage realms…';

	/// en: 'No workspaces yet.'
	String get noWorkspaces => 'No workspaces yet.';

	/// en: 'Sync'
	String get sync => 'Sync';

	/// en: 'Pull'
	String get pull => 'Pull';

	/// en: 'Push'
	String get push => 'Push';

	/// en: 'Create worktree'
	String get createWorktree => 'Create worktree';

	/// en: '(one) {1 worktree} (other) {${n} worktrees}'
	String worktreeCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 worktree',
		other: '${n} worktrees',
	);

	/// en: 'Expand worktrees'
	String get expandWorktrees => 'Expand worktrees';

	/// en: 'Collapse worktrees'
	String get collapseWorktrees => 'Collapse worktrees';
}

// Path: orkest.findBar
class Translations$orkest$findBar$en {
	Translations$orkest$findBar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Find'
	String get find => 'Find';

	/// en: 'Match case'
	String get matchCase => 'Match case';

	/// en: 'Whole word'
	String get wholeWord => 'Whole word';

	/// en: 'Use regular expression'
	String get useRegex => 'Use regular expression';

	/// en: 'Previous (⇧⏎)'
	String get previous => 'Previous (⇧⏎)';

	/// en: 'Next (⏎)'
	String get next => 'Next (⏎)';

	/// en: 'Close (Esc)'
	String get close => 'Close (Esc)';

	/// en: 'Bad pattern'
	String get badPattern => 'Bad pattern';

	/// en: '${current} of ${total}'
	String counter({required Object current, required Object total}) => '${current} of ${total}';

	/// en: 'No results'
	String get noResults => 'No results';
}

// Path: orkest.contentSearch
class Translations$orkest$contentSearch$en {
	Translations$orkest$contentSearch$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'SEARCH'
	String get sectionSearch => 'SEARCH';

	/// en: 'Search in files'
	String get searchInFiles => 'Search in files';

	/// en: 'Match case'
	String get matchCase => 'Match case';

	/// en: 'Whole word'
	String get wholeWord => 'Whole word';

	/// en: 'Use regular expression'
	String get useRegex => 'Use regular expression';

	/// en: 'Invalid regular expression.'
	String get invalidRegex => 'Invalid regular expression.';

	/// en: 'Type to search across files.'
	String get typeToSearch => 'Type to search across files.';

	/// en: 'Searching…'
	String get searching => 'Searching…';

	/// en: 'No results.'
	String get noResults => 'No results.';
}

// Path: orkest.topbar
class Translations$orkest$topbar$en {
	Translations$orkest$topbar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Collapse sidebar'
	String get collapseSidebar => 'Collapse sidebar';

	/// en: 'Show/hide files'
	String get toggleFiles => 'Show/hide files';

	/// en: 'Files unavailable in Orkest Code'
	String get filesUnavailable => 'Files unavailable in Orkest Code';

	/// en: 'Hide keyboard'
	String get hideKeyboard => 'Hide keyboard';

	/// en: 'Show office'
	String get showOffice => 'Show office';

	/// en: 'Show terminals'
	String get showTerminals => 'Show terminals';
}

// Path: orkest.tasks
class Translations$orkest$tasks$en {
	Translations$orkest$tasks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Hot reload'
	String get hotReload => 'Hot reload';

	/// en: 'Hot restart'
	String get hotRestart => 'Hot restart';

	/// en: 'Toggle debug paint'
	String get toggleDebugPaint => 'Toggle debug paint';

	/// en: 'Toggle platform'
	String get togglePlatform => 'Toggle platform';

	/// en: 'Quit'
	String get quit => 'Quit';
}

// Path: orkest.notifications
class Translations$orkest$notifications$en {
	Translations$orkest$notifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Agent finished'
	String get agentFinished => 'Agent finished';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Agent needs your input'
	String get agentNeedsAction => 'Agent needs your input';
}

// Path: orkest.terminalLink
class Translations$orkest$terminalLink$en {
	Translations$orkest$terminalLink$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Reveal in Finder'
	String get revealFinder => 'Reveal in Finder';

	/// en: 'Show in Explorer'
	String get revealExplorer => 'Show in Explorer';

	/// en: 'Open containing folder'
	String get revealFolder => 'Open containing folder';

	/// en: 'Copy path'
	String get copyPath => 'Copy path';

	/// en: 'Open link'
	String get openLink => 'Open link';

	/// en: 'Copy link'
	String get copyLink => 'Copy link';
}

// Path: orkest.terminal
class Translations$orkest$terminal$en {
	Translations$orkest$terminal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Warning: the folder "${requested}" does not exist. This terminal opened in "${path}".'
	String cwdFallbackWarning({required Object requested, required Object path}) => 'Warning: the folder "${requested}" does not exist. This terminal opened in "${path}".';

	/// en: 'Notice: .env.orkest is tracked by git (it came with the repository). Injected: ${keys}'
	String workspaceEnvTracked({required Object keys}) => 'Notice: .env.orkest is tracked by git (it came with the repository). Injected: ${keys}';
}

// Path: orkest.remoteHost
class Translations$orkest$remoteHost$en {
	Translations$orkest$remoteHost$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add remote host'
	String get addHost => 'Add remote host';

	/// en: 'Name'
	String get hostName => 'Name';

	/// en: 'SSH target (user@host)'
	String get sshTarget => 'SSH target (user@host)';

	/// en: 'Connecting to ${host}…'
	String connecting({required Object host}) => 'Connecting to ${host}…';

	/// en: 'SSH tunnel'
	String get openingTunnel => 'SSH tunnel';

	/// en: 'Installing server'
	String get installingServer => 'Installing server';

	/// en: 'Server ${version}'
	String handshake({required Object version}) => 'Server ${version}';

	/// en: 'Loading workspace…'
	String get loadingWorkspace => 'Loading workspace…';

	/// en: 'Reconnecting to ${host}…'
	String reconnecting({required Object host}) => 'Reconnecting to ${host}…';

	/// en: '${host} offline'
	String offline({required Object host}) => '${host} offline';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Reconnect'
	String get reconnect => 'Reconnect';

	/// en: 'Install server'
	String get installServer => 'Install server';

	/// en: 'Cannot reach ${host} over SSH. Is it on, and is Remote Login enabled?'
	String errSshUnreachable({required Object host}) => 'Cannot reach ${host} over SSH. Is it on, and is Remote Login enabled?';

	/// en: 'Could not install the server on ${host}.'
	String errInstallFailed({required Object host}) => 'Could not install the server on ${host}.';

	/// en: 'Server version incompatible; update it.'
	String get errVersionMismatch => 'Server version incompatible; update it.';

	/// en: 'Details: ${detail}'
	String errDetail({required Object detail}) => 'Details: ${detail}';

	/// en: 'Open folder on ${host}'
	String pickFolderTitle({required Object host}) => 'Open folder on ${host}';

	/// en: 'Open here'
	String get openHere => 'Open here';

	/// en: 'No subfolders'
	String get emptyFolder => 'No subfolders';

	/// en: 'Local'
	String get newLocal => 'Local';

	/// en: 'Remote'
	String get newRemote => 'Remote';

	/// en: 'Choose a host'
	String get chooseHost => 'Choose a host';

	/// en: 'New host…'
	String get newHostEntry => 'New host…';

	/// en: 'Edit host'
	String get editHost => 'Edit host';

	/// en: 'Username'
	String get userLabel => 'Username';

	/// en: 'Host / IP'
	String get hostLabel => 'Host / IP';

	/// en: 'Port'
	String get portLabel => 'Port';

	/// en: 'Authentication'
	String get authLabel => 'Authentication';

	/// en: 'SSH key'
	String get authKey => 'SSH key';

	/// en: 'Password'
	String get authPassword => 'Password';

	/// en: 'Password'
	String get passwordLabel => 'Password';

	/// en: 'Leave blank to keep current'
	String get passwordKeep => 'Leave blank to keep current';

	/// en: 'Username required'
	String get errUser => 'Username required';

	/// en: 'Host required'
	String get errHost => 'Host required';

	/// en: 'Password required'
	String get errPassword => 'Password required';

	/// en: 'Choose…'
	String get identityChoose => 'Choose…';

	/// en: 'No key selected'
	String get identityEmpty => 'No key selected';

	/// en: 'Select the SSH private key'
	String get identityDialogTitle => 'Select the SSH private key';

	/// en: 'Pick the private key to authenticate with.'
	String get errIdentity => 'Pick the private key to authenticate with.';

	/// en: 'Orkest Code does not trust ${host} yet. Connect again and confirm the fingerprint.'
	String errHostKeyUnknown({required Object host}) => 'Orkest Code does not trust ${host} yet. Connect again and confirm the fingerprint.';

	/// en: '${host} is presenting a different SSH key than the one stored. If you did not reinstall that machine, stop and check it — otherwise remove the old entry from ~/.ssh/known_hosts.'
	String errHostKeyChanged({required Object host}) => '${host} is presenting a different SSH key than the one stored. If you did not reinstall that machine, stop and check it — otherwise remove the old entry from ~/.ssh/known_hosts.';

	/// en: '${host} runs Windows but does not have Orkest Code installed. The remote server is installed from the Orkest Code bundle already on that machine, so install Orkest Code there and try again.'
	String errHostBundleMissing({required Object host}) => '${host} runs Windows but does not have Orkest Code installed. The remote server is installed from the Orkest Code bundle already on that machine, so install Orkest Code there and try again.';

	/// en: 'Could not identify the operating system of ${host}. The account may have a restricted shell, or no shell at all.'
	String errHostUnknownOs({required Object host}) => 'Could not identify the operating system of ${host}. The account may have a restricted shell, or no shell at all.';

	/// en: 'Only the public key is here. That works only if the private key is in your SSH agent; otherwise pick the private file (same name, without .pub).'
	String get errIdentityPublic => 'Only the public key is here. That works only if the private key is in your SSH agent; otherwise pick the private file (same name, without .pub).';

	/// en: 'That file does not look like a private key.'
	String get errIdentityNotKey => 'That file does not look like a private key.';

	/// en: 'That file no longer exists.'
	String get errIdentityMissingFile => 'That file no longer exists.';

	/// en: 'That file could not be read.'
	String get errIdentityUnreadable => 'That file could not be read.';
}

// Path: orkest.browserPane
class Translations$orkest$browserPane$en {
	Translations$orkest$browserPane$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Forward'
	String get forward => 'Forward';

	/// en: 'Reload'
	String get reload => 'Reload';

	/// en: 'Enter URL or address'
	String get urlHint => 'Enter URL or address';

	/// en: 'Go'
	String get go => 'Go';
}

// Path: orkest.documentWindow
class Translations$orkest$documentWindow$en {
	Translations$orkest$documentWindow$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Audio and video open in the main Orkest Code window.'
	String get mediaNotSupported => 'Audio and video open in the main Orkest Code window.';

	/// en: 'File not found: ${path}'
	String fileNotFound({required Object path}) => 'File not found: ${path}';
}

// Path: orkest.gallery
class Translations$orkest$gallery$en {
	Translations$orkest$gallery$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Special Orkest Code documents that give you a visual of what the AI agent is doing.'
	String get intro => 'Special Orkest Code documents that give you a visual of what the AI agent is doing.';

	/// en: 'Could not create the file'
	String get createErrorTitle => 'Could not create the file';

	late final Translations$orkest$gallery$dbQuery$en dbQuery = Translations$orkest$gallery$dbQuery$en.internal(_root);
	late final Translations$orkest$gallery$kanban$en kanban = Translations$orkest$gallery$kanban$en.internal(_root);
	late final Translations$orkest$gallery$layout$en layout = Translations$orkest$gallery$layout$en.internal(_root);
	late final Translations$orkest$gallery$httpRequest$en httpRequest = Translations$orkest$gallery$httpRequest$en.internal(_root);
	late final Translations$orkest$gallery$html$en html = Translations$orkest$gallery$html$en.internal(_root);
	late final Translations$orkest$gallery$tasks$en tasks = Translations$orkest$gallery$tasks$en.internal(_root);
	late final Translations$orkest$gallery$notebook$en notebook = Translations$orkest$gallery$notebook$en.internal(_root);
	late final Translations$orkest$gallery$workspaceEnv$en workspaceEnv = Translations$orkest$gallery$workspaceEnv$en.internal(_root);
	late final Translations$orkest$gallery$panel$en panel = Translations$orkest$gallery$panel$en.internal(_root);
}

// Path: orkest.notebook
class Translations$orkest$notebook$en {
	Translations$orkest$notebook$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notes'
	String get notes => 'Notes';

	/// en: 'New note'
	String get newNote => 'New note';

	/// en: 'Search notes'
	String get searchPlaceholder => 'Search notes';

	/// en: 'No notes yet. Create one, or ask the agent to write here.'
	String get empty => 'No notes yet. Create one, or ask the agent to write here.';

	/// en: 'No note matches.'
	String get noMatch => 'No note matches.';

	/// en: 'Select a note'
	String get selectNote => 'Select a note';

	/// en: 'Reload from disk'
	String get reload => 'Reload from disk';

	/// en: 'untagged'
	String get untagged => 'untagged';

	/// en: 'Could not save the note'
	String get saveFailed => 'Could not save the note';

	/// en: 'Could not create the note'
	String get createFailed => 'Could not create the note';

	/// en: 'add tag'
	String get addTag => 'add tag';

	/// en: 'Untitled'
	String get untitled => 'Untitled';

	/// en: 'Delete note'
	String get deleteNote => 'Delete note';

	/// en: 'Move “${name}” to the trash?'
	String deleteConfirm({required Object name}) => 'Move “${name}” to the trash?';

	/// en: 'Could not save the image'
	String get imageFailed => 'Could not save the image';

	late final Translations$orkest$notebook$format$en format = Translations$orkest$notebook$format$en.internal(_root);

	/// en: 'Linked from'
	String get backlinks => 'Linked from';

	/// en: 'Rename tag'
	String get renameTag => 'Rename tag';

	/// en: 'Delete tag'
	String get deleteTag => 'Delete tag';

	/// en: 'Remove “${name}” from ${count} notes? The notes stay.'
	String deleteTagConfirm({required Object name, required Object count}) => 'Remove “${name}” from ${count} notes? The notes stay.';

	/// en: 'Show notes list'
	String get showList => 'Show notes list';

	/// en: 'Hide notes list'
	String get hideList => 'Hide notes list';
}

// Path: orkest.layoutPreview
class Translations$orkest$layoutPreview$en {
	Translations$orkest$layoutPreview$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not apply the layout'
	String get applyFailedTitle => 'Could not apply the layout';

	/// en: 'Apply in Orkest Code'
	String get applyInOrkest => 'Apply in Orkest Code';

	/// en: 'Open as new workspace'
	String get applyNewWorkspace => 'Open as new workspace';

	/// en: 'Apply to ${workspace}'
	String applyTo({required Object workspace}) => 'Apply to ${workspace}';

	/// en: 'autorun: worktree. This layout is also applied on its own when you create a worktree of the workspace that holds it.'
	String get autorunWorktree => 'autorun: worktree. This layout is also applied on its own when you create a worktree of the workspace that holds it.';

	/// en: 'Command'
	String get command => 'Command';

	/// en: 'Folder'
	String get folder => 'Folder';

	/// en: 'no command, opens a shell'
	String get noCommand => 'no command, opens a shell';

	/// en: 'Replace layout'
	String get replaceConfirm => 'Replace layout';

	/// en: '${n} open tabs of this workspace will be closed, including any running work.'
	String replaceMessage({required Object n}) => '${n} open tabs of this workspace will be closed, including any running work.';

	/// en: 'Replace the layout of ${workspace}?'
	String replaceTitle({required Object workspace}) => 'Replace the layout of ${workspace}?';

	/// en: 'Not created on this system'
	String get skippedTitle => 'Not created on this system';

	/// en: 'split down'
	String get splitDown => 'split down';

	/// en: 'split right'
	String get splitRight => 'split right';

	/// en: 'tab'
	String get splitTab => 'tab';

	/// en: 'This layout opens ${n} terminals. Read the commands before applying.'
	String subtitle({required Object n}) => 'This layout opens ${n} terminals. Read the commands before applying.';
}

// Path: orkest.telemetry
class Translations$orkest$telemetry$en {
	Translations$orkest$telemetry$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Telemetry'
	String get tooltip => 'Telemetry';

	/// en: 'Telemetry'
	String get title => 'Telemetry';

	/// en: '${n} live'
	String liveRuns({required Object n}) => '${n} live';

	/// en: 'Open a workspace to see its telemetry.'
	String get noWorkspace => 'Open a workspace to see its telemetry.';

	/// en: 'Nothing here yet.'
	String get empty => 'Nothing here yet.';

	/// en: 'Nothing here yet.'
	String get emptyFiltered => 'Nothing here yet.';

	/// en: 'Filter cases'
	String get searchHint => 'Filter cases';

	/// en: 'Open'
	String get chipOpen => 'Open';

	/// en: 'New'
	String get chipNew => 'New';

	/// en: 'Resolved'
	String get chipResolved => 'Resolved';

	/// en: 'Ignored'
	String get chipIgnored => 'Ignored';

	/// en: 'Warnings'
	String get chipWarnings => 'Warnings';

	/// en: 'new'
	String get tagNew => 'new';

	/// en: 'regression'
	String get tagRegression => 'regression';

	/// en: 'resolved'
	String get tagResolved => 'resolved';

	/// en: 'ignored'
	String get tagIgnored => 'ignored';

	/// en: 'task'
	String get srcTask => 'task';

	/// en: 'orkest telemetry'
	String get srcWrapper => 'orkest telemetry';

	/// en: 'run ${id}'
	String run({required Object id}) => 'run ${id}';

	/// en: 'Mark resolved'
	String get resolve => 'Mark resolved';

	/// en: 'Ignore (hide from agents too)'
	String get ignore => 'Ignore (hide from agents too)';

	/// en: 'Reopen'
	String get reopen => 'Reopen';

	/// en: 'Clear occurrences'
	String get clear => 'Clear occurrences';

	/// en: 'Clear this run'
	String get clearRun => 'Clear this run';

	/// en: 'Clear project'
	String get clearProject => 'Clear project';

	/// en: 'Open ${location}'
	String openFile({required Object location}) => 'Open ${location}';

	/// en: 'Show in terminal'
	String get showInTerminal => 'Show in terminal';

	/// en: 'Copy CLI command'
	String get copyCommand => 'Copy CLI command';

	/// en: 'Copied'
	String get copied => 'Copied';

	/// en: 'Open'
	String get statusOpen => 'Open';

	/// en: 'Resolved'
	String get statusResolved => 'Resolved';

	/// en: 'Ignored'
	String get statusIgnored => 'Ignored';

	/// en: 'Occurrences'
	String get occurrences => 'Occurrences';

	/// en: 'in ${n} runs'
	String inRuns({required Object n}) => 'in ${n} runs';

	/// en: 'First'
	String get first => 'First';

	/// en: 'Last'
	String get last => 'Last';

	/// en: 'Origin'
	String get origin => 'Origin';

	/// en: 'Stack'
	String get sectionStack => 'Stack';

	/// en: 'project frames highlighted · click opens the file'
	String get stackHint => 'project frames highlighted · click opens the file';

	/// en: 'Correlated log'
	String get sectionCorrelated => 'Correlated log';

	/// en: 'the closest JSON log before the error, same run'
	String get correlatedHint => 'the closest JSON log before the error, same run';

	/// en: 'none'
	String get none => 'none';

	/// en: 'Occurrences by run'
	String get sectionRuns => 'Occurrences by run';

	/// en: 'same key (cwd, command): this is how new and regression are computed'
	String get runsHint => 'same key (cwd, command): this is how new and regression are computed';

	/// en: 'Raw context'
	String get sectionContext => 'Raw context';

	/// en: 'terminal lines around the last occurrence'
	String get contextHint => 'terminal lines around the last occurrence';

	/// en: 'current'
	String get current => 'current';

	/// en: 'fingerprint = type + normalized message + ${location}'
	String fingerprintHint({required Object location}) => 'fingerprint = type + normalized message + ${location}';

	/// en: 'changed in working tree'
	String get blameUncommitted => 'changed in working tree';

	/// en: 'changed ${ago} (${sha})'
	String blameCommit({required Object ago, required Object sha}) => 'changed ${ago} (${sha})';

	/// en: 'just now'
	String get justNow => 'just now';

	/// en: '${n}m ago'
	String minutesAgo({required Object n}) => '${n}m ago';

	/// en: '${n}h ago'
	String hoursAgo({required Object n}) => '${n}h ago';

	/// en: '${n}d ago'
	String daysAgo({required Object n}) => '${n}d ago';

	/// en: 'Resolved. If it comes back in a later run it reappears as a regression.'
	String get resolvedToast => 'Resolved. If it comes back in a later run it reappears as a regression.';

	/// en: 'Ignored. Agents no longer see it (unless --include-ignored).'
	String get ignoredToast => 'Ignored. Agents no longer see it (unless --include-ignored).';

	/// en: 'Occurrences deleted. Triage rules are kept.'
	String get clearedToast => 'Occurrences deleted. Triage rules are kept.';

	/// en: 'by you'
	String get byHuman => 'by you';

	/// en: 'by agent'
	String get byAgent => 'by agent';

	/// en: '${type} · ${file}'
	String caseTabTitle({required Object type, required Object file}) => '${type} · ${file}';

	/// en: 'App'
	String get srcApp => 'App';

	/// en: 'Orkest Code'
	String get chipApp => 'Orkest Code';
}

// Path: orkest.panelView
class Translations$orkest$panelView$en {
	Translations$orkest$panelView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Panels need the embedded web view, which is not available on Linux yet.'
	String get unavailable => 'Panels need the embedded web view, which is not available on Linux yet.';

	/// en: 'Open in browser'
	String get openInBrowser => 'Open in browser';

	/// en: 'Open as HTML'
	String get openAsHtml => 'Open as HTML';
}

// Path: settings.language
class Translations$settings$language$en {
	Translations$settings$language$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get title => 'Language';

	/// en: 'System'
	String get system => 'System';

	/// en: 'English'
	String get english => 'English';

	/// en: 'Português (BR)'
	String get portugueseBr => 'Português (BR)';

	/// en: 'Español'
	String get spanish => 'Español';
}

// Path: settings.page
class Translations$settings$page$en {
	Translations$settings$page$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$page$header$en header = Translations$settings$page$header$en.internal(_root);
	late final Translations$settings$page$nav$en nav = Translations$settings$page$nav$en.internal(_root);
	late final Translations$settings$page$general$en general = Translations$settings$page$general$en.internal(_root);
	late final Translations$settings$page$diagnostics$en diagnostics = Translations$settings$page$diagnostics$en.internal(_root);
	late final Translations$settings$page$storage$en storage = Translations$settings$page$storage$en.internal(_root);
	late final Translations$settings$page$terminal$en terminal = Translations$settings$page$terminal$en.internal(_root);
	late final Translations$settings$page$appearance$en appearance = Translations$settings$page$appearance$en.internal(_root);
	late final Translations$settings$page$notifications$en notifications = Translations$settings$page$notifications$en.internal(_root);
	late final Translations$settings$page$shortcuts$en shortcuts = Translations$settings$page$shortcuts$en.internal(_root);
	late final Translations$settings$page$languages$en languages = Translations$settings$page$languages$en.internal(_root);
	late final Translations$settings$page$automations$en automations = Translations$settings$page$automations$en.internal(_root);
}

// Path: settings.remoteHosts
class Translations$settings$remoteHosts$en {
	Translations$settings$remoteHosts$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Remote hosts'
	String get title => 'Remote hosts';

	/// en: 'Machines you reach over SSH. Adding a host here is the same as adding one from the workspace "+" menu.'
	String get description => 'Machines you reach over SSH. Adding a host here is the same as adding one from the workspace "+" menu.';

	/// en: 'No remote hosts yet.'
	String get empty => 'No remote hosts yet.';

	/// en: 'Add host'
	String get add => 'Add host';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Reconnect'
	String get reconnect => 'Reconnect';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Remove host'
	String get removeTitle => 'Remove host';

	/// en: 'Remove "${name}" and all its workspaces? Nothing is deleted on the host itself.'
	String removeMessage({required Object name}) => 'Remove "${name}" and all its workspaces? Nothing is deleted on the host itself.';

	/// en: '${count} workspace(s)'
	String workspacesCount({required Object count}) => '${count} workspace(s)';

	/// en: 'This device's key'
	String get deviceKeyTitle => 'This device\'s key';

	/// en: 'Add this public key to ~/.ssh/authorized_keys on the host so this device can connect.'
	String get deviceKeyDesc => 'Add this public key to ~/.ssh/authorized_keys on the host so this device can connect.';

	/// en: 'Copy public key'
	String get deviceKeyCopy => 'Copy public key';

	/// en: 'Public key copied'
	String get deviceKeyCopied => 'Public key copied';

	/// en: 'Connected'
	String get statusConnected => 'Connected';

	/// en: 'Connecting…'
	String get statusConnecting => 'Connecting…';

	/// en: 'Reconnecting…'
	String get statusReconnecting => 'Reconnecting…';

	/// en: 'Offline'
	String get statusOffline => 'Offline';

	/// en: 'Not connected'
	String get statusIdle => 'Not connected';

	/// en: 'How it works'
	String get helpTitle => 'How it works';

	/// en: 'Orkest Code connects to your machine over SSH and talks to a small server that runs the terminals, files and git there. The host must have Orkest Code (desktop) or the orkest-server installed and running, and this device’s public key added to its ~/.ssh/authorized_keys.'
	String get helpBody => 'Orkest Code connects to your machine over SSH and talks to a small server that runs the terminals, files and git there. The host must have Orkest Code (desktop) or the orkest-server installed and running, and this device’s public key added to its ~/.ssh/authorized_keys.';
}

// Path: automation.error
class Translations$automation$error$en {
	Translations$automation$error$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${harness} is not installed or is not on PATH.'
	String unavailable({required Object harness}) => '${harness} is not installed or is not on PATH.';

	/// en: 'Model "${model}" is not available for ${harness}. Choose another model in Settings.'
	String modelUnavailable({required Object model, required Object harness}) => 'Model "${model}" is not available for ${harness}. Choose another model in Settings.';

	/// en: '${harness}: ${detail}'
	String authentication({required Object harness, required Object detail}) => '${harness}: ${detail}';

	/// en: '${harness} did not respond within ${seconds} seconds.'
	String timeout({required Object harness, required Object seconds}) => '${harness} did not respond within ${seconds} seconds.';

	/// en: 'Commit message generation was cancelled.'
	String get cancelled => 'Commit message generation was cancelled.';

	/// en: '${harness}: ${detail}'
	String process({required Object harness, required Object detail}) => '${harness}: ${detail}';

	/// en: '${harness} could not generate a commit message.'
	String processNoDetail({required Object harness}) => '${harness} could not generate a commit message.';

	/// en: 'The automation returned an empty commit message.'
	String get invalidResponse => 'The automation returned an empty commit message.';

	/// en: 'Another commit message is already being generated.'
	String get busy => 'Another commit message is already being generated.';

	/// en: 'The automation could not generate a commit message.'
	String get unknown => 'The automation could not generate a commit message.';

	/// en: 'No workspace selected.'
	String get noWorkspace => 'No workspace selected.';

	/// en: 'File is outside the workspace roots.'
	String get fileOutsideWorkspace => 'File is outside the workspace roots.';

	/// en: 'Could not read the file: ${detail}'
	String fileUnreadable({required Object detail}) => 'Could not read the file: ${detail}';

	/// en: 'A commit message cannot be generated for a binary file.'
	String get binaryFile => 'A commit message cannot be generated for a binary file.';

	/// en: 'There are no changes to describe for this file.'
	String get noFileChanges => 'There are no changes to describe for this file.';

	/// en: 'There are no staged changes to describe.'
	String get noStagedChanges => 'There are no staged changes to describe.';

	/// en: 'Staged changes belong to multiple repositories. Generate them separately.'
	String get multipleRepositories => 'Staged changes belong to multiple repositories. Generate them separately.';

	/// en: 'Could not read the diff.'
	String get diffUnavailable => 'Could not read the diff.';

	/// en: 'Configure a commit message harness in Settings.'
	String get notConfigured => 'Configure a commit message harness in Settings.';
}

// Path: fileOperation.error
class Translations$fileOperation$error$en {
	Translations$fileOperation$error$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Already exists: “${name}”.'
	String alreadyExists({required Object name}) => 'Already exists: “${name}”.';

	/// en: 'Not found: “${name}”.'
	String notFound({required Object name}) => 'Not found: “${name}”.';

	/// en: 'Invalid path.'
	String get invalidPath => 'Invalid path.';

	/// en: 'The name cannot be empty.'
	String get emptyName => 'The name cannot be empty.';

	/// en: 'No workspace selected.'
	String get noWorkspace => 'No workspace selected.';

	/// en: 'Cannot move a folder into itself.'
	String get cannotMoveIntoItself => 'Cannot move a folder into itself.';

	/// en: 'Clipboard is empty.'
	String get clipboardEmpty => 'Clipboard is empty.';

	/// en: 'This tab is not a scratch file.'
	String get notScratchTab => 'This tab is not a scratch file.';

	/// en: 'Could not write the file.'
	String get writeFailed => 'Could not write the file.';

	/// en: 'Empty formatter command.'
	String get formatterEmptyCommand => 'Empty formatter command.';

	/// en: 'Formatter command must include the %FILE% placeholder.'
	String get formatterMissingPlaceholder => 'Formatter command must include the %FILE% placeholder.';

	/// en: 'Formatter timed out.'
	String get formatterTimeout => 'Formatter timed out.';

	/// en: 'Formatter exited with ${code}.'
	String formatterExitCode({required Object code}) => 'Formatter exited with ${code}.';

	/// en: 'The formatter could not run.'
	String get formatterFailed => 'The formatter could not run.';

	/// en: '${detail}'
	String osFailure({required Object detail}) => '${detail}';

	/// en: 'Name cannot contain “/”.'
	String get nameHasSlash => 'Name cannot contain “/”.';

	/// en: 'Invalid name.'
	String get invalidName => 'Invalid name.';

	/// en: 'Dropping files into a remote workspace is not supported yet.'
	String get remoteDropUnsupported => 'Dropping files into a remote workspace is not supported yet.';
}

// Path: theme.error
class Translations$theme$error$en {
	Translations$theme$error$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not read or write the theme file.'
	String get io => 'Could not read or write the theme file.';

	/// en: 'Could not read or write the theme file: ${detail}'
	String ioDetail({required Object detail}) => 'Could not read or write the theme file: ${detail}';

	/// en: 'This file is not valid JSON: ${detail}'
	String malformedJson({required Object detail}) => 'This file is not valid JSON: ${detail}';

	/// en: 'This file is not a valid theme.'
	String get invalidTheme => 'This file is not a valid theme.';

	/// en: 'This theme uses the id of a built-in theme. Change "id" in the file and import again.'
	String get reservedId => 'This theme uses the id of a built-in theme. Change "id" in the file and import again.';

	/// en: 'Expected an object at "${field}".'
	String notAnObject({required Object field}) => 'Expected an object at "${field}".';

	/// en: 'Missing required field "${field}".'
	String missingField({required Object field}) => 'Missing required field "${field}".';

	/// en: '"${value}" at "${field}" is not a color. Use #RGB, #RRGGBB or #RRGGBBAA.'
	String badColor({required Object value, required Object field}) => '"${value}" at "${field}" is not a color. Use #RGB, #RRGGBB or #RRGGBBAA.';

	/// en: 'Unknown base theme "${value}" in "extends".'
	String unknownBase({required Object value}) => 'Unknown base theme "${value}" in "extends".';

	/// en: 'The theme declares no variant. Add "dark", "light" or both under "variants".'
	String get noVariants => 'The theme declares no variant. Add "dark", "light" or both under "variants".';
}

// Path: orkest.httpView.error
class Translations$orkest$httpView$error$en {
	Translations$orkest$httpView$error$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Request failed'
	String get title => 'Request failed';

	/// en: 'No request found at the cursor.'
	String get noRequest => 'No request found at the cursor.';

	/// en: 'Invalid URL: ${url}'
	String invalidUrl({required Object url}) => 'Invalid URL: ${url}';

	/// en: 'Variable {{${name}}} has no value. Declare it with @${name} = … in this file.'
	String unresolvedVariable({required Object name}) => 'Variable {{${name}}} has no value. Declare it with @${name} = … in this file.';

	/// en: 'Body file not found: ${path}'
	String bodyFileMissing({required Object path}) => 'Body file not found: ${path}';

	/// en: 'Could not read the body file ${path}: ${detail}'
	String bodyFileUnreadable({required Object path, required Object detail}) => 'Could not read the body file ${path}: ${detail}';

	/// en: 'Could not reach the server: ${detail}'
	String connectionFailed({required Object detail}) => 'Could not reach the server: ${detail}';

	/// en: 'Could not reach the server.'
	String get connectionFailedNoDetail => 'Could not reach the server.';

	/// en: 'The request timed out after ${seconds}s.'
	String timeout({required Object seconds}) => 'The request timed out after ${seconds}s.';

	/// en: 'The response is larger than the ${bytes} byte limit.'
	String responseTooLarge({required Object bytes}) => 'The response is larger than the ${bytes} byte limit.';
}

// Path: orkest.kanbanView.deleteColumnDialog
class Translations$orkest$kanbanView$deleteColumnDialog$en {
	Translations$orkest$kanbanView$deleteColumnDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete “${name}”?'
	String title({required Object name}) => 'Delete “${name}”?';

	/// en: 'This column has ${count}. Choose what happens to them.'
	String message({required Object count}) => 'This column has ${count}. Choose what happens to them.';

	/// en: 'Move to the previous column'
	String get moveCards => 'Move to the previous column';

	/// en: 'Delete with the column'
	String get deleteAll => 'Delete with the column';

	/// en: 'This column is empty.'
	String get emptyMessage => 'This column is empty.';
}

// Path: orkest.gallery.dbQuery
class Translations$orkest$gallery$dbQuery$en {
	Translations$orkest$gallery$dbQuery$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Database query'
	String get title => 'Database query';

	/// en: 'SQL editor with a result grid, using one of the registered connections.'
	String get description => 'SQL editor with a result grid, using one of the registered connections.';
}

// Path: orkest.gallery.kanban
class Translations$orkest$gallery$kanban$en {
	Translations$orkest$gallery$kanban$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Kanban board'
	String get title => 'Kanban board';

	/// en: 'Columns and cards stored as plain markdown. Drag, edit and comment.'
	String get description => 'Columns and cards stored as plain markdown. Drag, edit and comment.';
}

// Path: orkest.gallery.layout
class Translations$orkest$gallery$layout$en {
	Translations$orkest$gallery$layout$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Pane layout'
	String get title => 'Pane layout';

	/// en: 'Terminals and splits to open in one go, like tmuxinator. Can run automatically on new worktrees.'
	String get description => 'Terminals and splits to open in one go, like tmuxinator. Can run automatically on new worktrees.';
}

// Path: orkest.gallery.httpRequest
class Translations$orkest$gallery$httpRequest$en {
	Translations$orkest$gallery$httpRequest$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'HTTP requests'
	String get title => 'HTTP requests';

	/// en: 'Write requests in a file and run them with the response next to it.'
	String get description => 'Write requests in a file and run them with the response next to it.';
}

// Path: orkest.gallery.html
class Translations$orkest$gallery$html$en {
	Translations$orkest$gallery$html$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'HTML view'
	String get title => 'HTML view';

	/// en: 'A page the agent writes and Orkest Code renders directly: mind maps, diagrams, charts, whatever you need.'
	String get description => 'A page the agent writes and Orkest Code renders directly: mind maps, diagrams, charts, whatever you need.';
}

// Path: orkest.gallery.tasks
class Translations$orkest$gallery$tasks$en {
	Translations$orkest$gallery$tasks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Tasks'
	String get title => 'Tasks';

	/// en: 'Commands to run from the Tasks panel, such as the dev server, tests and build. Stored in .orkest/tasks.json.'
	String get description => 'Commands to run from the Tasks panel, such as the dev server, tests and build. Stored in .orkest/tasks.json.';
}

// Path: orkest.gallery.notebook
class Translations$orkest$gallery$notebook$en {
	Translations$orkest$gallery$notebook$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notebook'
	String get title => 'Notebook';

	/// en: 'A folder of short notes with tags. The agent writes, you read and edit. Also opens in Obsidian.'
	String get description => 'A folder of short notes with tags. The agent writes, you read and edit. Also opens in Obsidian.';
}

// Path: orkest.gallery.workspaceEnv
class Translations$orkest$gallery$workspaceEnv$en {
	Translations$orkest$gallery$workspaceEnv$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workspace env'
	String get title => 'Workspace env';

	/// en: 'Variables injected into every terminal of this workspace. Put API tokens or logins here instead of pasting them into the agent's prompt. Kept out of git.'
	String get description => 'Variables injected into every terminal of this workspace. Put API tokens or logins here instead of pasting them into the agent\'s prompt. Kept out of git.';
}

// Path: orkest.gallery.panel
class Translations$orkest$gallery$panel$en {
	Translations$orkest$gallery$panel$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Panel'
	String get title => 'Panel';

	/// en: 'An HTML page with a bridge to the app: its buttons run Orkest Code CLI and shell commands on this machine. A playground for quick dashboards.'
	String get description => 'An HTML page with a bridge to the app: its buttons run Orkest Code CLI and shell commands on this machine. A playground for quick dashboards.';
}

// Path: orkest.notebook.format
class Translations$orkest$notebook$format$en {
	Translations$orkest$notebook$format$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Bold (⌘B)'
	String get bold => 'Bold (⌘B)';

	/// en: 'Italic (⌘I)'
	String get italic => 'Italic (⌘I)';

	/// en: 'Strikethrough'
	String get strike => 'Strikethrough';

	/// en: 'Heading 1'
	String get heading1 => 'Heading 1';

	/// en: 'Heading 2'
	String get heading2 => 'Heading 2';

	/// en: 'Heading 3'
	String get heading3 => 'Heading 3';

	/// en: 'Bullet list'
	String get bullets => 'Bullet list';

	/// en: 'Numbered list'
	String get numbered => 'Numbered list';

	/// en: 'Checklist'
	String get checklist => 'Checklist';

	/// en: 'Quote'
	String get quote => 'Quote';

	/// en: 'Inline code (⌘E)'
	String get code => 'Inline code (⌘E)';

	/// en: 'Code block'
	String get codeBlock => 'Code block';

	/// en: 'Link (⌘K)'
	String get link => 'Link (⌘K)';

	/// en: 'Divider'
	String get rule => 'Divider';

	/// en: 'Link to a note ([[…]])'
	String get noteLink => 'Link to a note ([[…]])';

	/// en: 'Search notes'
	String get noteLinkSearch => 'Search notes';

	/// en: 'Insert image…'
	String get image => 'Insert image…';
}

// Path: settings.page.header
class Translations$settings$page$header$en {
	Translations$settings$page$header$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Settings'
	String get title => 'Settings';
}

// Path: settings.page.nav
class Translations$settings$page$nav$en {
	Translations$settings$page$nav$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get general => 'General';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Terminal'
	String get terminal => 'Terminal';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Shortcuts'
	String get shortcuts => 'Shortcuts';

	/// en: 'Notifications'
	String get notifications => 'Notifications';

	/// en: 'Automations'
	String get automations => 'Automations';

	/// en: 'Remote hosts'
	String get remoteHosts => 'Remote hosts';
}

// Path: settings.page.general
class Translations$settings$page$general$en {
	Translations$settings$page$general$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Editor'
	String get sectionEditor => 'Editor';

	/// en: 'Engine'
	String get editorEngineTitle => 'Engine';

	/// en: 'Orkest Code (default)'
	String get editorEngineOrkest => 'Orkest Code (default)';

	/// en: 'Neovim'
	String get editorEngineNeovim => 'Neovim';

	/// en: 'Looking for Neovim…'
	String get neovimChecking => 'Looking for Neovim…';

	/// en: 'Neovim was not found in your shell PATH.'
	String get neovimNotFound => 'Neovim was not found in your shell PATH.';

	/// en: 'Check again'
	String get neovimRefresh => 'Check again';

	/// en: 'Show Orkest Code terminal'
	String get showOrkestTitle => 'Show Orkest Code terminal';

	/// en: 'Keep a pathless, terminal-only workspace pinned at the top of the rail. Turning it off closes its terminals.'
	String get showOrkestDesc => 'Keep a pathless, terminal-only workspace pinned at the top of the rail. Turning it off closes its terminals.';

	/// en: 'Launch at login'
	String get launchAtStartupTitle => 'Launch at login';

	/// en: 'Start Orkest Code automatically when you sign in to your computer.'
	String get launchAtStartupDesc => 'Start Orkest Code automatically when you sign in to your computer.';

	/// en: 'Updates'
	String get sectionUpdates => 'Updates';

	/// en: 'Check for updates'
	String get checkUpdatesTitle => 'Check for updates';

	/// en: 'How often Orkest Code should look for new versions.'
	String get checkUpdatesDesc => 'How often Orkest Code should look for new versions.';

	late final Translations$settings$page$general$updateFrequency$en updateFrequency = Translations$settings$page$general$updateFrequency$en.internal(_root);

	/// en: 'Developer mode'
	String get developerModeTitle => 'Developer mode';

	/// en: 'Records Orkest Code’s own errors and warnings in a separate Telemetry store (the “Orkest Code” chip) and turns on performance metrics. Only useful to whoever maintains the app.'
	String get developerModeDesc => 'Records Orkest Code’s own errors and warnings in a separate Telemetry store (the “Orkest Code” chip) and turns on performance metrics. Only useful to whoever maintains the app.';
}

// Path: settings.page.diagnostics
class Translations$settings$page$diagnostics$en {
	Translations$settings$page$diagnostics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Diagnostics'
	String get sectionTitle => 'Diagnostics';

	/// en: 'Log file'
	String get logFileTitle => 'Log file';

	/// en: 'Errors and startup events are recorded here, kept for ${days} days. ${path}'
	String logFileDesc({required Object days, required Object path}) => 'Errors and startup events are recorded here, kept for ${days} days.\n${path}';

	/// en: 'unavailable'
	String get unavailable => 'unavailable';

	/// en: 'Reveal'
	String get reveal => 'Reveal';

	/// en: 'Report a problem'
	String get reportTitle => 'Report a problem';

	/// en: 'Opens a pre-filled issue with your version, OS and recent log. Nothing is sent automatically — you review it first.'
	String get reportDesc => 'Opens a pre-filled issue with your version, OS and recent log. Nothing is sent automatically — you review it first.';

	/// en: 'Report…'
	String get reportButton => 'Report…';

	/// en: 'Problem report'
	String get reportDialogTitle => 'Problem report';

	/// en: 'Reported manually from Settings.'
	String get reportDialogError => 'Reported manually from Settings.';

	/// en: 'Describe what went wrong in the issue. The recent log is included below and in "Copy details".'
	String get reportDialogDescription => 'Describe what went wrong in the issue. The recent log is included below and in "Copy details".';
}

// Path: settings.page.storage
class Translations$settings$page$storage$en {
	Translations$settings$page$storage$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Storage'
	String get sectionTitle => 'Storage';

	/// en: 'Storage location'
	String get locationTitle => 'Storage location';

	/// en: 'Orkest Code keeps its projects, layouts and settings here. Point it at a synced folder to back it up. ${root}'
	String locationDesc({required Object root}) => 'Orkest Code keeps its projects, layouts and settings here. Point it at a synced folder to back it up.\n${root}';

	/// en: 'Use default'
	String get useDefault => 'Use default';

	/// en: 'Working…'
	String get working => 'Working…';

	/// en: 'Change…'
	String get change => 'Change…';

	/// en: 'Reset Orkest Code'
	String get resetTitle => 'Reset Orkest Code';

	/// en: 'Delete all local data — projects, layouts, settings and terminal history — and return to the default location.'
	String get resetDesc => 'Delete all local data — projects, layouts, settings and terminal history — and return to the default location.';

	/// en: 'Reset…'
	String get resetButton => 'Reset…';

	/// en: 'Reset'
	String get resetConfirm => 'Reset';

	/// en: 'Reset Orkest Code?'
	String get resetDialogTitle => 'Reset Orkest Code?';

	/// en: 'This permanently deletes all local Orkest Code data — projects, layouts, settings and terminal history. This cannot be undone. Orkest Code will close so you can start fresh.'
	String get resetDialogContent => 'This permanently deletes all local Orkest Code data — projects, layouts, settings and terminal history. This cannot be undone. Orkest Code will close so you can start fresh.';

	/// en: 'Restart required'
	String get restartRequiredTitle => 'Restart required';

	/// en: 'Orkest Code will use this folder from the next launch: ${path}'
	String restartChangeFolderMessage({required Object path}) => 'Orkest Code will use this folder from the next launch:\n${path}';

	/// en: 'Orkest Code will use the default system location from the next launch. Your data in the custom folder is left untouched.'
	String get restartUseDefaultMessage => 'Orkest Code will use the default system location from the next launch. Your data in the custom folder is left untouched.';

	/// en: 'All Orkest Code data was cleared. Restart to start fresh.'
	String get restartResetMessage => 'All Orkest Code data was cleared. Restart to start fresh.';

	/// en: 'Later'
	String get later => 'Later';

	/// en: 'Quit Orkest Code'
	String get quitOrkest => 'Quit Orkest Code';

	/// en: 'Choose a folder for Orkest Code data'
	String get chooseFolderDialogTitle => 'Choose a folder for Orkest Code data';
}

// Path: settings.page.terminal
class Translations$settings$page$terminal$en {
	Translations$settings$page$terminal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Default terminal'
	String get sectionDefaultTerminal => 'Default terminal';

	/// en: 'Engine'
	String get engineTitle => 'Engine';

	/// en: 'Used by new terminal tabs and task output buffers. Open tabs keep their current engine.'
	String get engineDesc => 'Used by new terminal tabs and task output buffers. Open tabs keep their current engine.';

	/// en: 'Shell'
	String get shellTitle => 'Shell';

	/// en: 'Which shell new terminal tabs open. The arrow next to + still opens any other one, just for that tab.'
	String get shellDesc => 'Which shell new terminal tabs open. The arrow next to + still opens any other one, just for that tab.';

	/// en: 'No WSL distros found. Install one (wsl.exe --install) and restart Orkest Code to see it listed here.'
	String get noWslMessage => 'No WSL distros found. Install one (wsl.exe --install) and restart Orkest Code to see it listed here.';

	/// en: 'Behavior'
	String get sectionBehavior => 'Behavior';

	/// en: 'Close tab when the shell exits'
	String get closeOnExitTitle => 'Close tab when the shell exits';

	/// en: 'When a shell ends on its own (exit, Ctrl-D), close its tab instead of leaving a dead terminal.'
	String get closeOnExitDesc => 'When a shell ends on its own (exit, Ctrl-D), close its tab instead of leaving a dead terminal.';
}

// Path: settings.page.appearance
class Translations$settings$page$appearance$en {
	Translations$settings$page$appearance$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Theme'
	String get sectionTheme => 'Theme';

	/// en: 'Theme'
	String get themeTitle => 'Theme';

	/// en: 'App colors, code highlighting and terminal palette.'
	String get themeDesc => 'App colors, code highlighting and terminal palette.';

	/// en: 'Mode'
	String get modeTitle => 'Mode';

	/// en: 'Which variant of the theme to use.'
	String get modeDesc => 'Which variant of the theme to use.';

	/// en: '"${theme}" only ships a dark variant, so this has no effect.'
	String modeOnlyDark({required Object theme}) => '"${theme}" only ships a dark variant, so this has no effect.';

	/// en: '"${theme}" only ships a light variant, so this has no effect.'
	String modeOnlyLight({required Object theme}) => '"${theme}" only ships a light variant, so this has no effect.';

	/// en: 'Theme file'
	String get themeFileTitle => 'Theme file';

	/// en: 'Import a theme from a JSON file, or export the active one.'
	String get themeFileDesc => 'Import a theme from a JSON file, or export the active one.';

	/// en: 'Code'
	String get previewCode => 'Code';

	/// en: 'Terminal'
	String get previewTerminal => 'Terminal';

	/// en: 'System'
	String get themeSystem => 'System';

	/// en: 'Light'
	String get themeLight => 'Light';

	/// en: 'Dark'
	String get themeDark => 'Dark';

	/// en: 'Fonts'
	String get sectionFonts => 'Fonts';

	/// en: 'Interface font'
	String get interfaceFontTitle => 'Interface font';

	/// en: 'Used across the whole app. Empty = system default.'
	String get interfaceFontDesc => 'Used across the whole app. Empty = system default.';

	/// en: 'Interface size'
	String get interfaceSizeTitle => 'Interface size';

	/// en: 'Code font'
	String get codeFontTitle => 'Code font';

	/// en: 'Code and diffs. Empty = system default.'
	String get codeFontDesc => 'Code and diffs. Empty = system default.';

	/// en: 'Code size'
	String get codeSizeTitle => 'Code size';

	/// en: 'Terminal font'
	String get terminalFontTitle => 'Terminal font';

	/// en: 'Terminal only. Empty = system default.'
	String get terminalFontDesc => 'Terminal only. Empty = system default.';

	/// en: 'Terminal size'
	String get terminalSizeTitle => 'Terminal size';

	/// en: 'Off = follows the code size.'
	String get terminalSizeDesc => 'Off = follows the code size.';

	/// en: 'Follow code size'
	String get terminalSizeInherit => 'Follow code size';

	/// en: 'Terminal weight'
	String get terminalWeightTitle => 'Terminal weight';

	/// en: 'Low-density screens render strokes heavier. Auto lightens them there and leaves Retina untouched.'
	String get terminalWeightDesc => 'Low-density screens render strokes heavier. Auto lightens them there and leaves Retina untouched.';

	/// en: 'Auto (by screen)'
	String get terminalWeightAuto => 'Auto (by screen)';

	/// en: 'Light'
	String get terminalWeightLight => 'Light';

	/// en: 'Normal'
	String get terminalWeightNormal => 'Normal';

	/// en: 'Medium'
	String get terminalWeightMedium => 'Medium';

	/// en: 'Semibold'
	String get terminalWeightSemiBold => 'Semibold';

	/// en: 'Conversation'
	String get sectionConversation => 'Conversation';

	/// en: 'Pin user message'
	String get pinUserMessageTitle => 'Pin user message';

	/// en: 'The question stays fixed at the top while the answer scrolls.'
	String get pinUserMessageDesc => 'The question stays fixed at the top while the answer scrolls.';

	/// en: 'Import…'
	String get importTheme => 'Import…';

	/// en: 'Export…'
	String get exportTheme => 'Export…';

	/// en: 'Remove'
	String get deleteTheme => 'Remove';

	/// en: 'Pick a theme file'
	String get importThemeDialog => 'Pick a theme file';

	/// en: 'Save theme as'
	String get exportThemeDialog => 'Save theme as';

	/// en: 'Theme "${name}" imported.'
	String themeImported({required Object name}) => 'Theme "${name}" imported.';

	/// en: 'Theme saved.'
	String get themeExported => 'Theme saved.';

	/// en: 'Theme removed.'
	String get themeDeleted => 'Theme removed.';

	/// en: 'Choose a font'
	String get fontPickerTitle => 'Choose a font';

	/// en: 'Search fonts'
	String get fontPickerSearch => 'Search fonts';

	/// en: 'No matching font found on this machine.'
	String get fontPickerEmpty => 'No matching font found on this machine.';

	/// en: 'included'
	String get fontPickerBundled => 'included';

	/// en: 'Not listed? Type the exact family name.'
	String get fontPickerCustom => 'Not listed? Type the exact family name.';

	/// en: 'Family name'
	String get fontPickerCustomHint => 'Family name';

	/// en: 'Use'
	String get fontPickerUse => 'Use';

	/// en: 'Default'
	String get fontPickerDefault => 'Default';

	/// en: 'Not found on this machine — falling back.'
	String get fontMissing => 'Not found on this machine — falling back.';

	/// en: 'Layout'
	String get sectionLayout => 'Layout';

	/// en: 'Swap side panels'
	String get swapPanelsTitle => 'Swap side panels';

	/// en: 'Puts workspaces on the right and files, search, git and database on the left.'
	String get swapPanelsDesc => 'Puts workspaces on the right and files, search, git and database on the left.';
}

// Path: settings.page.notifications
class Translations$settings$page$notifications$en {
	Translations$settings$page$notifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notifications'
	String get sectionTitle => 'Notifications';

	/// en: 'Enable notifications'
	String get enableTitle => 'Enable notifications';

	/// en: 'Alert me when an agent finishes a turn and the window is not focused.'
	String get enableDesc => 'Alert me when an agent finishes a turn and the window is not focused.';

	/// en: 'System permission'
	String get systemPermissionTitle => 'System permission';

	/// en: 'Orkest Code is allowed to send notifications.'
	String get grantedDesc => 'Orkest Code is allowed to send notifications.';

	/// en: 'macOS has not granted notification access yet.'
	String get notGrantedDesc => 'macOS has not granted notification access yet.';

	/// en: 'Granted'
	String get granted => 'Granted';

	/// en: 'Request permission'
	String get requestPermission => 'Request permission';

	/// en: 'Sounds'
	String get soundsTitle => 'Sounds';

	/// en: 'Volume'
	String get soundVolumeTitle => 'Volume';

	/// en: 'Turn completed'
	String get soundTurnDone => 'Turn completed';

	/// en: 'An agent finished its turn.'
	String get soundTurnDoneDesc => 'An agent finished its turn.';

	/// en: 'Action required'
	String get soundActionRequired => 'Action required';

	/// en: 'An agent is waiting for your approval or answer.'
	String get soundActionRequiredDesc => 'An agent is waiting for your approval or answer.';

	/// en: 'Default'
	String get soundDefault => 'Default';

	/// en: 'Custom: ${name}'
	String soundCustom({required Object name}) => 'Custom: ${name}';

	/// en: 'Choose file'
	String get soundChooseFile => 'Choose file';

	/// en: 'Reset to default'
	String get soundReset => 'Reset to default';

	/// en: 'Also play when this tab is active'
	String get soundOnActiveTab => 'Also play when this tab is active';

	/// en: 'Preview'
	String get soundPreview => 'Preview';
}

// Path: settings.page.shortcuts
class Translations$settings$page$shortcuts$en {
	Translations$settings$page$shortcuts$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keyboard shortcuts are not customizable yet.'
	String get notCustomizable => 'Keyboard shortcuts are not customizable yet.';
}

// Path: settings.page.languages
class Translations$settings$page$languages$en {
	Translations$settings$page$languages$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'FORMATTING'
	String get sectionFormatting => 'FORMATTING';

	/// en: 'Format on save'
	String get formatOnSaveTitle => 'Format on save';

	/// en: 'Format the file automatically when you save (⌘S).'
	String get formatOnSaveDesc => 'Format the file automatically when you save (⌘S).';

	/// en: 'LANGUAGE SERVERS'
	String get sectionLanguageServers => 'LANGUAGE SERVERS';

	/// en: 'Errors and formatting use each language's language server. Orkest Code does not install servers — it uses what is already on your machine. ● responds · ○ not found or invalid command (install the server or adjust the command).'
	String get footerNote => 'Errors and formatting use each language\'s language server. Orkest Code does not install servers — it uses what is already on your machine. ● responds · ○ not found or invalid command (install the server or adjust the command).';

	/// en: 'Language server command'
	String get serverCommandLabel => 'Language server command';

	/// en: 'Formatter command (optional)'
	String get formatterCommandLabel => 'Formatter command (optional)';

	/// en: 'External formatter with %FILE% placeholder. Takes precedence over the LSP formatter when set.'
	String get formatterHint => 'External formatter with %FILE% placeholder. Takes precedence over the LSP formatter when set.';

	/// en: 'Reset to default'
	String get resetToDefault => 'Reset to default';

	/// en: 'Save & restart'
	String get saveAndRestart => 'Save & restart';

	/// en: 'Server responds'
	String get statusResponds => 'Server responds';

	/// en: 'Server not found or command invalid'
	String get statusNotFound => 'Server not found or command invalid';
}

// Path: settings.page.automations
class Translations$settings$page$automations$en {
	Translations$settings$page$automations$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Commit messages'
	String get sectionCommitMessages => 'Commit messages';

	/// en: 'Harness'
	String get harness => 'Harness';

	/// en: 'Looking for installed command-line harnesses…'
	String get harnessDiscovering => 'Looking for installed command-line harnesses…';

	/// en: 'No supported harness was found on PATH.'
	String get harnessNoneFound => 'No supported harness was found on PATH.';

	/// en: '${harness} is configured but unavailable.'
	String harnessConfiguredUnavailable({required Object harness}) => '${harness} is configured but unavailable.';

	/// en: 'Choose the CLI used to generate commit messages.'
	String get harnessChoose => 'Choose the CLI used to generate commit messages.';

	/// en: 'Refresh installed harnesses'
	String get harnessRefresh => 'Refresh installed harnesses';

	/// en: 'Not configured'
	String get notConfigured => 'Not configured';

	/// en: 'Model'
	String get model => 'Model';

	/// en: 'The model list is unavailable until the harness is found.'
	String get modelUnavailable => 'The model list is unavailable until the harness is found.';

	/// en: 'This harness uses its CLI default model.'
	String get modelCliOnly => 'This harness uses its CLI default model.';

	/// en: 'CLI default'
	String get modelCliDefault => 'CLI default';

	/// en: 'Auto'
	String get modelAuto => 'Auto';

	/// en: 'Search among ${count} models…'
	String modelSearch({required Object count}) => 'Search among ${count} models…';

	/// en: 'This harness routes the model automatically.'
	String get modelAutoRouted => 'This harness routes the model automatically.';

	/// en: 'Only models your account can use are listed.'
	String get modelAccountOnly => 'Only models your account can use are listed.';

	/// en: 'Generate from Source Control'
	String get generateFromSourceControl => 'Generate from Source Control';

	/// en: 'Orkest Code sends only the selected diff and recent commit subjects. Common credential patterns and sensitive files are redacted before the harness runs.'
	String get generateFromSourceControlDescription => 'Orkest Code sends only the selected diff and recent commit subjects. Common credential patterns and sensitive files are redacted before the harness runs.';

	/// en: 'Could not discover installed automation harnesses.'
	String get discoveryFailed => 'Could not discover installed automation harnesses.';

	/// en: 'Model "${model}" is no longer available for ${harness}. Using the CLI default — pick another model in Settings if needed.'
	String staleModel({required Object model, required Object harness}) => 'Model "${model}" is no longer available for ${harness}. Using the CLI default — pick another model in Settings if needed.';

	/// en: 'Recommended'
	String get recommendedSuffix => 'Recommended';
}

// Path: settings.page.general.updateFrequency
class Translations$settings$page$general$updateFrequency$en {
	Translations$settings$page$general$updateFrequency$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Daily'
	String get daily => 'Daily';

	/// en: 'Weekly'
	String get weekly => 'Weekly';

	/// en: 'Monthly'
	String get monthly => 'Monthly';

	/// en: 'Never'
	String get never => 'Never';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'core.bootstrapError.title' => 'Failed to initialize Orkest Code',
			'core.bootstrapError.retry' => 'Retry',
			'core.macosNotifications.title' => 'Enable Notifications on macOS',
			'core.macosNotifications.intro' => 'Notifications are currently disabled in your system settings. Follow the steps below to enable them:',
			'core.macosNotifications.step1' => 'Open System Settings on your Mac.',
			'core.macosNotifications.step2' => 'Navigate to the Notifications section in the left sidebar.',
			'core.macosNotifications.step3' => 'Find and select the Orkest Code application from the list.',
			'core.macosNotifications.step4' => 'Toggle the Allow Notifications switch on.',
			'core.macosNotifications.tip' => 'Tip: If the app does not appear in the list, close and reopen it to trigger its registration in the system.',
			'core.macosNotifications.gotIt' => 'Got it',
			'core.appErrorView.renderFailed' => 'This part of the app failed to render',
			'core.appErrorView.details' => 'Details',
			'core.appErrorView.renderErrorTitle' => 'Render error',
			'core.errorReportDialog.defaultDescription' => 'Something went wrong. The details below were saved to the log — you can report them so it gets fixed.',
			'core.errorReportDialog.copyDetails' => 'Copy details',
			'core.errorReportDialog.reportIssue' => 'Report issue',
			'core.windowControls.minimize' => 'Minimize',
			'core.windowControls.maximize' => 'Maximize',
			'core.windowControls.close' => 'Close',
			'core.crash.title' => 'Unexpected shutdown',
			'core.crash.bannerTitle' => 'Orkest Code closed unexpectedly',
			'core.crash.report' => 'Report',
			'core.crash.dismiss' => 'Dismiss',
			'core.crash.crashMessage' => ({required Object version}) => 'The previous session (version ${version}) ended without shutting down cleanly. Want to report it? The log is included and you can review everything before sending.',
			'core.crash.crashError' => ({required Object startedAt, required Object pid}) => 'Session started at ${startedAt} (pid ${pid}) ended without a clean shutdown.',
			'core.crash.crashDescription' => 'No error was captured — the app was terminated by the system. The log below is from that session and is the most useful part.',
			'core.menu.settings' => 'Settings…',
			'core.menu.checkForUpdates' => 'Check for Updates…',
			'core.menu.file' => 'File',
			'core.menu.newTerminal' => 'New Terminal',
			'core.menu.openWorkspace' => 'Open Workspace',
			'core.menu.goToFile' => 'Go to File…',
			'core.menu.save' => 'Save',
			'core.menu.discard' => 'Discard',
			'core.menu.format' => 'Format',
			'core.menu.view' => 'View',
			'core.menu.toggleWorkspacePanel' => 'Toggle Workspace Panel',
			'core.menu.toggleFiles' => 'Toggle Files',
			'core.menu.splitRight' => 'Split Right',
			'core.menu.splitDown' => 'Split Down',
			'core.menu.focusPane' => 'Focus Pane',
			'core.menu.focusLeft' => 'Left  (⌘⌥←)',
			'core.menu.focusRight' => 'Right  (⌘⌥→)',
			'core.menu.focusUp' => 'Up  (⌘⌥↑)',
			'core.menu.focusDown' => 'Down  (⌘⌥↓)',
			'core.menu.selectTab' => 'Select Tab',
			'core.menu.tabN' => ({required Object n}) => 'Tab ${n}',
			'core.menu.lastTab' => 'Last Tab',
			'core.menu.previousWorkspace' => 'Previous Workspace',
			'core.menu.nextWorkspace' => 'Next Workspace',
			'core.menu.zoomIn' => 'Zoom In',
			'core.menu.zoomOut' => 'Zoom Out',
			'core.menu.actualSize' => 'Actual Size',
			'core.menu.window' => 'Window',
			'core.menu.quit' => 'Quit',
			'core.menu.minimize' => 'Minimize',
			'core.menu.zoom' => 'Zoom',
			'common.cancel' => 'Cancel',
			'common.confirm' => 'Confirm',
			'common.create' => 'Create',
			'common.gotIt' => 'Got it',
			'common.save' => 'Save',
			'common.close' => 'Close',
			'common.delete' => 'Delete',
			'common.done' => 'Done',
			'common.add' => 'Add',
			'common.test' => 'Test',
			'common.ok' => 'OK',
			'common.loading' => 'Loading…',
			'common.checking' => 'Checking…',
			'common.remove' => 'Remove',
			'common.restart' => 'Restart',
			'common.settings' => 'Settings',
			'common.send' => 'Send',
			'common.open' => 'Open',
			'common.dismiss' => 'Dismiss',
			'common.report' => 'Report',
			'common.copyCode' => 'Copy code',
			'common.search' => 'Search',
			'common.noResults' => 'No results',
			'orkest.officeWorld.reception' => 'Reception',
			'orkest.officeWorld.cafe' => 'Café',
			'orkest.officeWorld.restrooms' => 'Restrooms',
			'orkest.officeWorld.lounge' => 'Lounge',
			'orkest.officeWorld.rosterTitle' => 'Office agents',
			'orkest.officeWorld.rosterSearch' => 'Search agents or projects',
			'orkest.officeWorld.rosterEmpty' => 'No active agents found',
			'orkest.officeWorld.activityFeed' => 'Activity',
			'orkest.officeWorld.activityEmpty' => 'Observed activity will appear here.',
			'orkest.officeWorld.collapseRoster' => 'Collapse agent list',
			'orkest.officeWorld.collapseFeed' => 'Collapse activity feed',
			'orkest.officeWorld.reopenRoster' => 'Agents',
			'orkest.officeWorld.reopenFeed' => 'Activity',
			'orkest.officeWorld.working' => 'Working',
			'orkest.officeWorld.waiting' => 'Waiting',
			'orkest.officeWorld.idle' => 'Available',
			'orkest.officeWorld.agentProfile' => 'Agent profile',
			'orkest.officeWorld.project' => 'Project',
			'orkest.officeWorld.provider' => 'Agent',
			'orkest.officeWorld.currentStatus' => 'Current status',
			'orkest.officeWorld.followAgent' => 'Follow character',
			'orkest.officeWorld.stopFollowingAgent' => 'Stop following',
			'orkest.officeWorld.centerAgent' => 'Center character',
			'orkest.officeWorld.sessionDuration' => 'Current Orkest Code session',
			'orkest.officeWorld.workingDirectory' => 'Working directory',
			'orkest.officeWorld.statsPending' => 'Model, token and tool statistics are not collected by Orkest Code yet.',
			'orkest.officeWorld.recentActivity' => 'Recent activity in this run',
			'orkest.officeWorld.promptReceived' => 'Received a request',
			'orkest.officeWorld.agentThinking' => 'Thinking',
			'orkest.officeWorld.agentResponded' => 'Response sent',
			'orkest.officeWorld.activityError' => 'Something went wrong',
			'orkest.officeWorld.readingFile' => 'Reading a file',
			'orkest.officeWorld.searchingCode' => 'Searching the code',
			'orkest.officeWorld.editingFile' => 'Editing a file',
			'orkest.officeWorld.writingFile' => 'Writing a file',
			'orkest.officeWorld.runningCommand' => 'Terminal command',
			'orkest.officeWorld.runningTests' => 'Running tests',
			'orkest.officeWorld.browsingWeb' => 'Searching the web',
			'orkest.officeWorld.organizingTasks' => 'Organizing tasks',
			'orkest.officeWorld.callingSubagents' => 'Calling subagents',
			'orkest.officeWorld.toolCompleted' => 'Tool completed',
			'orkest.officeWorld.usingTool' => 'Using tool',
			'orkest.officeWorld.editAgentName' => 'Edit agent name',
			'orkest.officeWorld.agentName' => 'Agent name',
			'orkest.officeWorld.workingInTerminal' => 'Working in terminal',
			'orkest.officeWorld.waitingInTerminal' => 'Needs you in terminal',
			'orkest.officeWorld.waitingBubble' => 'Respond in terminal',
			'orkest.officeWorld.respond' => 'Respond',
			'orkest.officeWorld.dismissNotification' => 'Dismiss notification',
			'orkest.officeWorld.editAppearance' => 'Edit character',
			'orkest.officeWorld.randomizeAppearance' => 'Randomize',
			'orkest.officeWorld.resetAppearance' => 'Reset to random',
			'orkest.officeWorld.skin' => 'Skin',
			'orkest.officeWorld.hair' => 'Hair',
			'orkest.officeWorld.beard' => 'Facial hair',
			'orkest.officeWorld.eyes' => 'Eyes',
			'orkest.officeWorld.top' => 'Top',
			'orkest.officeWorld.bottom' => 'Bottom',
			'orkest.officeWorld.shoes' => 'Shoes',
			'orkest.officeWorld.accessory' => 'Accessory',
			'orkest.officeWorld.turnCompleted' => 'Turn completed',
			'orkest.officeWorld.subagentFailed' => 'Subagent failed',
			'orkest.officeWorld.subagentInterrupted' => 'Subagent interrupted',
			'orkest.officeWorld.openTerminal' => 'Open terminal',
			'orkest.officeWorld.interactInOffice' => 'Interact in Office',
			'orkest.officeWorld.liveTerminal' => 'Live terminal',
			'orkest.officeWorld.terminalInputPlaceholder' => 'Type into the terminal…',
			'orkest.officeWorld.terminalOfficeHint' => 'Input goes to the original session. Use the response options shown by the agent in this terminal.',
			'orkest.officeWorld.appearance' => 'Office appearance',
			'orkest.officeWorld.officeTheme' => 'Seasonal theme',
			'orkest.officeWorld.themeAuto' => 'Automatic',
			'orkest.officeWorld.themeNone' => 'Original',
			'orkest.officeWorld.themeChristmas' => 'Christmas',
			'orkest.officeWorld.themeHalloween' => 'Halloween',
			'orkest.officeWorld.showNames' => 'Show agent names',
			'orkest.officeWorld.bubbles' => 'Activity bubbles',
			'orkest.officeWorld.bubblesAll' => 'All',
			'orkest.officeWorld.bubblesImportant' => 'Important',
			'orkest.officeWorld.bubblesNone' => 'None',
			'orkest.officeWorld.movement' => 'Office movement',
			'orkest.officeWorld.movementCalm' => 'Calm',
			'orkest.officeWorld.movementNormal' => 'Normal',
			'orkest.officeWorld.movementLively' => 'Lively',
			'orkest.officeWorld.daylight' => 'Day and night',
			'orkest.officeWorld.sounds' => 'Office sounds',
			'orkest.officeWorld.soundVolume' => 'Volume',
			'orkest.officeWorld.soundAlerts' => 'Alerts and completed tasks',
			'orkest.officeWorld.soundKeys' => 'Keyboard',
			'orkest.officeWorld.soundElevator' => 'Elevator',
			'orkest.officeWorld.soundSocial' => 'Ping-pong and arcade',
			'orkest.officeWorld.daylightAuto' => 'Automatic',
			'orkest.officeWorld.daylightDay' => 'Always day',
			'orkest.officeWorld.daylightNight' => 'Always night',
			'orkest.officeWorld.socialLife' => 'Social life',
			'orkest.officeWorld.gameCoins' => ({required Object count}) => '${count} office coins',
			'orkest.officeWorld.earnedWorking' => ({required Object count}) => '${count} earned through activity',
			'orkest.officeWorld.matchRecord' => ({required Object wins, required Object losses}) => '${wins} wins · ${losses} losses',
			'orkest.officeWorld.personality' => 'Personality',
			'orkest.officeWorld.friendships' => 'Friendships',
			'orkest.officeWorld.rivals' => 'Rivalries',
			'orkest.officeWorld.socialLedger' => 'Coin history',
			'orkest.officeWorld.socialActivity' => 'Office social life',
			'orkest.officeWorld.delegatedBy' => ({required Object name}) => 'Delegated by ${name}',
			'orkest.officeWorld.shellWaiting' => 'Waiting for a command',
			'orkest.officeWorld.socialEconomy' => 'Office game — no real monetary value',
			'orkest.confirmDialog.unsavedChangesTitle' => 'Unsaved changes',
			'orkest.confirmDialog.unsavedChangesMessage' => ({required Object fileName}) => '“${fileName}” has unsaved changes. Save them before closing?',
			'orkest.confirmDialog.dontSave' => 'Don\'t save',
			'orkest.confirmDialog.saveAndClose' => 'Save & close',
			'orkest.neovim.unavailable' => 'Neovim is not available. Opening in Orkest Code instead.',
			'orkest.neovim.openFailed' => 'Could not reach Neovim. Opening in Orkest Code instead.',
			'orkest.neovim.unsavedTitle' => 'Unsaved Neovim buffers',
			'orkest.neovim.unsavedMessage' => 'Neovim has modified buffers. Close the tab and discard those changes?',
			'orkest.neovim.closeAnyway' => 'Close anyway',
			'orkest.worktreeCreateDialog.forkTitle' => 'Fork worktree',
			'orkest.worktreeCreateDialog.createTitle' => 'Create worktree',
			'orkest.worktreeCreateDialog.forkSubtitle' => ({required Object root}) => 'New worktree branched from ${root}.',
			'orkest.worktreeCreateDialog.createSubtitle' => ({required Object root}) => 'New feature in ${root} — new branch from the current HEAD.',
			'orkest.worktreeCreateDialog.namePlaceholder' => 'feat/minha-feature',
			'orkest.worktreeCreateDialog.errorWhitespace' => 'No spaces in the name.',
			'orkest.worktreeCreateDialog.errorInvalidChar' => 'Invalid character for a branch name.',
			'orkest.worktreeCreateDialog.errorInvalidSequence' => 'Invalid sequence (e.g. "..", "//", starting/ending with "/").',
			'orkest.worktreeCreateDialog.errorReserved' => 'Reserved position (do not start with "-"/"." or end with ".lock").',
			'orkest.worktreeCreateDialog.errorDuplicateBranch' => 'A branch with that name already exists.',
			'orkest.worktreeCreateDialog.errorDuplicateWorktree' => 'A worktree with that name already exists.',
			'orkest.worktreeCreateDialog.errorBranchHierarchyConflict' => ({required Object target, required Object existing}) => 'Cannot create branch \'${target}\' because it conflicts with the existing branch \'${existing}\'.',
			'orkest.worktreeCreateDialog.errorBranchHierarchicalConflictGeneral' => 'A branch with a conflicting hierarchy already exists.',
			'orkest.worktreeCreateDialog.fork' => 'Fork',
			'orkest.worktreeCreateDialog.postCheckoutHint' => 'This repository has a post-checkout hook.',
			'orkest.worktreeCreateDialog.running' => 'Running…',
			'orkest.worktreeCreateDialog.advancedSettings' => 'Advanced Settings',
			'orkest.worktreeCreateDialog.copyIgnored' => 'Copy ignored files (.gitignore)',
			'orkest.worktreeCreateDialog.copyIgnoredDesc' => 'Copies files ignored by .gitignore (e.g. .env, local keys) to the new worktree.',
			'orkest.worktreeCreateDialog.copyUntracked' => 'Copy untracked files',
			'orkest.worktreeCreateDialog.copyUntrackedDesc' => 'Copies new or modified files that haven\'t been staged yet.',
			'orkest.worktreeCreateDialog.baseBranch' => 'Base branch',
			'orkest.worktreeCreateDialog.baseBranchDesc' => 'The branch from which the new worktree and branch will be created.',
			'orkest.worktreeCreateDialog.fetchRemote' => 'Fetch remote branch',
			'orkest.worktreeCreateDialog.fetchRemoteDesc' => 'Run git fetch to guarantee the base branch is confirmed before creating the worktree.',
			'orkest.worktreeCreateDialog.searchBranch' => 'Search branch...',
			'orkest.worktreeCreateDialog.back' => 'Back',
			'orkest.commitMessageDialog.commitTitle' => 'Commit',
			'orkest.commitMessageDialog.stageAndCommitTitle' => 'Stage and Commit',
			'orkest.commitMessageDialog.scopeNote' => ({required Object fileName}) => 'Commit "${fileName}" only.',
			'orkest.commitMessageDialog.placeholder' => 'fix: short summary of the change',
			'orkest.commitMessageDialog.errorEmptySubject' => 'The first line (subject) cannot be empty.',
			'orkest.commitMessageDialog.errorTooShort' => ({required Object min}) => 'Subject too short (min ${min} characters).',
			'orkest.commitMessageDialog.errorTooLong' => ({required Object max}) => 'Subject too long (max ${max} characters).',
			'orkest.commitMessageDialog.errorTrailingPeriod' => 'Subject should not end with a period.',
			'orkest.commitMessageDialog.errorControlChars' => 'Subject contains control characters.',
			'orkest.commitMessageDialog.errorBlankSecondLine' => 'Leave the second line blank (git subject/body separator).',
			'orkest.commitMessageDialog.generate' => 'Generate commit message',
			'orkest.commitMessageDialog.generateWith' => ({required Object harness}) => 'Generate with ${harness}',
			'orkest.commitMessageDialog.generating' => 'Generating…',
			'orkest.commitMessageDialog.cancelGeneration' => 'Cancel generation',
			'orkest.tasksPanel.reloadTasksTooltip' => 'Reload tasks',
			'orkest.tasksPanel.restartTooltip' => 'Restart',
			'orkest.tasksPanel.stopTooltip' => 'Stop',
			'orkest.tasksPanel.runTooltip' => 'Run',
			'orkest.tasksPanel.sendsKeyTooltip' => ({required Object label, required Object key}) => '${label} (sends \'${key}\')',
			'orkest.tasksPanel.startingTooltip' => 'Starting…',
			'orkest.tasksPanel.stoppingTooltip' => 'Stopping…',
			'orkest.tasksPanel.switchProfileTooltip' => 'Switch profile',
			'orkest.tasksPanel.moreKeysTooltip' => 'More keys',
			'orkest.tasksPanel.sectionTasks' => 'TASKS',
			'orkest.tasksPanel.noTasks' => 'No tasks detected in this project.',
			'orkest.tasksPanel.createTasksJson' => 'Create tasks.json',
			'orkest.tasksPanel.generateComposeTasks' => 'Generate Compose tasks',
			'orkest.tasksPanel.selectComposeEngine' => 'Choose a Compose engine',
			'orkest.tasksPanel.noComposeEngine' => 'Docker Compose or Podman Compose was not found.',
			'orkest.tasksPanel.invalidComposeFile' => 'The active file is not a valid Compose file with services.',
			'orkest.tasksPanel.invalidTasksJson' => 'tasks.json is invalid. No changes were written.',
			'orkest.tasksPanel.composeConflicts' => ({required Object labels}) => 'Kept non-Compose tasks with conflicting labels: ${labels}',
			'orkest.orkestPage.chooseProjectFolderDialogTitle' => 'Choose the project folder',
			'orkest.orkestPage.chooseWorkspaceFolderDialogTitle' => 'Choose the workspace folder',
			'orkest.orkestPage.workspaceRenamedTitle' => 'Workspace renamed',
			'orkest.orkestPage.workspaceRenamedMessage' => ({required Object name}) => 'The new name "${name}" will only be sent to agents after restarting the workspace or the application.',
			'orkest.orkestPage.syncTitle' => ({required Object label}) => 'Sync — ${label}',
			'orkest.orkestPage.pullTitle' => ({required Object label}) => 'Pull — ${label}',
			'orkest.orkestPage.pushTitle' => ({required Object label}) => 'Push — ${label}',
			'orkest.orkestPage.updateFromParentTitle' => ({required Object name}) => 'Update from Parent — ${name}',
			'orkest.orkestPage.mergeToParentTitle' => ({required Object name}) => 'Merge to Parent — ${name}',
			'orkest.orkestPage.worktreeMergedAndRemoved' => 'Worktree merged and removed.',
			'orkest.orkestPage.nothingWasChanged' => 'Nothing was changed.',
			'orkest.orkestPage.newRealmTitle' => 'New realm',
			'orkest.orkestPage.closeWorkspaceTitle' => 'Close workspace',
			'orkest.orkestPage.closeWorkspaceMessage' => ({required Object name}) => 'Close "${name}"? The agents in this workspace will be terminated. The folder on disk is kept.',
			'orkest.orkestPage.closeAction' => 'Close',
			'orkest.orkestPage.removeWorktreeTitle' => 'Remove worktree',
			'orkest.orkestPage.removeWorktreeMessage' => ({required Object name, required Object warn}) => 'Remove "${name}"? The worktree folder and the branch will be deleted and the agents in this fork will be terminated.${warn}',
			'orkest.orkestPage.removeWorktreeWarning' => ({required Object name}) => '\n\nWarning: the branch "${name}" has not been merged yet — removing it (git branch -D) discards the unmerged work.',
			'orkest.orkestPage.failedToRemoveWorktreeTitle' => 'Failed to remove worktree',
			'orkest.orkestPage.openLayoutTitle' => 'Open layout',
			'orkest.orkestPage.replaceLayoutTitle' => 'Replace the current layout?',
			'orkest.orkestPage.replaceLayoutMessage' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 tab will be closed, including one with a running process.', other: '${n} tabs will be closed, including ones with running processes.', ),
			'orkest.orkestPage.replaceLayoutConfirm' => 'Replace',
			'orkest.orkestPage.restartServerTooltip' => 'Restart server',
			'orkest.orkestPage.noLspAvailable' => 'No LSP available',
			'orkest.orkestPage.lspRunning' => 'running',
			'orkest.orkestPage.lspStopped' => 'stopped',
			'orkest.welcomeView.title' => 'Welcome to Orkest Code',
			'orkest.welcomeView.subtitle' => 'Open a folder or connect to a remote host to start.',
			'orkest.welcomeView.createWorkspace' => 'Create workspace',
			'orkest.welcomeView.openLocalFolder' => 'Open local folder',
			'orkest.welcomeView.connectHost' => 'Connect to host',
			'orkest.welcomeView.configureHost' => 'Configure host',
			'orkest.welcomeView.addWorkspace' => 'Add workspace',
			'orkest.paneView.closePaneTitle' => 'Close pane?',
			'orkest.paneView.closePaneMessage' => ({required Object count}) => 'This closes all ${count} tab(s) in this pane and ends the agents/terminals in it.',
			'orkest.paneView.close' => 'Close',
			'orkest.paneView.closeOtherTabs' => 'Close others',
			'orkest.paneView.closeTabsToTheRight' => 'Close to the right',
			'orkest.paneView.closeAllTabs' => 'Close all',
			'orkest.paneView.closeTabsTitle' => 'Close tabs?',
			'orkest.paneView.closeTabsMessage' => ({required Object count}) => 'This closes ${count} tab(s) and ends the agents/terminals in them.',
			'orkest.paneView.allTabs' => 'All tabs',
			'orkest.paneView.pinTab' => 'Pin tab',
			'orkest.paneView.openInNewWindow' => 'Open in new window',
			'orkest.paneView.rename' => 'Rename',
			'orkest.paneView.openAsMarkdown' => 'Open as markdown',
			'orkest.paneView.openAsBoard' => 'Open as board',
			'orkest.paneView.resetTitle' => 'Reset Title',
			'orkest.paneView.copyId' => 'Copy Id',
			'orkest.paneView.restartTab' => 'Restart',
			'orkest.paneView.newTab' => 'New tab',
			'orkest.paneView.newTerminal' => 'New terminal…',
			'orkest.paneView.splitRight' => 'Split right',
			'orkest.paneView.splitDown' => 'Split down',
			'orkest.paneView.closePane' => 'Close pane',
			'orkest.paneView.dropHereToMove' => 'Drop here to move the tab',
			'orkest.paneView.dockAsTab' => 'Dock as tab',
			'orkest.paneView.openBrowser' => 'Open browser',
			'orkest.paneView.openTerminal' => 'Open terminal',
			'orkest.paneView.openAsLayout' => 'Open as layout',
			'orkest.paneView.openAsYaml' => 'Open as YAML',
			'orkest.paneView.openAsPanel' => 'Open as panel',
			'orkest.paneView.openAsHtml' => 'Open as HTML',
			'orkest.fileTreePanel.viewDiff' => 'View Diff',
			'orkest.fileTreePanel.commit' => 'Commit',
			'orkest.fileTreePanel.stageAndCommit' => 'Stage and Commit',
			'orkest.fileTreePanel.unstage' => 'Unstage',
			'orkest.fileTreePanel.stageChanges' => 'Stage Changes',
			'orkest.fileTreePanel.discardChanges' => 'Discard Changes',
			'orkest.fileTreePanel.enterCommitMessage' => 'Enter a commit message.',
			'orkest.fileTreePanel.commitUnavailable' => 'Commit is unavailable for this workspace.',
			'orkest.fileTreePanel.gitErrorTitle' => 'Git error',
			'orkest.fileTreePanel.deleteNewFileTitle' => 'Delete new file?',
			'orkest.fileTreePanel.discardChangesTitle' => 'Discard changes?',
			'orkest.fileTreePanel.deleteNewFileMessage' => ({required Object name}) => '"${name}" is a new file and cannot be restored. Delete it?',
			'orkest.fileTreePanel.discardOneMessage' => ({required Object name}) => 'Discard all changes in "${name}"? Deleted files will be restored.',
			'orkest.fileTreePanel.discard' => 'Discard',
			'orkest.fileTreePanel.deleteAllNewFilesTitle' => 'Delete all new files?',
			'orkest.fileTreePanel.allNewFilesMessage' => ({required Object count}) => 'All ${count} files are new and will be deleted. This cannot be undone.',
			'orkest.fileTreePanel.discardTrackedMessage' => ({required Object count, required Object extra}) => 'Discard changes in ${count} tracked file(s)?${extra}',
			'orkest.fileTreePanel.discardTrackedExtra' => ({required Object count}) => ' ${count} new file(s) will be kept.',
			'orkest.fileTreePanel.deleteAll' => 'Delete All',
			'orkest.fileTreePanel.deleteQuestionTitle' => 'Delete?',
			'orkest.fileTreePanel.moveToTrash' => ({required Object name}) => 'Move “${name}” to the Trash?',
			'orkest.fileTreePanel.permanentlyDelete' => ({required Object name}) => 'Permanently delete “${name}”? This can’t be undone.',
			'orkest.fileTreePanel.couldNotDeleteTitle' => 'Could not delete',
			'orkest.fileTreePanel.moveQuestionTitle' => 'Move?',
			'orkest.fileTreePanel.moveMessage' => ({required Object name, required Object dest}) => 'Move “${name}” to “${dest}”?',
			'orkest.fileTreePanel.moveAction' => 'Move',
			'orkest.fileTreePanel.couldNotMoveTitle' => 'Could not move',
			'orkest.fileTreePanel.couldNotPasteTitle' => 'Could not paste',
			'orkest.fileTreePanel.filesTooltip' => 'Files',
			'orkest.fileTreePanel.searchTooltip' => 'Search',
			'orkest.fileTreePanel.sourceControlTooltip' => 'Source Control',
			'orkest.fileTreePanel.databaseTooltip' => 'Database',
			'orkest.fileTreePanel.sectionFiles' => 'FILES',
			'orkest.fileTreePanel.newFile' => 'New file',
			'orkest.fileTreePanel.newFolder' => 'New folder',
			'orkest.fileTreePanel.refreshTooltip' => 'Refresh',
			'orkest.fileTreePanel.collapseAll' => 'Collapse all folders',
			'orkest.fileTreePanel.sectionSourceControl' => 'SOURCE CONTROL',
			'orkest.fileTreePanel.viewAsList' => 'View as List',
			'orkest.fileTreePanel.viewAsTree' => 'View as Tree',
			'orkest.fileTreePanel.noFolderMessage' => 'No folder — open a workspace.',
			'orkest.fileTreePanel.amend' => 'Amend',
			'orkest.fileTreePanel.commitMessagePlaceholder' => 'Commit Message',
			'orkest.fileTreePanel.amendCommit' => 'Amend Commit',
			'orkest.fileTreePanel.lastCommit' => 'last commit',
			'orkest.fileTreePanel.openInFinder' => 'Open in Finder',
			'orkest.fileTreePanel.openInExplorer' => 'Open in Explorer',
			'orkest.fileTreePanel.openInFileManager' => 'Open in file manager',
			'orkest.fileTreePanel.open' => 'Open',
			'orkest.fileTreePanel.openWith' => 'Open with',
			'orkest.fileTreePanel.openInNewWindow' => 'Open in new window',
			'orkest.fileTreePanel.openLayout' => 'Open layout',
			'orkest.fileTreePanel.openAsMarkdown' => 'Open as markdown',
			'orkest.fileTreePanel.showGitDiff' => 'Show git diff',
			'orkest.fileTreePanel.createTerminal' => 'Open terminal',
			'orkest.fileTreePanel.rename' => 'Rename',
			'orkest.fileTreePanel.copy' => 'Copy',
			'orkest.fileTreePanel.cut' => 'Cut',
			'orkest.fileTreePanel.paste' => 'Paste',
			'orkest.fileTreePanel.copyRelativePath' => 'Copy relative path',
			'orkest.fileTreePanel.copyAbsolutePath' => 'Copy absolute path',
			'orkest.fileTreePanel.renameFailed' => 'Rename failed.',
			'orkest.fileTreePanel.noChanges' => 'No changes.',
			'orkest.fileTreePanel.stagedChangesHeader' => ({required Object count}) => 'STAGED CHANGES (${count})',
			'orkest.fileTreePanel.changesHeader' => ({required Object count}) => 'CHANGES (${count})',
			'orkest.fileTreePanel.discardAllChanges' => 'Discard All Changes',
			'orkest.fileTreePanel.unstageAllChanges' => 'Unstage All Changes',
			'orkest.fileTreePanel.stageAllChanges' => 'Stage All Changes',
			'orkest.fileTreePanel.discardFolderChanges' => 'Discard Folder Changes',
			'orkest.fileTreePanel.unstageFolderChanges' => 'Unstage Folder Changes',
			'orkest.fileTreePanel.stageFolderChanges' => 'Stage Folder Changes',
			'orkest.fileTreePanel.generateCommitMessage' => 'Generate commit message',
			'orkest.fileTreePanel.generateWith' => ({required Object harness}) => 'Generate with ${harness}',
			'orkest.fileTreePanel.generateUnavailableWhileAmending' => 'Unavailable while amending a commit',
			'orkest.fileTreePanel.cancelGeneration' => 'Cancel generation',
			'orkest.fileTreePanel.changes' => 'Changes',
			'orkest.fileTreePanel.history' => 'History',
			'orkest.fileTreePanel.historyRepository' => 'Repository',
			'orkest.fileTreePanel.historyNoRepository' => 'No Git repository available.',
			'orkest.fileTreePanel.historyEmpty' => 'No commits found.',
			'orkest.fileTreePanel.historyLoadFailed' => 'Could not load Git history.',
			'orkest.fileTreePanel.historyUntitledCommit' => 'Untitled commit',
			'orkest.fileTreePanel.historyNow' => 'now',
			'orkest.fileTreePanel.historyMinutesAgo' => ({required Object count}) => '${count}m ago',
			'orkest.fileTreePanel.historyHoursAgo' => ({required Object count}) => '${count}h ago',
			'orkest.fileTreePanel.historyYesterday' => 'yesterday',
			'orkest.fileTreePanel.historyDayAgo' => '1d ago',
			'orkest.fileTreePanel.historyDaysAgo' => ({required Object count}) => '${count}d ago',
			'orkest.fileTreePanel.historyFiles' => 'Files changed',
			'orkest.fileTreePanel.historyFilesEmpty' => 'No files changed.',
			'orkest.fileTreePanel.historyFilesLoadFailed' => 'Could not load changed files.',
			'orkest.fileTreePanel.diffEmptyTree' => 'Empty tree',
			'orkest.fileTreePanel.diffOriginal' => ({required Object ref}) => 'Original ${ref}',
			'orkest.fileTreePanel.diffModified' => ({required Object ref}) => 'Modified ${ref}',
			'orkest.fileTreePanel.diffWorkingTree' => 'Working tree',
			'orkest.fileTreePanel.diffBinaryFile' => 'Binary file - no text diff.',
			'orkest.fileTreePanel.diffNoChanges' => 'No changes.',
			'orkest.fileTreePanel.diffError' => ({required Object detail}) => 'Could not read the diff: ${detail}',
			'orkest.fileTreePanel.galleryTooltip' => 'Gallery',
			'orkest.fileTreePanel.sectionGallery' => 'GALLERY',
			'orkest.fileTreePanel.openAsHtml' => 'Open as HTML',
			'orkest.fileTreePanel.importQuestionTitle' => 'Copy here?',
			'orkest.fileTreePanel.importMessage' => ({required Object count, required Object dest}) => 'Copy ${count} items into “${dest}”?',
			'orkest.fileTreePanel.importAction' => 'Copy',
			'orkest.fileTreePanel.couldNotImportTitle' => 'Could not copy',
			'orkest.fileTreePanel.openInAgent' => ({required Object harness}) => 'Open in ${harness}',
			'orkest.fileViewer.cantOpen' => 'Can\'t open this file.',
			'orkest.fileViewer.couldNotLoadImage' => 'Could not load the image.',
			'orkest.fileViewer.preview' => 'Preview',
			'orkest.fileViewer.source' => 'Source',
			'orkest.fileViewer.reload' => 'Reload',
			'orkest.workspaceSettingsDialog.choosePhotoTitle' => 'Choose workspace photo',
			'orkest.workspaceSettingsDialog.title' => 'Workspace settings',
			'orkest.workspaceSettingsDialog.namePlaceholder' => 'Workspace name',
			'orkest.workspaceSettingsDialog.addPhoto' => 'Add photo',
			'orkest.workspaceSettingsDialog.changePhoto' => 'Change photo',
			'orkest.workspaceSettingsDialog.remove' => 'Remove',
			'orkest.workspaceSettingsDialog.color' => 'Color',
			'orkest.workspaceSettingsDialog.host' => 'Host',
			'orkest.workspaceSettingsDialog.folder' => 'Folder',
			'orkest.realmDialogs.namePlaceholder' => 'Realm name',
			'orkest.realmDialogs.duplicateName' => 'A realm with this name already exists.',
			'orkest.realmDialogs.newRealmTitle' => 'New realm',
			'orkest.realmDialogs.renameRealmTitle' => 'Rename realm',
			'orkest.realmDialogs.rename' => 'Rename',
			'orkest.realmDialogs.deleteRealmTitle' => 'Delete realm',
			'orkest.realmDialogs.deleteMessage' => ({required Object name, required Object suffix}) => 'Delete "${name}"? No workspace is deleted — the folder list just changes.${suffix}',
			'orkest.realmDialogs.deleteSuffixOne' => ' Its workspace will move to Default.',
			'orkest.realmDialogs.deleteSuffixMany' => ({required Object count}) => ' Its ${count} workspaces will move to Default.',
			'orkest.realmDialogs.manageRealmsTitle' => 'Manage realms',
			'orkest.realmDialogs.workspaceCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 workspace', other: '${n} workspaces', ),
			'orkest.dbRedisTable.deleteKeyTitle' => 'Delete key',
			'orkest.dbRedisTable.deleteKeyMessage' => ({required Object key}) => 'Delete "${key}" from this Redis database?',
			'orkest.dbRedisTable.refresh' => 'Refresh',
			'orkest.dbRedisTable.newKey' => 'New key',
			'orkest.dbRedisTable.columnKey' => 'KEY',
			'orkest.dbRedisTable.columnValue' => 'VALUE',
			'orkest.dbRedisTable.columnType' => 'TYPE',
			'orkest.dbRedisTable.columnTtl' => 'TTL',
			'orkest.dbRedisTable.keyCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 key', other: '${n} keys', ),
			'orkest.dbRedisTable.noKeys' => 'No keys in this database.',
			'orkest.dbRedisTable.noKeysMatch' => ({required Object pattern}) => 'No keys match "${pattern}".',
			'orkest.dbRedisTable.loadMore' => 'Load more',
			'orkest.dbRedisTable.loadingFullValue' => 'Loading full value…',
			'orkest.dbRedisTable.ttlMustBeNumber' => 'TTL must be a number of seconds.',
			'orkest.dbRedisTable.addKey' => 'Add key',
			'orkest.dbRedisTable.keyFieldHint' => 'key',
			'orkest.dbRedisTable.ttlFieldHint' => 'ttl (s, optional)',
			'orkest.dbRedisTable.valueFieldHint' => 'value',
			'orkest.dbRedisTable.searchHint' => 'Search — pattern, e.g. user:*',
			'orkest.dbQueryView.saveQueryAs' => 'Save query as',
			'orkest.dbQueryView.couldNotSave' => 'Could not save',
			'orkest.dbQueryView.selectDatabase' => 'Select database',
			'orkest.dbQueryView.noSqlConnections' => 'No SQL connections',
			'orkest.dbQueryView.running' => 'Running…',
			'orkest.dbQueryView.runSelection' => 'Run selection',
			'orkest.dbQueryView.run' => 'Run',
			'orkest.dbQueryView.pickDatabaseHint' => 'Pick a database above, then Run (⌘↵).',
			'orkest.dbQueryView.runQueryHint' => 'Run the query (⌘↵) to see results here.',
			'orkest.dbQueryView.noRows' => 'No rows.',
			'orkest.dbQueryView.rowsAffected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 row affected', other: '${n} rows affected', ),
			'orkest.dbQueryView.rowsFooter' => ({required Object n}) => '${n} rows',
			'orkest.dbQueryView.truncatedSuffix' => ' · truncated (raise -- limit)',
			'orkest.dbQueryView.table' => 'Table',
			'orkest.dbQueryView.json' => 'JSON',
			'orkest.dbQueryView.unsaved' => 'unsaved',
			'orkest.dbQueryView.saved' => 'saved',
			'orkest.dbQueryView.copied' => 'Copied',
			'orkest.dbQueryView.copy' => 'Copy',
			'orkest.httpView.saveRequestAs' => 'Save request as',
			'orkest.httpView.couldNotSave' => 'Could not save',
			'orkest.httpView.run' => 'Run',
			'orkest.httpView.running' => 'Running…',
			'orkest.httpView.noRequests' => 'No request in this file — write one, e.g. GET https://example.com',
			'orkest.httpView.selectRequest' => 'Select request',
			'orkest.httpView.requestCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 request', other: '${n} requests', ),
			'orkest.httpView.runHint' => 'Run the request (⌘↵) to see the response here.',
			'orkest.httpView.emptyBody' => 'Empty response body.',
			'orkest.httpView.body' => 'JSON',
			'orkest.httpView.headers' => 'Headers',
			'orkest.httpView.raw' => 'Text',
			'orkest.httpView.truncatedSuffix' => ' · truncated (response too large)',
			'orkest.httpView.error.title' => 'Request failed',
			'orkest.httpView.error.noRequest' => 'No request found at the cursor.',
			'orkest.httpView.error.invalidUrl' => ({required Object url}) => 'Invalid URL: ${url}',
			'orkest.httpView.error.unresolvedVariable' => ({required Object name}) => 'Variable {{${name}}} has no value. Declare it with @${name} = … in this file.',
			'orkest.httpView.error.bodyFileMissing' => ({required Object path}) => 'Body file not found: ${path}',
			'orkest.httpView.error.bodyFileUnreadable' => ({required Object path, required Object detail}) => 'Could not read the body file ${path}: ${detail}',
			'orkest.httpView.error.connectionFailed' => ({required Object detail}) => 'Could not reach the server: ${detail}',
			'orkest.httpView.error.connectionFailedNoDetail' => 'Could not reach the server.',
			'orkest.httpView.error.timeout' => ({required Object seconds}) => 'The request timed out after ${seconds}s.',
			'orkest.httpView.error.responseTooLarge' => ({required Object bytes}) => 'The response is larger than the ${bytes} byte limit.',
			'orkest.kanbanView.filter' => 'Filter',
			'orkest.kanbanView.filterTitlePlaceholder' => 'Search titles',
			'orkest.kanbanView.filterLabels' => 'Labels',
			_ => null,
		} ?? switch (path) {
			'orkest.kanbanView.filterClear' => 'Clear',
			'orkest.kanbanView.filterDependencies' => 'Dependencies',
			'orkest.kanbanView.filterBlocked' => 'Blocked',
			'orkest.kanbanView.filterReady' => 'Ready',
			'orkest.kanbanView.blockedBy' => 'Blocked by',
			'orkest.kanbanView.addBlocker' => 'Add a blocking card',
			'orkest.kanbanView.searchCards' => 'Search cards',
			'orkest.kanbanView.unknownCard' => 'unknown',
			'orkest.kanbanView.boardView' => 'Board',
			'orkest.kanbanView.listView' => 'List',
			'orkest.kanbanView.refresh' => 'Refresh from disk',
			'orkest.kanbanView.manageLabels' => 'Labels',
			'orkest.kanbanView.labelsTitle' => 'Labels in this board',
			'orkest.kanbanView.labelNamePlaceholder' => 'label name',
			'orkest.kanbanView.labelUsage' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 card', other: '${n} cards', ),
			'orkest.kanbanView.deleteLabel' => 'Delete label',
			'orkest.kanbanView.newCard' => 'new card',
			'orkest.kanbanView.newCardTitle' => 'New card',
			'orkest.kanbanView.newColumn' => 'New column',
			'orkest.kanbanView.columnNameTitle' => 'Column name',
			'orkest.kanbanView.dragColumn' => 'Drag column',
			'orkest.kanbanView.columnOptions' => 'Column options',
			'orkest.kanbanView.renameColumn' => 'Rename column',
			'orkest.kanbanView.moveColumnLeft' => 'Move left',
			'orkest.kanbanView.moveColumnRight' => 'Move right',
			'orkest.kanbanView.deleteColumn' => 'Delete column',
			'orkest.kanbanView.newCardHere' => 'New card here',
			'orkest.kanbanView.duplicateCard' => 'Duplicate',
			'orkest.kanbanView.cardLabels' => 'Labels',
			'orkest.kanbanView.deleteCard' => 'Delete card',
			'orkest.kanbanView.advance' => 'Move to next column',
			'orkest.kanbanView.advanceHold' => 'Move to next column (hold: move to last column)',
			'orkest.kanbanView.advanceBack' => 'Move back a column',
			'orkest.kanbanView.emptyColumn' => 'No cards',
			'orkest.kanbanView.cardCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 card', other: '${n} cards', ),
			'orkest.kanbanView.notes' => 'Note',
			'orkest.kanbanView.notesPlaceholder' => 'Write a note',
			'orkest.kanbanView.comments' => 'Comments',
			'orkest.kanbanView.addComment' => 'Add comment',
			'orkest.kanbanView.commentPlaceholder' => 'Write a comment',
			'orkest.kanbanView.noComments' => 'No comments yet',
			'orkest.kanbanView.closeDetail' => 'Close',
			'orkest.kanbanView.notABoard' => 'This file has no ## columns yet — it opens as markdown.',
			'orkest.kanbanView.startBoard' => 'Start a board',
			'orkest.kanbanView.couldNotSave' => 'Could not save the board',
			'orkest.kanbanView.unrecognizedBlock' => 'Not recognized by the parser — drags whole, no inline editing.',
			'orkest.kanbanView.deleteColumnDialog.title' => ({required Object name}) => 'Delete “${name}”?',
			'orkest.kanbanView.deleteColumnDialog.message' => ({required Object count}) => 'This column has ${count}. Choose what happens to them.',
			'orkest.kanbanView.deleteColumnDialog.moveCards' => 'Move to the previous column',
			'orkest.kanbanView.deleteColumnDialog.deleteAll' => 'Delete with the column',
			'orkest.kanbanView.deleteColumnDialog.emptyMessage' => 'This column is empty.',
			'orkest.dbPanel.sectionDatabase' => 'DATABASE',
			'orkest.dbPanel.edit' => 'Edit…',
			'orkest.dbPanel.copyName' => 'Copy name',
			'orkest.dbPanel.newQuery' => 'New query',
			'orkest.dbPanel.browseKeys' => 'Browse keys',
			'orkest.dbPanel.deleteConnectionTitle' => 'Delete connection',
			'orkest.dbPanel.deleteConnectionMessage' => ({required Object name}) => 'Remove "${name}" from this workspace? Any saved password is discarded. .dbq files that reference it are not touched.',
			'orkest.dbPanel.footer' => ({required Object n}) => '.orkest/databases.json · ${n} connections',
			'orkest.dbPanel.footerOne' => '.orkest/databases.json · 1 connection',
			'orkest.dbPanel.noConnections' => 'No connections yet.',
			'orkest.dbPanel.passwordRequired' => 'Password not found on the host. Open this connection and enter it again — it is saved on the machine that runs the database, not on this one.',
			'orkest.dbMongoView.deleteDocumentTitle' => 'Delete document',
			'orkest.dbMongoView.deleteDocumentMessage' => ({required Object id, required Object collection}) => 'Delete the document with _id ${id} from "${collection}"?',
			'orkest.dbMongoView.filterHint' => 'Filter — JSON, e.g. {"status": "active"}',
			'orkest.dbMongoView.docCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 doc', other: '${n} docs', ),
			'orkest.dbMongoView.refresh' => 'Refresh',
			'orkest.dbMongoView.insertDocument' => 'Insert document',
			'orkest.dbMongoView.noDocuments' => 'No documents in this collection.',
			'orkest.dbMongoView.noDocumentsMatch' => 'No documents match this filter.',
			'orkest.dbMongoView.loadMore' => 'Load more',
			'orkest.dbMongoView.edit' => 'Edit',
			'orkest.dbMongoView.insert' => 'Insert',
			'orkest.dbConnectionDialog.chooseFileTitle' => 'Choose SQLite database',
			'orkest.dbConnectionDialog.file' => 'File',
			'orkest.dbConnectionDialog.chooseFilePlaceholder' => 'Choose a SQLite file…',
			'orkest.dbConnectionDialog.name' => 'Name',
			'orkest.dbConnectionDialog.password' => 'Password',
			'orkest.dbConnectionDialog.savePassword' => 'Save Password',
			'orkest.dbConnectionDialog.allowWrites' => 'Allow writes (agents)',
			'orkest.dbConnectionDialog.allowWritesHint' => 'off = agents can only read via CLI',
			'orkest.dbConnectionDialog.visibleToAgents' => 'Visible to agents',
			'orkest.dbConnectionDialog.visibleToAgentsHint' => 'off = hidden from the CLI, GUI only',
			'orkest.dbConnectionDialog.testing' => 'Testing connection…',
			'orkest.dbConnectionDialog.connectionOk' => 'Connection OK',
			'orkest.dbConnectionDialog.connectionFailed' => 'Connection failed',
			'orkest.dbConnectionDialog.editTitle' => 'Edit connection',
			'orkest.dbConnectionDialog.newTitle' => 'New connection',
			'orkest.dbConnectionDialog.connectionString' => 'Connection string',
			'orkest.dbConnectionDialog.invalidUrl' => 'Not a valid connection URL.',
			'orkest.dbConnectionDialog.sshTunnel' => 'SSH Tunnel',
			'orkest.dbConnectionDialog.sshHost' => 'SSH Host',
			'orkest.dbConnectionDialog.sshPort' => 'SSH Port',
			'orkest.dbConnectionDialog.sshUser' => 'SSH User',
			'orkest.dbConnectionDialog.privateKey' => 'Private key',
			'orkest.dbConnectionDialog.choosePrivateKeyPlaceholder' => 'Choose a private key…',
			'orkest.dbConnectionDialog.choosePrivateKeyDialogTitle' => 'Choose SSH private key',
			'orkest.dbConnectionDialog.keyPassphrase' => 'Key passphrase',
			'orkest.dbConnectionDialog.savePassphrase' => 'Save passphrase',
			'orkest.dbConnectionDialog.passwordOnHost' => 'The password is stored on the host, not on this machine.',
			'orkest.sshPrompts.unknownSshHostTitle' => 'Unknown SSH host',
			'orkest.sshPrompts.neverConnected' => ({required Object endpoint}) => 'Orkest Code has never connected to ${endpoint} before.',
			'orkest.sshPrompts.trustHint' => 'Trust it only if this fingerprint matches the server. You can check it on the server with:',
			'orkest.sshPrompts.trust' => 'Trust',
			'orkest.sshPrompts.sshKeyPassphraseTitle' => 'SSH key passphrase',
			'orkest.sshPrompts.unlockMessage' => ({required Object keyPath, required Object connectionName}) => 'Unlock ${keyPath} to connect "${connectionName}".',
			'orkest.sshPrompts.keptInMemoryHint' => 'Kept in memory until Orkest Code quits. To let agents use this connection, enable "Save passphrase" in the connection.',
			'orkest.sshPrompts.unlock' => 'Unlock',
			'orkest.projectsRail.workspaces' => 'Workspaces',
			'orkest.projectsRail.keepAwakeOn' => 'Keeping this computer awake for remote access. Click to let it sleep again.',
			'orkest.projectsRail.keepAwakeOff' => 'Keep this computer awake for remote access. Off again when Orkest Code restarts.',
			'orkest.projectsRail.keepAwakeBattery' => 'Keeping awake on battery power. This drains the battery.',
			'orkest.projectsRail.keepAwakeLid' => 'Closing a laptop lid still puts it to sleep.',
			'orkest.projectsRail.newWorkspace' => 'New workspace',
			'orkest.projectsRail.settings' => 'Settings',
			'orkest.projectsRail.mergeToParent' => 'Merge to Parent',
			'orkest.projectsRail.updateFromParent' => 'Update from Parent',
			'orkest.projectsRail.forkWorktree' => 'Fork Worktree',
			'orkest.projectsRail.copyBranch' => 'Copy branch',
			'orkest.projectsRail.remove' => 'Remove',
			'orkest.projectsRail.moveToRealm' => 'Move to realm',
			'orkest.projectsRail.copyWorkspaceId' => 'Copy workspace id',
			'orkest.projectsRail.rename' => 'Rename',
			'orkest.projectsRail.close' => 'Close',
			'orkest.projectsRail.newRealm' => 'New realm…',
			'orkest.projectsRail.manageRealms' => 'Manage realms…',
			'orkest.projectsRail.noWorkspaces' => 'No workspaces yet.',
			'orkest.projectsRail.sync' => 'Sync',
			'orkest.projectsRail.pull' => 'Pull',
			'orkest.projectsRail.push' => 'Push',
			'orkest.projectsRail.createWorktree' => 'Create worktree',
			'orkest.projectsRail.worktreeCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 worktree', other: '${n} worktrees', ),
			'orkest.projectsRail.expandWorktrees' => 'Expand worktrees',
			'orkest.projectsRail.collapseWorktrees' => 'Collapse worktrees',
			'orkest.findBar.find' => 'Find',
			'orkest.findBar.matchCase' => 'Match case',
			'orkest.findBar.wholeWord' => 'Whole word',
			'orkest.findBar.useRegex' => 'Use regular expression',
			'orkest.findBar.previous' => 'Previous (⇧⏎)',
			'orkest.findBar.next' => 'Next (⏎)',
			'orkest.findBar.close' => 'Close (Esc)',
			'orkest.findBar.badPattern' => 'Bad pattern',
			'orkest.findBar.counter' => ({required Object current, required Object total}) => '${current} of ${total}',
			'orkest.findBar.noResults' => 'No results',
			'orkest.contentSearch.sectionSearch' => 'SEARCH',
			'orkest.contentSearch.searchInFiles' => 'Search in files',
			'orkest.contentSearch.matchCase' => 'Match case',
			'orkest.contentSearch.wholeWord' => 'Whole word',
			'orkest.contentSearch.useRegex' => 'Use regular expression',
			'orkest.contentSearch.invalidRegex' => 'Invalid regular expression.',
			'orkest.contentSearch.typeToSearch' => 'Type to search across files.',
			'orkest.contentSearch.searching' => 'Searching…',
			'orkest.contentSearch.noResults' => 'No results.',
			'orkest.topbar.collapseSidebar' => 'Collapse sidebar',
			'orkest.topbar.toggleFiles' => 'Show/hide files',
			'orkest.topbar.filesUnavailable' => 'Files unavailable in Orkest Code',
			'orkest.topbar.hideKeyboard' => 'Hide keyboard',
			'orkest.topbar.showOffice' => 'Show office',
			'orkest.topbar.showTerminals' => 'Show terminals',
			'orkest.tasks.hotReload' => 'Hot reload',
			'orkest.tasks.hotRestart' => 'Hot restart',
			'orkest.tasks.toggleDebugPaint' => 'Toggle debug paint',
			'orkest.tasks.togglePlatform' => 'Toggle platform',
			'orkest.tasks.quit' => 'Quit',
			'orkest.notifications.agentFinished' => 'Agent finished',
			'orkest.notifications.open' => 'Open',
			'orkest.notifications.agentNeedsAction' => 'Agent needs your input',
			'orkest.terminalLink.open' => 'Open',
			'orkest.terminalLink.revealFinder' => 'Reveal in Finder',
			'orkest.terminalLink.revealExplorer' => 'Show in Explorer',
			'orkest.terminalLink.revealFolder' => 'Open containing folder',
			'orkest.terminalLink.copyPath' => 'Copy path',
			'orkest.terminalLink.openLink' => 'Open link',
			'orkest.terminalLink.copyLink' => 'Copy link',
			'orkest.terminal.cwdFallbackWarning' => ({required Object requested, required Object path}) => 'Warning: the folder "${requested}" does not exist. This terminal opened in "${path}".',
			'orkest.terminal.workspaceEnvTracked' => ({required Object keys}) => 'Notice: .env.orkest is tracked by git (it came with the repository). Injected: ${keys}',
			'orkest.remoteHost.addHost' => 'Add remote host',
			'orkest.remoteHost.hostName' => 'Name',
			'orkest.remoteHost.sshTarget' => 'SSH target (user@host)',
			'orkest.remoteHost.connecting' => ({required Object host}) => 'Connecting to ${host}…',
			'orkest.remoteHost.openingTunnel' => 'SSH tunnel',
			'orkest.remoteHost.installingServer' => 'Installing server',
			'orkest.remoteHost.handshake' => ({required Object version}) => 'Server ${version}',
			'orkest.remoteHost.loadingWorkspace' => 'Loading workspace…',
			'orkest.remoteHost.reconnecting' => ({required Object host}) => 'Reconnecting to ${host}…',
			'orkest.remoteHost.offline' => ({required Object host}) => '${host} offline',
			'orkest.remoteHost.remove' => 'Remove',
			'orkest.remoteHost.reconnect' => 'Reconnect',
			'orkest.remoteHost.installServer' => 'Install server',
			'orkest.remoteHost.errSshUnreachable' => ({required Object host}) => 'Cannot reach ${host} over SSH. Is it on, and is Remote Login enabled?',
			'orkest.remoteHost.errInstallFailed' => ({required Object host}) => 'Could not install the server on ${host}.',
			'orkest.remoteHost.errVersionMismatch' => 'Server version incompatible; update it.',
			'orkest.remoteHost.errDetail' => ({required Object detail}) => 'Details: ${detail}',
			'orkest.remoteHost.pickFolderTitle' => ({required Object host}) => 'Open folder on ${host}',
			'orkest.remoteHost.openHere' => 'Open here',
			'orkest.remoteHost.emptyFolder' => 'No subfolders',
			'orkest.remoteHost.newLocal' => 'Local',
			'orkest.remoteHost.newRemote' => 'Remote',
			'orkest.remoteHost.chooseHost' => 'Choose a host',
			'orkest.remoteHost.newHostEntry' => 'New host…',
			'orkest.remoteHost.editHost' => 'Edit host',
			'orkest.remoteHost.userLabel' => 'Username',
			'orkest.remoteHost.hostLabel' => 'Host / IP',
			'orkest.remoteHost.portLabel' => 'Port',
			'orkest.remoteHost.authLabel' => 'Authentication',
			'orkest.remoteHost.authKey' => 'SSH key',
			'orkest.remoteHost.authPassword' => 'Password',
			'orkest.remoteHost.passwordLabel' => 'Password',
			'orkest.remoteHost.passwordKeep' => 'Leave blank to keep current',
			'orkest.remoteHost.errUser' => 'Username required',
			'orkest.remoteHost.errHost' => 'Host required',
			'orkest.remoteHost.errPassword' => 'Password required',
			'orkest.remoteHost.identityChoose' => 'Choose…',
			'orkest.remoteHost.identityEmpty' => 'No key selected',
			'orkest.remoteHost.identityDialogTitle' => 'Select the SSH private key',
			'orkest.remoteHost.errIdentity' => 'Pick the private key to authenticate with.',
			'orkest.remoteHost.errHostKeyUnknown' => ({required Object host}) => 'Orkest Code does not trust ${host} yet. Connect again and confirm the fingerprint.',
			'orkest.remoteHost.errHostKeyChanged' => ({required Object host}) => '${host} is presenting a different SSH key than the one stored. If you did not reinstall that machine, stop and check it — otherwise remove the old entry from ~/.ssh/known_hosts.',
			'orkest.remoteHost.errHostBundleMissing' => ({required Object host}) => '${host} runs Windows but does not have Orkest Code installed. The remote server is installed from the Orkest Code bundle already on that machine, so install Orkest Code there and try again.',
			'orkest.remoteHost.errHostUnknownOs' => ({required Object host}) => 'Could not identify the operating system of ${host}. The account may have a restricted shell, or no shell at all.',
			'orkest.remoteHost.errIdentityPublic' => 'Only the public key is here. That works only if the private key is in your SSH agent; otherwise pick the private file (same name, without .pub).',
			'orkest.remoteHost.errIdentityNotKey' => 'That file does not look like a private key.',
			'orkest.remoteHost.errIdentityMissingFile' => 'That file no longer exists.',
			'orkest.remoteHost.errIdentityUnreadable' => 'That file could not be read.',
			'orkest.browserPane.back' => 'Back',
			'orkest.browserPane.forward' => 'Forward',
			'orkest.browserPane.reload' => 'Reload',
			'orkest.browserPane.urlHint' => 'Enter URL or address',
			'orkest.browserPane.go' => 'Go',
			'orkest.documentWindow.mediaNotSupported' => 'Audio and video open in the main Orkest Code window.',
			'orkest.documentWindow.fileNotFound' => ({required Object path}) => 'File not found: ${path}',
			'orkest.gallery.intro' => 'Special Orkest Code documents that give you a visual of what the AI agent is doing.',
			'orkest.gallery.createErrorTitle' => 'Could not create the file',
			'orkest.gallery.dbQuery.title' => 'Database query',
			'orkest.gallery.dbQuery.description' => 'SQL editor with a result grid, using one of the registered connections.',
			'orkest.gallery.kanban.title' => 'Kanban board',
			'orkest.gallery.kanban.description' => 'Columns and cards stored as plain markdown. Drag, edit and comment.',
			'orkest.gallery.layout.title' => 'Pane layout',
			'orkest.gallery.layout.description' => 'Terminals and splits to open in one go, like tmuxinator. Can run automatically on new worktrees.',
			'orkest.gallery.httpRequest.title' => 'HTTP requests',
			'orkest.gallery.httpRequest.description' => 'Write requests in a file and run them with the response next to it.',
			'orkest.gallery.html.title' => 'HTML view',
			'orkest.gallery.html.description' => 'A page the agent writes and Orkest Code renders directly: mind maps, diagrams, charts, whatever you need.',
			'orkest.gallery.tasks.title' => 'Tasks',
			'orkest.gallery.tasks.description' => 'Commands to run from the Tasks panel, such as the dev server, tests and build. Stored in .orkest/tasks.json.',
			'orkest.gallery.notebook.title' => 'Notebook',
			'orkest.gallery.notebook.description' => 'A folder of short notes with tags. The agent writes, you read and edit. Also opens in Obsidian.',
			'orkest.gallery.workspaceEnv.title' => 'Workspace env',
			'orkest.gallery.workspaceEnv.description' => 'Variables injected into every terminal of this workspace. Put API tokens or logins here instead of pasting them into the agent\'s prompt. Kept out of git.',
			'orkest.gallery.panel.title' => 'Panel',
			'orkest.gallery.panel.description' => 'An HTML page with a bridge to the app: its buttons run Orkest Code CLI and shell commands on this machine. A playground for quick dashboards.',
			'orkest.notebook.notes' => 'Notes',
			'orkest.notebook.newNote' => 'New note',
			'orkest.notebook.searchPlaceholder' => 'Search notes',
			'orkest.notebook.empty' => 'No notes yet. Create one, or ask the agent to write here.',
			'orkest.notebook.noMatch' => 'No note matches.',
			'orkest.notebook.selectNote' => 'Select a note',
			'orkest.notebook.reload' => 'Reload from disk',
			'orkest.notebook.untagged' => 'untagged',
			'orkest.notebook.saveFailed' => 'Could not save the note',
			'orkest.notebook.createFailed' => 'Could not create the note',
			'orkest.notebook.addTag' => 'add tag',
			'orkest.notebook.untitled' => 'Untitled',
			'orkest.notebook.deleteNote' => 'Delete note',
			'orkest.notebook.deleteConfirm' => ({required Object name}) => 'Move “${name}” to the trash?',
			'orkest.notebook.imageFailed' => 'Could not save the image',
			'orkest.notebook.format.bold' => 'Bold (⌘B)',
			'orkest.notebook.format.italic' => 'Italic (⌘I)',
			'orkest.notebook.format.strike' => 'Strikethrough',
			'orkest.notebook.format.heading1' => 'Heading 1',
			'orkest.notebook.format.heading2' => 'Heading 2',
			'orkest.notebook.format.heading3' => 'Heading 3',
			'orkest.notebook.format.bullets' => 'Bullet list',
			'orkest.notebook.format.numbered' => 'Numbered list',
			'orkest.notebook.format.checklist' => 'Checklist',
			'orkest.notebook.format.quote' => 'Quote',
			'orkest.notebook.format.code' => 'Inline code (⌘E)',
			'orkest.notebook.format.codeBlock' => 'Code block',
			'orkest.notebook.format.link' => 'Link (⌘K)',
			'orkest.notebook.format.rule' => 'Divider',
			'orkest.notebook.format.noteLink' => 'Link to a note ([[…]])',
			'orkest.notebook.format.noteLinkSearch' => 'Search notes',
			'orkest.notebook.format.image' => 'Insert image…',
			'orkest.notebook.backlinks' => 'Linked from',
			'orkest.notebook.renameTag' => 'Rename tag',
			'orkest.notebook.deleteTag' => 'Delete tag',
			'orkest.notebook.deleteTagConfirm' => ({required Object name, required Object count}) => 'Remove “${name}” from ${count} notes? The notes stay.',
			'orkest.notebook.showList' => 'Show notes list',
			'orkest.notebook.hideList' => 'Hide notes list',
			'orkest.layoutPreview.applyFailedTitle' => 'Could not apply the layout',
			'orkest.layoutPreview.applyInOrkest' => 'Apply in Orkest Code',
			'orkest.layoutPreview.applyNewWorkspace' => 'Open as new workspace',
			'orkest.layoutPreview.applyTo' => ({required Object workspace}) => 'Apply to ${workspace}',
			'orkest.layoutPreview.autorunWorktree' => 'autorun: worktree. This layout is also applied on its own when you create a worktree of the workspace that holds it.',
			'orkest.layoutPreview.command' => 'Command',
			'orkest.layoutPreview.folder' => 'Folder',
			'orkest.layoutPreview.noCommand' => 'no command, opens a shell',
			'orkest.layoutPreview.replaceConfirm' => 'Replace layout',
			'orkest.layoutPreview.replaceMessage' => ({required Object n}) => '${n} open tabs of this workspace will be closed, including any running work.',
			'orkest.layoutPreview.replaceTitle' => ({required Object workspace}) => 'Replace the layout of ${workspace}?',
			'orkest.layoutPreview.skippedTitle' => 'Not created on this system',
			'orkest.layoutPreview.splitDown' => 'split down',
			'orkest.layoutPreview.splitRight' => 'split right',
			'orkest.layoutPreview.splitTab' => 'tab',
			'orkest.layoutPreview.subtitle' => ({required Object n}) => 'This layout opens ${n} terminals. Read the commands before applying.',
			'orkest.telemetry.tooltip' => 'Telemetry',
			'orkest.telemetry.title' => 'Telemetry',
			'orkest.telemetry.liveRuns' => ({required Object n}) => '${n} live',
			'orkest.telemetry.noWorkspace' => 'Open a workspace to see its telemetry.',
			'orkest.telemetry.empty' => 'Nothing here yet.',
			'orkest.telemetry.emptyFiltered' => 'Nothing here yet.',
			'orkest.telemetry.searchHint' => 'Filter cases',
			'orkest.telemetry.chipOpen' => 'Open',
			'orkest.telemetry.chipNew' => 'New',
			'orkest.telemetry.chipResolved' => 'Resolved',
			'orkest.telemetry.chipIgnored' => 'Ignored',
			'orkest.telemetry.chipWarnings' => 'Warnings',
			'orkest.telemetry.tagNew' => 'new',
			'orkest.telemetry.tagRegression' => 'regression',
			'orkest.telemetry.tagResolved' => 'resolved',
			'orkest.telemetry.tagIgnored' => 'ignored',
			'orkest.telemetry.srcTask' => 'task',
			'orkest.telemetry.srcWrapper' => 'orkest telemetry',
			'orkest.telemetry.run' => ({required Object id}) => 'run ${id}',
			'orkest.telemetry.resolve' => 'Mark resolved',
			'orkest.telemetry.ignore' => 'Ignore (hide from agents too)',
			'orkest.telemetry.reopen' => 'Reopen',
			'orkest.telemetry.clear' => 'Clear occurrences',
			'orkest.telemetry.clearRun' => 'Clear this run',
			'orkest.telemetry.clearProject' => 'Clear project',
			'orkest.telemetry.openFile' => ({required Object location}) => 'Open ${location}',
			'orkest.telemetry.showInTerminal' => 'Show in terminal',
			'orkest.telemetry.copyCommand' => 'Copy CLI command',
			'orkest.telemetry.copied' => 'Copied',
			'orkest.telemetry.statusOpen' => 'Open',
			'orkest.telemetry.statusResolved' => 'Resolved',
			'orkest.telemetry.statusIgnored' => 'Ignored',
			'orkest.telemetry.occurrences' => 'Occurrences',
			'orkest.telemetry.inRuns' => ({required Object n}) => 'in ${n} runs',
			'orkest.telemetry.first' => 'First',
			'orkest.telemetry.last' => 'Last',
			'orkest.telemetry.origin' => 'Origin',
			'orkest.telemetry.sectionStack' => 'Stack',
			'orkest.telemetry.stackHint' => 'project frames highlighted · click opens the file',
			'orkest.telemetry.sectionCorrelated' => 'Correlated log',
			'orkest.telemetry.correlatedHint' => 'the closest JSON log before the error, same run',
			'orkest.telemetry.none' => 'none',
			'orkest.telemetry.sectionRuns' => 'Occurrences by run',
			'orkest.telemetry.runsHint' => 'same key (cwd, command): this is how new and regression are computed',
			'orkest.telemetry.sectionContext' => 'Raw context',
			'orkest.telemetry.contextHint' => 'terminal lines around the last occurrence',
			'orkest.telemetry.current' => 'current',
			'orkest.telemetry.fingerprintHint' => ({required Object location}) => 'fingerprint = type + normalized message + ${location}',
			'orkest.telemetry.blameUncommitted' => 'changed in working tree',
			'orkest.telemetry.blameCommit' => ({required Object ago, required Object sha}) => 'changed ${ago} (${sha})',
			'orkest.telemetry.justNow' => 'just now',
			'orkest.telemetry.minutesAgo' => ({required Object n}) => '${n}m ago',
			'orkest.telemetry.hoursAgo' => ({required Object n}) => '${n}h ago',
			'orkest.telemetry.daysAgo' => ({required Object n}) => '${n}d ago',
			'orkest.telemetry.resolvedToast' => 'Resolved. If it comes back in a later run it reappears as a regression.',
			'orkest.telemetry.ignoredToast' => 'Ignored. Agents no longer see it (unless --include-ignored).',
			'orkest.telemetry.clearedToast' => 'Occurrences deleted. Triage rules are kept.',
			'orkest.telemetry.byHuman' => 'by you',
			'orkest.telemetry.byAgent' => 'by agent',
			'orkest.telemetry.caseTabTitle' => ({required Object type, required Object file}) => '${type} · ${file}',
			'orkest.telemetry.srcApp' => 'App',
			'orkest.telemetry.chipApp' => 'Orkest Code',
			'orkest.panelView.unavailable' => 'Panels need the embedded web view, which is not available on Linux yet.',
			'orkest.panelView.openInBrowser' => 'Open in browser',
			'orkest.panelView.openAsHtml' => 'Open as HTML',
			'settings.language.title' => 'Language',
			'settings.language.system' => 'System',
			'settings.language.english' => 'English',
			'settings.language.portugueseBr' => 'Português (BR)',
			'settings.language.spanish' => 'Español',
			'settings.page.header.back' => 'Back',
			'settings.page.header.title' => 'Settings',
			'settings.page.nav.general' => 'General',
			'settings.page.nav.appearance' => 'Appearance',
			'settings.page.nav.terminal' => 'Terminal',
			'settings.page.nav.language' => 'Language',
			'settings.page.nav.shortcuts' => 'Shortcuts',
			'settings.page.nav.notifications' => 'Notifications',
			'settings.page.nav.automations' => 'Automations',
			'settings.page.nav.remoteHosts' => 'Remote hosts',
			'settings.page.general.sectionEditor' => 'Editor',
			'settings.page.general.editorEngineTitle' => 'Engine',
			'settings.page.general.editorEngineOrkest' => 'Orkest Code (default)',
			'settings.page.general.editorEngineNeovim' => 'Neovim',
			'settings.page.general.neovimChecking' => 'Looking for Neovim…',
			'settings.page.general.neovimNotFound' => 'Neovim was not found in your shell PATH.',
			'settings.page.general.neovimRefresh' => 'Check again',
			'settings.page.general.showOrkestTitle' => 'Show Orkest Code terminal',
			'settings.page.general.showOrkestDesc' => 'Keep a pathless, terminal-only workspace pinned at the top of the rail. Turning it off closes its terminals.',
			'settings.page.general.launchAtStartupTitle' => 'Launch at login',
			'settings.page.general.launchAtStartupDesc' => 'Start Orkest Code automatically when you sign in to your computer.',
			'settings.page.general.sectionUpdates' => 'Updates',
			'settings.page.general.checkUpdatesTitle' => 'Check for updates',
			'settings.page.general.checkUpdatesDesc' => 'How often Orkest Code should look for new versions.',
			'settings.page.general.updateFrequency.daily' => 'Daily',
			'settings.page.general.updateFrequency.weekly' => 'Weekly',
			'settings.page.general.updateFrequency.monthly' => 'Monthly',
			'settings.page.general.updateFrequency.never' => 'Never',
			'settings.page.general.developerModeTitle' => 'Developer mode',
			'settings.page.general.developerModeDesc' => 'Records Orkest Code’s own errors and warnings in a separate Telemetry store (the “Orkest Code” chip) and turns on performance metrics. Only useful to whoever maintains the app.',
			'settings.page.diagnostics.sectionTitle' => 'Diagnostics',
			'settings.page.diagnostics.logFileTitle' => 'Log file',
			'settings.page.diagnostics.logFileDesc' => ({required Object days, required Object path}) => 'Errors and startup events are recorded here, kept for ${days} days.\n${path}',
			'settings.page.diagnostics.unavailable' => 'unavailable',
			'settings.page.diagnostics.reveal' => 'Reveal',
			'settings.page.diagnostics.reportTitle' => 'Report a problem',
			'settings.page.diagnostics.reportDesc' => 'Opens a pre-filled issue with your version, OS and recent log. Nothing is sent automatically — you review it first.',
			'settings.page.diagnostics.reportButton' => 'Report…',
			'settings.page.diagnostics.reportDialogTitle' => 'Problem report',
			'settings.page.diagnostics.reportDialogError' => 'Reported manually from Settings.',
			'settings.page.diagnostics.reportDialogDescription' => 'Describe what went wrong in the issue. The recent log is included below and in "Copy details".',
			'settings.page.storage.sectionTitle' => 'Storage',
			'settings.page.storage.locationTitle' => 'Storage location',
			'settings.page.storage.locationDesc' => ({required Object root}) => 'Orkest Code keeps its projects, layouts and settings here. Point it at a synced folder to back it up.\n${root}',
			'settings.page.storage.useDefault' => 'Use default',
			'settings.page.storage.working' => 'Working…',
			'settings.page.storage.change' => 'Change…',
			'settings.page.storage.resetTitle' => 'Reset Orkest Code',
			'settings.page.storage.resetDesc' => 'Delete all local data — projects, layouts, settings and terminal history — and return to the default location.',
			'settings.page.storage.resetButton' => 'Reset…',
			'settings.page.storage.resetConfirm' => 'Reset',
			'settings.page.storage.resetDialogTitle' => 'Reset Orkest Code?',
			'settings.page.storage.resetDialogContent' => 'This permanently deletes all local Orkest Code data — projects, layouts, settings and terminal history. This cannot be undone. Orkest Code will close so you can start fresh.',
			'settings.page.storage.restartRequiredTitle' => 'Restart required',
			'settings.page.storage.restartChangeFolderMessage' => ({required Object path}) => 'Orkest Code will use this folder from the next launch:\n${path}',
			'settings.page.storage.restartUseDefaultMessage' => 'Orkest Code will use the default system location from the next launch. Your data in the custom folder is left untouched.',
			'settings.page.storage.restartResetMessage' => 'All Orkest Code data was cleared. Restart to start fresh.',
			'settings.page.storage.later' => 'Later',
			'settings.page.storage.quitOrkest' => 'Quit Orkest Code',
			'settings.page.storage.chooseFolderDialogTitle' => 'Choose a folder for Orkest Code data',
			'settings.page.terminal.sectionDefaultTerminal' => 'Default terminal',
			'settings.page.terminal.engineTitle' => 'Engine',
			'settings.page.terminal.engineDesc' => 'Used by new terminal tabs and task output buffers. Open tabs keep their current engine.',
			'settings.page.terminal.shellTitle' => 'Shell',
			'settings.page.terminal.shellDesc' => 'Which shell new terminal tabs open. The arrow next to + still opens any other one, just for that tab.',
			'settings.page.terminal.noWslMessage' => 'No WSL distros found. Install one (wsl.exe --install) and restart Orkest Code to see it listed here.',
			'settings.page.terminal.sectionBehavior' => 'Behavior',
			'settings.page.terminal.closeOnExitTitle' => 'Close tab when the shell exits',
			'settings.page.terminal.closeOnExitDesc' => 'When a shell ends on its own (exit, Ctrl-D), close its tab instead of leaving a dead terminal.',
			'settings.page.appearance.sectionTheme' => 'Theme',
			'settings.page.appearance.themeTitle' => 'Theme',
			'settings.page.appearance.themeDesc' => 'App colors, code highlighting and terminal palette.',
			'settings.page.appearance.modeTitle' => 'Mode',
			'settings.page.appearance.modeDesc' => 'Which variant of the theme to use.',
			'settings.page.appearance.modeOnlyDark' => ({required Object theme}) => '"${theme}" only ships a dark variant, so this has no effect.',
			'settings.page.appearance.modeOnlyLight' => ({required Object theme}) => '"${theme}" only ships a light variant, so this has no effect.',
			'settings.page.appearance.themeFileTitle' => 'Theme file',
			'settings.page.appearance.themeFileDesc' => 'Import a theme from a JSON file, or export the active one.',
			'settings.page.appearance.previewCode' => 'Code',
			'settings.page.appearance.previewTerminal' => 'Terminal',
			'settings.page.appearance.themeSystem' => 'System',
			'settings.page.appearance.themeLight' => 'Light',
			'settings.page.appearance.themeDark' => 'Dark',
			'settings.page.appearance.sectionFonts' => 'Fonts',
			'settings.page.appearance.interfaceFontTitle' => 'Interface font',
			'settings.page.appearance.interfaceFontDesc' => 'Used across the whole app. Empty = system default.',
			'settings.page.appearance.interfaceSizeTitle' => 'Interface size',
			'settings.page.appearance.codeFontTitle' => 'Code font',
			'settings.page.appearance.codeFontDesc' => 'Code and diffs. Empty = system default.',
			'settings.page.appearance.codeSizeTitle' => 'Code size',
			'settings.page.appearance.terminalFontTitle' => 'Terminal font',
			'settings.page.appearance.terminalFontDesc' => 'Terminal only. Empty = system default.',
			'settings.page.appearance.terminalSizeTitle' => 'Terminal size',
			'settings.page.appearance.terminalSizeDesc' => 'Off = follows the code size.',
			'settings.page.appearance.terminalSizeInherit' => 'Follow code size',
			'settings.page.appearance.terminalWeightTitle' => 'Terminal weight',
			'settings.page.appearance.terminalWeightDesc' => 'Low-density screens render strokes heavier. Auto lightens them there and leaves Retina untouched.',
			'settings.page.appearance.terminalWeightAuto' => 'Auto (by screen)',
			'settings.page.appearance.terminalWeightLight' => 'Light',
			'settings.page.appearance.terminalWeightNormal' => 'Normal',
			'settings.page.appearance.terminalWeightMedium' => 'Medium',
			'settings.page.appearance.terminalWeightSemiBold' => 'Semibold',
			'settings.page.appearance.sectionConversation' => 'Conversation',
			'settings.page.appearance.pinUserMessageTitle' => 'Pin user message',
			'settings.page.appearance.pinUserMessageDesc' => 'The question stays fixed at the top while the answer scrolls.',
			'settings.page.appearance.importTheme' => 'Import…',
			'settings.page.appearance.exportTheme' => 'Export…',
			'settings.page.appearance.deleteTheme' => 'Remove',
			'settings.page.appearance.importThemeDialog' => 'Pick a theme file',
			'settings.page.appearance.exportThemeDialog' => 'Save theme as',
			'settings.page.appearance.themeImported' => ({required Object name}) => 'Theme "${name}" imported.',
			'settings.page.appearance.themeExported' => 'Theme saved.',
			'settings.page.appearance.themeDeleted' => 'Theme removed.',
			'settings.page.appearance.fontPickerTitle' => 'Choose a font',
			'settings.page.appearance.fontPickerSearch' => 'Search fonts',
			'settings.page.appearance.fontPickerEmpty' => 'No matching font found on this machine.',
			'settings.page.appearance.fontPickerBundled' => 'included',
			'settings.page.appearance.fontPickerCustom' => 'Not listed? Type the exact family name.',
			'settings.page.appearance.fontPickerCustomHint' => 'Family name',
			'settings.page.appearance.fontPickerUse' => 'Use',
			'settings.page.appearance.fontPickerDefault' => 'Default',
			'settings.page.appearance.fontMissing' => 'Not found on this machine — falling back.',
			'settings.page.appearance.sectionLayout' => 'Layout',
			'settings.page.appearance.swapPanelsTitle' => 'Swap side panels',
			'settings.page.appearance.swapPanelsDesc' => 'Puts workspaces on the right and files, search, git and database on the left.',
			'settings.page.notifications.sectionTitle' => 'Notifications',
			'settings.page.notifications.enableTitle' => 'Enable notifications',
			'settings.page.notifications.enableDesc' => 'Alert me when an agent finishes a turn and the window is not focused.',
			'settings.page.notifications.systemPermissionTitle' => 'System permission',
			'settings.page.notifications.grantedDesc' => 'Orkest Code is allowed to send notifications.',
			'settings.page.notifications.notGrantedDesc' => 'macOS has not granted notification access yet.',
			'settings.page.notifications.granted' => 'Granted',
			'settings.page.notifications.requestPermission' => 'Request permission',
			'settings.page.notifications.soundsTitle' => 'Sounds',
			'settings.page.notifications.soundVolumeTitle' => 'Volume',
			'settings.page.notifications.soundTurnDone' => 'Turn completed',
			'settings.page.notifications.soundTurnDoneDesc' => 'An agent finished its turn.',
			_ => null,
		} ?? switch (path) {
			'settings.page.notifications.soundActionRequired' => 'Action required',
			'settings.page.notifications.soundActionRequiredDesc' => 'An agent is waiting for your approval or answer.',
			'settings.page.notifications.soundDefault' => 'Default',
			'settings.page.notifications.soundCustom' => ({required Object name}) => 'Custom: ${name}',
			'settings.page.notifications.soundChooseFile' => 'Choose file',
			'settings.page.notifications.soundReset' => 'Reset to default',
			'settings.page.notifications.soundOnActiveTab' => 'Also play when this tab is active',
			'settings.page.notifications.soundPreview' => 'Preview',
			'settings.page.shortcuts.notCustomizable' => 'Keyboard shortcuts are not customizable yet.',
			'settings.page.languages.sectionFormatting' => 'FORMATTING',
			'settings.page.languages.formatOnSaveTitle' => 'Format on save',
			'settings.page.languages.formatOnSaveDesc' => 'Format the file automatically when you save (⌘S).',
			'settings.page.languages.sectionLanguageServers' => 'LANGUAGE SERVERS',
			'settings.page.languages.footerNote' => 'Errors and formatting use each language\'s language server. Orkest Code does not install servers — it uses what is already on your machine. ● responds · ○ not found or invalid command (install the server or adjust the command).',
			'settings.page.languages.serverCommandLabel' => 'Language server command',
			'settings.page.languages.formatterCommandLabel' => 'Formatter command (optional)',
			'settings.page.languages.formatterHint' => 'External formatter with %FILE% placeholder. Takes precedence over the LSP formatter when set.',
			'settings.page.languages.resetToDefault' => 'Reset to default',
			'settings.page.languages.saveAndRestart' => 'Save & restart',
			'settings.page.languages.statusResponds' => 'Server responds',
			'settings.page.languages.statusNotFound' => 'Server not found or command invalid',
			'settings.page.automations.sectionCommitMessages' => 'Commit messages',
			'settings.page.automations.harness' => 'Harness',
			'settings.page.automations.harnessDiscovering' => 'Looking for installed command-line harnesses…',
			'settings.page.automations.harnessNoneFound' => 'No supported harness was found on PATH.',
			'settings.page.automations.harnessConfiguredUnavailable' => ({required Object harness}) => '${harness} is configured but unavailable.',
			'settings.page.automations.harnessChoose' => 'Choose the CLI used to generate commit messages.',
			'settings.page.automations.harnessRefresh' => 'Refresh installed harnesses',
			'settings.page.automations.notConfigured' => 'Not configured',
			'settings.page.automations.model' => 'Model',
			'settings.page.automations.modelUnavailable' => 'The model list is unavailable until the harness is found.',
			'settings.page.automations.modelCliOnly' => 'This harness uses its CLI default model.',
			'settings.page.automations.modelCliDefault' => 'CLI default',
			'settings.page.automations.modelAuto' => 'Auto',
			'settings.page.automations.modelSearch' => ({required Object count}) => 'Search among ${count} models…',
			'settings.page.automations.modelAutoRouted' => 'This harness routes the model automatically.',
			'settings.page.automations.modelAccountOnly' => 'Only models your account can use are listed.',
			'settings.page.automations.generateFromSourceControl' => 'Generate from Source Control',
			'settings.page.automations.generateFromSourceControlDescription' => 'Orkest Code sends only the selected diff and recent commit subjects. Common credential patterns and sensitive files are redacted before the harness runs.',
			'settings.page.automations.discoveryFailed' => 'Could not discover installed automation harnesses.',
			'settings.page.automations.staleModel' => ({required Object model, required Object harness}) => 'Model "${model}" is no longer available for ${harness}. Using the CLI default — pick another model in Settings if needed.',
			'settings.page.automations.recommendedSuffix' => 'Recommended',
			'settings.remoteHosts.title' => 'Remote hosts',
			'settings.remoteHosts.description' => 'Machines you reach over SSH. Adding a host here is the same as adding one from the workspace "+" menu.',
			'settings.remoteHosts.empty' => 'No remote hosts yet.',
			'settings.remoteHosts.add' => 'Add host',
			'settings.remoteHosts.edit' => 'Edit',
			'settings.remoteHosts.reconnect' => 'Reconnect',
			'settings.remoteHosts.remove' => 'Remove',
			'settings.remoteHosts.removeTitle' => 'Remove host',
			'settings.remoteHosts.removeMessage' => ({required Object name}) => 'Remove "${name}" and all its workspaces? Nothing is deleted on the host itself.',
			'settings.remoteHosts.workspacesCount' => ({required Object count}) => '${count} workspace(s)',
			'settings.remoteHosts.deviceKeyTitle' => 'This device\'s key',
			'settings.remoteHosts.deviceKeyDesc' => 'Add this public key to ~/.ssh/authorized_keys on the host so this device can connect.',
			'settings.remoteHosts.deviceKeyCopy' => 'Copy public key',
			'settings.remoteHosts.deviceKeyCopied' => 'Public key copied',
			'settings.remoteHosts.statusConnected' => 'Connected',
			'settings.remoteHosts.statusConnecting' => 'Connecting…',
			'settings.remoteHosts.statusReconnecting' => 'Reconnecting…',
			'settings.remoteHosts.statusOffline' => 'Offline',
			'settings.remoteHosts.statusIdle' => 'Not connected',
			'settings.remoteHosts.helpTitle' => 'How it works',
			'settings.remoteHosts.helpBody' => 'Orkest Code connects to your machine over SSH and talks to a small server that runs the terminals, files and git there. The host must have Orkest Code (desktop) or the orkest-server installed and running, and this device’s public key added to its ~/.ssh/authorized_keys.',
			'automation.error.unavailable' => ({required Object harness}) => '${harness} is not installed or is not on PATH.',
			'automation.error.modelUnavailable' => ({required Object model, required Object harness}) => 'Model "${model}" is not available for ${harness}. Choose another model in Settings.',
			'automation.error.authentication' => ({required Object harness, required Object detail}) => '${harness}: ${detail}',
			'automation.error.timeout' => ({required Object harness, required Object seconds}) => '${harness} did not respond within ${seconds} seconds.',
			'automation.error.cancelled' => 'Commit message generation was cancelled.',
			'automation.error.process' => ({required Object harness, required Object detail}) => '${harness}: ${detail}',
			'automation.error.processNoDetail' => ({required Object harness}) => '${harness} could not generate a commit message.',
			'automation.error.invalidResponse' => 'The automation returned an empty commit message.',
			'automation.error.busy' => 'Another commit message is already being generated.',
			'automation.error.unknown' => 'The automation could not generate a commit message.',
			'automation.error.noWorkspace' => 'No workspace selected.',
			'automation.error.fileOutsideWorkspace' => 'File is outside the workspace roots.',
			'automation.error.fileUnreadable' => ({required Object detail}) => 'Could not read the file: ${detail}',
			'automation.error.binaryFile' => 'A commit message cannot be generated for a binary file.',
			'automation.error.noFileChanges' => 'There are no changes to describe for this file.',
			'automation.error.noStagedChanges' => 'There are no staged changes to describe.',
			'automation.error.multipleRepositories' => 'Staged changes belong to multiple repositories. Generate them separately.',
			'automation.error.diffUnavailable' => 'Could not read the diff.',
			'automation.error.notConfigured' => 'Configure a commit message harness in Settings.',
			'fileOperation.error.alreadyExists' => ({required Object name}) => 'Already exists: “${name}”.',
			'fileOperation.error.notFound' => ({required Object name}) => 'Not found: “${name}”.',
			'fileOperation.error.invalidPath' => 'Invalid path.',
			'fileOperation.error.emptyName' => 'The name cannot be empty.',
			'fileOperation.error.noWorkspace' => 'No workspace selected.',
			'fileOperation.error.cannotMoveIntoItself' => 'Cannot move a folder into itself.',
			'fileOperation.error.clipboardEmpty' => 'Clipboard is empty.',
			'fileOperation.error.notScratchTab' => 'This tab is not a scratch file.',
			'fileOperation.error.writeFailed' => 'Could not write the file.',
			'fileOperation.error.formatterEmptyCommand' => 'Empty formatter command.',
			'fileOperation.error.formatterMissingPlaceholder' => 'Formatter command must include the %FILE% placeholder.',
			'fileOperation.error.formatterTimeout' => 'Formatter timed out.',
			'fileOperation.error.formatterExitCode' => ({required Object code}) => 'Formatter exited with ${code}.',
			'fileOperation.error.formatterFailed' => 'The formatter could not run.',
			'fileOperation.error.osFailure' => ({required Object detail}) => '${detail}',
			'fileOperation.error.nameHasSlash' => 'Name cannot contain “/”.',
			'fileOperation.error.invalidName' => 'Invalid name.',
			'fileOperation.error.remoteDropUnsupported' => 'Dropping files into a remote workspace is not supported yet.',
			'theme.error.io' => 'Could not read or write the theme file.',
			'theme.error.ioDetail' => ({required Object detail}) => 'Could not read or write the theme file: ${detail}',
			'theme.error.malformedJson' => ({required Object detail}) => 'This file is not valid JSON: ${detail}',
			'theme.error.invalidTheme' => 'This file is not a valid theme.',
			'theme.error.reservedId' => 'This theme uses the id of a built-in theme. Change "id" in the file and import again.',
			'theme.error.notAnObject' => ({required Object field}) => 'Expected an object at "${field}".',
			'theme.error.missingField' => ({required Object field}) => 'Missing required field "${field}".',
			'theme.error.badColor' => ({required Object value, required Object field}) => '"${value}" at "${field}" is not a color. Use #RGB, #RRGGBB or #RRGGBBAA.',
			'theme.error.unknownBase' => ({required Object value}) => 'Unknown base theme "${value}" in "extends".',
			'theme.error.noVariants' => 'The theme declares no variant. Add "dark", "light" or both under "variants".',
			_ => null,
		};
	}
}
