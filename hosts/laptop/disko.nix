# Deklaratives Partitionslayout fuer nixos-anywhere/disko.
# ESP + LUKS-Container, darin LVM: 20G Swap (Hibernate) + btrfs-Root.
# passwordFile wird nur beim Formatieren gelesen (nixos-anywhere
# --disk-encryption-keys /tmp/luks-password <lokale Datei>).
{ ... }:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/tmp/luks-password";
              settings.allowDiscards = true;   # TRIM auf NVMe durchreichen
              content = {
                type = "lvm_pv";
                vg = "vg0";
              };
            };
          };
        };
      };
    };
    lvm_vg.vg0 = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "20G";   # > 16G RAM, damit das Hibernate-Image sicher passt
          content = { type = "swap"; };
        };
        root = {
          size = "100%FREE";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = { mountpoint = "/";     mountOptions = [ "compress=zstd" ]; };
              "/home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" ]; };
              "/nix"  = { mountpoint = "/nix";  mountOptions = [ "compress=zstd" "noatime" ]; };
            };
          };
        };
      };
    };
  };
}
