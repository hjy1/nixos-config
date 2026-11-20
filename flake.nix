{
  description = "NixOS - niri + Dux Shell. Hosts auto-discovered from ./hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Every directory under ./hosts is a machine, except ones starting
      # with "_" (templates). Adding a machine means creating a directory -
      # this file never needs editing again.
      hostNames = lib.attrNames (
        lib.filterAttrs
          (name: type: type == "directory" && !lib.hasPrefix "_" name)
          (builtins.readDir ./hosts)
      );
    in
    {
      packages.${system}.disko = disko.packages.${system}.disko;

      # CUDA toolchain on demand instead of in the system closure.
      #   nix develop ~/nixos-config#cuda
      # or in a project:  echo 'use flake ~/nixos-config#cuda' > .envrc
      devShells.${system}.cuda =
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        pkgs.mkShell {
          packages = with pkgs; [
            cudaPackages.cudatoolkit
            cudaPackages.cuda_cudart
            cmake
            ninja
            gcc
            uv
            python3
          ];
          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            echo "cuda devshell: $(nvcc --version | tail -1)"
          '';
        };

      nixosConfigurations = lib.genAttrs hostNames (name:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            ./configuration.nix
            ./modules/maintenance.nix
            (./hosts + "/${name}")   # that host's default.nix picks its modules
          ];
        }
      );
    };
}
