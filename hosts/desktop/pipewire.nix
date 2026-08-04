{ dotfiles, ... }:
{
  xdg.configFile."pipewire/pipewire.conf.d".source =
    "${dotfiles}/.config/pipewire/pipewire.conf.d";

  # Pin Spotify routing to the virtual sink "sink_music_combined"
  # (defined in dotfiles, 99-rodecaster-multichannel.conf).
  #
  # Spotify (Chromium/CEF) registers as a pipewire-pulse client without an
  # application.id. WirePlumber builds its restore key from the first present
  # one of application.id / application.name / media.name / node.name
  # (state-stream.lua:formKey), so the key can collide with other
  # Chromium-based clients: they overwrite each other, which is why the sink
  # set in pavucontrol gets lost after every restart.
  #
  # update-props sets target.object as a REAL node property (only pulse.rules
  # can do that for client streams; stream.rules only changes a local copy in
  # the restore hook). WirePlumber linking prefers this property, and the
  # restore no longer overwrites it (state-stream.lua, fix #335).
  #
  # The binary is matched as a regex ("~" prefix): spicetify wraps Spotify via
  # wrapProgramShell, so the running process can be ".spotify-wrapped" rather
  # than plain "spotify". Verify with `pactl list clients | grep -i binary`.
  xdg.configFile."pipewire/pipewire-pulse.conf.d/50-spotify-target.conf".text = ''
    pulse.rules = [
      {
        matches = [ { application.process.binary = "~.*[Ss]potify.*" } ]
        actions = { update-props = { target.object = "sink_music_combined" } }
      }
    ]
  '';
}
