# MacBook NixOS-Parität — Phase 1 (MVP) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein lauffähiges macOS-Setup (M4 Pro) mit AeroSpace-Tiling + geteiltem home-manager-Stack, verwaltet aus demselben Flake wie das NixOS-Setup — ohne die bestehenden NixOS-Konfigurationen zu brechen.

**Architecture:** Die flachen `home/program-configs/*.nix` werden nach Plattform in `shared/`, `linux/`, `darwin/` aufgeteilt. `home.nix` wird zu `home-shared.nix` (portabel) plus `home-linux.nix` und `home-darwin.nix`. Das Flake bekommt einen `darwinConfigurations.macbook`-Output (nix-darwin), der home-manager als darwin-Modul einhängt. AeroSpace wird als home-manager-Modul (`programs.aerospace`) mit den Hyprland-Keybinds (Alt-Modifier) konfiguriert.

**Tech Stack:** Nix Flakes, nix-darwin, home-manager, AeroSpace, catppuccin/nix, kitty.

## Global Constraints

- nixpkgs = `github:NixOS/nixpkgs/nixos-unstable`; `home-manager` folgt nixpkgs (bestehend).
- Theme: Catppuccin **Mocha**, Accent **teal**. Border-Farben verbatim: `$sky = rgb(89dceb)`, `$teal = rgb(94e2d5)`.
- WM-Modifier auf macOS = **Alt (⌥)**.
- macOS-Ziel: `aarch64-darwin`, Benutzer **`paulweber`**, Home **`/Users/paulweber`**.
- NixOS-Ziel (unverändert): Benutzer **`paul`**, Home **`/home/paul`**.
- **Nach jeder Task müssen `nixosConfigurations.{desktop,laptop,vm}` weiterhin evaluieren.**
- **Scope = MVP.** Kein SketchyBar, kein JankyBorders, kein Sol/Ueli, kein Scratchpad — die sind Phase 2.
- Verifikation läuft auf dem Mac. Voller NixOS-*Build* braucht eine Linux-Maschine/CI; hier wird NixOS per `nix eval` auf Evaluierbarkeit geprüft (fängt Refactor-Fehler ab, nicht 100% der Build-Fehler — das ist eine bewusste Grenze).

## Prerequisites (einmalig, vor Task 1 prüfen)

- [ ] **Auf dem Mac arbeiten & Nix mit Flakes vorhanden:**
  Run: `whoami && nix --version && echo 'experimental-features = nix-command flakes' | grep -q . && nix flake metadata --json >/dev/null 2>&1 && echo OK`
  Erwartet: `whoami` gibt `paulweber` aus (falls abweichend: den Wert überall in diesem Plan durch den echten Benutzernamen ersetzen); `nix --version` ≥ 2.18; kein Fehler beim `nix flake metadata`.
  Falls Nix fehlt: zuerst Nix installieren (Determinate Systems Installer oder offizieller Installer), dann fortfahren.

## File Structure (Zielzustand nach Phase 1)

```
flake.nix                                  # + nix-darwin input, darwinConfigurations.macbook
home/
  home-shared.nix                          # NEU: importiert alle shared-Module + home.stateVersion
  home-linux.nix                           # NEU: home-shared + linux-Module + user paul / /home/paul
  home-darwin.nix                          # NEU: home-shared + darwin-Module + user paulweber / /Users/paulweber
  program-configs/
    shared/                                # NEU
      starship.nix fish.nix vim.nix kitty.nix alacritty.nix tmux.nix
      hyfetch.nix claude-code.nix theming.nix ssh.nix
    linux/                                  # NEU
      hyprland.nix hyprlock.nix quickshell.nix rofi.nix xdg-mime.nix
      vencord.nix brave.nix theming.nix ssh.nix
    darwin/                                 # NEU
      aerospace.nix ssh.nix
hosts/
  macbook/
    default.nix                            # NEU: nix-darwin host (hostPlatform, defaults, hostname)
```

`home/home.nix` wird entfernt (durch `home-linux.nix` ersetzt).

---

### Task 1: Platform-Split der home-manager-Module (NixOS bleibt intakt)

Reine Reorganisation + Aufteilung von `theming.nix`/`ssh.nix`. Keine Verhaltensänderung für NixOS.

**Files:**
- Create: `home/program-configs/shared/` (Verzeichnis), `home/program-configs/linux/`, `home/program-configs/darwin/`
- Move: 8 portable Module → `shared/`, 5 linux-Module + `brave.nix` → `linux/`
- Create: `home/program-configs/shared/theming.nix`, `home/program-configs/linux/theming.nix` (Split)
- Create: `home/program-configs/shared/ssh.nix`, `home/program-configs/linux/ssh.nix` (Split)
- Create: `home/home-shared.nix`, `home/home-linux.nix`
- Delete: `home/home.nix`, `home/program-configs/theming.nix`, `home/program-configs/ssh.nix`
- Modify: `flake.nix` (nixos mkHost importiert `home-linux.nix`)

**Interfaces:**
- Produces: `home/home-shared.nix` (importiert alle `shared/`-Module, setzt `home.stateVersion = "26.05"`; setzt **nicht** username/homeDirectory). `home/home-linux.nix` (importiert `home-shared.nix` + alle `linux/`-Module, setzt `home.username = "paul"`, `home.homeDirectory = "/home/paul"`).

- [ ] **Step 1: Baseline festhalten — NixOS evaluiert aktuell**

Run: `nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath`
Expected: Ein `/nix/store/*.drv`-Pfad wird ausgegeben (kein Eval-Fehler). Dies ist der Referenzzustand.

- [ ] **Step 2: Verzeichnisse anlegen und portable Module verschieben**

```bash
cd /Users/paulweber/fleet/nixos
mkdir -p home/program-configs/shared home/program-configs/linux home/program-configs/darwin
git mv home/program-configs/starship.nix    home/program-configs/shared/
git mv home/program-configs/fish.nix        home/program-configs/shared/
git mv home/program-configs/vim.nix         home/program-configs/shared/
git mv home/program-configs/kitty.nix       home/program-configs/shared/
git mv home/program-configs/alacritty.nix   home/program-configs/shared/
git mv home/program-configs/tmux.nix        home/program-configs/shared/
git mv home/program-configs/hyfetch.nix     home/program-configs/shared/
git mv home/program-configs/claude-code.nix home/program-configs/shared/
```

- [ ] **Step 3: Linux-only-Module verschieben (inkl. brave)**

```bash
git mv home/program-configs/hyprland.nix  home/program-configs/linux/
git mv home/program-configs/hyprlock.nix  home/program-configs/linux/
git mv home/program-configs/quickshell.nix home/program-configs/linux/
git mv home/program-configs/rofi.nix      home/program-configs/linux/
git mv home/program-configs/xdg-mime.nix  home/program-configs/linux/
git mv home/program-configs/vencord.nix   home/program-configs/linux/
git mv home/program-configs/brave.nix     home/program-configs/linux/
```

- [ ] **Step 4: `theming.nix` aufteilen — shared-Basis erzeugen**

Create `home/program-configs/shared/theming.nix` (nur die plattformunabhängige Catppuccin-Basis, die kitty/fish/starship/tmux/bat/vim themt):

```nix
{ catppuccin, ... }:
{
  imports = [ catppuccin.homeModules.catppuccin ];

  # Plattformunabhaengige Catppuccin-Basis: themt via autoEnable alle aktivierten
  # CLI-/TUI-Programme (kitty, fish, starship, tmux, bat, vim). GTK/Qt/Kvantum/Cursor
  # sind Linux-Konzepte und liegen in linux/theming.nix.
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    accent = "teal";
  };
}
```

- [ ] **Step 5: `theming.nix` aufteilen — linux-Teil erzeugen**

Create `home/program-configs/linux/theming.nix` (der GTK/Qt/Kvantum/Cursor-Teil aus der alten Datei):

```nix
{ pkgs, ... }:
{
  # Ergaenzt die shared Catppuccin-Basis um Linux-spezifisches Theming.
  catppuccin = {
    cursors.enable = true;
    hyprland.enable = false;
    # hyprlock wird manuell in linux/hyprlock.nix gethemet.
    hyprlock.enable = false;

    # Catppuccin-eingefaerbte Papirus-Icons (setzt gtk.iconTheme).
    gtk.icon.enable = true;

    # Qt-Theme via Kvantum.
    kvantum.enable = true;
  };

  # Qt-Apps (z.B. Prism Launcher) ueber Kvantum + qt6ct themen.
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "kvantum";
      package = pkgs.kdePackages.qtstyleplugin-kvantum;
    };
  };

  # GTK-Widget-Theme (Fensterfarben/Buttons).
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-teal-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "teal" ];
        variant = "mocha";
      };
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    size = 24;
  };
}
```

- [ ] **Step 6: alte `theming.nix` entfernen**

```bash
git rm home/program-configs/theming.nix
```

- [ ] **Step 7: `ssh.nix` aufteilen — shared-Teil (nur `programs.ssh`-Settings)**

Create `home/program-configs/shared/ssh.nix`:

```nix
{ ... }:
{
  programs.ssh = {
    enable = true;
    # eigene Defaults statt der (deprecateten) home-manager-Vorgaben
    enableDefaultConfig = false;

    settings = {
      # Keys beim ersten Benutzen automatisch in den Agent laden.
      "*".AddKeysToAgent = "yes";

      # github: immer diesen Key nehmen
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };
}
```

- [ ] **Step 8: `ssh.nix` aufteilen — linux-Teil (systemd + gnome-keyring)**

Create `home/program-configs/linux/ssh.nix`:

```nix
{ pkgs, ... }:
let
  # Askpass-Helfer: liest die Key-Passphrase aus dem gnome-keyring.
  keyringAskpass = pkgs.writeShellScript "ssh-askpass-keyring" ''
    exec ${pkgs.libsecret}/bin/secret-tool lookup ssh id_ed25519
  '';
in
{
  # secret-tool zum einmaligen Ablegen/Auslesen der Passphrase
  home.packages = [ pkgs.libsecret ];

  # Persistenter OpenSSH-Agent als systemd-User-Service.
  services.ssh-agent.enable = true;

  # Laedt den Key beim Login automatisch in den Agent (Passphrase aus gnome-keyring).
  # EINMALIG nach dem ersten Rebuild ausfuehren (fragt nach der Passphrase):
  #   secret-tool store --label='ssh id_ed25519 passphrase' ssh id_ed25519
  systemd.user.services.ssh-add-key = {
    Unit = {
      Description = "SSH-Key mit Passphrase aus gnome-keyring in den Agent laden";
      After = [ "ssh-agent.service" "graphical-session.target" ];
      Requires = [ "ssh-agent.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "SSH_AUTH_SOCK=%t/ssh-agent"
        "SSH_ASKPASS=${keyringAskpass}"
        "SSH_ASKPASS_REQUIRE=force"
      ];
      ExecStart = "${pkgs.openssh}/bin/ssh-add %h/.ssh/id_ed25519";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
```

- [ ] **Step 9: alte `ssh.nix` entfernen**

```bash
git rm home/program-configs/ssh.nix
```

- [ ] **Step 10: `home-shared.nix` erzeugen**

Create `home/home-shared.nix`:

```nix
{ ... }:
{
  imports = [
    ./program-configs/shared/starship.nix
    ./program-configs/shared/fish.nix
    ./program-configs/shared/vim.nix
    ./program-configs/shared/kitty.nix
    ./program-configs/shared/alacritty.nix
    ./program-configs/shared/tmux.nix
    ./program-configs/shared/hyfetch.nix
    ./program-configs/shared/claude-code.nix
    ./program-configs/shared/theming.nix
    ./program-configs/shared/ssh.nix
  ];

  home.stateVersion = "26.05";
}
```

- [ ] **Step 11: `home-linux.nix` erzeugen**

Create `home/home-linux.nix`:

```nix
{ ... }:
{
  imports = [
    ./home-shared.nix
    ./program-configs/linux/hyprland.nix
    ./program-configs/linux/quickshell.nix
    ./program-configs/linux/hyprlock.nix
    ./program-configs/linux/vencord.nix
    ./program-configs/linux/brave.nix
    ./program-configs/linux/theming.nix
    ./program-configs/linux/rofi.nix
    ./program-configs/linux/xdg-mime.nix
    ./program-configs/linux/ssh.nix
  ];

  home.username = "paul";
  home.homeDirectory = "/home/paul";
}
```

- [ ] **Step 12: alte `home.nix` entfernen**

```bash
git rm home/home.nix
```

- [ ] **Step 13: flake.nix — nixos mkHost auf `home-linux.nix` umstellen**

In `flake.nix`, im `mkHost`-Block, diese Zeile:

```nix
          home-manager.users.paul = import ./home/home.nix;
```

ersetzen durch:

```nix
          home-manager.users.paul = import ./home/home-linux.nix;
```

- [ ] **Step 14: NixOS-Evaluierung verifizieren (alle drei Hosts)**

Run:
```bash
nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.vm.config.system.build.toplevel.drvPath
```
Expected: Jeder Befehl gibt einen `/nix/store/*.drv`-Pfad aus, kein Fehler. Damit ist der Split für NixOS verhaltensneutral.

- [ ] **Step 15: Commit**

```bash
git add -A
git commit -m "refactor: split home-manager modules into shared/linux/darwin

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: nix-darwin-Gerüst — `darwinConfigurations.macbook` baut

**Files:**
- Modify: `flake.nix` (nix-darwin-Input + `mkDarwin` + `darwinConfigurations.macbook`)
- Create: `hosts/macbook/default.nix`
- Create: `home/home-darwin.nix`

**Interfaces:**
- Consumes: `home/home-shared.nix` (aus Task 1).
- Produces: `home/home-darwin.nix` (importiert `home-shared.nix`, setzt `home.username = "paulweber"`, `home.homeDirectory = "/Users/paulweber"`). Flake-Output `darwinConfigurations.macbook.system`.

- [ ] **Step 1: nix-darwin als Input hinzufügen**

In `flake.nix`, im `inputs`-Block nach dem `home-manager`-Input einfügen:

```nix
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: `nix-darwin` in die Output-Argumente aufnehmen**

In `flake.nix` die `outputs`-Zeile:

```nix
  outputs = { self, nixpkgs, home-manager, disko, dotfiles, rodecaster-tidal-bridge, streamcontroller-tidal, tidaluna, nixcord, catppuccin, gsr-ui-nix, ... }:
```

ergänzen um `nix-darwin` (vor dem `... }:`):

```nix
  outputs = { self, nixpkgs, home-manager, nix-darwin, disko, dotfiles, rodecaster-tidal-bridge, streamcontroller-tidal, tidaluna, nixcord, catppuccin, gsr-ui-nix, ... }:
```

- [ ] **Step 3: `home-darwin.nix` erzeugen (vorerst nur shared)**

Create `home/home-darwin.nix`:

```nix
{ ... }:
{
  imports = [
    ./home-shared.nix
  ];

  home.username = "paulweber";
  home.homeDirectory = "/Users/paulweber";
}
```

- [ ] **Step 4: nix-darwin-Host anlegen**

Create `hosts/macbook/default.nix`:

```nix
{ ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "paul-macbook";

  # nix-darwin verlangt fuer user-bezogene Optionen (homebrew, defaults) einen Primaeruser.
  system.primaryUser = "paulweber";
  users.users.paulweber.home = "/Users/paulweber";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Systemweit Dark Mode.
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";

  # nix-darwin-Schema-Version. Falls darwin-rebuild einen anderen Wert erwartet,
  # meldet es das explizit — dann hier anpassen.
  system.stateVersion = 5;
}
```

- [ ] **Step 5: `mkDarwin` + Output ergänzen**

In `flake.nix`, im `let`-Block nach der `mkHost`-Definition einfügen:

```nix
    mkDarwin = host: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit catppuccin; };
      modules = [
        ./hosts/${host}
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit catppuccin; };
          home-manager.users.paulweber = import ./home/home-darwin.nix;
        }
      ];
    };
```

Und im `in { ... }`-Block nach dem `nixosConfigurations`-Block ergänzen:

```nix
    darwinConfigurations = {
      macbook = mkDarwin "macbook";
    };
```

- [ ] **Step 6: darwin-System bauen**

Run: `nix build .#darwinConfigurations.macbook.system --no-link --print-out-paths`
Expected: Ein `/nix/store/*-darwin-system-*`-Pfad wird ausgegeben, kein Eval-/Build-Fehler.
Falls Fehler wie „catppuccin.cursors …" auf darwin: in `home/home-darwin.nix` `catppuccin.cursors.enable = false;` ergänzen. Falls `system.stateVersion`-Warnung: den gemeldeten Wert in `hosts/macbook/default.nix` eintragen.

- [ ] **Step 7: NixOS-Eval erneut prüfen (Regression)**

Run: `nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath`
Expected: `/nix/store/*.drv`-Pfad, kein Fehler.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add nix-darwin darwinConfigurations.macbook skeleton

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: kitty-Blur auf macOS

**Files:**
- Modify: `home/program-configs/shared/kitty.nix`

**Interfaces:**
- Consumes: `programs.kitty.settings` (bestehend).

- [ ] **Step 1: Blur-Settings ergänzen**

In `home/program-configs/shared/kitty.nix` den `settings`-Block anpassen — `background_opacity` ändern und `background_blur` hinzufügen:

```nix
        font_size        = 11;

        background_opacity = 0.90;
        # Auf macOS rendert kitty den Blur selbst (native API), unabhaengig vom
        # Compositor. Der Wert ist dort zugleich der Blur-Radius; bis ~64 unkritisch.
        # Unter Hyprland uebernimmt den Blur der Compositor — dieselbe Zeile schadet nicht.
        background_blur    = 32;

        cursor_trail = 3;
```

- [ ] **Step 2: darwin-Build verifizieren**

Run: `nix build .#darwinConfigurations.macbook.system --no-link --print-out-paths`
Expected: `/nix/store/*-darwin-system-*`-Pfad, kein Fehler.

- [ ] **Step 3: NixOS-Eval prüfen (Regression)**

Run: `nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath`
Expected: `/nix/store/*.drv`-Pfad, kein Fehler.

- [ ] **Step 4: Commit**

```bash
git add home/program-configs/shared/kitty.nix
git commit -m "feat: kitty background blur (works natively on macOS)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: macOS-SSH-Variante (Keychain)

**Files:**
- Create: `home/program-configs/darwin/ssh.nix`
- Modify: `home/home-darwin.nix`

**Interfaces:**
- Consumes: `home/program-configs/shared/ssh.nix` (`programs.ssh.settings`, aus Task 1). home-manager merged die `settings`-Attrsets beider Module.
- Produces: `home/program-configs/darwin/ssh.nix`.

- [ ] **Step 1: darwin-SSH-Modul erzeugen**

Create `home/program-configs/darwin/ssh.nix`:

```nix
{ ... }:
{
  # macOS hat einen system-eigenen ssh-agent (kein systemd noetig). UseKeychain
  # laedt die Passphrase aus der macOS-Keychain; zusammen mit AddKeysToAgent (shared)
  # wird der Key einmalig entsperrt und danach nicht mehr abgefragt.
  programs.ssh.settings."*".UseKeychain = "yes";
}
```

- [ ] **Step 2: in home-darwin importieren**

In `home/home-darwin.nix` den `imports`-Block ergänzen:

```nix
  imports = [
    ./home-shared.nix
    ./program-configs/darwin/ssh.nix
  ];
```

- [ ] **Step 3: darwin-Build verifizieren**

Run: `nix build .#darwinConfigurations.macbook.system --no-link --print-out-paths`
Expected: `/nix/store/*-darwin-system-*`-Pfad, kein Fehler.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: macOS ssh keychain integration

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: AeroSpace-Modul (Tiling-WM mit Hyprland-Keybinds)

**Files:**
- Create: `home/program-configs/darwin/aerospace.nix`
- Modify: `home/home-darwin.nix`

**Interfaces:**
- Produces: `home/program-configs/darwin/aerospace.nix` (`programs.aerospace` mit `launchd.enable = true`).

- [ ] **Step 1: AeroSpace-Modul erzeugen**

Create `home/program-configs/darwin/aerospace.nix`:

```nix
{ ... }:
{
  programs.aerospace = {
    enable = true;
    # home-manager verwaltet den launchd-Autostart (kein manuelles start-at-login).
    launchd.enable = true;

    userSettings = {
      # Kein eigenes Login-Item — macht launchd (s.o.).
      start-at-login = false;

      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      # Gaps analog Hyprland (gaps_in=5, gaps_out=10).
      gaps = {
        inner.horizontal = 5;
        inner.vertical = 5;
        outer.left = 10;
        outer.right = 10;
        outer.top = 10;
        outer.bottom = 10;
      };

      # Modifier = Alt (⌥), 1:1 zu den SUPER-Bindings unter Hyprland.
      mode.main.binding = {
        # Programme / Fenster
        alt-enter = "exec-and-forget open -na kitty";
        alt-shift-q = "close";
        alt-f = "fullscreen";
        alt-v = "layout floating tiling";
        alt-j = "layout tiles horizontal vertical";
        alt-e = "exec-and-forget open -a Finder";

        # Launcher (MVP: Raycast per URL-Scheme; Phase 2 -> Sol/Ueli)
        alt-shift-enter = "exec-and-forget open raycast://";

        # Fokus bewegen
        alt-left = "focus left";
        alt-right = "focus right";
        alt-up = "focus up";
        alt-down = "focus down";

        # Workspaces wechseln (1..10)
        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        # Fenster in Workspace verschieben (1..10)
        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";
      };
    };
  };
}
```

- [ ] **Step 2: in home-darwin importieren**

In `home/home-darwin.nix` den `imports`-Block ergänzen (jetzt vollständig):

```nix
  imports = [
    ./home-shared.nix
    ./program-configs/darwin/ssh.nix
    ./program-configs/darwin/aerospace.nix
  ];
```

- [ ] **Step 3: darwin-Build verifizieren**

Run: `nix build .#darwinConfigurations.macbook.system --no-link --print-out-paths`
Expected: `/nix/store/*-darwin-system-*`-Pfad, kein Fehler. Falls die AeroSpace-Optionsnamen abweichen (z.B. `userSettings` vs. `settings`), meldet der Build den unbekannten Optionspfad — dann laut Fehlermeldung korrigieren.

- [ ] **Step 4: NixOS-Eval prüfen (Regression)**

Run: `nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath`
Expected: `/nix/store/*.drv`-Pfad, kein Fehler.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: aerospace tiling WM with Hyprland keybinds (alt modifier)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Erst-Aktivierung + MVP-Validierung

Der einzige Task, der das System real aktiviert (nicht nur baut) und manuelle macOS-Schritte enthält.

**Files:**
- Create: `hosts/macbook/README.md` (manuelle Schritte dokumentiert)

- [ ] **Step 1: Erstmalige Aktivierung (Bootstrap, da `darwin-rebuild` noch nicht im PATH)**

Run: `sudo nix run nix-darwin -- switch --flake .#macbook`
Expected: nix-darwin aktiviert die Konfiguration; am Ende steht sinngemäß „setting up user launchd services" ohne Fehler. Ab jetzt existiert `darwin-rebuild`.

- [ ] **Step 2: AeroSpace-Berechtigung erteilen (manuell, einmalig)**

AeroSpace startet über launchd. macOS fragt nach der **Accessibility**-Berechtigung:
Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen → **AeroSpace** aktivieren.
Danach: `aerospace reload-config` (oder ab-/anmelden).
Expected: Fenster werden gekachelt; `alt-1..0` wechselt Workspaces.

- [ ] **Step 3: Keybinds manuell prüfen**

Prüfen (Erwartung in Klammern):
- `alt-enter` (kitty öffnet) · `alt-shift-q` (Fenster schließt) · `alt-f` (Fullscreen)
- `alt-1` / `alt-2` (Workspace-Wechsel) · `alt-shift-2` (aktives Fenster nach WS 2)
- `alt-←/→/↑/↓` (Fokuswechsel) · `alt-v` (floating toggle)
- `alt-shift-enter` (Raycast erscheint)

- [ ] **Step 4: kitty-Blur + Dark Mode + Theme visuell prüfen**

- kitty öffnen: Hintergrund transparent + geblurrt (wie unter Hyprland).
- Systemweit Dark Mode aktiv.
- kitty/fish/starship/tmux im Catppuccin-Mocha-Look (teal Akzent).

- [ ] **Step 5: NixOS-Eval final prüfen (Regression)**

Run:
```bash
nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
nix eval --raw .#nixosConfigurations.vm.config.system.build.toplevel.drvPath
```
Expected: alle drei geben `/nix/store/*.drv` aus.

- [ ] **Step 6: Manuelle Schritte dokumentieren**

Create `hosts/macbook/README.md`:

```markdown
# macbook (nix-darwin)

## Erst-Setup
1. `sudo nix run nix-darwin -- switch --flake .#macbook`
2. Bedienungshilfen-Berechtigung für **AeroSpace** erteilen
   (Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen).
3. Danach normal: `darwin-rebuild switch --flake .#macbook`

## Manuelle / nicht-deklarative Punkte
- AeroSpace-Accessibility-Berechtigung (einmalig, macOS-Sicherheit).
- Launcher: im MVP Raycast (Hotkey `alt-shift-enter` via AeroSpace). Phase 2: Sol/Ueli.
- Brave & GUI-Casks: Phase 2 via homebrew.

## Phase 2 (offen)
SketchyBar (Notch-Layout), JankyBorders (Sky→Teal), Sol/Ueli-Launcher, Brave via homebrew.
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "docs: macbook host setup + manual steps (Phase 1 MVP complete)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review (vom Plan-Autor durchgeführt)

**Spec-Abdeckung:** Flake-Erweiterung (T2) ✓ · Modul-Split shared/linux/darwin (T1) ✓ · portable Module auf Mac (T1/T2) ✓ · AeroSpace-Keybind-Mapping inkl. Gaps (T5) ✓ · Catppuccin nach shared (T1) ✓ · Raycast-Hotkey `alt-shift-enter` (T5) ✓ · `system.defaults` Dark Mode (T2) ✓ · kitty-Blur (T3) ✓ · Validierung inkl. „NixOS darf nicht brechen" (jede Task) ✓ · manuelle Schritte dokumentiert (T6) ✓.

**Abweichungen von der Spec (bewusst, mit Nutzer abgestimmt):** `ssh.nix` wird gesplittet (Spec listete es pauschal als shared — real Linux-Systemd-Abhängigkeit); `brave.nix` → linux/ (darwin via homebrew in Phase 2); macOS-User ist `paulweber`, nicht `paul`.

**Platzhalter-Scan:** Keine TBD/TODO. Umgebungsabhängige Unbekannte (nix-darwin `stateVersion`, evtl. AeroSpace-Optionsname, catppuccin-cursors auf darwin) sind als explizite „falls Fehler → so korrigieren"-Schritte kodiert, nicht als Platzhalter versteckt.

**Typ-/Namenskonsistenz:** `home-shared.nix` / `home-linux.nix` / `home-darwin.nix`, `darwinConfigurations.macbook`, `programs.aerospace.userSettings`, Benutzer `paul` (Linux) vs. `paulweber` (macOS) über alle Tasks konsistent verwendet.
