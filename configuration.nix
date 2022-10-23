# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: let
  unstable = import <nixos-unstable> {config = {allowUnfree = true;};};
in {
  boot.kernelPackages = pkgs.linuxPackages_zen;

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  system.copySystemConfiguration = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "admin+acme@example.com";
  security.pki.certificateFiles = ["/etc/ssl/certs/"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "nixos"; # Define your hostname.
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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  #Enable flatpak
  services.flatpak.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-kde];
  xdg.portal.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Hardware settings
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
    };
  };

  # Enable sound with pipewire.
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

  # Enable nvidia drivers
  # NVIDIA drivers are unfree.

  services.xserver.videoDrivers = ["nvidia"];

  hardware = {
    enableAllFirmware = true;
    cpu.amd.updateMicrocode = true; #needs unfree

    opengl.enable = true;
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
    #Enable other graphical drivers
    opengl.driSupport = true;
    opengl.driSupport32Bit = true;
    opengl.extraPackages32 = with pkgs.pkgsi686Linux; [libva];
    opengl.setLdLibraryPath = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.

  environment.shells = with pkgs; [zsh];

  users.users.mykolas = {
    isNormalUser = true;
    description = "Mykola Suprun";
    extraGroups = ["networkmanager" "wheel"];
    # packages = with pkgs; [
    #   firefox
    #   pkgs.libsForQt5.yakuake
    #   pkgs.tdesktop
    #   pkgs.megasync
    #   pkgs.thefuck
    # ];
  };

  users.extraUsers.mykolas = {
    shell = pkgs.zsh;
  };

  # home-manager.users.mykolas.nixpkgs.config = import ./nixpkgs-config.nix;
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.users.mykolas = {pkgs, ...}: {
    home.packages = [
      pkgs.firefox
      pkgs.libsForQt5.yakuake
      pkgs.oh-my-zsh
      pkgs.megasync
      pkgs.thefuck
      pkgs.neovim
      pkgs.fzf
      pkgs.fzf-zsh
      pkgs.discord
      pkgs.rnix-lsp
    ];

    programs = {
      git = {
        enable = true;
        userName = "Mykola Suprun";
        userEmail = "mykola.suprun@protonmail.com";
      };

      zsh = {
        enable = true;

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
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
        };
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    pkgs.linuxKernel.kernels.linux_zen
    wget
    gitFull
    pkgs.neovim
    pkgs.vscode
    pkgs.sublime4
    pkgs.libsForQt5.plasma-pa
    pkgs.libsForQt5.bluedevil
    pkgs.libsForQt5.plasma-nm
    pkgs.clinfo
    pkgs.zsh
    pkgs.oh-my-zsh

    pkgs.libsForQt5.sddm-kcm
    wine64Packages.fonts
    winePackages.fonts
    pkgs.docker
    pkgs.cacert
    pkgs.fcitx5-with-addons
    pkgs.fcitx5-gtk
    pkgs.fcitx5-rime
    pkgs.fcitx5-mozc
    pkgs.fcitx5-hangul
    pkgs.fcitx5-m17n
    pkgs.fcitx5-configtool
    pkgs.fcitx5-table-other
    pkgs.libsForQt5.fcitx5-qt
    pkgs.alejandra

    (steam.override {withJava = true;})

    unstable.wineWowPackages.stagingFull
    unstable.winetricks
    unstable.pkgs.vulkan-tools
    unstable.pkgs.vulkan-loader
    unstable.pkgs.vkBasalt
    unstable.pkgs.dxvk
    unstable.pkgs.vulkan-headers
    unstable.pkgs.vulkan-validation-layers
    # unstable.wineWowPackages.waylandFull
    # # support both 32- and 64-bit applications
    # wineWowPackages.stable

    # # support 64-bit only
    # (wine.override { wineBuild = "wine64"; })

    # # wine-staging (version with experimental features)
    # wineWowPackages.staging

    # # winetricks (all versions)
    # winetricks

    # # native wayland support (unstable)
    # wineWowPackages.waylandFull
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          libgdiplus
        ];
    };
  };

  programs.java.enable = true;

  # Enable and configure Zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = ["git" "python" "man"];
    theme = "agnoster";
  };

  programs.zsh.ohMyZsh.customPkgs = [
    pkgs.nix-zsh-completions
    # and even more...
  ];

  # Enable Fcitx support
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-mozc
      fcitx5-hangul
      fcitx5-rime
      fcitx5-table-other
      fcitx5-m17n
    ];
  };

  # i18n.inputMethod = {
  #   enabled = "fcitx5";
  #   fcitx5.addons = with pkgs.fcitx-engines; [ mozc hangul m17n rime table-other];
  # };

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

  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };
}
