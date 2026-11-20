{
  description = "MAINGEAR MG-1 MK.II (X870E) - NixOS, niri + Dux Shell, RTX 50-series";

  inputs = {
    # Tracking nixos-unstable. `nix flake update` moves this forward;
    # flake.lock pins the exact commit so other machines match bit-for-bit.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.mg1 = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hosts/mg1/hardware-configuration.nix
          ./modules/nvidia.nix
          ./modules/desktop.nix
          ./modules/packages.nix
          ./modules/gaming.nix
        ];
      };
    };
}
