{
  description = "MAINGEAR MG-1 MK.II (X870E) - NixOS, niri + Dux Shell, RTX 50-series";

  inputs = {
    # Tracking nixos-unstable. `nix flake update` moves this forward;
    # flake.lock pins the exact commit so other machines match bit-for-bit.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Declarative disk partitioning, for installing new machines.
    # Follows our nixpkgs so we don't build a second copy of it.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.mg1 = nixpkgs.lib.nixosSystem {
        inherit system;
        # Makes `inputs` available as a module argument, so any module can
        # reference other flake inputs. Without this, modules can only see
        # nixpkgs - which blocks disko, home-manager, and anything else.
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hosts/mg1/hardware-configuration.nix
          ./modules/maintenance.nix
          ./modules/nvidia.nix
          ./modules/desktop.nix
          ./modules/packages.nix
          ./modules/gaming.nix
        ];
      };

      # TEMPLATE for a second machine. Uncomment, rename, and generate
      # hosts/<name>/hardware-configuration.nix on that machine first.
      #
      # nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      #   inherit system;
      #   specialArgs = { inherit inputs; };
      #   modules = [
      #     disko.nixosModules.disko
      #     ./hosts/laptop/disk.nix          # copied from hosts/_template/
      #     ./hosts/laptop/hardware-configuration.nix
      #     ./configuration.nix
      #     ./modules/maintenance.nix
      #     ./modules/desktop.nix
      #     ./modules/packages.nix
      #     # ./modules/nvidia.nix           # only if that machine has an NVIDIA GPU
      #     # ./modules/gaming.nix
      #   ];
      # };
    };
}
