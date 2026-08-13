{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  home = config.home.homeDirectory;
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    ANDROID_HOME = "${home}/Library/Android/sdk";
  };

  # Ported verbatim from the pre-Nix ~/.zshrc. Order is priority order: the
  # first entry wins. ~/.local/bin must stay first - it is how the `claude`
  # binary is resolved, and it is deliberately not managed by Nix.
  # /opt/homebrew/bin is last so Nix-installed tools (rg, fd, jq, ...) take
  # precedence over any Homebrew copy of the same tool.
  home.sessionPath = [
    "${home}/.local/bin"
    "${home}/.pub-cache/bin"
    "${home}/.antigravity/antigravity/bin"
    "${home}/.antigravity-ide/antigravity-ide/bin"
    "${home}/Library/Android/sdk/platform-tools"
    "/opt/homebrew/bin"
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid

    # Kept from the previous setup so the familiar git aliases (gst, gco, gd,
    # ...) survive the migration. The theme is empty on purpose: Starship
    # renders the prompt, not oh-my-zsh.
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "";
    };

    initContent = ''
      bindkey '^f' autosuggest-accept

      # Google Cloud SDK. These scripts adjust PATH and install completions,
      # so they have to be sourced rather than declared.
      if [ -f "${home}/google-cloud-sdk/path.zsh.inc" ]; then
        . "${home}/google-cloud-sdk/path.zsh.inc"
      fi
      if [ -f "${home}/google-cloud-sdk/completion.zsh.inc" ]; then
        . "${home}/google-cloud-sdk/completion.zsh.inc"
      fi

      # Kiro shell integration, only when running inside Kiro.
      if [ "$TERM_PROGRAM" = "kiro" ] && command -v kiro >/dev/null 2>&1; then
        . "$(kiro --locate-shell-integration-path zsh)"
      fi

      # To go back to powerlevel10k instead of Starship: set
      # programs.starship.enable = false below, then uncomment these two lines.
      # source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
      # [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

      # Escape hatch. Home Manager renders ~/.zshrc as a read-only symlink into
      # the Nix store, so installers that append to it (gcloud, Antigravity,
      # some IDEs) silently fail. Anything imperative goes in ~/.zshrc.local,
      # which is never managed by Nix and never committed.
      #
      # Written as an if rather than `[ -f ... ] && source ...` so that a
      # missing file does not leave $? non-zero, which would make Starship
      # paint the very first prompt of every shell red.
      if [ -f ~/.zshrc.local ]; then
        source ~/.zshrc.local
      fi
    '';

    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";

      # Ordinary interactive agents. Upstream maps `cc`/`co` straight to the
      # permission-skipping modes; that makes ambient authority the default.
      # Here the plain aliases are the safe ones and escalation is explicit,
      # so that granting an agent extra authority stays a deliberate act
      # rather than a habit.
      c = "claude";
      cx = "codex";
      c-auto = "claude --dangerously-skip-permissions";
      cx-auto = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";

  # ~/.claude/settings.json is deliberately NOT symlinked, unlike upstream.
  #
  # This repo is a public fork, and the real user-level settings file carries a
  # permission allowlist naming private project paths and app IDs. The committed
  # copy at home/.claude/settings.json is sanitised (theme, statusLine, plugins,
  # marketplaces only) and serves as a portable baseline, not as the live file.
  #
  # Splitting it was not an option: Claude Code has no user-level
  # settings.local.json. `settings.local.json` exists only at project scope, so
  # there is nowhere private for a user-level allowlist to live except
  # ~/.claude/settings.json itself. Linking the sanitised file over it would
  # discard the allowlist. Copy from the baseline by hand when setting up a new
  # machine.

  # Pi is omitted for now: it is a post-video addition upstream and not part of
  # the core Claude Code + Codex + Herdr workflow this machine is adopting
  # first. Upstream links ~/.pi/agent/{themes,extensions,models.json,
  # settings.json}; those files are still in this repo under home/.pi/ so
  # re-enabling later is a paste job.

  # One canonical instruction file, linked everywhere the agents look for it.
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  # OpenCode has no Homebrew cask, so it is not installed declaratively - but
  # the link costs nothing and works the moment OpenCode appears.
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
