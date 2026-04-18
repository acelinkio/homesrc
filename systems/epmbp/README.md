# instructions
* install brew
* install brew packages
```sh
brew install firefox font-monaspace-nerd-font kitty openlens pgadmin4 visual-studio-code git-credential-manager
```


# nix setup
* follow instructions for nix install
* use this flake
```sh
# first config setup
sudo -H nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --impure --flake ./
# after cloning this repo, can use apply_nix
```

# socket_vmnet install
CANNOT BE INSTALLED VIA BREW
follow install instructions from website. https://lima-vm.io/docs/config/network/vmnet/#socket_vmnet
```sh
VERSION="$(curl -fsSL https://api.github.com/repos/lima-vm/socket_vmnet/releases/latest | jq -r .tag_name)"
FILE="socket_vmnet-${VERSION:1}-$(uname -m).tar.gz"
# Download the binary archive
curl -OSL "https://github.com/lima-vm/socket_vmnet/releases/download/${VERSION}/${FILE}"
# Install /opt/socket_vmnet from the binary archive
sudo tar Cxzvf / "${FILE}" opt/socket_vmnet
```

# colima/kube
Colima is being used to run containers locally.  We'll be using that and devspace to develop in.

## deleting
```sh
#recreate lazy way
colima delete --data -p ai 
# my rerun nix config command
apply_nix
#trigger nix again
launchctl kickstart -k gui/$(id -u)/org.nix-community.home.colima-ai

# otherwise configure the flake
# isService = false
colima delete --data -p ai 
# isService = true
```

## regenerating configurations
```
# by default we changed COLIMA_SAVE_CONFIG=0 in our env configs because nix wants to own files and colima wants to make edits
# temporarily enabling allows colima to regenerate files
COLIMA_SAVE_CONFIG=1 colima start -p ai
```