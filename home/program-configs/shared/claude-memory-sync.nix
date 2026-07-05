{ config, lib, pkgs, ... }:

let
  # ── Kanonischer Store ────────────────────────────────────────────────────
  # Ein Git-Checkout, den alle Geraete teilen. Die datei-basierten Memories
  # sind winzige Markdown-Dateien; der Store haelt einen Ordner pro Projekt.
  repoUrl = "git@github.com:SpotifyNutzeer/claude-memory.git";
  store   = "${config.home.homeDirectory}/claude-memory";

  # ── Projekte ─────────────────────────────────────────────────────────────
  # Logische Projekte == Store-Ordnernamen.
  projectNames = [ "fluxcd" "nixos" "bernice-portfolio" ];

  # Kandidaten-Elternverzeichnisse. Die Repos liegen je nach Rechner woanders
  # (macOS: ~/fleet, NixOS: ~/git). Aus dem Projekt-Arbeitsverzeichnis leitet
  # Claude Code den Projekt-Key ab (jeder "/" wird zu "-") — und der divergiert
  # damit pro Rechner. Statt den Key hart zu kodieren, sucht das Activation-
  # Script pro Projekt den ERSTEN existierenden Pfad und berechnet den Key
  # daraus. So passt sich das Modul jedem Rechner selbst an, und es werden nur
  # Symlinks fuer tatsaechlich ausgecheckte Projekte angelegt.
  projectBases = [
    "${config.home.homeDirectory}/fleet"
    "${config.home.homeDirectory}/git"
  ];

  basesSh = lib.concatStringsSep " " (map lib.escapeShellArg projectBases);

  # Pro Projekt: alle Basis-Verzeichnisse durchgehen; existiert eines, Key aus
  # dem echten Pfad ableiten (/home/paul/git/nixos -> -home-paul-git-nixos) und
  # den memory-Ordner durch einen Symlink auf den Store ersetzen. Ein echter
  # vorhandener Ordner wird vorher gesichert, damit nichts verloren geht.
  linkLines = lib.concatStringsSep "\n" (map (name: ''
    for base in ${basesSh}; do
      proj="$base/${name}"
      [ -d "$proj" ] || continue
      key="$(echo "$proj" | ${pkgs.gnused}/bin/sed 's:/:-:g')"
      mem="${config.home.homeDirectory}/.claude/projects/$key/memory"
      run mkdir -p "${config.home.homeDirectory}/.claude/projects/$key"
      if [ -e "$mem" ] && [ ! -L "$mem" ]; then
        run mv "$mem" "$mem.pre-sync-backup-$(${pkgs.coreutils}/bin/date +%s)"
      fi
      run ln -sfn "${store}/${name}" "$mem"
    done
  '') projectNames);

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

    # Beim Sessionende lokale Aenderungen zurueckspielen (nur bei Aenderung,
    # race-sicher via pull --rebase vor push, || true gegen Session-Blockade).
    Stop = [{
      hooks = [{
        type = "command";
        command = "${pkgs.git}/bin/git -C ${store} add -A && ${pkgs.git}/bin/git -C ${store} diff --cached --quiet || (${pkgs.git}/bin/git -C ${store} commit -qm 'sync: memory update' && ${pkgs.git}/bin/git -C ${store} pull --rebase --autostash && ${pkgs.git}/bin/git -C ${store} push) || true";
      }];
    }];
  };
}
