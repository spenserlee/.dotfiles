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
    dotfig fetch origin '*:*' # fetch remote branches

---

## Installation

This should just be a script, but for now:

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
* Dependencies for common language LSP support
```
sudo apt install python3-venv
sudo apt install npm
curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
```
---

## TODO / NOTES:

* neovim plugins tbd
    * LSP / DAP
    * treesitter
    * whichkey
    * quickfix

* tmux session save/restore

* fix italics not working in tmux
    * <https://old.reddit.com/r/tmux/comments/yd62te/i_really_need_help_with_italic_and_truecolor>

* fix git gutter / fugitive not working for bare repo
    * workaround is to invoke nvim after setting some env vars:
        `GIT_DIR=$HOME/.dotfiles GIT_WORK_TREE=$HOME nvim`
    * similar problem discussed here:
      * <https://github.com/tpope/vim-fugitive/issues/1981#issuecomment-1107388377>
      * <https://stackoverflow.com/a/66624354/5323947>

* try out ZSH

