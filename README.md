# .dotfiles

My configuration files contained in a bare git repo inspired by:

https://www.atlassian.com/git/tutorials/dotfiles

TLDR:

    git init --bare $HOME/.dotfiles
    alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    dotfig config --local status.showUntrackedFiles no

New machine:

    alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    git clone --bare git@github.com:spenserlee/.dotfiles.git $HOME/.dotfiles
    mkdir -p .config-backup && \
        dotfig checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
        xargs -I{} mv {} .config-backup/{}
    dotfig checkout
    dotfig config --local status.showUntrackedFiles no

---

## TODO / NOTES:

* neovim plugins tbd
    * vim-highlighter or vim-marks
    * LSP / DAP
    * treesitter
    * leap
    * whichkey
    * quickfix
    * statusline

* fix git gutter / fugitive not working for bare repo
    * potential leads:
      * <https://github.com/tpope/vim-fugitive/issues/1981#issuecomment-1107388377>
      * <https://stackoverflow.com/a/66624354/5323947>

* try out ZSH

## Installation

This should just be a script, but for now:

* git
```
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install git
git config --global core.editor "nvim"
git config --global commit.verbose true
```
* tmux
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
* fzf
```
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```
* ripgrep
```
curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
sha256sum ripgrep_13.0.0_amd64.deb 
sudo dpkg -i ripgrep_13.0.0_amd64.deb 
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
git checkout stable
sudo apt-get install ninja-build gettext cmake unzip curl
make CMAKE_BUILD_TYPE=RelWithDebInfo
cd build && cpack -G DEB && sudo dpkg -i --force-overwrite nvim-linux64.deb
sudo apt install python3-pip
python3 -m pip install --user --upgrade pynvim
```
