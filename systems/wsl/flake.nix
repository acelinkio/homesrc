{
  description = "WSL Setup";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  inputs.nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.nixoswsl.url = "github:nix-community/NixOS-WSL";
  inputs.nixoswsl.inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.url = "github:nix-community/home-manager/release-25.11";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.vscode-server.url = "github:nix-community/nixos-vscode-server";
  inputs.vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  inputs.krewfile.url = "github:brumhard/krewfile";
  inputs.krewfile.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixoswsl,
      home-manager,
      vscode-server,
      ...
    }@inputs:
    let
      username = "arlan";
      systemname = "wsl";
      stateversion_system = "25.05";
      stateversion_homemanager = "25.05";
      system = "x86_64-linux";
      packs = import nixpkgs { inherit system; };
      packsUnstable = import nixpkgs-unstable { inherit system; };
    in
    {
      nixosConfigurations.${systemname} = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          nixoswsl.nixosModules.wsl
          vscode-server.nixosModules.default
          home-manager.nixosModules.home-manager
          # homemanager inline
          (
            { ... }:
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = {
                imports = [ inputs.krewfile.homeManagerModules.krewfile ];
                home.username = username;
                home.homeDirectory = "/home/${username}";
                home.stateVersion = "${stateversion_homemanager}";
                home.sessionVariables = {
                  SHELL = "/etc/profiles/per-user/${username}/bin/zsh";
                };
                home.packages = [
                  packs.nixfmt-rfc-style # nix formatter
                  packs.nil # nix language server
                  packs.kubectx # kubectx kubens
                  packs.k9s
                  packs.jqp
                  packs.cilium-cli
                  packsUnstable.kubectl
                  packsUnstable.kubernetes-helm
                  packsUnstable.devspace
                  packsUnstable.gh
                  packsUnstable.wslu
                  packsUnstable.hurl
                ];
                home.file = {
                  vscode = {
                    target = ".vscode-server/server-env-setup";
                    text = ''
                      # Make sure that basic commands are available
                      PATH=$PATH:/run/current-system/sw/bin/
                    '';
                  };
                };
                programs.home-manager.enable = true;
                programs.git = {
                  enable = true;
                  settings = {
                    user = {
                      email = "arlanlloyd@gmail.com";
                      name = "Arlan Lloyd";
                    };
                    credential = {
                      helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
                    };
                  };
                  package = packs.git;
                };
                programs.direnv = {
                  enable = true;
                  nix-direnv.enable = true;
                };
                # programs.krewfile = {
                #   enable = true;
                #   krewPackage = packs.krew;
                #   indexes = {
                #     netshoot = "https://github.com/nilic/kubectl-netshoot.git";
                #   };
                #   plugins = [
                #     "browse-pvc"
                #     "pv-migrate"
                #     "stern"
                #     "klock"
                #     "neat"
                #     "oidc-login"
                #     "netshoot/netshoot"
                #     "view-secret"
                #   ];
                # };
                programs.zsh = {
                  enable = true;
                  package = packs.zsh;
                  autocd = true;
                  autosuggestion.enable = true;
                  completionInit = "autoload -U compinit && compinit -i";
                  enableCompletion = true;
                  history.size = 10000;
                  history.save = 10000;
                  history.expireDuplicatesFirst = true;
                  history.ignoreDups = true;
                  history.ignoreSpace = true;
                  historySubstringSearch.enable = true;
                  plugins = [
                    {
                      name = "fast-syntax-highlighting";
                      src = "${packs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
                    }
                  ];
                  shellAliases = {
                    cd_src = "cd ~/source/github.com/acelinkio/homesrc";
                    cd_gh = "cd ~/source/github.com/";
                    ghb = "gh browse";
                    code_src = "code ~/source/github.com/acelinkio/homesrc";
                    code_lab = "code ~/source/github.com/acelinkio/homesrc/workspaces/homelab.code-workspace";
                    cd_nix = "cd ~/source/github.com/acelinkio/homesrc/systems/wsl";
                    apply_nix = "sudo nixos-rebuild switch --flake ~/source/github.com/acelinkio/homesrc/systems/wsl/.#wsl";
                    op_login = "eval $(op signin)";
                  };
                };
                programs.starship = {
                  enable = true;
                  enableTransience = true; # only works with fish, not zsh
                  settings = {
                    aws.disabled = true;
                    hostname.ssh_only = false;
                    os.disabled = false;
                    username.show_always = true;
                  };
                };
              };
            }
          )
          # wsl inline
          (
            { pkgs, ... }:
            {
              wsl = {
                enable = true;
                defaultUser = username;
                wslConf = {
                  interop.appendWindowsPath = true;
                };
              };
            }
          )

          # nixos inline
          (
            { pkgs, ... }:
            {
              system = {
                stateVersion = "${stateversion_system}";
              };
              environment.systemPackages = [
                packs.btop
                packs.htop
                packs.wget
                packs.jq
                packs.yq-go
                packs.dnsutils
                #unfree
                (import nixpkgs {
                  config.allowUnfree = true;
                  inherit system;
                })._1password-cli
              ];
              nix = {
                registry.nixpkgs.flake = inputs.nixpkgs;
                channel.enable = false;
                settings.flake-registry = "";
                settings.experimental-features = [
                  "nix-command"
                  "flakes"
                ];
                gc.automatic = true;
                gc.options = "--delete-older-than 7d";
              };
              programs.zsh.enable = true;
              users.defaultUserShell = packs.zsh;
              environment.pathsToLink = [ "/share/zsh" ];
              environment.shells = [ packs.zsh ];
              networking.hostName = systemname;
              services.pulseaudio.enable = true;
              services.k3s = {
                enable = false;
                role = "server";
                package = (import nixpkgs-unstable { inherit (pkgs) system; }).k3s_1_32;
              };
            }
          )
          # vscode remoting inline
          (
            { pkgs, ... }:
            {
              programs.nix-ld.enable = true;
              services.vscode-server.enable = true;
            }
          )
        ];
      };
    };
}
