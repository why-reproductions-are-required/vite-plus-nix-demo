{
  description = "Demo: use vite-plus (the `vp` CLI) from nixpkgs via Nix";

  inputs = {
    # vite-plus is not in nixpkgs master yet. This pins the fork branch that
    # adds it (NixOS/nixpkgs#500492 takeover, vite-plus 0.2.1).
    #
    # Once the upstream PR is merged you can drop this and use plain nixpkgs:
    #   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:fengmk2/nixpkgs/vite-plus-init";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # `nix develop` -> a shell with `vp` (and Node.js) on PATH.
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.vite-plus
              pkgs.nodejs
            ];
            shellHook = ''
              # `sed -n 1p` drains all of `vp`'s output; piping to `head -n1`
              # closes the pipe early and makes `vp` panic with EPIPE.
              echo "vite-plus ready: $(vp --version 2>/dev/null | sed -n 1p)"
              echo "Try:  vp --help"
            '';
          };
        }
      );

      # `nix build .#vite-plus` -> the vp CLI in ./result/bin/vp
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.vite-plus;
          vite-plus = pkgs.vite-plus;
        }
      );

      # `nix run` -> runs `vp` directly
      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${(pkgsFor system).vite-plus}/bin/vp";
        };
      });
    };
}
