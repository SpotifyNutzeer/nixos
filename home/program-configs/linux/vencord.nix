{ nixcord, ... }:
{
  imports = [ nixcord.homeModules.nixcord ];
  programs.nixcord = {
    enable = true;

    discord.vencord.enable = true;

    # Screensharing/Go-Live: Discord lief bisher unter XWayland und nutzte damit
    # X11-Screencapture statt des Wayland-PipeWire-Portals -> xdg-desktop-portal
    # (hyprland-share-picker) wurde nie aufgerufen, es erschien keine Auswahl.
    # Native Wayland + PipeWire-Capturer erzwingen, damit getDisplayMedia ueber
    # das Portal geht und die Quellen-Auswahl erscheint.
    discord.commandLineArgs = [
      "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
      "--ozone-platform=wayland"
    ];

    # Theming
    config = {
      useQuickCss = true;
      themeLinks = [
        "https://catppuccin.github.io/discord/dist/catppuccin-mocha-teal.theme.css"
      ];
      frameless = false;

      plugins = {
        betterRoleDot.enable = true;
        betterSessions.enable = true;
        betterSettings.enable = true;
        betterUploadButton.enable = true;
        biggerStreamPreview.enable = true;
        callTimer.enable = true;
        characterCounter.enable = true;
        clearUrls.enable = true;
        copyFileContents.enable = true;
        copyUserUrls.enable = true;
        crashHandler.enable = true;
        dearrow.enable = true;
        experiments.enable = true;
        expressionCloner.enable = true;
        fixCodeblockGap.enable = true;
        fixImagesQuality.enable = true;
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        loadingQuotes.enable = true;
        memberCount.enable = true;
        mentionAvatars.enable = true;
        messageLinkEmbeds.enable = true;
        messageLogger.enable = true;
        noMosaic.enable = true;
        onePingPerDm.enable = true;
        oneko.enable = true;
        openInApp.enable = true;
        permissionFreeWill.enable = true;
        permissionsViewer.enable = true;
        petpet.enable = true;
        platformIndicators.enable = true;
        previewMessage.enable = true;
        relationshipNotifier.enable = true;
        roleColorEverywhere.enable = true;
        serverInfo.enable = true;
        shikiCodeblocks.enable = true;
        showConnections.enable = true;
        showHiddenChannels.enable = true;
        showHiddenThings.enable = true;
        showMeYourName.enable = true;
        silentMessageToggle.enable = true;
        translate.enable = true;
        typingIndicator.enable = true;
        typingTweaks.enable = true;
        unindent.enable = true;
        userVoiceShow.enable = true;
        validUser.enable = true;
        vencordToolbox.enable = true;
        viewIcons.enable = true;
        whoReacted.enable = true;
        youtubeAdblock.enable = true;
      };
    };
  };
}
