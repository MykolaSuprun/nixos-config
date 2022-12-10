# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  unstable = import <nixos-unstable> {config = {allowUnfree = true;};};
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-unstable";
  };
 
  # nix settings`
  nix =  {
    # settings.experimental-features = [ "nix-command" "flakes" ];
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };

  #Enable flatpak
  services.flatpak.enable = true;
  # xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-kde];
  xdg.portal.enable = true;

  # backup system configuration 
  system.copySystemConfiguration = true;

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.useOSProber = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  
  # Linux kernel
    # boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Nvidia drivers
  services.xserver.videoDrivers = ["nvidia"];
  services.xmr-stak.cudaSupport = true;
  

  # hardware settings
  hardware = {
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

    enableAllFirmware = true;

    nvidia.nvidiaSettings = true;

    cpu.amd.updateMicrocode = true; #needs unfree
    opengl = {
      enable = true;
      #Enable other graphical drivers
      driSupport = true;
      driSupport32Bit = true;
      extraPackages32 = with pkgs.pkgsi686Linux; [libva];
      setLdLibraryPath = true;
    };


    bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };

    };
  };

  # Enable Docker 
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    enableNvidia = true;
  };
  # Set up desktop environment
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.plasma5.phononBackend = "vlc";
  services.xserver.desktopManager.plasma5.useQtScaling = true;
  services.xserver.desktopManager.plasma5.runUsingSystemd = true;
  programs.gnupg.agent.pinentryFlavor = "qt";
  # GTK theme fix
  programs.dconf.enable = true;


  networking.hostName = "Geks-Nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Warsaw";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.utf8";
    LC_IDENTIFICATION = "en_IE.utf8";
    LC_MEASUREMENT = "en_IE.utf8";
    LC_MONETARY = "en_IE.utf8";
    LC_NAME = "en_IE.utf8";
    LC_NUMERIC = "en_IE.utf8";
    LC_PAPER = "en_IE.utf8";
    LC_TELEPHONE = "en_IE.utf8";
    LC_TIME = "en_IE.utf8";
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc hangul m17n unikey table-other rime ];
    fcitx5.addons = with pkgs; [ 
      fcitx5-rime 
      fcitx5-gtk 
      libsForQt5.fcitx5-qt 
      fcitx5-with-addons
      fcitx5-chinese-addons
      fcitx5-table-other
      fcitx5-configtool
      fcitx5-hangul
      fcitx5-unikey
      fcitx5-m17n
      fcitx5-mozc
    ];
  };


  # sound settings
  sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;

      config.pipewire = {
        "context.properties" = {
          "link.max-buffers" = 16;
          "log.level" = 2;
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 32;
          "core.daemon" = true;
          "core.name" = "pipewire-0";
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = ["ifexists" "nofail"];
          }
          {name = "libpipewire-module-protocol-native";}
          {name = "libpipewire-module-profiler";}
          {name = "libpipewire-module-metadata";}
          {name = "libpipewire-module-spa-device-factory";}
          {name = "libpipewire-module-spa-node-factory";}
          {name = "libpipewire-module-client-node";}
          {name = "libpipewire-module-client-device";}
          {
            name = "libpipewire-module-portal";
            flags = ["ifexists" "nofail"];
          }
          {
            name = "libpipewire-module-access";
            args = {};
          }
          {name = "libpipewire-module-adapter";}
          {name = "libpipewire-module-link-factory";}
          {name = "libpipewire-module-session-manager";}
        ];
      };

      config.pipewire-pulse = {
        "context.properties" = {
          "log.level" = 2;
        };
        "context.modules" = [
          {
            name = "libpipewire-module-rtkit";
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = ["ifexists" "nofail"];
          }
          {name = "libpipewire-module-protocol-native";}
          {name = "libpipewire-module-client-node";}
          {name = "libpipewire-module-adapter";}
          {name = "libpipewire-module-metadata";}
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              "pulse.min.req" = "32/48000";
              "pulse.default.req" = "32/48000";
              "pulse.max.req" = "32/48000";
              "pulse.min.quantum" = "32/48000";
              "pulse.max.quantum" = "32/48000";
              "server.address" = ["unix:native"];
            };
          }
        ];
        "stream.properties" = {
          "node.latency" = "32/48000";
          "resample.quality" = 1;
        };
      };
    };

    services.pipewire = {
      media-session.config.bluez-monitor.rules = [
        {
          # Matches all cards
          matches = [{"device.name" = "~bluez_card.*";}];
          actions = {
            "update-props" = {
              "bluez5.reconnect-profiles" = ["hfp_hf" "hsp_hs" "a2dp_sink"];
              # mSBC is not expected to work on all headset + adapter combinations.
              "bluez5.msbc-support" = true;
              # SBC-XQ is not expected to work on all headset + adapter combinations.
              "bluez5.sbc-xq-support" = true;
            };
          };
        }
        {
          matches = [
            # Matches all sources
            {"node.name" = "~bluez_input.*";}
            # Matches all outputs
            {"node.name" = "~bluez_output.*";}
          ];
        }
      ];
    };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
   
    # basic packages
    wget
    p7zip
    rar
    xorg.xhost
    distrobox
    ntfs3g
    mpv
    github-desktop
    zsh
    oh-my-zsh
    fzf-zsh

    # python
    python310
    python310Packages.websockets
    python310Packages.pip
    # python310Packages.poetry

    #fcitx
    libsForQt5.fcitx-qt5
    fcitx-configtool
    librime
    libhangul
    rime-data
    vimPlugins.fcitx-vim
    fcitx5-gtk

    # plasma
    libsForQt5.konsole
    libsForQt5.ark

    #graphic, steam, wine libraries
    mesa
    libdrm
    # (steam.override {withJava = true;})
    wine-staging
    wine-wayland
    winetricks
    vulkan-tools
    vulkan-loader
    vulkan-extension-layer
    vkBasalt
    dxvk
    vulkan-headers
    vulkan-validation-layers
    wine64Packages.fonts
    winePackages.fonts
    # lutris
  ];

  # steam
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  #   dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  # };

  # nixpkgs.config.packageOverrides = pkgs: {
  #   steam = pkgs.steam.override {
  #     extraPkgs = pkgs:
  #       with pkgs; [
  #         libgdiplus
  #       ];
  #   };
  # };

  # nixpkgs.overlays = [
  #   (self: super:
  #     { lutris = super.lutris.override { extraLibraries = pkgs: [pkgs.libunwind ]; }; })
  # ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

  # set Neovim as vi and vim
  programs = {
    neovim.enable = true;
    neovim.viAlias = true;
    neovim.vimAlias = true;
    thefuck.enable = true;
  };

  environment.shells = with pkgs; [zsh bashInteractive ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mykolas = {
    isNormalUser = true;
    description = "Mykola Suprun";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [];
  };

  users.extraUsers.mykolas = {
    shell = pkgs.bashInteractive;
  };


  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.mykolas = {pkgs, ...}: {
    home.stateVersion = "22.05";
    home.packages = [
      pkgs.firefox
      pkgs.sublime4
      pkgs.vscode
      pkgs.brave
      pkgs.ledger
      pkgs.oh-my-zsh
      pkgs.megasync
      pkgs.thefuck
      pkgs.neovim
      pkgs.fzf
      pkgs.fzf-zsh
      pkgs.discord
      pkgs.rnix-lsp
      pkgs.vlc
      pkgs.tdesktop
      pkgs.thefuck
      pkgs.libsForQt5.konsole
      pkgs.libsForQt5.yakuake
      pkgs.libsForQt5.qmltermwidget
      pkgs.libsForQt5.qt5.qtwebsockets
      pkgs.qbittorrent
    ];

    programs = {
      git = {
        enable = true;
        userName = "Mykola Suprun";
        userEmail = "mykola.suprun@protonmail.com";
      };

      bash = {
        enableCompletion = true;

        shellAliases = {
          vi = "nvim";
          vim = "nvim";
          nano = "nvim";
          editconf = "sudo subl /etc/nixos/configuration.nix";
          sysbuild = "sudo nixos-rebuild switch";
          sysupgrade = "sudo nixos-rebuild switch --upgrade";
          confdir = "/etc/nixos";

        };

      };

      zsh = {
        enable = true; 

        oh-my-zsh = {
          enable = true;
          theme = "agnoster";
          plugins = [
            "git"
            "cp"
            "thefuck"
            "aliases"
            "branch"
            "cabal"
            "docker"
            "python"
            "scala"
            "sbt"
            "stack"
            "sublime"
            "sudo"
            "systemd"
            "zsh-interactive-cd"
            "vi-mode"
            "archlinux"
          ];
        };

        sessionVariables = {
          GTK_IM_MDOULE = "fcitx5";
          QT_IM_MODULE = "fcitx5";
          XMODIFIERS = "@im=fcitx5";
          GLFW_IM_MODULE = "ibus"; # IME support in kitty
        };

        shellAliases = {
          vi = "nvim";
          vim = "nvim";
          nano = "nvim";
          editconf = "sudo subl /etc/nixos/configuration.nix";
          sysbuild = "sudo nixos-rebuild switch";
          sysupgrade = "sudo nixos-rebuild switch --upgrade";
          confdir = "/etc/nixos";
          nsgc = "nix-collect-garbage";
          arch = "distrobox-enter arch";
        };
      };
    };
  };


  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    inconsolata
  ];
  fonts.fontDir.enable = true;

}

