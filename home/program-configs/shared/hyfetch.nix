{ ... }: 
{
  programs.hyfetch = {
    enable = true;
    settings = {
      preset = "gay-men";
      mode = "rgb";
      auto_detect_light_dark = true;
      light_dark = "dark";
      lightness = 0.65;
      color_align.mode = "horizontal";
      backend = "fastfetch";
      pride_month_disable = false;
    };
  };
}
