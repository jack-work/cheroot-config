# hush: the credential keeper figaro's skills shell out to.
#
# figaro has no network verbs of its own. `hush brave "query"` is how an aria
# searches the web: hush decrypts the API key, hands it to the script through
# the environment, and forgets it. Without hush on the box, the brave skill in
# config/figaro/skills describes something the machine cannot do.
#
# Same nullable-package split as modules/figaro.nix, for the same reason: gluck
# develops hush and installs it with `go install`, so a flake pin there would
# cost a lockfile bump per build. Every other machine takes the pin.
#
# THE COMMAND DIRECTORY IS LINKED FILE BY FILE. `hush secret seal` writes
# secrets.toml beside command.toml, and against a store symlink that write fails
# with EPERM. linkDir keeps the directory real and writable. See lib/link-dir.nix.
#
# NO SECRET IS IN THIS REPO, and the per-machine identity is the point: each box
# holds its own age identity and its own copy of the key, so losing one does not
# leak the others. On a machine that has never run hush:
#
#     hush init
#     printf 'secret = "<brave api key>"\n' > ~/.config/hush/commands/brave/secrets.toml
#     hush secret seal brave
#     hush up -d
{ inputs, config, ... }:
{
  # `hm@{ ... }` rather than destructuring `config`: the OUTER `config` is the
  # flake config, needed below for linkDir. Same split as shell/fish.nix.
  flake.modules.homeManager.hush =
    hm@{ lib, pkgs, ... }:
    {
      options.my.hush.package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = inputs.hush.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultText = lib.literalExpression "inputs.hush.packages.\${system}.default";
        description = ''
          The hush binary this host installs, or `null` to take the command
          definitions and leave the binary to the host's own loop. Null on the
          development host.
        '';
      };

      options.my.hush.unlock = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        example = ''
          [unlock]
          method = "keyring"
        '';
        description = ''
          The `[unlock]` policy for this machine's hush.toml, or null to leave
          the file unmanaged. How the identity is unlocked is a fact about the
          BOX, not about hush: a desktop with a running Secret Service uses the
          keyring, a headless or bare machine reads a 0600 file, and a machine
          with someone sitting at it can just be asked.

          The passphrase itself is never here. Only the method is.
        '';
      };

      config = {
        home.packages = lib.optional (hm.config.my.hush.package != null) hm.config.my.hush.package;

        xdg.configFile =
          config.flake.lib.linkDir ../config/hush/commands/brave "hush/commands/brave"
          // lib.optionalAttrs (hm.config.my.hush.unlock != null) {
            "hush/hush.toml".text = hm.config.my.hush.unlock;
          };
      };
    };
}
