# Template host. install.sh copies this directory to hosts/<name>/.
#
# Comment out whatever this machine doesn't have. modules/nvidia.nix pulls in
# the CUDA toolkit, which is multi-GB - drop it on anything without an
# NVIDIA GPU.
{
  imports = [
    ./disk.nix
    ./hardware-configuration.nix
    ../../modules/desktop.nix
    ../../modules/packages.nix
    # ../../modules/nvidia.nix
    # ../../modules/gaming.nix
  ];
}
