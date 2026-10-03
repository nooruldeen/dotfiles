# Project notes for agents

This is a fork of `kunchenguid/dotfiles`, adapted for a Mac that was already in
heavy daily use. Several upstream decisions are deliberately inverted here.
Do NOT silently revert them, and do not "restore upstream behaviour" during a
merge without reading this file first.

## Deliberate divergences from upstream

- **`homebrew.onActivation.cleanup = "none"`, not `"zap"`.** Upstream sets
  `"zap"` on purpose and its own AGENTS.md tells you not to soften it. That
  reasoning does not transfer to this machine. This Mac carries ~95 formulae
  including `mongodb-community`, `postgresql@14` and `rabbitmq`; `"zap"` removes
  undeclared packages *and* their data directories. Tightening this is a
  migration, not a one-line edit: every package in daily use must be listed in
  `configuration.nix` first, and `"uninstall"` is the correct intermediate step
  because it spares data directories.

- **`nix-homebrew.autoMigrate = true`.** Required to adopt the pre-existing
  user-owned `/opt/homebrew` instead of aborting activation.

- **`claude-code` is not a declared cask.** Claude Code is installed natively at
  `~/.local/bin/claude`, self-updates, and runs ahead of the cask. Declaring the
  cask would place a second, older binary on PATH. This is the one intentionally
  non-declarative component in the stack.

- **`home-manager.backupFileExtension = "hm-backup"`** in `flake.nix`. Without
  it the first activation aborts on the pre-existing `~/.zshrc`.

- **`~/.claude/settings.json` is not symlinked**, unlike upstream. This fork is
  public and the real user-level file carries a permission allowlist naming
  private project paths. `home/.claude/settings.json` is a sanitised baseline
  only. Do not add the symlink back: Claude Code has no user-level
  `settings.local.json` to keep the allowlist in, so linking would discard it.

- **`PLAN.md` and `Brewfile*` are gitignored.** They contain a machine audit
  (username, installed software, App Store apps, data-directory sizes). Do not
  commit them to this public fork.

- **Pi comes from `nixpkgs-unstable`, not npm.** Upstream tells you to
  `npm install -g` it; here `home.nix` installs `pi-coding-agent` from the
  `nixpkgs-unstable` flake input, because the packages in
  `home/.pi/agent/settings.json` fail to load on 26.05's Pi 0.75. It is wrapped
  with a Nix `nodejs` as a PATH suffix because Pi shells out to npm for those
  `npm:` packages. Update Pi with `nix flake update nixpkgs-unstable`; that
  input is used for nothing else. Pi config links match upstream.

- **`c` / `cx` are the plain agent aliases; `c-auto` / `cx-auto` are the
  permission-skipping ones.** Upstream maps `cc` / `co` directly to
  `--dangerously-skip-permissions` and `--full-auto`. Escalation is explicit
  here. Do not collapse them back.

## Things that are load-bearing in `home.nix`

`programs.zsh` renders `~/.zshrc` as a read-only Nix store symlink, which
replaced a hand-written file. These were ported from it and the machine breaks
without them:

- `~/.local/bin` first on PATH - this is how the `claude` binary resolves.
- `~/.pub-cache/bin`, Antigravity bins, Android `platform-tools`, `ANDROID_HOME`.
- The Google Cloud SDK `path.zsh.inc` and `completion.zsh.inc` includes.
- The `~/.zshrc.local` source at the end: installers append to `~/.zshrc` and
  cannot append to a store symlink, so imperative additions land there instead.

`/opt/homebrew/bin` is deliberately *last* on PATH so Nix-installed tools win
over Homebrew copies of the same binary.

## Validation

Before proposing a change to any `.nix` file:

    nix flake check --no-build
    nix build .#darwinConfigurations.mac.system --dry-run

Do not claim either passed unless it actually ran. Applying a change is
`./rebuild.sh`, which needs `sudo`; leave that to the human unless asked.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this
project. Do not repeat what the codebase already shows; point to the
authoritative file or command instead. Prefer rewriting or pruning existing
entries over appending new ones.
