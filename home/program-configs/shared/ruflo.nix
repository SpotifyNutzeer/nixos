{ lib, pkgs, ruflo, ... }:

let
  # Version aus dem Flake-Input ableiten: das Repo-package.json traegt dieselbe
  # Version wie das npm-Paket "ruflo" (Repo heisst intern noch claude-flow).
  # `nix flake update ruflo` bumpt damit Marketplace, CLI-Pin und (nach
  # Re-Vendoring, siehe harness/) die Harness-Dateien gemeinsam.
  rufloVersion = (builtins.fromJSON (builtins.readFile "${ruflo}/package.json")).version;

  # Der komplette Output von `ruflo init --yes` (v${rufloVersion}), eingecheckt
  # unter ./ruflo/harness. Vendoring statt Verlinken aus dem Flake-Input, weil
  # init eine SUBMENGE der im Repo/npm-Paket liegenden Templates auswaehlt und
  # drei Dateien generiert/patcht (settings.json -> hier deklarativ,
  # helpers.manifest.json, statusline.cjs). Abweichungen vom Init-Original:
  #  1. statusline.cjs: BAKED_INSTALL_ROOT = "" (Template-Default) — init
  #     backt dort einen absoluten npx-Cache-Pfad ein, der nur auf einer
  #     Maschine existiert.
  #  2. auto-memory-hook.mjs, metrics-db.mjs, learning-service.mjs:
  #     PROJECT_ROOT bevorzugt $CLAUDE_PROJECT_DIR (setzt Claude Code bei
  #     jedem Hook) vor der Ableitung aus dem Skript-Pfad. Ohne den Patch
  #     loest Node den Symlink in den read-only Store auf und die Skripte
  #     crashen bei mkdir .claude-flow/data im Store. Semantik unveraendert:
  #     Laufzeit-Zustand landet im Projekt, wie bei init-per-Projekt.
  #  3. auto-memory-hook.mjs: der memory-package.json-Sidecar (Zeiger auf
  #     @claude-flow/memory im npx-Cache) wird zusaetzlich in
  #     ~/.claude-flow/ gesucht — init schreibt ihn pro Projekt, das
  #     Activation-Script unten pflegt die user-level Variante. Ohne
  #     aufloesbares Memory-Paket degradiert Self-Learning auf einen
  #     JSON-Fallback und warnt bei jedem SessionStart.
  #  4. helpers/.helpers-version ist auf die CLI-Version gestampt (init
  #     hinterlaesst den stale Paket-Stamp, hier 3.32.29): bei Differenz
  #     versucht die CLI bei jedem Start, die kritischen Helpers ins
  #     Projekt/Home zu re-kopieren (helper-refresh.ts) — gegen die
  #     read-only Store-Symlinks scheitert das nur still, aber der Stamp
  #     macht es gleich zum No-Op.
  # Aktualisieren (VORHER pruefen, dass die neue Flake-Input-Version auch
  # auf npm publiziert ist — der Input trackt main, npm hinkt ggf. nach):
  #   cd $(mktemp -d) && npx -y ruflo@<neue version> init --yes
  #   dann agents/commands/skills/helpers + CLAUDE.md + .agents-Skill nach
  #   harness/ kopieren, sed auf BAKED_INSTALL_ROOT + PROJECT_ROOT/Sidecar-
  #   Patches wiederholen (siehe oben) und .helpers-version auf die neue
  #   Version stampen.
  harness = ./ruflo/harness;

  # Hook-Kommandos wie von `ruflo init` in settings.json geschrieben: Helper
  # aus dem Projekt nehmen, sonst Fallback auf ~/.claude/helpers — den
  # Fallback nutzt dieses Setup als Hauptpfad, da die Helpers user-level
  # installiert sind. Einzige Abweichung vom init-Original: absoluter
  # node-Pfad statt nacktem `node` — bei GUI-Start (macOS Dock) hat Claude
  # Code keinen Shell-PATH und die Hooks wuerden still mit exit 127 sterben.
  # Hooks sind best-effort Telemetrie/Koordination und exiten immer 0
  # (~20 ms gemessen), blockieren also nie einen Tool-Call.
  nodeBin = lib.getExe pkgs.nodejs;
  mkHelperHook = helper: sub: timeout: {
    type = "command";
    command = "sh -c 'D=\"\${CLAUDE_PROJECT_DIR:-.}\"; [ -f \"$D/.claude/helpers/${helper}\" ] || D=\"\${HOME}\"; exec ${nodeBin} \"$D/.claude/helpers/${helper}\" ${sub}'";
  } // lib.optionalAttrs (timeout != null) { inherit timeout; };

  hook = sub: timeout: mkHelperHook "hook-handler.cjs" sub timeout;
  memHook = sub: timeout: mkHelperHook "auto-memory-hook.mjs" sub timeout;
in
{
  # ── CLI ────────────────────────────────────────────────────────────────────
  # Ersatz fuer "npm install -g ruflo" aus install.sh (geht auf NixOS nicht):
  # duenner npx-Wrapper mit gepinnter Version. Beim ersten Aufruf laedt npx
  # das Paket in den Cache (~/.npm/_npx), danach offline-faehig. Das echte
  # Paket ist ein Shim um @claude-flow/cli.
  home.packages = [
    (pkgs.writeShellScriptBin "ruflo" ''
      export PATH="${pkgs.nodejs}/bin:$PATH"
      exec npx -y "ruflo@${rufloVersion}" "$@"
    '')
  ];

  # ── Harness-Dateien (user-level statt pro Projekt) ────────────────────────
  # `ruflo init` legt das alles pro Projekt an; die Hook-Kommandos (oben)
  # unterstuetzen aber explizit ~/.claude als Fallback. Damit gilt der Harness
  # in JEDEM Projekt, ohne jedes Repo zuzumuellen. Laufzeit-Zustand legen die
  # Hooks selbst an: ~/.ruflo/ (User-State) und <projekt>/.claude-flow/
  # (Sessions, Daten) — beides mutabel, gehoert nicht ins Nix-Store.
  home.file.".claude/helpers" = {
    source = "${harness}/claude/helpers";
    recursive = true;
  };
  # Skill-Discovery-Konvention (skills.sh): init materialisiert
  # .agents/skills/ruflo/SKILL.md im Projekt; user-level Pendant hier.
  home.file.".agents/skills/ruflo" = {
    source = "${harness}/agents-skills/ruflo";
    recursive = true;
  };

  # ── Memory-Sidecar (Self-Learning) ────────────────────────────────────────
  # `ruflo init` schreibt pro Projekt .claude-flow/memory-package.json mit dem
  # absoluten Pfad zu @claude-flow/memory im npx-Cache — nur so ist das Paket
  # auf dem npx-Installationsweg aufloesbar (optionalDependency der CLI, mit
  # eigenen Sibling-Deps, daher nicht in den Store kopierbar). Hier die
  # user-level Uebersetzung: npx-Cache fuer die gepinnte Version primen,
  # Pfad aufloesen, Sidecar nach ~/.claude-flow/ schreiben (der gepatchte
  # auto-memory-hook.mjs prueft diesen Fallback). Idempotent; braucht Netz
  # nur beim ersten Lauf bzw. nach Versions-Bump. Schlaegt das fehl, laeuft
  # alles weiter — Self-Learning nutzt dann den JSON-Fallback und der
  # SessionStart-Hook warnt sichtbar.
  home.activation.rufloMemorySidecar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.nodejs}/bin:$PATH"
    rufloSidecarOk=$(node -e 'try { const fs = require("fs"); const r = JSON.parse(fs.readFileSync(process.env.HOME + "/.claude-flow/memory-package.json", "utf8")); if (r.pinnedRuflo === "${rufloVersion}" && fs.existsSync(r.distPath)) console.log("ok"); } catch {}' 2>/dev/null || true)
    if [ "$rufloSidecarOk" != "ok" ]; then
      rufloFindDist() {
        for m in "$HOME"/.npm/_npx/*/node_modules; do
          [ -f "$m/ruflo/package.json" ] || continue
          v=$(node -p "require('$m/ruflo/package.json').version" 2>/dev/null || true)
          [ "$v" = "${rufloVersion}" ] || continue
          if [ -f "$m/@claude-flow/memory/dist/index.js" ]; then
            echo "$m/@claude-flow/memory/dist/index.js"
            return 0
          fi
        done
        return 0
      }
      rufloDist=$(rufloFindDist)
      if [ -z "$rufloDist" ]; then
        echo "ruflo: prime npx-Cache fuer ruflo@${rufloVersion} (erster Lauf, braucht Netz) ..."
        npx -y "ruflo@${rufloVersion}" --version >/dev/null 2>&1 || true
        rufloDist=$(rufloFindDist)
      fi
      if [ -n "$rufloDist" ]; then
        run node -e 'const fs = require("fs"); const dir = process.env.HOME + "/.claude-flow"; fs.mkdirSync(dir, { recursive: true }); let ver = ""; try { ver = require(process.argv[1].replace(/dist\/index\.js$/, "package.json")).version; } catch {} fs.writeFileSync(dir + "/memory-package.json", JSON.stringify({ distPath: process.argv[1], version: ver, resolvedBy: "home-manager", pinnedRuflo: "${rufloVersion}" }, null, 2) + "\n");' "$rufloDist"
      else
        echo "ruflo: @claude-flow/memory nicht aufloesbar — Self-Learning laeuft im JSON-Fallback (heilt sich beim naechsten switch mit Netz)"
      fi
    fi
  '';

  programs.claude-code = {
    # 17 Agents, 16 Command-Gruppen, 30 Skills — 1:1 der init-Output.
    # agentsDir/commandsDir symlinken die kompletten Verzeichnisse; skills
    # akzeptiert direkt ein Verzeichnis mit einem Ordner pro Skill.
    agentsDir = "${harness}/claude/agents";
    commandsDir = "${harness}/claude/commands";
    skills = "${harness}/claude/skills";

    # Ruflos CLAUDE.md als globales Memory (~/.claude/CLAUDE.md) — init legt
    # es pro Projekt an, user-level wirkt es ueberall.
    context = "${harness}/CLAUDE.md";

    # MCP-Server wie in dem von init geschriebenen .mcp.json, nur mit
    # gepinnter Version statt @latest. install.sh wuerde zusaetzlich
    # CLAUDE_FLOW_CWD=$HOME setzen (user-scope-Server starten mit cwd=/);
    # das home-manager-Modul liefert den Server als Personal-Plugin aus,
    # der pro Projekt mit Projekt-cwd startet — Env-Override wuerde hier
    # alle Tools faelschlich auf $HOME zeigen lassen, deshalb weggelassen.
    # command mit absolutem npx-Pfad (statt "npx" wie im init-Original) aus
    # demselben Grund wie bei den Hooks: GUI-Starts ohne Shell-PATH.
    mcpServers.claude-flow = {
      command = "${pkgs.nodejs}/bin/npx";
      args = [ "-y" "ruflo@${rufloVersion}" "mcp" "start" ];
      env = {
        npm_config_update_notifier = "false";
        CLAUDE_FLOW_MODE = "v3";
        CLAUDE_FLOW_HOOKS_ENABLED = "true";
        CLAUDE_FLOW_TOPOLOGY = "hierarchical-mesh";
        CLAUDE_FLOW_MAX_AGENTS = "15";
        CLAUDE_FLOW_MEMORY_BACKEND = "hybrid";
      };
      autoStart = false;
    };

    settings = {
      # Alle 11 Hook-Typen exakt wie von `ruflo init --yes` registriert.
      # SessionStart/Stop mergen per Listen-Konkatenation mit den
      # Sync-Hooks aus claude-memory-sync.nix — beide laufen.
      hooks = {
        PreToolUse = [
          { matcher = "Bash";                 hooks = [ (hook "pre-bash" 5000) ]; }
          { matcher = "Write|Edit|MultiEdit"; hooks = [ (hook "pre-edit" 5000) ]; }
        ];
        PostToolUse = [
          { matcher = "Write|Edit|MultiEdit"; hooks = [ (hook "post-edit" 10000) ]; }
          { matcher = "Bash";                 hooks = [ (hook "post-bash" 5000) ]; }
        ];
        UserPromptSubmit = [
          { hooks = [ (hook "route" 10000) ]; }
        ];
        SessionStart = [
          { hooks = [ (hook "session-restore" 15000) (memHook "import" 8000) ]; }
        ];
        SessionEnd = [
          { hooks = [ (hook "session-end" 10000) ]; }
        ];
        Stop = [
          { hooks = [ (memHook "sync" 10000) ]; }
        ];
        PreCompact = [
          { matcher = "manual"; hooks = [ (hook "compact-manual" null) (hook "session-end" 5000) ]; }
          { matcher = "auto";   hooks = [ (hook "compact-auto" null)   (hook "session-end" 6000) ]; }
        ];
        SubagentStart = [
          { hooks = [ (hook "status" 3000) ]; }
        ];
        SubagentStop = [
          { hooks = [ (hook "post-task" 5000) ]; }
        ];
        Notification = [
          { hooks = [ (hook "notify" 3000) ]; }
        ];
      };

      # RuFlo-Statusline (Swarm-/Hook-/Memory-/Security-Status). Ersetzt
      # keine bestehende — es gab keine.
      statusLine = {
        type = "command";
        command = "sh -c 'D=\"\${CLAUDE_PROJECT_DIR:-.}\"; [ -f \"$D/.claude/helpers/statusline.cjs\" ] || D=\"\${HOME}\"; exec ${nodeBin} \"$D/.claude/helpers/statusline.cjs\"'";
      };

      # Konkateniert mit allow/deny aus claude-code.nix.
      permissions = {
        allow = [
          "Bash(npx @claude-flow*)"
          "Bash(npx claude-flow*)"
          "Bash(node .claude/*)"
          # init-Original — matcht, wenn ein Projekt den Server per eigenem
          # .mcp.json unter dem Key "claude-flow" registriert.
          "mcp__claude-flow__*"
          # Unser Server kommt aber als Personal-Plugin aus dem
          # home-manager-Modul (mcpServers-Option) und dessen Tools heissen
          # mcp__plugin_<plugin>_<server>__<tool> (verifiziert via
          # `claude mcp list`: plugin:claude-code-home-manager:claude-flow).
          "mcp__plugin_claude-code-home-manager_claude-flow__*"
        ];
        deny = [
          "Read(./.env)"
          "Read(./.env.*)"
        ];
      };

      # CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS setzt bereits claude-code.nix.
      env = {
        CLAUDE_FLOW_V3_ENABLED = "true";
        CLAUDE_FLOW_HOOKS_ENABLED = "true";
      };

      # Ruflo-interner Config-Block, verbatim aus dem von init generierten
      # settings.json — bis auf: platform pro System statt hart kodiert,
      # teammateMode "tmux" statt "auto" (Pauls Setting in claude-code.nix).
      # init setzt auch settings.model = claude-sonnet-5; bewusst NICHT
      # uebernommen — model = "Fable" bleibt (claude-code.nix).
      # modelPreferences steuert nur ruflo-internes Routing.
      claudeFlow = {
        version = "3.0.0";
        enabled = true;
        platform = {
          os = if pkgs.stdenv.isDarwin then "darwin" else "linux";
          arch = if pkgs.stdenv.isAarch64 then "arm64" else "x64";
          shell = "fish";
        };
        modelPreferences = {
          default = "claude-sonnet-5";
          routing = "claude-haiku-4-5-20251001";
        };
        agentTeams = {
          enabled = true;
          teammateMode = "tmux";
          taskListEnabled = true;
          mailboxEnabled = true;
          coordination = {
            autoAssignOnIdle = true;
            trainPatternsOnComplete = true;
            notifyLeadOnComplete = true;
            sharedMemoryNamespace = "agent-teams";
          };
          hooks = {
            teammateIdle = {
              enabled = true;
              autoAssign = true;
              checkTaskList = true;
            };
            taskCompleted = {
              enabled = true;
              trainPatterns = true;
              notifyLead = true;
            };
          };
        };
        swarm = {
          topology = "hierarchical-mesh";
          maxAgents = 15;
        };
        memory = {
          backend = "hybrid";
          enableHNSW = true;
          learningBridge.enabled = true;
          memoryGraph.enabled = true;
          agentScopes.enabled = true;
        };
        neural.enabled = true;
        daemon = {
          autoStart = false;
          workers = [ "map" "audit" "optimize" ];
          schedules = {
            audit = { interval = "4h"; priority = "critical"; };
            optimize = { interval = "2h"; priority = "high"; };
          };
        };
        learning = {
          enabled = true;
          autoTrain = true;
          patterns = [ "coordination" "optimization" "prediction" ];
          retention = {
            shortTerm = "24h";
            longTerm = "30d";
          };
        };
        adr = {
          autoGenerate = true;
          directory = "/docs/adr";
          template = "madr";
        };
        ddd = {
          trackDomains = true;
          validateBoundedContexts = true;
          directory = "/docs/ddd";
        };
        security = {
          autoScan = true;
          scanOnEdit = true;
          cveCheck = true;
          threatModel = true;
        };
      };
    };
  };
}
