# dotfiles

Personal Mac setup, managed with `nix-darwin` and Home Manager.
One repo, one command, and the machine ends up configured the same way every time.

Forked from [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles)
([walkthrough video](https://youtu.be/5N-okeDdIuI)) and adapted for a Mac that
was already in daily use. **The differences from upstream are deliberate and are
documented in [AGENTS.md](AGENTS.md).** Read that before changing anything, and
before merging upstream.

## What you get

- System settings (key repeat, dock, Finder, trackpad)
- Homebrew apps: WezTerm, Codex, Herdr
- Nix user packages: ripgrep, fd, fzf, jq, lazygit, Neovim, Pi, Hack Nerd Font
- Shell: zsh with oh-my-zsh's git plugin, autosuggestions, syntax highlighting
  and the Starship prompt
- Editor: Neovim config, rose-pine moon
- Terminal: WezTerm config, rose-pine moon, dimmed unfocused windows, Kitty
  keyboard protocol and Option+Enter forwarded to the program (for Pi)
- Agent configs: Claude, Codex and OpenCode all share one `home/AGENTS.md`;
  Pi gets its theme, extensions, `models.json` and `settings.json` linked

## The one thing to read before running this

Upstream sets `homebrew.onActivation.cleanup = "zap"`, which uninstalls every
Homebrew package not declared in `configuration.nix`, along with its data
directories.

**This fork sets `cleanup = "none"`** because this machine already had ~95
formulae installed, including `mongodb-community`, `postgresql@14` and
`rabbitmq`. Nothing undeclared is touched.

If you are adopting this repo on a different machine and want full
reproducibility, the migration is:

1. `brew list --formula` and `brew list --cask`
2. add everything you actually rely on to `brews` / `casks`
3. switch to `cleanup = "uninstall"` and rebuild
4. only consider `"zap"` once you are confident, since it also deletes data
   directories

## Prerequisites

- Apple Silicon by default. On Intel, set
  `nixpkgs.hostPlatform = "x86_64-darwin";` in `configuration.nix`.
- Xcode command line tools: `xcode-select --install`

## Setup

```sh
git clone https://github.com/nooruldeen/dotfiles.git
cd dotfiles
chmod +x bootstrap.sh rebuild.sh
./bootstrap.sh
```

`bootstrap.sh` installs Determinate Nix, symlinks the repo to `~/.dotfiles`,
reconciles the username in `flake.nix` with your macOS username, and runs the
first `darwin-rebuild switch`. It needs `sudo`.

Existing files that Home Manager takes over, `~/.zshrc` above all, are renamed
to `*.hm-backup` rather than deleted.

`~/.claude/settings.json` is **not** managed here. `home/.claude/settings.json`
is a sanitised baseline (theme, status line, plugins, marketplaces) because this
fork is public and a real user-level allowlist names private project paths.
Claude Code has no user-level `settings.local.json` to split it into, so the live
file is simply left alone. Copy from the baseline by hand on a new machine.

### After the first bootstrap

`nix-homebrew.autoMigrate = true` adopts the existing `/opt/homebrew`. Per the
module's own description it "will automatically delete Homebrew repositories
while keeping installed packages" - so packages survive, but taps have to be
re-added:

```sh
brew tap dart-lang/dart
brew tap leoafarias/fvm
brew tap mongodb/brew
```

`mutableTaps` is left at its default of `true`, so `brew tap` keeps working.

Take a snapshot of the pre-migration Homebrew state first, as a recovery artifact
and as the worklist for moving packages into `configuration.nix` later:

```sh
brew bundle dump --file=Brewfile.pre-nix
```

It is gitignored on purpose, since it enumerates installed and App Store apps.
Note that `brew bundle dump` only records install-on-request packages, so it is
a worklist rather than a complete inventory: on this machine it listed 14 of ~95
formulae and omitted `mongodb-community` entirely.

Then verify the toolchain:

```sh
rg --version && fd --version && fzf --version && jq --version
nvim --version && lazygit --version && herdr --version
claude --version && codex --version
```

## Daily use

Edit the repo, then:

```sh
./rebuild.sh
```

Validate before applying:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

## Shell aliases

Plain aliases run the agents normally. Escalation is explicit and separate:

| alias | runs |
| --- | --- |
| `c` | `claude` |
| `cx` | `codex` |
| `c-auto` | `claude --dangerously-skip-permissions` |
| `cx-auto` | `codex --full-auto` |

Upstream maps `cc` / `co` straight to the escalated forms. That is not the
default here, on purpose.

## Imperative shell additions

`~/.zshrc` is a read-only symlink into the Nix store, so installers that append
to it (gcloud, Antigravity, some IDEs) cannot write there. Anything imperative
goes in `~/.zshrc.local`, which is sourced last and is never managed by Nix.

## Claude Code is not declared

Claude Code is installed with Anthropic's native installer:

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

It self-updates and runs ahead of the Homebrew cask, so the cask is deliberately
not in `configuration.nix`. This is the one intentionally non-declarative piece
of the stack.

## Syncing with upstream

```sh
git fetch upstream
git merge upstream/main
```

Re-read [AGENTS.md](AGENTS.md) afterwards. Upstream's own agent notes instruct
agents to keep `cleanup = "zap"`; that instruction does not apply to this fork.

## Credit

All of the original design and nearly all of the configuration is
[kunchenguid](https://github.com/kunchenguid)'s work.
