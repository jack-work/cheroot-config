{ buildGoModule }:
buildGoModule {
  pname = "figaro-apply";
  version = "0.1.0";
  src = ./.;
  vendorHash = null;
  env.CGO_ENABLED = "0";
  ldflags = [
    "-s"
    "-w"
  ];
  meta.mainProgram = "figaro-apply";
}
