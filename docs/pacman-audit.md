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
sudo pacman -Rns github-cli lazygit fzf
```

| package | why |
|---|---|
| `github-cli` | flake provides `gh` |
| `lazygit` | **replaced by `gitui` at your request — see the warning below** |
| `fzf` | flake provides it; verified `fzf-tmux` ships with nix's build, which `tmux.conf`'s `prefix + B` needs |

> **`lazygit` removal breaks three neovim bindings.** `snacks.nvim` binds
> `<leader>gg`, `<leader>gl` and `<leader>gf` to `Snacks.lazygit`, and
> `tree-bear.lua` calls `require("tree-bear").lazygit_worktree()`. `gitui` is
> **not** a drop-in: snacks has no gitui provider, and tree-bear shells out to
> lazygit by name. Those bindings will error until `~/.config/nvim` is updated —
> which this flake deliberately does not manage. Either update the nvim config
> first, or keep lazygit installed alongside gitui until you do.

After switching, run `tmux kill-server` once. `run-shell` inherits the tmux
*server's* environment, captured at server start; a server predating the switch
has no `~/.nix-profile/bin` on PATH and will not find `fzf-tmux`.

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
`modules/system/packages.nix` for the system half.

## Fonts

`noto-fonts*` `ttf-*` `adobe-source-han-sans-*` `awesome-terminal-fonts` are all
in nixpkgs and could move. Low priority: they work, and fontconfig finds them
either way. The one that *had* to move already did — `GoMono Nerd Font` was
hand-installed under `~/.local/share/fonts` and owned by no package at all,
which is why cheroot rendered boxes. See `modules/fonts.nix`.

## Not in nixpkgs

`pkgfile` — Arch-specific (`pacman` file index). No nix equivalent, and none
wanted.
