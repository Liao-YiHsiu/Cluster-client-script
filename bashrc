# /etc/bashrc

# System wide functions and aliases
# Environment stuff goes in /etc/profile

# It's NOT a good idea to change this file unless you know what you
# are doing. It's much better to create a custom.sh shell script in
# /etc/profile.d/ to make custom changes to your environment, as this
# will prevent the need for merging in future updates.

# are we an interactive shell?
if [ "$PS1" ]; then
  if [ -z "$PROMPT_COMMAND" ]; then
    case $TERM in
    xterm*|vte*)
      if [ -e /etc/sysconfig/bash-prompt-xterm ]; then
          PROMPT_COMMAND=/etc/sysconfig/bash-prompt-xterm
      elif [ "${VTE_VERSION:-0}" -ge 3405 ]; then
          PROMPT_COMMAND="__vte_prompt_command"
      else
          PROMPT_COMMAND='printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
      fi
      ;;
    screen*)
      if [ -e /etc/sysconfig/bash-prompt-screen ]; then
          PROMPT_COMMAND=/etc/sysconfig/bash-prompt-screen
      else
          PROMPT_COMMAND='printf "\033k%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
      fi
      ;;
    *)
      [ -e /etc/sysconfig/bash-prompt-default ] && PROMPT_COMMAND=/etc/sysconfig/bash-prompt-default
      ;;
    esac
  fi
  # Turn on parallel history
  shopt -s histappend
  history -a
  # Turn on checkwinsize
  shopt -s checkwinsize
  [ "$PS1" = "\\s-\\v\\\$ " ] && PS1="[\u@\h \W]\\$ "
  # You might want to have e.g. tty in prompt (e.g. more virtual machines)
  # and console windows
  # If you want to do so, just add e.g.
  # if [ "$PS1" ]; then
  #   PS1="[\u@\h:\l \W]\\$ "
  # fi
  # to your custom modification shell script in /etc/profile.d/ directory
fi

if ! shopt -q login_shell ; then # We're not a login shell
    # Need to redefine pathmunge, it get's undefined at the end of /etc/profile
    pathmunge () {
        case ":${PATH}:" in
            *:"$1":*)
                ;;
            *)
                if [ "$2" = "after" ] ; then
                    PATH=$PATH:$1
                else
                    PATH=$1:$PATH
                fi
        esac
    }

    # By default, we want umask to get set. This sets it for non-login shell.
    # Current threshold for system reserved uid/gids is 200
    # You could check uidgid reservation validity in
    # /usr/share/doc/setup-*/uidgid file
    if [ $UID -gt 199 ] && [ "`id -gn`" = "`id -un`" ]; then
       umask 002
    else
       umask 022
    fi

    SHELL=/bin/bash
    # Only display echos from profile.d scripts if we are no login shell
    # and interactive - otherwise just process them to set envvars
    for i in /etc/profile.d/*.sh; do
        if [ -r "$i" ]; then
            if [ "$PS1" ]; then
                . "$i"
            else
                . "$i" >/dev/null
            fi
        fi
    done

    unset i
    unset -f pathmunge
fi
# vim:ts=4:sw=4
SETUP_ROOT=/home_local/speech/Cluster-client-script/
KALDI_PATH=$SETUP_ROOT/kaldi
PATH=$PATH:$KALDI_PATH/tools/openfst/bin
PATH=$PATH:$KALDI_PATH/tools/irstlm/bin
PATH=$PATH:$KALDI_PATH/src/bin
PATH=$PATH:$KALDI_PATH/src/fstbin
PATH=$PATH:$KALDI_PATH/src/gmmbin
PATH=$PATH:$KALDI_PATH/src/featbin
PATH=$PATH:$KALDI_PATH/src/lm
PATH=$PATH:$KALDI_PATH/src/lmbin
PATH=$PATH:$KALDI_PATH/src/sgmmbin
PATH=$PATH:$KALDI_PATH/src/sgmm2bin
PATH=$PATH:$KALDI_PATH/src/fgmmbin
PATH=$PATH:$KALDI_PATH/src/latbin
PATH=$PATH:$KALDI_PATH/src/nnetbin
PATH=$PATH:$KALDI_PATH/src/nnet2bin
PATH=$PATH:$KALDI_PATH/src/kwsbin
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KALDI_PATH/tools/openfst/lib
PATH=$PATH:/usr/local/cuda-8.0/bin
PATH=$PATH:/usr/local/cuda-7.5/bin
#remember to change to /usr/local/cuda-8.0 
PATH=$PATH:$SETUP_ROOT/libdnn/bin
PATH=$PATH:/usr/local/MATLAB/R2015b/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home_local/speech/Cluster-client-script/opencv-3.1.0/build/lib

# setup caffe
CAFFE=$SETUP_ROOT/caffe
PATH=$PATH:$CAFFE/build/tools
PYTHONPATH=$CAFFE/python:$PYTHONPATH

# setup manual scripts
PATH=$PATH:$SETUP_ROOT/tools

export PATH

# setup opencv
export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python2.7/site-packages/

# setup SRILM
export PATH=$PATH:/share/SRILM/bin/i686-m64-rhel

# make CUDA and nvidia-smi use same GPU ID
export CUDA_DEVICE_ORDER=PCI_BUS_ID

# setup "go"
export PATH=$PATH:/usr/local/go/bin

alias queue_1gpu="queue_battleship.pl --gpu 1 --host-list $HOSTNAME --no-log-file"
alias queue="queue_battleship.pl --no-log-file"

_complete_queue()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--max-jobs-run --gpu --num-threads --host-list --no-log-file "
    #if [[ ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        #return 0
    #fi 
}
complete -F _complete_queue -o bashdefault -o default queue_battleship.pl
