{ lib, pkgs, ruflo, ... }:
{
  # Claude Code deklarativ ueber das home-manager-Modul. Es schreibt
  # ~/.claude/settings.json als (read-only) Nix-Store-Symlink — Einstellungen
  # also HIER aendern, nicht zur Laufzeit ueber /config (das wuerde nicht
  # persistieren). Das claude-Binary kommt ueber home.packages aus diesem Modul,
  # deshalb ist es aus common/programs.nix entfernt. tmux selbst bleibt
  # system-weit in common/programs.nix.
  programs.claude-code = {
    enable = true;

    settings = {
      # ── bestehende Settings uebernommen ──────────────────────────────
      theme   = "dark-ansi";
      tui     = "fullscreen";
      verbose = true;
      model   = "Fable";
      # ── tmux ─────────────────────────────────────────────────────────
      # Agent-Teams laufen im tmux-Split-Pane-Modus: jeder Teammate bekommt
      # einen eigenen Pane. "tmux" erzwingt das (Alternative: "auto" = nur
      # falls tmux/iTerm2 vorhanden). Braucht das experimentelle Feature-Flag.
      teammateMode = "tmux";

      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";

        # Auto-Updater aus. Auf NixOS liegt die claude-Binary immutable im
        # Nix-Store; der Updater versucht sie zu ersetzen, scheitert und
        # blockiert den Start. Es gibt keinen settings.json-Config-Key dafuer
        # (autoUpdates in ~/.claude.json ist nur App-State) — die Env-Variable
        # ist der zuverlaessige Kill-Switch und wird vor dem Updater-Check
        # angewendet. Updates kommen ausschliesslich ueber nixos-rebuild.
        # DISABLE_UPDATES = "1" wuerde zusaetzlich manuelles `claude update` sperren.
        DISABLE_AUTOUPDATER = "1";
      };

      permissions = {
        defaultMode = "auto";
        # tmux-Kommandos ohne Rueckfrage erlauben (send-keys, split-window, …).
        allow = [ "Bash(tmux:*)" ];
      };

      # Plugins deklarativ aktivieren. Format: "<plugin>@<marketplace>" = true.
      # Die Marketplace "claude-plugins-official" (anthropics/claude-plugins-official)
      # registriert Claude Code beim ersten Start selbst; wir setzen hier nur das
      # Enable-Flag — kein interaktives /plugin install noetig (das wuerde in die
      # read-only settings.json schreiben wollen und fehlschlagen). code-review und
      # frontend-design liegen als first-party Plugins direkt im Marketplace-Repo;
      # superpowers (github.com/obra/superpowers) zieht Claude beim Aktivieren nach.
      enabledPlugins = {
        "superpowers@claude-plugins-official"     = true;
        "frontend-design@claude-plugins-official" = true;
        "code-review@claude-plugins-official"     = true;
        # ruflo-core ist hier bewusst NICHT aktiviert: der komplette
        # Ruflo-Harness kommt jetzt aus ruflo.nix (aequivalent zu
        # install.sh --full, d.h. CLI + MCP-Server + `ruflo init`-Setup).
        # Das Plugin ist laut Ruflo-README die "lite"-ALTERNATIVE dazu und
        # wuerde parallel doppelte Hooks und einen zweiten MCP-Server
        # (mcp__plugin_ruflo-core_ruflo__*, 314 Tools) registrieren.
        # Andere Plugins aus dem Marketplace (nur Agents/Commands/Skills,
        # z.B. "ruflo-swarm@ruflo") koennen gefahrlos ergaenzt werden.
      };

      # Ruflo-Marketplace (github.com/ruvnet/ruflo) deklarativ registrieren,
      # Version pinnt flake.lock. BEWUSST via extraKnownMarketplaces statt
      # der marketplaces-Option des Moduls: sobald `marketplaces` gesetzt
      # ist, verwaltet das Modul ~/.claude/plugins/known_marketplaces.json
      # als read-only Store-Symlink — dann kann Claude Code die offizielle
      # Marketplace nicht mehr selbst registrieren (deren reservierter Name
      # akzeptiert nur github-Quellen der anthropics-Org, was die Option
      # nicht ausdruecken kann) und superpowers/code-review/frontend-design
      # laden nicht mehr ("Marketplace not found"). So bleibt die Datei
      # beschreibbarer Laufzeit-Zustand und Claude merged diesen Eintrag
      # beim Start selbst dazu. Der komplette Ruflo-Harness (Hooks, Helpers,
      # Agents, Skills, Commands, MCP, CLI) liegt in ruflo.nix.
      extraKnownMarketplaces.ruflo = {
        source = {
          source = "directory";
          path = "${ruflo}";
        };
      };
    };
  };

  # Ruflo-Hooks, -Statusline und -MCP-Server (ruflo.nix) brauchen node/npx
  # auf dem PATH. Auf NixOS liegt nodejs bereits system-weit
  # (common/programs.nix); auf darwin verwaltet Nix kein nodejs — hier fuer
  # den Home-User nachziehen.
  home.packages = lib.optionals pkgs.stdenv.isDarwin [ pkgs.nodejs ];
}
