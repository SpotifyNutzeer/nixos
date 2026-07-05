{ ... }:
{
  # Homebrew-Casks deklarativ via nix-darwin. Setzt voraus, dass Homebrew
  # installiert ist (ist es, /opt/homebrew). Verwaltet werden NUR die hier
  # gelisteten Pakete.
  homebrew = {
    enable = true;

    # WICHTIG: additiv verwalten. cleanup="none" laesst manuell installierte
    # brew-Formeln/Casks in Ruhe. "uninstall"/"zap" wuerde alles Undeklarierte
    # entfernen — hier bewusst NICHT gewollt.
    onActivation.cleanup = "none";

    casks = [
      # Brave Origin: bezahlte, minimalistische Brave-Variante (ohne Leo/Wallet/
      # Rewards/Tor/VPN). In nixpkgs (noch) nicht verfuegbar, daher auf macOS via
      # Cask statt programs.brave. Linux nutzt weiterhin normales brave.
      "brave-origin"
    ];
  };
}
