lib: src: dst:
lib.mapAttrs' (name: _: {
  name = "${dst}/${name}";
  value.source = src + "/${name}";
}) (lib.filterAttrs (_: type: type == "regular") (builtins.readDir src))
