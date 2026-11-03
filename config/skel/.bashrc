# KAVYA OS - User Shell Profile (.bashrc)
# Clean, modern terminal prompt with OS learning shortcuts

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Colored Prompt: [kavya@kavya-os ~]$
PS1='\[\033[01;36m\]\u\[\033[00m\]@\[\033[01;34m\]\h\[\033[00m\]:\[\033[01;32m\]\w\[\033[00m\]\$ '

# Color support for ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Standard Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# KAVYA OS Custom Commands
alias info='kinfo'
alias sys='ksys'
alias mem='kmem'
alias health='khealth'
alias schedule='kschedule'
alias ps-tree='kps --tree'
alias ps-zombies='kps --zombies'

# Show system overview on interactive shell start
if [ -t 1 ] && [ -x /usr/local/bin/kinfo ] && [ -z "$KAVYA_GREETED" ]; then
    export KAVYA_GREETED=1
    kinfo
fi
