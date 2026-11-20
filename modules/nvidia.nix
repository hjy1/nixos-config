# NVIDIA + CUDA for the RTX 50-series (Blackwell) card in this box.
#
# Detected hardware:
#   10de:2b85  NVIDIA Blackwell  (was running on nouveau - barely functional)
#   1002:13c0  AMD Raphael iGPU  (what was actually driving your display)
#
# Setting videoDrivers = [ "nvidia" ] makes NixOS blacklist nouveau for you.
{ config, pkgs, lib, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Proton need the 32-bit stack
  };

  hardware.nvidia = {
    # MANDATORY on Blackwell. The old proprietary kernel module does not
    # support 50-series cards - with open = false you get a black screen.
    open = true;

    # Required for Wayland (niri will not start without it).
    modesetting.enable = true;

    nvidiaSettings = true;

    # Desktop with a wall socket: leave suspend/resume power hooks off.
    # They exist for laptops and add failure modes you don't need.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # 615.78.08. The branches available are production/stable (595.112.07)
    # and latest (615.78.08).
    #
    # `latest` is the right pick here specifically BECAUSE of the kernel: this
    # host runs linuxPackages_latest (7.3.x), and the proprietary NVIDIA kernel
    # module has to compile against it. A newer driver branch has seen newer
    # kernels. Pairing the newest kernel with a conservative driver is the
    # combination most likely to fail to build.
    #
    # If you ever drop to the default kernel (6.18.x), `production` becomes the
    # safer choice again - the two settings should move together.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # Load nvidia early so you get KMS from boot rather than a mode switch.
  boot.initrd.kernelModules = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    nvtopPackages.full   # GPU monitor; small, genuinely wants to be global
  ];

  # The CUDA *toolkit* (nvcc, headers, cuda-merged-13.5 - multi-GB) is
  # deliberately NOT here. It would sit in every generation and be retained
  # by GC for 30 days.
  #
  # Note what you still get system-wide: the NVIDIA driver ships libcuda.so,
  # the CUDA *runtime*. So prebuilt CUDA binaries - PyTorch wheels, llama.cpp
  # releases, anything that dlopens libcuda - work fine without the toolkit.
  # Only *compiling* .cu source needs nvcc.
  #
  # For that, use the devShell in this flake:
  #     nix develop ~/nixos-config#cuda
  # or per-project, which is the better habit:
  #     echo 'use flake ~/nixos-config#cuda' > .envrc && direnv allow

  # DELIBERATELY NOT SET:
  #   nixpkgs.config.cudaSupport = true;
  # That flag rebuilds every CUDA-capable package in your closure from
  # source with no binary cache hits - think hours of compiling, including
  # things you never asked for. Set it per-package via .override if some
  # specific package needs CUDA support compiled in.

  # Also deliberately not set globally:
  #   environment.sessionVariables.LIBVA_DRIVER_NAME = "nvidia";
  # You have two GPUs; forcing the VA-API driver system-wide tends to break
  # hardware video decode in browsers rather than fix it. Set it per-app if
  # you need it.
}
