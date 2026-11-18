{ lib }:
let
  seatKinds = [
    "strategist"
    "knight"
    "steward"
  ];

  kinds = seatKinds ++ [ "reviewer" ];

  rosterKindOf = {
    strategist = "leader";
    knight = "builder";
    steward = "steward";
  };

  isExactForm = s: builtins.isString s && builtins.match "@([0-9a-f]{8}|[0-9a-f]{32})" s != null;

  holderOutfit = regiment: kind: "regiment-${regiment}-${kind}";
  mintOutfit = seat: "role-${seat}-mint";

  agreementText =
    regName: reg:
    let
      titleOf = kind: lib.concatMapStringsSep ", " (s: s.title) (seatsOf reg kind);
      subst =
        builtins.replaceStrings
          [ "{strategist}" "{knight}" "{steward}" "{reviewer-outfit}" "{retire-ttl}" ]
          [
            (titleOf "strategist")
            (titleOf "knight")
            (titleOf "steward")
            (holderOutfit regName "reviewer")
            reg.reviewer.retireTtl
          ];
    in
    lib.concatMapStringsSep "\n" (c: "- " + subst c) reg.agreement;

  seatsOf = reg: kind: lib.attrValues (lib.filterAttrs (_: s: s.kind == kind) reg.seats);

  validateRegiment =
    roster: name: reg:
    let
      count = kind: builtins.length (seatsOf reg kind);
      seatNames = builtins.attrNames reg.seats;
    in
    map (k: "regiment ${name}: needs exactly one ${k}, has ${toString (count k)}") (
      builtins.filter (k: count k != 1) seatKinds
    )
    ++ lib.optional (
      reg.leader != "none" && !(roster ? ${reg.leader})
    ) "regiment ${name}: leader '${reg.leader}' must be 'none' or a declared role"
    ++ lib.optional (builtins.elem reg.leader seatNames) "regiment ${name}: its leader '${reg.leader}' cannot be one of its own seats"
    ++ lib.concatLists (
      lib.mapAttrsToList (
        seat: s:
        lib.optional (
          s.form != null && !(isExactForm s.form)
        ) "regiment ${name}: seat ${seat}: form '${s.form}' must be @ and 8 or 32 hex digits"
      ) reg.seats
    );

  seatRole =
    regName: reg: seat: s:
    let
      k = reg.kinds.${s.kind};
      adopted = s.form != null;
    in
    {
      name = seat;
      kind = rosterKindOf.${s.kind};
      inherit (reg) leader;
      inherit (s) purpose form handoff;
      inherit (k) provider model;
      mantra = s.mantra;
      mint = false;
      cacheControl = null;
      forward = [ ];
      forwardUntil = null;
      charter = if adopted then s.charter else null;
      maxChildren = if adopted then k.maxChildren else null;
      fields = if adopted then seatFields regName reg s else { };
      mode = reg.mode;
    };

  seatFields = regName: reg: s: {
    name = s.title;
    role-name = s.title;
    orchestration.policy = reg.orchestration;
    regiment = {
      name = regName;
      seat = s.kind;
      agreement = agreementText regName reg;
    };
  };

  successorOutfits =
    regName: reg: kind:
    lib.concatStringsSep "," (reg.successorBase ++ [ (holderOutfit regName kind) ]);

  holderSpec =
    reg: kind:
    let
      k = reg.kinds.${kind};
    in
    lib.optionalAttrs (k.provider != null || k.model != null) {
      system = lib.filterAttrs (_: v: v != null) { inherit (k) provider model; };
    };

  renderOutfits =
    regName: reg:
    lib.mapAttrs' (kind: _: lib.nameValuePair (holderOutfit regName kind) (holderSpec reg kind)) (
      lib.genAttrs seatKinds (_: null)
    )
    // {
      ${holderOutfit regName "reviewer"} = lib.recursiveUpdate (holderSpec reg "reviewer") {
        system.ttl = reg.reviewer.ttl;
        regiment = {
          name = regName;
          seat = "reviewer";
          agreement = agreementText regName reg;
        };
      };
    }
    // lib.mapAttrs' (
      seat: s:
      lib.nameValuePair (mintOutfit seat) (
        lib.filterAttrs (_: v: v != null) {
          layers = reg.successionLayers;
          inherit (s) charter handoff;
          succession-policy.outfit = successorOutfits regName reg s.kind;
        }
        // lib.optionalAttrs (reg.kinds.${s.kind}.maxChildren != null) {
          system.fanout.max_children = reg.kinds.${s.kind}.maxChildren;
        }
        // seatFields regName reg s
      )
    ) reg.seats;

  inertFields =
    regName: reg:
    lib.concatLists (
      lib.mapAttrsToList (
        kind: k:
        lib.optional (k.quota != null) "regiment ${regName}: ${kind}.quota"
        ++ lib.optional (k.scopes != null) "regiment ${regName}: ${kind}.scopes"
        ++ lib.optional (k.childPolicy != null) "regiment ${regName}: ${kind}.childPolicy"
      ) reg.kinds
    );

  render =
    roster: regiments:
    let
      seats = lib.concatLists (
        lib.mapAttrsToList (
          regName: reg:
          lib.mapAttrsToList (seat: s: {
            inherit
              regName
              reg
              seat
              s
              ;
          }) reg.seats
        ) regiments
      );
      seatNames = map (x: x.seat) seats;
      clashes =
        map (n: "regiment seat '${n}' is already a declared role") (
          builtins.filter (n: roster ? ${n}) seatNames
        )
        ++ map (n: "regiment seat '${n}' is declared by more than one regiment") (
          lib.unique (builtins.filter (n: lib.count (x: x == n) seatNames > 1) seatNames)
        );
      known = roster // lib.genAttrs seatNames (_: { });
      errs = lib.concatLists (lib.mapAttrsToList (validateRegiment known) regiments);
      all = errs ++ clashes;
    in
    if all != [ ] then
      throw ("charter figaro regiments invalid:\n  " + lib.concatStringsSep "\n  " all)
    else
      {
        roster = builtins.listToAttrs (
          map (x: lib.nameValuePair x.seat (seatRole x.regName x.reg x.seat x.s)) seats
        );
        outfits = lib.foldl' (acc: regName: acc // renderOutfits regName regiments.${regName}) { } (
          builtins.attrNames regiments
        );
        inert = lib.concatLists (lib.mapAttrsToList inertFields regiments);
      };
in
{
  inherit
    seatKinds
    kinds
    rosterKindOf
    validateRegiment
    render
    holderOutfit
    mintOutfit
    ;
}
