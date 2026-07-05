{ config, lib, pkgs, ... }:

let
  # ── Kanonischer Store ────────────────────────────────────────────────────
  # Ein Git-Checkout, den alle Geraete teilen. Die datei-basierten Memories
  # sind winzige Markdown-Dateien; der Store haelt einen Ordner pro Projekt.
  repoUrl = "git@github.com:SpotifyNutzeer/claude-memory.git";
  store   = "${config.home.homeDirectory}/claude-memory";

  # ── Projekt-Mapping ──────────────────────────────────────────────────────
  # repo-Ordner  ->  lokaler Arbeitsverzeichnis-Pfad des Projekts. Aus dem Pfad
  # leitet Claude Code den Projekt-Key ab (jeder "/" wird zu "-"). Der Key
  # divergiert pro Maschine (macOS: /Users/paulweber, NixOS: /home/paul) —
  # deshalb wird er HIER pro Build aus homeDirectory berechnet, statt hart
  # kodiert. So zeigt auf jedem Geraet der richtige maschinenspezifische
  # memory-Ordner auf denselben geteilten Store-Ordner.
  projects = {
    "fluxcd"            = "${config.home.homeDirectory}/fleet/fluxcd";
    "nixos"             = "${config.home.homeDirectory}/fleet/nixos";
    "bernice-portfolio" = "${config.home.homeDirectory}/fleet/bernice-portfolio";
  };

  # "/Users/paulweber/fleet/fluxcd" -> "-Users-paulweber-fleet-fluxcd"
  mkKey = path: lib.replaceStrings [ "/" ] [ "-" ] path;

  projectsRoot = "${config.home.homeDirectory}/.claude/projects";

  # Shell-Zeilen, die pro Projekt den memory-Ordner durch einen Symlink auf
  # den Store ersetzen. Vorhandene echte Ordner werden (falls noch nicht
  # migriert) einmalig gesichert, damit nichts verloren geht.
  linkLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: path:
    let key = mkKey path; in ''
      mem="${projectsRoot}/${key}/memory"
      run mkdir -p "${projectsRoot}/${key}"
      if [ -e "$mem" ] && [ ! -L "$mem" ]; then
        run mv "$mem" "$mem.pre-sync-backup-$(${pkgs.coreutils}/bin/date +%s)"
      fi
      run ln -sfn "${store}/${name}" "$mem"
    '') projects);

in
{
  # git wird zur Aktivierungs- und Hook-Laufzeit gebraucht.
  home.packages = [ pkgs.git ];

  # ── Aktivierung: Store klonen + Symlinks setzen ──────────────────────────
  # Laeuft bei jedem `home-manager switch`. Idempotent: klont den Store beim
  # ersten Mal, danach nur noch pull; setzt/erneuert die Symlinks.
  home.activation.claudeMemorySync =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export PATH="${pkgs.git}/bin:${pkgs.openssh}/bin:$PATH"
      if [ ! -d "${store}/.git" ]; then
        run git clone ${repoUrl} "${store}" || \
          echo "claude-memory: clone fehlgeschlagen (SSH-Key vorhanden?) — Symlinks trotzdem gesetzt"
      else
        run git -C "${store}" pull --rebase --autostash --quiet || true
      fi
      ${linkLines}
    '';

  # ── Sync-Hooks ───────────────────────────────────────────────────────────
  # Werden in ~/.claude/settings.json gemerged (home-manager fasst
  # programs.claude-code.settings ueber Module hinweg zusammen).
  programs.claude-code.settings.hooks = {
    # Beim Sessionstart den neuesten Stand der anderen Geraete holen.
    SessionStart = [{
      hooks = [{
        type = "command";
        command = "${pkgs.git}/bin/git -C ${store} pull --rebase --autostash --quiet || true";
      }];
    }];

    # Beim Sessionende lokale Aenderungen zurueckspielen.
    Stop = [{
      hooks = [{
        type = "command";
        # TODO(human): race-sichere Commit+Push-Logik als eine Shell-Zeile.
        # Verfuegbar: git-Binary unter ${pkgs.git}/bin/git, Store-Pfad ${store}.
        # Anforderungen siehe "Learn by Doing"-Request.
        command = "${pkgs.git}/bin/git -C ${store} add -A && ${pkgs.git}/bin/git -C ${store} diff --cached --quiet || (${pkgs.git}/bin/git -C ${store} commit -qm 'sync: memory update' && ${pkgs.git}/bin/git -C ${store} pull --rebase --autostash && ${pkgs.git}/bin/git -C ${store} push) || true";
      }];
    }];
  };
}
