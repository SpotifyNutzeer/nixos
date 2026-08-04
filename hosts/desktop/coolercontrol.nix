{ config, ... }:
{
  # CoolerControl: fan control daemon (coolercontrold) + GUI (coolercontrol).
  programs.coolercontrol.enable = true;

  # it87: Super-I/O sensors & fans of the Gigabyte X870E AORUS PRO (ITE chip).
  # Out-of-tree module, because the mainline it87 does not know newer ITE chips.
  boot.extraModulePackages = [ config.boot.kernelPackages.it87 ];
  boot.kernelModules = [ "it87" ];

  # Gigabyte AM5: ACPI usually claims the Super-I/O I/O region, otherwise it87
  # is not allowed to access it ("Failed to enable I/O"). 'lax' permits access
  # despite the ACPI reservation. If it87 also loads without it, this line can
  # be removed again.
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  # Seed the CoolerControl config (fan curves/profiles) from the Arch setup once.
  # 'C' only copies if the file does not exist yet -> after that it belongs to
  # the daemon (which writes it itself at runtime). Reproducible (a fresh
  # installation gets the curves), but deliberately NOT a read-only Nix symlink.
  systemd.tmpfiles.rules = [
    "d /etc/coolercontrol 0755 root root -"
    "C /etc/coolercontrol/config.toml 0644 root root - ${./coolercontrol/config.toml}"
    "C /etc/coolercontrol/config-ui.json 0644 root root - ${./coolercontrol/config-ui.json}"
  ];

  # If it87 does not auto-detect the chip (dmesg: "no device" / wrong ID),
  # add the matching force_id here, e.g.:
  # boot.extraModprobeConfig = ''
  #   options it87 force_id=0x8689
  # '';
}
