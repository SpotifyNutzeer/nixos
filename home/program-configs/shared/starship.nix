{ ... }: 
let
  sep = builtins.fromJSON ''"\ue0b0"'';
  lang = symbol: {
    style = "fg:base bg:mauve";
    format = "[ $symbol($version) ]($style)";
    inherit symbol;
  };
in
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;

      format =
        "$directory" +
        "[${sep}](fg:teal bg:green)" +
        "$git_branch$git_status" +
        "[${sep}](fg:green bg:mauve)" +
        "$c$cpp$dart$deno$elixir$elm$golang$haskell$java$julia$lua$nim$nodejs$python$ruby$rust$swift$conda$pixi$package$docker_context" +
        "[${sep}](fg:mauve bg:peach)" +
        "$cmd_duration" +
        "[${sep}](fg:peach bg:surface1)" +
        "$time" +
        "[${sep}](fg:surface1)" +
        "$character";

      character = {
        success_symbol = "[ ❯](mauve)";
        error_symbol = "[ ❯](red)";
        vimcmd_symbol = "[ ❮](green)";
      };

      directory = {
        style = "fg:base bg:teal";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        read_only = " ";
        home_symbol = " ~";
      };

      git_branch = {
        style = "fg:base bg:green";
        format = "[ $symbol$branch ]($style)";
        symbol = " ";
      };

      git_status = {
        style = "fg:base bg:green";
        format = "[$all_status$ahead_behind ]($style)";
        conflicted = "⚠ ";
        ahead = "⇡\${count} ";
        behind = "⇣\${count} ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
        up_to_date = "";
        untracked = "? ";
        stashed = "≡ ";
        modified = "● ";
        staged = "+ ";
        renamed = "» ";
        deleted = "✘ ";
      };

      cmd_duration = {
        min_time = 2000;
        style = "fg:base bg:peach";
        format = "[  $duration ]($style)";
      };

      time = {
        disabled = false;
        time_format = "%H:%M";
        style = "fg:text bg:surface1";
        format = "[  $time ]($style)";
      };

      c      = lang " ";
      cpp    = lang " ";
      golang = lang " ";
      java   = lang " ";
      nodejs = lang " ";
      python = lang " ";
      
      docker_context = {
        style = "fg:base bg:mauve";
        format = "[ $symbol$context ]($style)";
        symbol = " ";
      };
    };
  };
}
