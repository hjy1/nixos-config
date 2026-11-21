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

            # The directory name IS the hostname. Keeps `nixos-rebuild switch
            # --flake ~/nixos-config` (no #attr) correct on every machine, and
            # makes it impossible for a new host to boot up wearing another
            # machine's name. mkDefault, so a host can disagree if it must.
            { networking.hostName = lib.mkDefault name; }

            # Base layer - unconditional on every host.
            ./configuration.nix
            ./modules/maintenance.nix

            # Feature layer - imported everywhere, so every option below
            # always exists. Each module decides for itself whether to do
            # anything, reading the my.* flags the host sets. A host selects
            # features by setting flags, NOT by curating an import list:
            # curating the list is what let hosts/gear and hosts/_template
            # drift into two different systems.
            ./modules/defaults.nix
            ./modules/desktop.nix
            ./modules/fonts.nix
            ./modules/gaming.nix
            ./modules/nvidia.nix
            ./modules/packages.nix
            ./modules/shell.nix

            # Host layer - hardware, disks, and the flags.
            (./hosts + "/${name}")
          ];
        }
      );
    };
}
