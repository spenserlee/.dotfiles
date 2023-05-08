# .dotfiles

My configuration files contained in a bare git repo inspired by:

https://www.atlassian.com/git/tutorials/dotfiles

TLDR:

	git init --bare $HOME/.dotfiles
	alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
	dotfig config --local status.showUntrackedFiles no

---

TODO / NOTES:

* install FZF
* setup neovim config
    * install latest nvim 0.9, apt only offers up to 0.7
    * built from source
        * sudo apt remove neovim
        * git clone https://github.com/neovim/neovim
        * cd neovim/
        * git checkout stable
        * sudo apt-get install ninja-build gettext cmake unzip curl
        * make CMAKE_BUILD_TYPE=RelWithDebInfo
        * cd build && cpack -G DEB && sudo dpkg -i --force-overwrite nvim-linux64.deb
        * sudo apt install python3-pip
        * python3 -m pip install --user --upgrade pynvim
    * init.vim vs init.lua
        * decide to go all in with lua config, seems simple enough
    * similarly, vim-plug vs. packer vs. lazy
        * ok I think I go with lazy
    * nvimpager
* setup basic vim config
    * this would be to set some sane defaults to copy to other machines easily
* try out ZSH
