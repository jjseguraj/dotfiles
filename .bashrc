# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
# force_color_prompt=yes

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

# Source the git prompt script, if installed, for the prompt to show the
# current branch when the current directory is part of a git project.
if [ -f /usr/share/git/git-prompt.sh ]; then
    . /usr/share/git/git-prompt.sh
fi
green="\[\033[01;32m\]"
reset="\[\033[00m\]"
blue="\[\033[01;34m\]"

if [ "$color_prompt" = yes ]; then
    PS1="[\u@\h$green\$(__git_ps1)$reset: $blue\W$reset]\$ "
else
    PS1="[\u@\h\$(__git_ps1): \W]\$ "
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \W\a\]$PS1"
    ;;
*)
    ;;
esac

# Exports
export GIT_EDITOR=vim

# Alias definitions.
# Put all your additions into separate files in ~/.bash_aliases.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -d ~/.bash_aliases ]; then
    for file in ~/.bash_aliases/*; do
        . $file
    done
fi

# Extra paths.
# Having specific extra paths in a separate file like ~/.bash_extra_paths,
# instead of adding them here directly, helps to share .bashrc between
# different installations, e.g. home and work.
if [ -f ~/.bash_extra_paths ]; then
    . ~/.bash_extra_paths
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

# Allows C-Q to reach Vim
stty -ixon
stty -ixany

# cowsay "hello jose!!!"
