{ ... }:
{
  homebrew = {
    enable = true;

    onActivation.cleanup = "none";

    casks = [
      "brave-origin"
      "vorssaint"
    ];
  };
}
