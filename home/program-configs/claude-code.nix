{ ... }:
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

      # ── tmux ─────────────────────────────────────────────────────────
      # Agent-Teams laufen im tmux-Split-Pane-Modus: jeder Teammate bekommt
      # einen eigenen Pane. "tmux" erzwingt das (Alternative: "auto" = nur
      # falls tmux/iTerm2 vorhanden). Braucht das experimentelle Feature-Flag.
      teammateMode = "tmux";

      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
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
      };
    };
  };
}
