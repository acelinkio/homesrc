{
  description = "epmbp";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager-unstable.url = "github:nix-community/home-manager/master";
    home-manager-unstable.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nixpkgs-unstable, home-manager, home-manager-unstable }:
  let
    username = "ep";
    stateversion_homemanager = "25.11";
    system = "aarch64-darwin";
    packs = import nixpkgs { inherit system; };
    packsUnstable = import nixpkgs-unstable { inherit system; };
  in
  {
    darwinConfigurations."epmbp" = nix-darwin.lib.darwinSystem {
      modules = [
        # nix-darwin inline
        (
          { ... }: {
          environment.systemPackages =
            [ 
              packs.vim
              packs.btop
              packs.tree
              packs.jq
              packs.yq-go
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
          environment.pathsToLink = [ "/share/zsh" ];
          environment.shells = [ packs.zsh ];
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.primaryUser = username;
          system.stateVersion = 6;
          nixpkgs.hostPlatform = "aarch64-darwin";
          # https://github.com/nix-community/home-manager/issues/4026
          users.users.${username}.home = "/Users/${username}";
          # homebrew - requires homebrew to be installed independently
          # https://brew.sh
          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              upgrade = true;
              # "zap" removes formulae/casks not listed below
              # "uninstall" removes but keeps deps; "none" to skip
              cleanup = "zap";
            };
            # git-credential-manager install is done manually via brew
            # however installation fails because the git config is managed
            # via this flake/nix
            # cli
            brews = [
            ];
            # gui
            casks = [
              "1password"
              "claude-code"
              "discord"
              "firefox"
              "font-monaspice-nerd-font"
              "freelens"
              "kitty"
              "steam"
              "visual-studio-code"
            ];
          };
          }
        )
        # home-manager
        home-manager.darwinModules.home-manager
        # home-manager inline
        (
          { pkgs, ... }:
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = {
              imports = [ (inputs.home-manager-unstable + "/modules/services/colima.nix") ];
              home.username = username;
              home.homeDirectory = "/Users/${username}";
              home.stateVersion = "${stateversion_homemanager}";
              home.sessionVariables = {
                SHELL = "/etc/profiles/per-user/${username}/bin/zsh";
                # prevent colima cli from saving to files
                COLIMA_SAVE_CONFIG = "0";
              };
              home.packages = [
                packs.nixfmt-rfc-style # nix formatter
                packs.nil # nix language server
                packs.kubectx # kubectx kubens
                packs.k9s
                packs.jqp
                packs.hostctl
                # this install is not functional
                # packsUnstable.git-credential-manager
                packsUnstable.kubectl
                packsUnstable.kubernetes-helm
                packsUnstable.helmfile
                packsUnstable.devspace
                packsUnstable.hurl
                packsUnstable.gh
              ];
              home.file = {
                # installed via brew
                # kitten choose-fonts
                kitty = {
                  target = ".config/kitty/kitty.conf";
                  force = true;
                  text = ''
                    font_family      family="MonaspiceKr Nerd Font Mono"
                    bold_font        auto
                    italic_font      auto
                    bold_italic_font auto
                  '';
                };
                kuberc = {
                  target = ".kube/kuberc";
                  force = true;
                  text = ''
                    apiVersion: kubectl.config.k8s.io/v1beta1
                    kind: Preference
                    defaults:
                      - command: apply
                        options:
                          - name: server-side
                            default: "true"
                  '';
                };
              };
              services.colima = {
                enable = true;
                package = packsUnstable.colima;
                profiles = {
                  localdev = {
                    name = "localdev";
                    isActive = true;
                    isService = true;
                    settings = {
                      cpu = 4;
                      memory = 8;
                      disk = 80;
                      runtime = "containerd";
                      kubernetes = {
                        enabled = true;
                        version = "v1.35.3+k3s1";
                        k3sArgs = [
                          "--disable=coredns,flannel,local-storage,metrics-server,servicelb,traefik"
                          "--flannel-backend='none'"
                          "--disable-network-policy"
                          "--disable-cloud-controller"
                          "--disable-kube-proxy"
                          "--node-ip=192.168.64.2"
                        ];
                        port = 6443;
                      };
                      network = {
                        address = true;
                        mode = "shared";
                      };
                    };
                  };
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
                    # some reason the nix based package does not work
                    # using `brew install git-credential-manager`
                    # ignore post install script error if nix-darwin is installed/managing ~/.config/git/config
                    helper = "manager";
                  };
                };
                package = packsUnstable.git;
              };
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
                  cd_nix = "cd ~/source/github.com/acelinkio/homesrc/systems/epmbp";
                  apply_nix = "sudo darwin-rebuild switch --flake ~/source/github.com/acelinkio/homesrc/systems/epmbp";
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
      ];
    };
  };
}
