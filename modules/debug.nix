# flake-parts' debug output, on purpose.
#
# WHAT IT IS. `debug = true` makes flake-parts publish `flake.debug` — the
# whole module evaluation, `options` and `config` included. It adds an output
# and changes nothing about what any host installs.
#
# WHY IT IS ON. It is what `nixd` reads to complete `modules/*.nix`. The
# repo-root `.nvim.lua` points the language server at three option sources:
#
#   nixpkgs        the package set, for `pkgs.<tab>`
#   home_manager   homeConfigurations."<user>@<host>".options — the aspects
#   flake_parts    THIS. `.debug.options`, so writing a MODULE gets completion
#                  and hover, not just the home-manager options inside one.
#
# Without this line that third source resolves to nothing and fails silently:
# nixd simply offers no completion in the flake-parts half of every file, which
# is exactly the half that is unfamiliar. The failure looks like "nixd is a bit
# weak" rather than like a missing option, which is why it is worth a file and
# a comment rather than a bare `true` tucked into options.nix.
#
# COST. One extra flake output, evaluated only when something asks for it.
# `nix flake check` does not walk it (it is not a standard output, and is
# reported as unknown exactly like `modules` and `lib` already are).
{
  debug = true;
}
