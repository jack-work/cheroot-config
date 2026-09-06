# A Firefox/Zen add-on pinned from addons.mozilla.org, for the few that rycee's
# firefox-addons set lacks (static themes) or that are unfree.
#
# Arguments for a new one, given its id:
#
#   curl -sL https://addons.mozilla.org/api/v5/addons/addon/<url-encoded-id>/ \
#     | jq '{v: .current_version.version, url: .current_version.file.url}'
#   nix store prefetch-file --json <url> | jq -r .hash
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
  # Only read when a profile sets extensions.exhaustivePermissions, but the
  # attribute must exist: the module destructures meta out of every extension.
  mozPermissions ? [ ],
  # Unfree add-ons say so here, and modules/host-builder.nix permits them by
  # name.
  license ? lib.licenses.free,
}:

stdenvNoCC.mkDerivation {
  pname = name;
  inherit version;

  src = fetchurl { inherit url hash; };

  # Gecko wants the archive named for the add-on id, not its contents.
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
