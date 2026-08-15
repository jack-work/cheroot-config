# pacman → nix audit (gluck, 2026-08-15)

291 explicitly-installed pacman packages (1239 including dependencies).
Classified by whether nix *could* own them, and whether it *should*.

**The rule that governs all of this:** `~/.nix-profile/bin` precedes `/usr/bin`.
So installing something from nix that pacman also provides does not replace it —
it **shadows** it. Two copies on disk, the nix one winning silently, and pacman
upgrades that appear to do nothing. Every migration below is therefore a pair:
add to the flake, and `pacman -Rns` the old one.

Before removing anything, check nothing depends on it:

```sh
pacman -Qi <pkg> | grep -E 'Required By|Optional For'
```

---

## Required before the first switch

The flake already installs these; pacman's copies must go or they will be
shadowed:

```sh
sudo pacman -Rns github-cli fzf
```

| package | why |
|---|---|
| `github-cli` | flake provides `gh` |
| `fzf` | flake provides it; verified `fzf-tmux` ships with nix's build, which `tmux.conf`'s `prefix + B` needs |

> **Removing `github-cli` breaks git auth unless `.gitconfig` is fixed first.**
> Your hand-written `~/.gitconfig` set
> `helper = !/usr/bin/gh auth git-credential` — an **absolute path** into
> pacman's copy. `modules/git.nix` now declares the helper unqualified, so it
> resolves through PATH from any source. But see the next warning.

> **Delete `~/.gitconfig` by hand after switching.** home-manager writes to
> `$XDG_CONFIG_HOME/git/config`, and git reads *both* files, last value winning.
> `-b bak` will not back up `~/.gitconfig` because home-manager does not manage
> that path. Measured with both present, the **stale** `/usr/bin/gh` helper
> wins. Once: `mv ~/.gitconfig ~/.gitconfig.pre-nix`.

`lazygit` is **kept** for now: `snacks.nvim` binds `<leader>gg/gl/gf` to it and
`tree-bear.lua` calls `lazygit_worktree()`. `gitui` is additive until the nvim
config stops naming lazygit. nix's 0.63.1 will shadow pacman's 0.64.1 — a silent
minor downgrade, noted so it is not a surprise.

After switching, run `tmux kill-server` once. `run-shell` inherits the tmux
*server's* environment, captured at server start; a server predating the switch
has no `~/.nix-profile/bin` on PATH and will not find `fzf-tmux`.

---

## Candidates for home *management*, not just installation

Installing a package from nix is the small half. The larger half is
home-manager's `programs.*` / `services.*` modules, which manage the tool's
**configuration** as well. home-manager ships **350 program modules** and **162
service modules**; **39** of them match something you have installed via pacman:

| worth adopting | why |
|---|---|
| `programs.git` | **done** — `.gitconfig` was unmanaged and carried the `/usr/bin/gh` trap |
| `programs.gh` | gh aliases and settings, currently unmanaged |
| `programs.go` | `env.GOPATH` / `GOBIN` / `GOFLAGS` — would replace the hand-rolled `GOFLAGS` in `10-env` and the `go env GOPATH` shelling-out in `30-path` |
| `programs.btop`, `programs.htop` | small configs, currently hand-tuned or default |
| `programs.less`, `programs.ripgrep` | `LESS` opts, ripgrep ignore rules |
| `programs.fastfetch` | the shell greeting, currently distro default |
| `programs.bun`, `programs.uv`, `programs.npm` | registry/config files |
| `programs.aichat`, `programs.claude-code` | both already installed via pacman |

| deliberately NOT adopting | why |
|---|---|
| `programs.tmux` | generates tmux.conf from Nix attrs. Yours is 185 tuned lines incl. the 3.7b workaround — a rewrite with no gain |
| `programs.neovim` | config is a git clone that lazy.nvim and mason write into |
| `programs.waybar`, `services.mako`, `programs.alacritty`, `programs.rofi`, `programs.wofi`, `programs.swaylock`, `programs.wlogout` | we manage these as verbatim files, and enabling the module also installs a nix build of something that draws — see Tier 3 |
| `programs.chromium`, `programs.obs-studio`, `programs.vesktop`, `programs.freetube` | GPU / Electron; keep on pacman |

### The `package = null` trick

Many home-manager modules declare their package option **nullable**, which lets
you take the configuration management while leaving the *binary* to the distro —
exactly the right split on Arch. Verified nullable in this home-manager revision:

`git` `go` `btop` `less` `ripgrep` `fastfetch` `bun` `uv` `npm` `micro`
`aichat` `lazygit` `tmux`

```nix
programs.btop = {
  enable = true;
  package = null;      # pacman keeps the binary; nix owns ~/.config/btop
  settings = { ... };
};
```

This is the answer for anything heavy, or anything where the distro's version
should win.

---

## Tier 1 — safe to migrate, no system integration

Pure user-space CLI. All verified present in the pinned nixpkgs.

`btop` `htop` `glances` `duf` `tabiew` `pv` `sox` `dolt` `nmap` `rsync`
`unrar` `zip` `unzip` `wl-clipboard` `cbonsai` `aichat` `claude-code`
`fastfetch` `micro` `nano` `less` `diffutils` `man-pages` `plocate` `bind`
`ethtool` `tree` `wget`

Cost of moving: one `pacman -Rns` each. Benefit: pinned, reproducible, and
present on every host the flake touches.

## Tier 2 — migrate deliberately, version-sensitive

Toolchains and cloud CLIs. nix *has* them, but these are exactly the packages
where a silent version change hurts, and several are currently **newer** on
pacman.

`go` `rustup` `nodejs` `typescript` `bun` `uv` `python3` `pipx`
`terraform` `kubectl` `awscli2` `azure-cli` `postgresql` `docker-compose`
`docker-buildx` `podman-compose` `ghostscript`

Two live examples of why to be deliberate: nixpkgs `nodejs` is **24.18.0** while
pacman ships **26.4.0**; nixpkgs `gcc` is **15.3.0** against pacman's **16.2.1**.
This is the reason `my.platform.toolchainFromNix` defaults to **false** — see
`modules/platform.nix`.

## Tier 3 — keep on pacman (Arch), nix only on NixOS

**127 system packages**: kernel (`linux-cachyos*`), drivers (`nvidia-*`,
`mesa-*`, `vulkan-*`, `lib32-*`), firmware, bootloader (`grub`, `mkinitcpio`,
`efibootmgr`), filesystems (`btrfs-progs`, `lvm2`, `cryptsetup`, `snapper`),
services (`networkmanager`, `bluez`, `pipewire`, `wireplumber`, `cups`, `sddm`,
`tailscale`, `docker`), and all `cachyos-*` distro integration.

**51 packages that draw**: `niri` `waybar` `mako` `rofi` `alacritty` `swaybg`
`swaylock-*` `wofi` `wob` `firefox` `thorium-browser` `zen-browser` `gimp`
`obs-studio` `zoom` `zed` `rider` `1password` `xournalpp` …

These touch the GPU, and nixpkgs Mesa on a non-NixOS host is
[nixpkgs#9415](https://github.com/NixOS/nixpkgs/issues/9415) — open since 2015. A
nix-built compositor links nixpkgs Mesa against the Arch kernel driver and
renders in software, or not at all.

On **NixOS** every one of these flips to nix, via
`my.platform.desktopFromNix = true` for the graphical stack and
`modules/system/nixos.nix` for the system half.

## Fonts

`noto-fonts*` `ttf-*` `adobe-source-han-sans-*` `awesome-terminal-fonts` are all
in nixpkgs and could move. Low priority: they work, and fontconfig finds them
either way. The one that *had* to move already did — `GoMono Nerd Font` was
hand-installed under `~/.local/share/fonts` and owned by no package at all,
which is why cheroot rendered boxes. See `modules/fonts.nix`.

## Not in nixpkgs

`pkgfile` — Arch-specific (`pacman` file index). No nix equivalent, and none
wanted.
