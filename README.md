# .dotfiles

My configuration files contained in a bare git repo inspired by:

https://www.atlassian.com/git/tutorials/dotfiles

TLDR:

	git init --bare $HOME/.dotfiles
	alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
	dotfig config --local status.showUntrackedFiles no

