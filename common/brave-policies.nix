{ ... }:
{
  environment.etc."brave/policies/managed/paul.json".text = builtins.toJSON {
    BraveRewardsDisabled = true;
    BraveWalletDisabled  = true;
    BraveVPNDisabled     = true;
    BraveAIChatEnabled   = false;
    BraveNewsDisabled    = true;

    DefaultSearchProviderEnabled    = true;
    DefaultSearchProviderName       = "Google";
    DefaultSearchProviderSearchURL  = "https://google.com/search?q={searchTerms}";
    DefaultSearchProviderSuggestURL = "https://google.com/complete/search?output=chrome&q={searchTerms}";

    # New tab -> Google
    NewTabPageLocation = "https://google.com";

    # Point Bitwarden at your self-hosted instance
    "3rdparty".extensions."nngceckbapebfimnlniiiahkandclblb".environment.base =
      "https://webvault.paul.wtf";
  };
}
