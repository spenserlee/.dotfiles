# .dotfiles

Configuration files for my development environment using neovim and tmux.

![nvim DAP debugging](./.config/dotshowcase/new_preview_01.png?raw=true "Preview nvim DAP")



---

Currently managed in a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles).

TLDR:

    git init --bare $HOME/.dotfiles
    alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    dotfig config --local status.showUntrackedFiles no

---

Setting up a new machine:

    # First install required applications!
    alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    git clone --bare git@github.com:spenserlee/.dotfiles.git $HOME/.dotfiles
    mkdir -p .config-backup && \
        dotfig checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
        xargs -I{} mv {} .config-backup/{}
    dotfig checkout
    dotfig config --local status.showUntrackedFiles no

Due to bare repo, may require explicit git config for new branches:

    $ cat .dotfiles/config
    [core]
            repositoryformatversion = 0
            filemode = true
            bare = true
    [remote "origin"]
            url = git@github.com:spenserlee/.dotfiles.git
            fetch = +refs/heads/*:refs/remotes/origin/*
    [status]
            showUntrackedFiles = no
    [branch "main"]
            remote = origin
            merge = refs/heads/main
    [branch "work"]
            remote = origin
            merge = refs/heads/work

---

## TODO:

* Installation script for the required applications.
* Theme picker for night/day color schemes.
* Verify necessity of luarocks installation.


## Required Applications Setup

* git
```
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install git
git config --global core.editor "nvim"
git config --global commit.verbose true
git config --global alias.hs "log --pretty='%C(Yellow)%h  %C(reset)%ad (%C(Green)%cr%C(reset))%x09 %C(Blue)%an: %C(reset)%s' --date=short"

# setup global pre-commit for nocheckin
# https://gist.github.com/xezrunner/e6dbafcc21fcbc976c93bdee0f371a08
mkdir ~/.git-core-hooks
git config --global core.hooksPath ~/.git-core-hooks
```
* tmux (version 3.2a+ required)
```
sudo apt install libevent-dev
wget https://github.com/tmux/tmux/releases/download/3.2a/tmux-3.2a.tar.gz
tar xf tmux-3.2a.tar.gz
cd tmux-3.2a/
./configure && make
sudo make install
```
* fzf
```
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```
* ripgrep
```
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb
sudo dpkg -i ripgrep_14.1.1-1_amd64.deb
```
* fd
```
sudo apt install fd-find
ln -s $(which fdfind) ~/.local/bin/fd
```
* neovim (build from source, apt is too far behind)
```
sudo apt remove --purge neovim
git clone https://github.com/neovim/neovim
cd neovim/
git checkout v0.10.2
sudo apt-get install ninja-build gettext cmake unzip curl
make CMAKE_BUILD_TYPE=RelWithDebInfo
cd build && cpack -G DEB && sudo dpkg -i --force-overwrite nvim-linux64.deb
sudo apt install python3-pip
python3 -m pip install --user --upgrade pynvim
```
* Dependencies for common language LSP support
```
sudo apt install python3-venv
sudo apt install npm
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
```
* Luarocks
```
# get latest release: http://luarocks.github.io/luarocks/releases
sudo apt install build-essential libreadline-dev unzip


# install latest lua (maybe not necessary...?)
curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
tar zxf lua-5.4.7.tar.gz
cd lua-5.4.7
make linux test
sudo make install
cd ../

# install laurocks
cd luarocks-3.11.1/
./configure --with-lua-include=/usr/local/include
make
sudo make install
sudo apt install lua5.1
```
