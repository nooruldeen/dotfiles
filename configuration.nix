{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;

  system.defaults = {
    NSGlobalDomain = {
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      AppleShowAllExtensions = true;

      # Upstream also sets these two. They are personal taste and they change
      # the look of the machine on first activation, so they are opt-in here.
      # AppleInterfaceStyle = "Dark";
      # _HIHideMenuBar = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };

  nix-homebrew = {
    enable = true;
    inherit user;

    # This Mac already had a user-owned Homebrew at /opt/homebrew with ~95
    # formulae and three taps (dart-lang/dart, leoafarias/fvm, mongodb/brew).
    # nix-homebrew refuses to activate over an existing installation unless it
    # is allowed to adopt it. nix-homebrew installs and owns Homebrew itself
    # but "does not manage any package installed by it", so adoption transfers
    # ownership of the prefix without touching what is installed.
    autoMigrate = true;

    # Left at the default (true) on purpose: `brew tap` still works. Setting it
    # false would make the three existing taps undeclared-and-forbidden.
    # mutableTaps = false;
  };

  homebrew = {
    enable = true;

    # DO NOT change this to "uninstall" or "zap" without reading AGENTS.md.
    #
    # Upstream ships "zap". On this machine that would uninstall every formula
    # not listed below - all ~95 of them, including mongodb-community,
    # postgresql@14 and rabbitmq - and "zap" additionally deletes their data
    # directories. "none" leaves undeclared packages alone.
    #
    # Migration path: move packages you rely on into brews/casks below over
    # time. Only once that list is genuinely complete is it safe to tighten
    # this, and "uninstall" is the correct next step rather than "zap"
    # because it leaves data directories intact.
    onActivation.cleanup = "none";

    # Upstream enables this. Left off so that `darwin-rebuild switch` stays a
    # fast, predictable operation instead of also upgrading unrelated packages.
    onActivation.autoUpdate = false;

    brews = [
      "herdr"
    ];

    casks = [
      "wezterm"
      "codex"

      # "claude-code" is deliberately NOT declared.
      #
      # Claude Code is already installed via Anthropic's native installer at
      # ~/.local/bin/claude, which self-updates and is ahead of the cask
      # (2.1.231 vs 2.1.220). Declaring the cask too would put a second, older
      # claude binary on PATH and leave the winner to shell ordering.
      # This is the one intentionally non-declarative piece of the stack: a
      # self-updating agent binary beats a pinned, perpetually stale one.
    ];
  };
}
