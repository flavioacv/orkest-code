# Catálogo técnico do OpenIDEA

Inventário estático em 04/11/2026. Origem: `/Volumes/Externo 1/projetos/zurc/openidea`. Escopo assumido pelo contexto: OpenIDEA, não o produto OpenHands.

40 diretórios de funcionalidades, 35 crates, 77 definições de linguagem e 510 declarações explícitas de comandos Tauri identificadas. Contagens não equivalem a funcionalidades independentes nem comprovam execução.

## Features e crates

Features: `agents`, `analysis`, `app`, `build`, `build-tools`, `code-insight`, `color-preview`, `coverage`, `database`, `debugger`, `dependencies`, `deployment`, `github`, `graphql`, `http-client`, `libraries`, `macros`, `notebook`, `perf`, `plugins`, `profiler`, `project-tree`, `project-trust`, `remote-dev`, `run`, `run-anything`, `scratch`, `search`, `services`, `settings`, `ssh`, `templates`, `terminal`, `todo`, `tools`, `vcs`, `viewers`, `vim`, `web`, `welcome`.

Crates: `ide-agent`, `ide-analysis`, `ide-build`, `ide-clipboard`, `ide-core`, `ide-coverage`, `ide-dap`, `ide-db`, `ide-docker`, `ide-extension`, `ide-fonts`, `ide-github`, `ide-host`, `ide-http`, `ide-index`, `ide-jsonrpc`, `ide-language`, `ide-lsp`, `ide-notebook`, `ide-plugin`, `ide-profiler`, `ide-remote`, `ide-run`, `ide-sdk`, `ide-search`, `ide-spell`, `ide-ssh`, `ide-syntax`, `ide-terminal`, `ide-text`, `ide-tools`, `ide-vcs`, `ide-vfs`, `ide-web`, `ide-workspace`.

## Linguagens

Extração lexical de nomes de servidores e adaptadores declarados em TOML; não é um parser completo de configuração. Há fallbacks em código. Ausência de servidor nesta tabela não significa ausência de syntax highlighting. Configuração não garante instalação.

| Linguagem | Servidores declarados | Adaptador | Fonte |
|---|---|---|---|
| AsciiDoc |  |  | `languages/asciidoc.toml` |
| Batch |  |  | `languages/bat.toml` |
| C | clangd | lldb-dap | `languages/c.toml` |
| Clojure | clojure-lsp |  | `languages/clojure.toml` |
| CMake | neocmakelsp, cmake-language-server |  | `languages/cmake.toml` |
| C++ | clangd | lldb-dap | `languages/cpp.toml` |
| C# | csharp-ls | netcoredbg | `languages/csharp.toml` |
| CSS | vscode-css-language-server |  | `languages/css.toml` |
| D | serve-d |  | `languages/d.toml` |
| Dart | dart | dart | `languages/dart.toml` |
| Diff |  |  | `languages/diff.toml` |
| Dockerfile | dockerfile-language-server |  | `languages/dockerfile.toml` |
| .env |  |  | `languages/dotenv.toml` |
| Elixir | elixir-ls | elixir-ls-debugger | `languages/elixir.toml` |
| ERB |  |  | `languages/erb.toml` |
| Erlang | elp |  | `languages/erlang.toml` |
| F# | fsautocomplete | netcoredbg | `languages/fsharp.toml` |
| GDScript | godot | godot | `languages/gdscript.toml` |
| Godot Shader |  |  | `languages/gdshader.toml` |
| Git Attributes |  |  | `languages/gitattributes.toml` |
| Go | gopls | delve | `languages/go.toml` |
| Godot Resource |  |  | `languages/godot-resource.toml` |
| Go Module | gopls |  | `languages/gomod.toml` |
| Go Workspace | gopls |  | `languages/gowork.toml` |
| GraphQL | graphql-lsp |  | `languages/graphql.toml` |
| Groovy | groovy-language-server |  | `languages/groovy.toml` |
| Haskell | haskell-language-server |  | `languages/haskell.toml` |
| HCL |  |  | `languages/hcl.toml` |
| HTML | angular-language-server, vscode-html-language-server |  | `languages/html.toml` |
| HTTP Request |  |  | `languages/http.toml` |
| Ignore File |  |  | `languages/ignore.toml` |
| INI |  |  | `languages/ini.toml` |
| Java | jdtls | java-debug | `languages/java.toml` |
| JavaScript | vtsls, typescript-language-server, oxlint | js-debug | `languages/javascript.toml` |
| JavaScript JSX | vtsls, typescript-language-server, oxlint | js-debug | `languages/javascriptreact.toml` |
| JSON | vscode-json-language-server |  | `languages/json.toml` |
| JSON with Comments | vscode-json-language-server |  | `languages/jsonc.toml` |
| JSP |  |  | `languages/jsp.toml` |
| Julia | julia-languageserver |  | `languages/julia.toml` |
| Kotlin | kotlin-lsp, kotlin-language-server | kotlin-debug-adapter | `languages/kotlin.toml` |
| LaTeX | texlab |  | `languages/latex.toml` |
| Less | vscode-css-language-server |  | `languages/less.toml` |
| Log |  |  | `languages/log.toml` |
| Lua | lua-language-server |  | `languages/lua.toml` |
| Makefile |  |  | `languages/makefile.toml` |
| Markdown | marksman |  | `languages/markdown.toml` |
| Nix | nil, nixd |  | `languages/nix.toml` |
| Objective-C | clangd | lldb-dap | `languages/objective-c.toml` |
| Objective-C++ | clangd | lldb-dap | `languages/objective-cpp.toml` |
| OCaml Interface | ocamllsp |  | `languages/ocaml-interface.toml` |
| OCaml | ocamllsp | ocamlearlybird | `languages/ocaml.toml` |
| Perl | perlnavigator |  | `languages/perl.toml` |
| PHP | intelephense, phpactor | php-debug | `languages/php.toml` |
| Plain Text |  |  | `languages/plaintext.toml` |
| PowerShell | powershell-editor-services |  | `languages/powershell.toml` |
| Properties |  |  | `languages/properties.toml` |
| Protocol Buffers | buf |  | `languages/proto.toml` |
| Python | basedpyright, pyright, ty, pyrefly, ruff | debugpy | `languages/python.toml` |
| R | r-languageserver |  | `languages/r.toml` |
| Ruby | ruby-lsp, solargraph |  | `languages/ruby.toml` |
| Rust | rust-analyzer | codelldb | `languages/rust.toml` |
| Sass |  |  | `languages/sass.toml` |
| Scala | metals |  | `languages/scala.toml` |
| SCSS | vscode-css-language-server |  | `languages/scss.toml` |
| Shell Script | bash-language-server | bash-debug | `languages/shellscript.toml` |
| SQL | sqls |  | `languages/sql.toml` |
| Svelte | svelte-language-server, oxlint |  | `languages/svelte.toml` |
| Swift | sourcekit-lsp | lldb-dap | `languages/swift.toml` |
| Terraform Variables | terraform-ls |  | `languages/terraform-vars.toml` |
| Terraform | terraform-ls |  | `languages/terraform.toml` |
| TOML | taplo |  | `languages/toml.toml` |
| TypeScript | vtsls, typescript-language-server, angular-language-server, oxlint | js-debug | `languages/typescript.toml` |
| TypeScript JSX | vtsls, typescript-language-server, oxlint | js-debug | `languages/typescriptreact.toml` |
| Vue | vue-language-server, vtsls, oxlint |  | `languages/vue.toml` |
| XML | lemminx |  | `languages/xml.toml` |
| YAML | yaml-language-server |  | `languages/yaml.toml` |
| Zig | zls | codelldb | `languages/zig.toml` |

## Comandos por domínio

Funções explicitamente anotadas com `#[tauri::command]` em `src-tauri/src/commands/*.rs`. Não inclui funções internas, ações puramente frontend ou comandos gerados por macros. A exposição remota deve ser conferida no dispatcher RPC.

### agent (24)

| Comando | Fonte |
|---|---|
| `agent_subscribe` | `src-tauri/src/commands/agent.rs:19` |
| `agent_providers` | `src-tauri/src/commands/agent.rs:35` |
| `agent_set_command` | `src-tauri/src/commands/agent.rs:43` |
| `agent_set_env` | `src-tauri/src/commands/agent.rs:56` |
| `agent_registry_list` | `src-tauri/src/commands/agent.rs:69` |
| `agent_registry_install` | `src-tauri/src/commands/agent.rs:81` |
| `agent_registry_remove` | `src-tauri/src/commands/agent.rs:94` |
| `agent_commands` | `src-tauri/src/commands/agent.rs:102` |
| `agent_entries` | `src-tauri/src/commands/agent.rs:114` |
| `agent_create` | `src-tauri/src/commands/agent.rs:125` |
| `agent_prompt` | `src-tauri/src/commands/agent.rs:132` |
| `agent_unqueue` | `src-tauri/src/commands/agent.rs:145` |
| `agent_send_queued_now` | `src-tauri/src/commands/agent.rs:157` |
| `agent_set_config` | `src-tauri/src/commands/agent.rs:169` |
| `agent_fork` | `src-tauri/src/commands/agent.rs:182` |
| `agent_rollback` | `src-tauri/src/commands/agent.rs:194` |
| `agent_probe` | `src-tauri/src/commands/agent.rs:207` |
| `agent_cancel` | `src-tauri/src/commands/agent.rs:219` |
| `agent_respond` | `src-tauri/src/commands/agent.rs:231` |
| `agent_archive` | `src-tauri/src/commands/agent.rs:243` |
| `agent_unarchive` | `src-tauri/src/commands/agent.rs:249` |
| `agent_delete` | `src-tauri/src/commands/agent.rs:255` |
| `agent_changes` | `src-tauri/src/commands/agent.rs:266` |
| `agent_base_text` | `src-tauri/src/commands/agent.rs:273` |

### analysis (5)

| Comando | Fonte |
|---|---|
| `inspect_code` | `src-tauri/src/commands/analysis.rs:16` |
| `analysis_locate_duplicates` | `src-tauri/src/commands/analysis.rs:36` |
| `structural_languages` | `src-tauri/src/commands/analysis.rs:49` |
| `structural_validate` | `src-tauri/src/commands/analysis.rs:56` |
| `structural_search` | `src-tauri/src/commands/analysis.rs:65` |

### app (22)

| Comando | Fonte |
|---|---|
| `app_info` | `src-tauri/src/commands/app.rs:26` |
| `recent_projects` | `src-tauri/src/commands/app.rs:41` |
| `remove_recent_project` | `src-tauri/src/commands/app.rs:48` |
| `open_project` | `src-tauri/src/commands/app.rs:54` |
| `light_edit_open` | `src-tauri/src/commands/app.rs:79` |
| `project_rename` | `src-tauri/src/commands/app.rs:101` |
| `close_project` | `src-tauri/src/commands/app.rs:115` |
| `languages` | `src-tauri/src/commands/app.rs:127` |
| `settings_get` | `src-tauri/src/commands/app.rs:136` |
| `settings_get_global` | `src-tauri/src/commands/app.rs:145` |
| `settings_set` | `src-tauri/src/commands/app.rs:154` |
| `settings_export` | `src-tauri/src/commands/app.rs:183` |
| `settings_import` | `src-tauri/src/commands/app.rs:203` |
| `project_roots` | `src-tauri/src/commands/app.rs:224` |
| `project_current` | `src-tauri/src/commands/app.rs:231` |
| `cancel_request` | `src-tauri/src/commands/app.rs:237` |
| `cancel_task` | `src-tauri/src/commands/app.rs:245` |
| `log_frontend` | `src-tauri/src/commands/app.rs:261` |
| `project_trust_status` | `src-tauri/src/commands/app.rs:272` |
| `project_trust_list` | `src-tauri/src/commands/app.rs:278` |
| `project_trust_set` | `src-tauri/src/commands/app.rs:284` |
| `project_trust_remove_location` | `src-tauri/src/commands/app.rs:299` |

### build (7)

| Comando | Fonte |
|---|---|
| `build_model` | `src-tauri/src/commands/build.rs:16` |
| `build_sync` | `src-tauri/src/commands/build.rs:25` |
| `gradle_dependencies` | `src-tauri/src/commands/build.rs:49` |
| `gradle_published_catalog` | `src-tauri/src/commands/build.rs:65` |
| `maven_dependency_declaration` | `src-tauri/src/commands/build.rs:76` |
| `maven_exclude_dependency` | `src-tauri/src/commands/build.rs:90` |
| `build_run` | `src-tauri/src/commands/build.rs:106` |

### bytes (3)

| Comando | Fonte |
|---|---|
| `fs_probe` | `src-tauri/src/commands/bytes.rs:14` |
| `fs_read_range` | `src-tauri/src/commands/bytes.rs:21` |
| `fs_read_image` | `src-tauri/src/commands/bytes.rs:28` |

### caches (2)

| Comando | Fonte |
|---|---|
| `caches_schedule_invalidation` | `src-tauri/src/commands/caches.rs:11` |
| `app_restart` | `src-tauri/src/commands/caches.rs:25` |

### clipboard (3)

| Comando | Fonte |
|---|---|
| `clipboard_file_list` | `src-tauri/src/commands/clipboard.rs:14` |
| `clipboard_has_files` | `src-tauri/src/commands/clipboard.rs:21` |
| `clipboard_set_file_list` | `src-tauri/src/commands/clipboard.rs:30` |

### coverage (3)

| Comando | Fonte |
|---|---|
| `coverage_prepare` | `src-tauri/src/commands/coverage.rs:15` |
| `coverage_collect` | `src-tauri/src/commands/coverage.rs:26` |
| `coverage_import` | `src-tauri/src/commands/coverage.rs:38` |

### db (28)

| Comando | Fonte |
|---|---|
| `db_sources` | `src-tauri/src/commands/db.rs:13` |
| `db_save_sources` | `src-tauri/src/commands/db.rs:19` |
| `db_set_password` | `src-tauri/src/commands/db.rs:25` |
| `db_test` | `src-tauri/src/commands/db.rs:37` |
| `db_set_ssh_secret` | `src-tauri/src/commands/db.rs:49` |
| `db_trust_ssh_host` | `src-tauri/src/commands/db.rs:61` |
| `db_connected` | `src-tauri/src/commands/db.rs:67` |
| `db_connect` | `src-tauri/src/commands/db.rs:73` |
| `db_set_manual_commit` | `src-tauri/src/commands/db.rs:79` |
| `db_finish_transaction` | `src-tauri/src/commands/db.rs:90` |
| `db_disconnect` | `src-tauri/src/commands/db.rs:101` |
| `db_databases` | `src-tauri/src/commands/db.rs:107` |
| `db_schemas` | `src-tauri/src/commands/db.rs:113` |
| `db_tables` | `src-tauri/src/commands/db.rs:119` |
| `db_table_details` | `src-tauri/src/commands/db.rs:130` |
| `db_ddl` | `src-tauri/src/commands/db.rs:142` |
| `db_schema_objects` | `src-tauri/src/commands/db.rs:154` |
| `db_object_ddl` | `src-tauri/src/commands/db.rs:165` |
| `db_explain` | `src-tauri/src/commands/db.rs:178` |
| `db_history` | `src-tauri/src/commands/db.rs:190` |
| `db_remove_history` | `src-tauri/src/commands/db.rs:200` |
| `db_export_file` | `src-tauri/src/commands/db.rs:214` |
| `db_completion` | `src-tauri/src/commands/db.rs:224` |
| `db_statements` | `src-tauri/src/commands/db.rs:234` |
| `db_execute` | `src-tauri/src/commands/db.rs:247` |
| `db_table_page` | `src-tauri/src/commands/db.rs:261` |
| `db_apply_edits` | `src-tauri/src/commands/db.rs:290` |
| `db_console_path` | `src-tauri/src/commands/db.rs:303` |

### debug (30)

| Comando | Fonte |
|---|---|
| `debug_start` | `src-tauri/src/commands/debug.rs:14` |
| `debug_set_breakpoints` | `src-tauri/src/commands/debug.rs:24` |
| `debug_threads` | `src-tauri/src/commands/debug.rs:34` |
| `debug_stack_trace` | `src-tauri/src/commands/debug.rs:40` |
| `debug_scopes` | `src-tauri/src/commands/debug.rs:50` |
| `debug_variables` | `src-tauri/src/commands/debug.rs:56` |
| `debug_evaluate` | `src-tauri/src/commands/debug.rs:66` |
| `debug_completions` | `src-tauri/src/commands/debug.rs:78` |
| `debug_resume` | `src-tauri/src/commands/debug.rs:91` |
| `debug_pause` | `src-tauri/src/commands/debug.rs:97` |
| `debug_step` | `src-tauri/src/commands/debug.rs:103` |
| `debug_run_to` | `src-tauri/src/commands/debug.rs:114` |
| `debug_stop` | `src-tauri/src/commands/debug.rs:127` |
| `debug_evaluate_in` | `src-tauri/src/commands/debug.rs:134` |
| `debug_breakpoint_states` | `src-tauri/src/commands/debug.rs:147` |
| `debug_sessions` | `src-tauri/src/commands/debug.rs:154` |
| `debug_exception_filters` | `src-tauri/src/commands/debug.rs:160` |
| `debug_set_exception_breakpoints` | `src-tauri/src/commands/debug.rs:166` |
| `debug_set_variable` | `src-tauri/src/commands/debug.rs:175` |
| `debug_force_step_over` | `src-tauri/src/commands/debug.rs:191` |
| `debug_step_in_targets` | `src-tauri/src/commands/debug.rs:202` |
| `debug_step_in_target` | `src-tauri/src/commands/debug.rs:212` |
| `debug_restart_frame` | `src-tauri/src/commands/debug.rs:224` |
| `debug_capabilities` | `src-tauri/src/commands/debug.rs:230` |
| `debug_set_function_breakpoints` | `src-tauri/src/commands/debug.rs:237` |
| `debug_set_data_breakpoints` | `src-tauri/src/commands/debug.rs:247` |
| `debug_data_breakpoint_info` | `src-tauri/src/commands/debug.rs:256` |
| `debug_attachable_processes` | `src-tauri/src/commands/debug.rs:269` |
| `debug_listen_for_jvm` | `src-tauri/src/commands/debug.rs:277` |
| `debug_redefine_classes` | `src-tauri/src/commands/debug.rs:290` |

### dependencies (1)

| Comando | Fonte |
|---|---|
| `dependency_versions` | `src-tauri/src/commands/dependencies.rs:9` |

### deploy (15)

| Comando | Fonte |
|---|---|
| `deploy_coverage` | `src-tauri/src/commands/deploy.rs:9` |
| `deploy_upload` | `src-tauri/src/commands/deploy.rs:19` |
| `deploy_download` | `src-tauri/src/commands/deploy.rs:31` |
| `deploy_delete_remote` | `src-tauri/src/commands/deploy.rs:43` |
| `deploy_compare` | `src-tauri/src/commands/deploy.rs:54` |
| `deploy_sync` | `src-tauri/src/commands/deploy.rs:66` |
| `deploy_info` | `src-tauri/src/commands/deploy.rs:78` |
| `deploy_server_root` | `src-tauri/src/commands/deploy.rs:89` |
| `remote_list` | `src-tauri/src/commands/deploy.rs:99` |
| `remote_open` | `src-tauri/src/commands/deploy.rs:109` |
| `remote_of` | `src-tauri/src/commands/deploy.rs:115` |
| `remote_delete` | `src-tauri/src/commands/deploy.rs:121` |
| `remote_mkdir` | `src-tauri/src/commands/deploy.rs:127` |
| `remote_rename` | `src-tauri/src/commands/deploy.rs:133` |
| `deploy_test_connection` | `src-tauri/src/commands/deploy.rs:144` |

### doc (17)

| Comando | Fonte |
|---|---|
| `doc_open` | `src-tauri/src/commands/doc.rs:17` |
| `doc_close` | `src-tauri/src/commands/doc.rs:23` |
| `doc_edit` | `src-tauri/src/commands/doc.rs:33` |
| `doc_save` | `src-tauri/src/commands/doc.rs:53` |
| `doc_save_all` | `src-tauri/src/commands/doc.rs:59` |
| `doc_sync_from_disk` | `src-tauri/src/commands/doc.rs:65` |
| `doc_snapshot` | `src-tauri/src/commands/doc.rs:71` |
| `doc_open_virtual` | `src-tauri/src/commands/doc.rs:78` |
| `doc_ui_mode` | `src-tauri/src/commands/doc.rs:86` |
| `doc_set_encoding` | `src-tauri/src/commands/doc.rs:93` |
| `doc_set_line_ending` | `src-tauri/src/commands/doc.rs:105` |
| `doc_outline` | `src-tauri/src/commands/doc.rs:122` |
| `doc_folding` | `src-tauri/src/commands/doc.rs:128` |
| `doc_highlights` | `src-tauri/src/commands/doc.rs:136` |
| `doc_selection_ranges` | `src-tauri/src/commands/doc.rs:144` |
| `history_list` | `src-tauri/src/commands/doc.rs:155` |
| `history_content` | `src-tauri/src/commands/doc.rs:161` |

### docker (14)

| Comando | Fonte |
|---|---|
| `docker_snapshot` | `src-tauri/src/commands/docker.rs:31` |
| `docker_container_op` | `src-tauri/src/commands/docker.rs:37` |
| `docker_remove` | `src-tauri/src/commands/docker.rs:43` |
| `docker_inspect` | `src-tauri/src/commands/docker.rs:55` |
| `docker_logs` | `src-tauri/src/commands/docker.rs:63` |
| `docker_events` | `src-tauri/src/commands/docker.rs:84` |
| `docker_pull` | `src-tauri/src/commands/docker.rs:101` |
| `docker_prune` | `src-tauri/src/commands/docker.rs:120` |
| `docker_compose_op` | `src-tauri/src/commands/docker.rs:139` |
| `docker_settings` | `src-tauri/src/commands/docker.rs:160` |
| `docker_save_settings` | `src-tauri/src/commands/docker.rs:167` |
| `docker_set_registry_password` | `src-tauri/src/commands/docker.rs:175` |
| `docker_registry_login` | `src-tauri/src/commands/docker.rs:187` |
| `docker_run_env` | `src-tauri/src/commands/docker.rs:208` |

### env (1)

| Comando | Fonte |
|---|---|
| `env_reload` | `src-tauri/src/commands/env.rs:12` |

### fonts (2)

| Comando | Fonte |
|---|---|
| `system_font_families` | `src-tauri/src/commands/fonts.rs:11` |
| `user_font_data` | `src-tauri/src/commands/fonts.rs:19` |

### fs (12)

| Comando | Fonte |
|---|---|
| `fs_entry_kind` | `src-tauri/src/commands/fs.rs:10` |
| `fs_compare_directories` | `src-tauri/src/commands/fs.rs:16` |
| `fs_copy_merge` | `src-tauri/src/commands/fs.rs:29` |
| `fs_read_dir` | `src-tauri/src/commands/fs.rs:42` |
| `fs_create_file` | `src-tauri/src/commands/fs.rs:50` |
| `fs_create_file_bytes` | `src-tauri/src/commands/fs.rs:56` |
| `fs_create_dir` | `src-tauri/src/commands/fs.rs:62` |
| `fs_rename` | `src-tauri/src/commands/fs.rs:68` |
| `fs_set_writable` | `src-tauri/src/commands/fs.rs:76` |
| `fs_delete` | `src-tauri/src/commands/fs.rs:83` |
| `fs_copy` | `src-tauri/src/commands/fs.rs:89` |
| `fs_read_text` | `src-tauri/src/commands/fs.rs:97` |

### github (11)

| Comando | Fonte |
|---|---|
| `gh_account_repos` | `src-tauri/src/commands/github.rs:41` |
| `gh_availability` | `src-tauri/src/commands/github.rs:47` |
| `gh_pr_list` | `src-tauri/src/commands/github.rs:58` |
| `gh_pr_view` | `src-tauri/src/commands/github.rs:70` |
| `gh_pr_review_comments` | `src-tauri/src/commands/github.rs:82` |
| `gh_pr_checkout` | `src-tauri/src/commands/github.rs:94` |
| `gh_pr_create` | `src-tauri/src/commands/github.rs:119` |
| `gh_pr_review` | `src-tauri/src/commands/github.rs:143` |
| `gh_pr_comment` | `src-tauri/src/commands/github.rs:157` |
| `gh_api` | `src-tauri/src/commands/github.rs:171` |
| `gh_pr_prepare_diff` | `src-tauri/src/commands/github.rs:185` |

### history (3)

| Comando | Fonte |
|---|---|
| `history_list_dir` | `src-tauri/src/commands/history.rs:14` |
| `history_put_label` | `src-tauri/src/commands/history.rs:25` |
| `history_restore` | `src-tauri/src/commands/history.rs:33` |

### http (7)

| Comando | Fonte |
|---|---|
| `http_requests` | `src-tauri/src/commands/http.rs:9` |
| `http_environments` | `src-tauri/src/commands/http.rs:16` |
| `http_execute` | `src-tauri/src/commands/http.rs:31` |
| `http_history` | `src-tauri/src/commands/http.rs:64` |
| `http_history_get` | `src-tauri/src/commands/http.rs:70` |
| `http_history_clear` | `src-tauri/src/commands/http.rs:76` |
| `proxy_check_connection` | `src-tauri/src/commands/http.rs:84` |

### java (3)

| Comando | Fonte |
|---|---|
| `java_resolve_launch` | `src-tauri/src/commands/java.rs:17` |
| `java_debug_server` | `src-tauri/src/commands/java.rs:31` |
| `java_build_workspace` | `src-tauri/src/commands/java.rs:38` |

### lsp (37)

| Comando | Fonte |
|---|---|
| `lsp_completion` | `src-tauri/src/commands/lsp.rs:12` |
| `lsp_inline_completion` | `src-tauri/src/commands/lsp.rs:26` |
| `lsp_resolve_completion` | `src-tauri/src/commands/lsp.rs:39` |
| `lsp_hover` | `src-tauri/src/commands/lsp.rs:50` |
| `lsp_signature_help` | `src-tauri/src/commands/lsp.rs:62` |
| `lsp_goto` | `src-tauri/src/commands/lsp.rs:73` |
| `lsp_implementations` | `src-tauri/src/commands/lsp.rs:88` |
| `lsp_virtual_document` | `src-tauri/src/commands/lsp.rs:102` |
| `lsp_resolve_class_file` | `src-tauri/src/commands/lsp.rs:112` |
| `lsp_references` | `src-tauri/src/commands/lsp.rs:125` |
| `lsp_document_highlights` | `src-tauri/src/commands/lsp.rs:148` |
| `lsp_workspace_symbols` | `src-tauri/src/commands/lsp.rs:159` |
| `lsp_code_actions` | `src-tauri/src/commands/lsp.rs:170` |
| `lsp_code_action_query` | `src-tauri/src/commands/lsp.rs:183` |
| `lsp_resolve_code_action` | `src-tauri/src/commands/lsp.rs:197` |
| `lsp_apply_code_action` | `src-tauri/src/commands/lsp.rs:209` |
| `lsp_prepare_rename` | `src-tauri/src/commands/lsp.rs:220` |
| `lsp_rename` | `src-tauri/src/commands/lsp.rs:232` |
| `lsp_hierarchy_members` | `src-tauri/src/commands/lsp.rs:246` |
| `lsp_hierarchy_refactor` | `src-tauri/src/commands/lsp.rs:261` |
| `lsp_format` | `src-tauri/src/commands/lsp.rs:277` |
| `lsp_inlay_hints` | `src-tauri/src/commands/lsp.rs:289` |
| `lsp_semantic_tokens` | `src-tauri/src/commands/lsp.rs:300` |
| `lsp_code_lens` | `src-tauri/src/commands/lsp.rs:310` |
| `lsp_document_links` | `src-tauri/src/commands/lsp.rs:317` |
| `lsp_call_hierarchy` | `src-tauri/src/commands/lsp.rs:327` |
| `lsp_type_hierarchy` | `src-tauri/src/commands/lsp.rs:340` |
| `lsp_servers` | `src-tauri/src/commands/lsp.rs:352` |
| `lsp_resend_diagnostics` | `src-tauri/src/commands/lsp.rs:359` |
| `lsp_restart` | `src-tauri/src/commands/lsp.rs:365` |
| `apply_workspace_edit` | `src-tauri/src/commands/lsp.rs:372` |
| `prepare_workspace_edit` | `src-tauri/src/commands/lsp.rs:378` |
| `undo_workspace_edit` | `src-tauri/src/commands/lsp.rs:388` |
| `redo_workspace_edit` | `src-tauri/src/commands/lsp.rs:394` |
| `lsp_execute_command` | `src-tauri/src/commands/lsp.rs:402` |
| `lsp_resolve_command` | `src-tauri/src/commands/lsp.rs:413` |
| `lsp_execute_code_action` | `src-tauri/src/commands/lsp.rs:427` |

### nav (13)

| Comando | Fonte |
|---|---|
| `index_status` | `src-tauri/src/commands/nav.rs:15` |
| `index_file_extensions` | `src-tauri/src/commands/nav.rs:21` |
| `find_files` | `src-tauri/src/commands/nav.rs:27` |
| `find_dirs` | `src-tauri/src/commands/nav.rs:34` |
| `spring_route_sources` | `src-tauri/src/commands/nav.rs:41` |
| `find_symbols` | `src-tauri/src/commands/nav.rs:50` |
| `mark_recent` | `src-tauri/src/commands/nav.rs:62` |
| `remove_recent` | `src-tauri/src/commands/nav.rs:68` |
| `recent_files` | `src-tauri/src/commands/nav.rs:75` |
| `web_goto` | `src-tauri/src/commands/nav.rs:82` |
| `fs_resolve_reference` | `src-tauri/src/commands/nav.rs:89` |
| `path_completions` | `src-tauri/src/commands/nav.rs:101` |
| `web_unresolved_references` | `src-tauri/src/commands/nav.rs:113` |

### notebook (11)

| Comando | Fonte |
|---|---|
| `notebook_open` | `src-tauri/src/commands/notebook.rs:11` |
| `notebook_get` | `src-tauri/src/commands/notebook.rs:17` |
| `notebook_edit` | `src-tauri/src/commands/notebook.rs:23` |
| `notebook_save` | `src-tauri/src/commands/notebook.rs:35` |
| `notebook_reload` | `src-tauri/src/commands/notebook.rs:41` |
| `notebook_undo` | `src-tauri/src/commands/notebook.rs:47` |
| `notebook_redo` | `src-tauri/src/commands/notebook.rs:53` |
| `notebook_close` | `src-tauri/src/commands/notebook.rs:59` |
| `notebook_interrupt` | `src-tauri/src/commands/notebook.rs:65` |
| `notebook_restart` | `src-tauri/src/commands/notebook.rs:71` |
| `notebook_execute` | `src-tauri/src/commands/notebook.rs:78` |

### perf (2)

| Comando | Fonte |
|---|---|
| `app_metrics` | `src-tauri/src/commands/perf.rs:62` |
| `clear_caches` | `src-tauri/src/commands/perf.rs:222` |

### plugin (39)

| Comando | Fonte |
|---|---|
| `plugin_subscribe` | `src-tauri/src/commands/plugin.rs:166` |
| `plugin_list` | `src-tauri/src/commands/plugin.rs:175` |
| `plugin_set_enabled` | `src-tauri/src/commands/plugin.rs:192` |
| `plugin_preview_install` | `src-tauri/src/commands/plugin.rs:200` |
| `plugin_install_dir` | `src-tauri/src/commands/plugin.rs:209` |
| `plugin_grant` | `src-tauri/src/commands/plugin.rs:217` |
| `plugin_set_capability` | `src-tauri/src/commands/plugin.rs:225` |
| `plugin_link` | `src-tauri/src/commands/plugin.rs:238` |
| `plugin_unlink` | `src-tauri/src/commands/plugin.rs:245` |
| `plugin_assets` | `src-tauri/src/commands/plugin.rs:253` |
| `plugin_activation_event` | `src-tauri/src/commands/plugin.rs:265` |
| `plugin_catalog` | `src-tauri/src/commands/plugin.rs:293` |
| `plugin_uninstall` | `src-tauri/src/commands/plugin.rs:305` |
| `plugin_reload` | `src-tauri/src/commands/plugin.rs:313` |
| `plugin_run_command` | `src-tauri/src/commands/plugin.rs:321` |
| `plugin_post_events` | `src-tauri/src/commands/plugin.rs:342` |
| `plugin_event_kinds` | `src-tauri/src/commands/plugin.rs:349` |
| `plugin_status_items` | `src-tauri/src/commands/plugin.rs:363` |
| `plugin_cancel_task` | `src-tauri/src/commands/plugin.rs:375` |
| `plugin_line_markers` | `src-tauri/src/commands/plugin.rs:382` |
| `plugin_view_render` | `src-tauri/src/commands/plugin.rs:394` |
| `plugin_view_event` | `src-tauri/src/commands/plugin.rs:410` |
| `plugin_web_page` | `src-tauri/src/commands/plugin.rs:426` |
| `plugin_web_save_file` | `src-tauri/src/commands/plugin.rs:441` |
| `plugin_web_read_file` | `src-tauri/src/commands/plugin.rs:458` |
| `plugin_market` | `src-tauri/src/commands/plugin.rs:479` |
| `plugin_market_url` | `src-tauri/src/commands/plugin.rs:489` |
| `plugin_set_market_url` | `src-tauri/src/commands/plugin.rs:496` |
| `plugin_market_download` | `src-tauri/src/commands/plugin.rs:503` |
| `plugin_unpack_package` | `src-tauri/src/commands/plugin.rs:511` |
| `plugin_read_intellij_theme` | `src-tauri/src/commands/plugin.rs:519` |
| `plugin_installed_intellij_themes` | `src-tauri/src/commands/plugin.rs:526` |
| `plugin_stage_package` | `src-tauri/src/commands/plugin.rs:533` |
| `plugin_roll_back` | `src-tauri/src/commands/plugin.rs:545` |
| `plugin_secrets` | `src-tauri/src/commands/plugin.rs:560` |
| `plugin_set_secret` | `src-tauri/src/commands/plugin.rs:567` |
| `plugin_set_active_file` | `src-tauri/src/commands/plugin.rs:611` |
| `plugin_set_theme` | `src-tauri/src/commands/plugin.rs:618` |
| `plugin_set_theme_frame` | `src-tauri/src/commands/plugin.rs:633` |

### profiler (2)

| Comando | Fonte |
|---|---|
| `profiler_prepare` | `src-tauri/src/commands/profiler.rs:13` |
| `profiler_collect` | `src-tauri/src/commands/profiler.rs:30` |

### refactor (5)

| Comando | Fonte |
|---|---|
| `refactor_file_move_edits` | `src-tauri/src/commands/refactor.rs:14` |
| `refactor_move_files` | `src-tauri/src/commands/refactor.rs:27` |
| `refactor_undo_file_move` | `src-tauri/src/commands/refactor.rs:40` |
| `refactor_can_undo_file_move` | `src-tauri/src/commands/refactor.rs:47` |
| `refactor_file_move_text_edits` | `src-tauri/src/commands/refactor.rs:55` |

### run (25)

| Comando | Fonte |
|---|---|
| `run_dotnet_resolve` | `src-tauri/src/commands/run.rs:13` |
| `run_application_build` | `src-tauri/src/commands/run.rs:24` |
| `run_application_publish` | `src-tauri/src/commands/run.rs:35` |
| `run_configs` | `src-tauri/src/commands/run.rs:48` |
| `run_save_configs` | `src-tauri/src/commands/run.rs:58` |
| `run_without_derived` | `src-tauri/src/commands/run.rs:70` |
| `run_apply_settings` | `src-tauri/src/commands/run.rs:84` |
| `run_start` | `src-tauri/src/commands/run.rs:97` |
| `run_stop` | `src-tauri/src/commands/run.rs:111` |
| `run_stdin` | `src-tauri/src/commands/run.rs:117` |
| `run_resize` | `src-tauri/src/commands/run.rs:124` |
| `run_list` | `src-tauri/src/commands/run.rs:130` |
| `run_close_stdin` | `src-tauri/src/commands/run.rs:136` |
| `run_templates` | `src-tauri/src/commands/run.rs:142` |
| `run_save_templates` | `src-tauri/src/commands/run.rs:148` |
| `run_import_sources` | `src-tauri/src/commands/run.rs:155` |
| `run_import_configs` | `src-tauri/src/commands/run.rs:165` |
| `run_system_env` | `src-tauri/src/commands/run.rs:177` |
| `run_gradle_jvm_args_script` | `src-tauri/src/commands/run.rs:184` |
| `run_test_reports` | `src-tauri/src/commands/run.rs:196` |
| `run_tomcat_home` | `src-tauri/src/commands/run.rs:207` |
| `run_tomcat_artifacts` | `src-tauri/src/commands/run.rs:216` |
| `run_tomcat_build` | `src-tauri/src/commands/run.rs:224` |
| `run_tomcat_sync` | `src-tauri/src/commands/run.rs:233` |
| `run_tomcat_update` | `src-tauri/src/commands/run.rs:245` |

### sdk (7)

| Comando | Fonte |
|---|---|
| `sdk_detect` | `src-tauri/src/commands/sdk.rs:16` |
| `sdk_python_effective` | `src-tauri/src/commands/sdk.rs:23` |
| `sdk_project_libraries` | `src-tauri/src/commands/sdk.rs:31` |
| `sdk_locate_tools` | `src-tauri/src/commands/sdk.rs:41` |
| `sdk_python_create_venv` | `src-tauri/src/commands/sdk.rs:53` |
| `sdk_python_packages` | `src-tauri/src/commands/sdk.rs:74` |
| `sdk_python_pip` | `src-tauri/src/commands/sdk.rs:87` |

### search (4)

| Comando | Fonte |
|---|---|
| `search_start` | `src-tauri/src/commands/search.rs:16` |
| `replace_in_files` | `src-tauri/src/commands/search.rs:38` |
| `replace_preview` | `src-tauri/src/commands/search.rs:64` |
| `search_validate` | `src-tauri/src/commands/search.rs:80` |

### spell (2)

| Comando | Fonte |
|---|---|
| `spell_check` | `src-tauri/src/commands/spell.rs:15` |
| `spell_suggest` | `src-tauri/src/commands/spell.rs:28` |

### ssh (10)

| Comando | Fonte |
|---|---|
| `ssh_test` | `src-tauri/src/commands/ssh.rs:17` |
| `ssh_set_secret` | `src-tauri/src/commands/ssh.rs:29` |
| `ssh_needs_secret` | `src-tauri/src/commands/ssh.rs:36` |
| `ssh_trust_host` | `src-tauri/src/commands/ssh.rs:43` |
| `ssh_connected` | `src-tauri/src/commands/ssh.rs:51` |
| `ssh_disconnect` | `src-tauri/src/commands/ssh.rs:57` |
| `ssh_askpass_answer` | `src-tauri/src/commands/ssh.rs:64` |
| `git_credentials` | `src-tauri/src/commands/ssh.rs:74` |
| `git_credential_forget` | `src-tauri/src/commands/ssh.rs:81` |
| `ssh_terminal_command` | `src-tauri/src/commands/ssh.rs:99` |

### syntax (9)

| Comando | Fonte |
|---|---|
| `syntax_support` | `src-tauri/src/commands/syntax.rs:18` |
| `syntax_node_at` | `src-tauri/src/commands/syntax.rs:25` |
| `syntax_expression_at` | `src-tauri/src/commands/syntax.rs:39` |
| `syntax_errors` | `src-tauri/src/commands/syntax.rs:52` |
| `syntax_locals` | `src-tauri/src/commands/syntax.rs:65` |
| `syntax_identifiers` | `src-tauri/src/commands/syntax.rs:78` |
| `syntax_identifiers_in_files` | `src-tauri/src/commands/syntax.rs:92` |
| `syntax_structural_ranges` | `src-tauri/src/commands/syntax.rs:106` |
| `jvm_file_presentations` | `src-tauri/src/commands/syntax.rs:118` |

### term (8)

| Comando | Fonte |
|---|---|
| `term_spawn` | `src-tauri/src/commands/term.rs:11` |
| `term_store_image` | `src-tauri/src/commands/term.rs:29` |
| `term_write` | `src-tauri/src/commands/term.rs:40` |
| `term_resize` | `src-tauri/src/commands/term.rs:46` |
| `term_kill` | `src-tauri/src/commands/term.rs:52` |
| `term_is_busy` | `src-tauri/src/commands/term.rs:60` |
| `term_default_shell` | `src-tauri/src/commands/term.rs:67` |
| `term_available_shells` | `src-tauri/src/commands/term.rs:74` |

### tools (7)

| Comando | Fonte |
|---|---|
| `tools_list` | `src-tauri/src/commands/tools.rs:17` |
| `tools_install` | `src-tauri/src/commands/tools.rs:25` |
| `tools_uninstall` | `src-tauri/src/commands/tools.rs:39` |
| `jdk_download_vendors` | `src-tauri/src/commands/tools.rs:46` |
| `jdk_download_releases` | `src-tauri/src/commands/tools.rs:53` |
| `jdk_download_location` | `src-tauri/src/commands/tools.rs:65` |
| `jdk_download` | `src-tauri/src/commands/tools.rs:76` |

### vcs (76)

| Comando | Fonte |
|---|---|
| `vcs_status` | `src-tauri/src/commands/vcs.rs:15` |
| `vcs_roots` | `src-tauri/src/commands/vcs.rs:21` |
| `vcs_branch_info` | `src-tauri/src/commands/vcs.rs:27` |
| `vcs_line_hunks` | `src-tauri/src/commands/vcs.rs:38` |
| `vcs_file_at` | `src-tauri/src/commands/vcs.rs:44` |
| `vcs_block_history` | `src-tauri/src/commands/vcs.rs:57` |
| `vcs_blame` | `src-tauri/src/commands/vcs.rs:70` |
| `vcs_log` | `src-tauri/src/commands/vcs.rs:82` |
| `vcs_log_refs` | `src-tauri/src/commands/vcs.rs:93` |
| `vcs_log_users` | `src-tauri/src/commands/vcs.rs:103` |
| `vcs_open_external_log` | `src-tauri/src/commands/vcs.rs:113` |
| `vcs_log_details` | `src-tauri/src/commands/vcs.rs:123` |
| `vcs_log_details_batch` | `src-tauri/src/commands/vcs.rs:134` |
| `vcs_log_index` | `src-tauri/src/commands/vcs.rs:145` |
| `vcs_revision_children` | `src-tauri/src/commands/vcs.rs:155` |
| `vcs_revision_files` | `src-tauri/src/commands/vcs.rs:167` |
| `vcs_commit_files` | `src-tauri/src/commands/vcs.rs:178` |
| `vcs_commits_changes` | `src-tauri/src/commands/vcs.rs:190` |
| `vcs_branches` | `src-tauri/src/commands/vcs.rs:201` |
| `vcs_stashes` | `src-tauri/src/commands/vcs.rs:207` |
| `vcs_stage` | `src-tauri/src/commands/vcs.rs:213` |
| `vcs_add_to_ignore` | `src-tauri/src/commands/vcs.rs:219` |
| `vcs_unstage` | `src-tauri/src/commands/vcs.rs:230` |
| `vcs_stage_patch` | `src-tauri/src/commands/vcs.rs:236` |
| `vcs_discard` | `src-tauri/src/commands/vcs.rs:242` |
| `vcs_commit` | `src-tauri/src/commands/vcs.rs:248` |
| `vcs_checkout` | `src-tauri/src/commands/vcs.rs:260` |
| `vcs_create_branch` | `src-tauri/src/commands/vcs.rs:274` |
| `vcs_undo_commit` | `src-tauri/src/commands/vcs.rs:289` |
| `vcs_delete_branch` | `src-tauri/src/commands/vcs.rs:300` |
| `vcs_restore_branch` | `src-tauri/src/commands/vcs.rs:312` |
| `vcs_rename_branch` | `src-tauri/src/commands/vcs.rs:323` |
| `vcs_merge` | `src-tauri/src/commands/vcs.rs:335` |
| `vcs_rebase` | `src-tauri/src/commands/vcs.rs:346` |
| `vcs_stash_push` | `src-tauri/src/commands/vcs.rs:357` |
| `vcs_stash_apply` | `src-tauri/src/commands/vcs.rs:370` |
| `vcs_stash_drop` | `src-tauri/src/commands/vcs.rs:384` |
| `vcs_remote` | `src-tauri/src/commands/vcs.rs:396` |
| `vcs_conflict_versions` | `src-tauri/src/commands/vcs.rs:411` |
| `vcs_diff_text` | `src-tauri/src/commands/vcs.rs:421` |
| `vcs_diff_hunks` | `src-tauri/src/commands/vcs.rs:433` |
| `vcs_stage_hunks` | `src-tauri/src/commands/vcs.rs:441` |
| `vcs_clone` | `src-tauri/src/commands/vcs.rs:453` |
| `vcs_init` | `src-tauri/src/commands/vcs.rs:467` |
| `vcs_git_version` | `src-tauri/src/commands/vcs.rs:475` |
| `vcs_detected_git` | `src-tauri/src/commands/vcs.rs:482` |
| `vcs_config_get` | `src-tauri/src/commands/vcs.rs:489` |
| `vcs_operation` | `src-tauri/src/commands/vcs.rs:502` |
| `vcs_create_tag` | `src-tauri/src/commands/vcs.rs:523` |
| `vcs_tags` | `src-tauri/src/commands/vcs.rs:537` |
| `vcs_merge_with` | `src-tauri/src/commands/vcs.rs:544` |
| `vcs_rebase_with` | `src-tauri/src/commands/vcs.rs:557` |
| `vcs_remotes` | `src-tauri/src/commands/vcs.rs:569` |
| `vcs_edit_remote` | `src-tauri/src/commands/vcs.rs:575` |
| `vcs_worktrees` | `src-tauri/src/commands/vcs.rs:586` |
| `vcs_add_worktree` | `src-tauri/src/commands/vcs.rs:596` |
| `vcs_remove_worktree` | `src-tauri/src/commands/vcs.rs:609` |
| `vcs_diff_with_worktree` | `src-tauri/src/commands/vcs.rs:622` |
| `vcs_diff_revisions` | `src-tauri/src/commands/vcs.rs:634` |
| `vcs_merge_base` | `src-tauri/src/commands/vcs.rs:647` |
| `vcs_create_patch` | `src-tauri/src/commands/vcs.rs:659` |
| `vcs_patch_preview` | `src-tauri/src/commands/vcs.rs:670` |
| `vcs_apply_patch` | `src-tauri/src/commands/vcs.rs:681` |
| `vcs_shelve` | `src-tauri/src/commands/vcs.rs:693` |
| `vcs_shelves` | `src-tauri/src/commands/vcs.rs:704` |
| `vcs_unshelve` | `src-tauri/src/commands/vcs.rs:712` |
| `vcs_shelf_delete` | `src-tauri/src/commands/vcs.rs:724` |
| `vcs_shelf_rename` | `src-tauri/src/commands/vcs.rs:730` |
| `vcs_shelf_patch` | `src-tauri/src/commands/vcs.rs:736` |
| `vcs_changelists_load` | `src-tauri/src/commands/vcs.rs:747` |
| `vcs_changelists_save` | `src-tauri/src/commands/vcs.rs:753` |
| `vcs_write_patch` | `src-tauri/src/commands/vcs.rs:760` |
| `vcs_shelf_diff` | `src-tauri/src/commands/vcs.rs:771` |
| `vcs_shelf_import` | `src-tauri/src/commands/vcs.rs:781` |
| `vcs_compare_scope` | `src-tauri/src/commands/vcs.rs:793` |
| `vcs_compare_paths` | `src-tauri/src/commands/vcs.rs:803` |

### web (3)

| Comando | Fonte |
|---|---|
| `web_browsers` | `src-tauri/src/commands/web.rs:12` |
| `web_url` | `src-tauri/src/commands/web.rs:19` |
| `web_open` | `src-tauri/src/commands/web.rs:27` |

### window (25)

| Comando | Fonte |
|---|---|
| `window_open_project` | `src-tauri/src/commands/window.rs:19` |
| `window_open_files` | `src-tauri/src/commands/window.rs:34` |
| `window_open_file_in_new_window` | `src-tauri/src/commands/window.rs:47` |
| `window_open_remote` | `src-tauri/src/commands/window.rs:59` |
| `window_new` | `src-tauri/src/commands/window.rs:71` |
| `window_open_settings` | `src-tauri/src/commands/window.rs:80` |
| `window_open_comparison` | `src-tauri/src/commands/window.rs:94` |
| `window_open_deployment` | `src-tauri/src/commands/window.rs:107` |
| `window_cycle` | `src-tauri/src/commands/window.rs:120` |
| `window_toggle_fullscreen` | `src-tauri/src/commands/window.rs:126` |
| `window_set_titlebar_height` | `src-tauri/src/commands/window.rs:133` |
| `window_take_launch` | `src-tauri/src/commands/window.rs:147` |
| `window_open_projects` | `src-tauri/src/commands/window.rs:163` |
| `window_close_context` | `src-tauri/src/commands/window.rs:192` |
| `app_quit` | `src-tauri/src/commands/window.rs:199` |
| `app_cancel_quit` | `src-tauri/src/commands/window.rs:210` |
| `menu_configure` | `src-tauri/src/commands/window.rs:220` |
| `menu_refresh` | `src-tauri/src/commands/window.rs:233` |
| `menu_model` | `src-tauri/src/commands/window.rs:240` |
| `menu_set_disabled` | `src-tauri/src/commands/window.rs:254` |
| `app_log_location` | `src-tauri/src/commands/window.rs:275` |
| `app_build_info` | `src-tauri/src/commands/window.rs:296` |
| `app_check_update` | `src-tauri/src/commands/window.rs:361` |
| `app_startup_update_check` | `src-tauri/src/commands/window.rs:382` |
| `app_install_update` | `src-tauri/src/commands/window.rs:452` |

### window_group (9)

| Comando | Fonte |
|---|---|
| `window_group_current` | `src-tauri/src/commands/window_group.rs:7` |
| `window_group_merge` | `src-tauri/src/commands/window_group.rs:13` |
| `window_group_select` | `src-tauri/src/commands/window_group.rs:20` |
| `window_group_detach` | `src-tauri/src/commands/window_group.rs:27` |
| `window_group_close` | `src-tauri/src/commands/window_group.rs:34` |
| `window_group_close_tabs` | `src-tauri/src/commands/window_group.rs:47` |
| `window_group_cancel_close` | `src-tauri/src/commands/window_group.rs:54` |
| `window_group_reorder` | `src-tauri/src/commands/window_group.rs:60` |
| `window_group_restore` | `src-tauri/src/commands/window_group.rs:68` |

### workspace (3)

| Comando | Fonte |
|---|---|
| `workspace_create` | `src-tauri/src/commands/workspace.rs:10` |
| `workspace_update` | `src-tauri/src/commands/workspace.rs:21` |
| `workspace_attach` | `src-tauri/src/commands/workspace.rs:36` |
