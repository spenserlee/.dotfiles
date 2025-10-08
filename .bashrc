# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# fix UTF8 characters in tmux?
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# TODO; branch out dotfiles for work PC?
export USESUDO=/usr/bin/sudo
export FORTIPKG=/home/slee01/fortipkg

# dotfiles config git management
alias dotfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# maintain git completion for dotfile config alias
source /usr/share/bash-completion/completions/git
__git_complete dotfig __git_main

alias windir="cd /mnt/c/Users/Spenser"
alias vim='nvim'
alias vi='nvim'
alias v='nvim'

alias fgvm="sudo ip netns exec kvm_ns1"
alias fgvm2="sudo ip netns exec kvm_ns2"

export VISUAL=nvim
export EDITOR="$VISUAL"

export MANPAGER='nvim +Man!'

export FZF_DEFAULT_OPTS='--height 60% --border --reverse'
export FZF_DEFAULT_COMMAND="rg --files --hidden --smart-case -g '!{.git,.svn}'"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

export RIPGREP_CONFIG_PATH=/home/slee01/.ripgreprc

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

function we_are_in_git_work_tree {
    git rev-parse --is-inside-work-tree &> /dev/null
}

function parse_git_branch {
    if we_are_in_git_work_tree
    then
        local BR=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD 2> /dev/null)
        if [ "$BR" == HEAD ]
        then
            # revision isn't a named branch, try to get tag name
            local NM=$(git name-rev --name-only HEAD 2> /dev/null)
            # revision isn't a tag, use shortened hash
            if [ "$NM" != undefined ]
            then echo -n "@$NM"
            else git rev-parse --short HEAD 2> /dev/null
            fi
        else
            echo -n $BR
        fi
    fi
}

function set_prompt {
    local top_connect=$'\\[\\e[m\\]'"┌"
    # local time="[\[\e[34m\]\T\[\e[m\]]─"   # Time in 12-hour format HH:MM:SS
    local time="[\[\e[34m\]\t\[\e[m\]]─"   # Time in 24-hour format HH:MM:SS
    local user="\[\e[36m\]\u"
    local at="\[\e[m\]@"
    local host="\[\e[32m\]`hostname | cut -d "-" -f 3`\[\e[m\]:"
    local dir="\[\e[33m\]\w"
    local git_color="\[\033[31m\]"
    local git_branch='(`parse_git_branch`)'
    local git_diff='`git rev-parse 2>/dev/null && (git diff --no-ext-diff --quiet --exit-code 2> /dev/null || echo -e \*)`'
    local bot_connect=$'\\[\\e[m\\]\n'"└"
    # local prompt="λ"
    # local prompt="»"
    # local prompt="➤"
    # local prompt="∙"
    # local prompt="➜"
    # local prompt="✦"
    local prompt="❱"
    # local prompt="▶"
    # local prompt="↠"
    local top_connect=$'\\[\\e[m\\]'"┏"
    local bot_connect=$'\\[\\e[m\\]\n'"┗"

    if [ -z "$time_prompt" ] || [ $time_prompt -eq 0 ]; then
        time_prompt=0
        export PS1="$top_connect$user$at$host$dir$git_color$git_branch$git_diff$bot_connect$prompt "
    else
        export PS1="$top_connect$time$user$at$host$dir$git_color$git_branch$git_diff$bot_connect$prompt "
    fi
}

function toggle_time_prompt {
    if [ $time_prompt -eq 0 ]; then
        time_prompt=1
    else
        time_prompt=0
    fi
    set_prompt
}

set_prompt

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
# export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history
# Don't forget to initialize with old history:
# cat ~/.bash_history >>~/.bash_eternal_history

# Force prompt to write history after every command.
# http://superuser.com/questions/20900/bash-history-loss
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
. "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
