# instructions
* install brew
* 
```sh
brew install firefox font-monaspace-nerd-font kitty openlens pgadmin4 visual-studio-code
```

* follow instructions for nix install
* use this flake
```sh
# last config setup
sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --impure --flake ./
# after cloning this repo, can use apply_nix
```
* note that some reason the nix git-credential manager does not function correctly, rely upon brew's install