{
  description = "NixOS - niri + Dux Shell. System in modules/, me in home/, hosts auto-discovered";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Per-user layer, run STANDALONE: `hms` (home-manager switch) applies
    # home/ as the user, no sudo. Follows nixpkgs so there is one package
    # set, not two.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Identity, shared by the system and home-manager. See me.nix.
      me = import ./me.nix;

      # One package set for home-manager and the devShell.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

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
          specialArgs = { inherit inputs me; };
          modules = [
            disko.nixosModules.disko

            # The directory name IS the hostname. Keeps `nixos-rebuild switch
            # --flake ~/nixos-config` (no #attr) correct on every machine, and
            # makes it impossible for a new host to boot up wearing another
            # machine's name. mkDefault, so a host can disagree if it must.
            { networking.hostName = lib.mkDefault name; }

            # Base layer - unconditional on every host.
            ./configuration.nix
            ./modules/user.nix      # the account (identity from me.nix)
            ./modules/maintenance.nix

            # Feature layer - imported everywhere, so every option below
            # always exists. Each module decides for itself whether to do
            # anything, reading the my.* flags the host sets. A host selects
            # features by setting flags, NOT by curating an import list:
            # curating the list is what let hosts/gear and hosts/_template
            # drift into two different systems.
            ./modules/desktop.nix
            ./modules/fonts.nix
            ./modules/gaming.nix
            ./modules/nvidia.nix
            ./modules/packages.nix
            ./modules/shell.nix
            ./modules/tailscale.nix

            # Host layer - hardware, disks, and the flags.
            (./hosts + "/${name}")
          ];
        }
      );

      # Everything that is about ME rather than the machine: shell plugins,
      # prompt, git identity, apps, default apps, dotfile links. Applied as
      # the user, no sudo:
      #   hms   ==  home-manager switch --flake ~/nixos-config
      # home-manager picks this attribute by $USER. Same on every host.
      homeConfigurations.${me.name} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit me; };
        modules = [ ./home ];
      };
    };
}
