with import ./. {};

let ghc = ghcWithPackages
     (hkgs: with hkgs; [ text ]);
in pkgs.stdenv.mkDerivation {
    name = "generate-env";
    buildInputs = [ ghc pkgs.cabal2nix ];
    shellHook = "eval $(egrep ^export ${ghc}/bin/ghc)";
}
