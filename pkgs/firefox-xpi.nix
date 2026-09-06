# A Firefox/Zen extension pinned straight from addons.mozilla.org.
#
# WHY THIS EXISTS. Most add-ons come from rycee's `firefox-addons` input, which
# is generated, versioned and updated for us. A few never make it into that set
# — static themes in particular — and the alternatives are both worse:
#
#   * `policies.ExtensionSettings` installs by AMO slug, but policies need a
#     WRAPPED package and our Zen comes from pacman (see modules/desktop/zen.nix).
#   * Installing by hand leaves the machine that has it and the machine that
#     does not looking identical in git.
#
# So: pin the file. AMO's download URLs are immutable per version, the hash
# fixes the bytes, and `addonId` is what home-manager keys the profile entry on.
#
# Finding the arguments for a new add-on, given its id:
#
#   curl -sL https://addons.mozilla.org/api/v5/addons/addon/<url-encoded-id>/ \
#     | jq '{v: .current_version.version, url: .current_version.file.url}'
#   nix store prefetch-file --json <url> | jq -r .hash
#
# Usage (from a module):
#
#   (pkgs.callPackage ../../pkgs/firefox-xpi.nix { } {
#     name = "kanagawa-wave-dark-theme"; version = "2.5";
#     addonId = "{7efc2a80-...}"; url = "https://..."; hash = "sha256-...";
#   })
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

{
  name,
  version,
  addonId,
  url,
  hash,
  # Empty is correct for a static theme and for anything whose permissions this
  # profile does not audit. home-manager only reads it when a profile turns on
  # `extensions.exhaustivePermissions`, but the attribute must EXIST — the
  # module destructures `meta` out of every extension package.
  mozPermissions ? [ ],
  # DECLARE UNFREE ADD-ONS UNFREE. 1Password's extension is proprietary, and
  # the honest thing is to say so and let the allowlist in modules/systems.nix
  # permit it by name — not to omit a license and slip it past the check.
  license ? lib.licenses.free,
}:

stdenvNoCC.mkDerivation {
  pname = name;
  inherit version;

  src = fetchurl { inherit url hash; };

  # An xpi is a zip, and unpacking it would be worse than pointless: gecko wants
  # the archive, named for the add-on id, in the extensions directory.
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 "$src" \
      "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"
    runHook postInstall
  '';

  passthru = { inherit addonId; };

  meta = {
    inherit mozPermissions license;
    description = "Firefox add-on ${name}, pinned from addons.mozilla.org";
    homepage = "https://addons.mozilla.org/firefox/addon/${name}/";
    platforms = lib.platforms.all;
  };
}
