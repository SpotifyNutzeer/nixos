{ pkgs, ... }:
{
  programs.brave = {
    enable = true;
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "clngdbkpkpeebahjckkjfobafhncgmne"; } # Stylus
      { id = "lppmekppnliemjclknbagdhoocikieoi"; } # 7TV
      { id = "gebbhagfogifgggkldgodflihgfeippi"; } # Return Youtube Dislike
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock for Youtube
      { id = "bkkmolkhemgaeaeggcmfbghljjjoofoh"; } # Catppuccin Mocha Theme
    ];
  };
}
