{ config, ... }:
{
  # CoolerControl: Fan-Control-Daemon (coolercontrold) + GUI (coolercontrol).
  programs.coolercontrol.enable = true;

  # it87: Super-I/O-Sensoren & Lüfter des Gigabyte X870E AORUS PRO (ITE-Chip).
  # Out-of-Tree-Modul, weil das Mainline-it87 neuere ITE-Chips nicht kennt.
  boot.extraModulePackages = [ config.boot.kernelPackages.it87 ];
  boot.kernelModules = [ "it87" ];

  # Gigabyte AM5: ACPI beansprucht meist die Super-I/O-I/O-Region, sonst darf
  # it87 nicht drauf ("Failed to enable I/O"). 'lax' erlaubt den Zugriff trotz
  # ACPI-Reservierung. Falls it87 auch ohne lädt, kann die Zeile wieder weg.
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  # CoolerControl-Config (Lüfterkurven/Profile) aus dem Arch-Setup einmalig seeden.
  # 'C' kopiert nur, wenn die Datei noch nicht existiert -> danach gehört sie dem
  # Daemon (der sie zur Laufzeit selbst schreibt). Reproduzierbar (frische
  # Installation kriegt die Kurven), aber bewusst KEIN read-only-Nix-Symlink.
  systemd.tmpfiles.rules = [
    "d /etc/coolercontrol 0755 root root -"
    "C /etc/coolercontrol/config.toml 0644 root root - ${./coolercontrol/config.toml}"
    "C /etc/coolercontrol/config-ui.json 0644 root root - ${./coolercontrol/config-ui.json}"
  ];

  # Falls it87 den Chip nicht auto-erkennt (dmesg: "no device" / falsche ID),
  # hier den passenden force_id ergänzen, z.B.:
  # boot.extraModprobeConfig = ''
  #   options it87 force_id=0x8689
  # '';
}
