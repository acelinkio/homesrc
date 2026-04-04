# instructions
* install brew
* install brew packages (wip to nix)
```sh
brew install firefox font-monaspace-nerd-font kitty openlens pgadmin4 visual-studio-code git-credential-manager
```

* follow instructions for nix install
* use this flake
```sh
# first config setup
sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --impure --flake ./
# after cloning this repo, can use apply_nix
```


# kube
Colima is being used to run containers locally.  We'll be using that and devspace to develop in.