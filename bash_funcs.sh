#!/bin/bash

# Useful bash functions.

# Starts ssh-agent and stores the SSH_AUTH_SOCK / SSH_AGENT_PID for
# later reuse.
start-ssh-agent() {
  ssh-agent -s > ~/.ssh-agent.conf 2> /dev/null
  source ~/.ssh-agent.conf > /dev/null
}

# Loads SSH identities (starting ssh-agent if necessary), recovering
# from stale sockets.
load-ssh-key() {
  # SSH-agent setup adapted from
  # http://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions.

  # Time a key should be kept, in seconds.
  key_ttl=$((3600*8))
  if [ -f ~/.ssh-agent.conf ] ; then
    # Found previous config, try loading it.
    source ~/.ssh-agent.conf > /dev/null
  	# List all identities the SSH agent knows about.
    ssh-add -l > /dev/null 2>&1
    stat=$?
    # $?=0 means the socket is there and it has a key
    if [ $stat -eq 1 ] ; then
  		# $?=1 means the socket is there but contains no key
      ssh-add -t $key_ttl > /dev/null 2>&1
    elif [ $stat -eq 2 ] ; then
  		# $?=2 means the socket is not there or broken
      rm -f $SSH_AUTH_SOCK
      start-ssh-agent
      ssh-add -t $key_ttl > /dev/null 2>&1
    fi
  else
  	# No existing config.
    start-ssh-agent
    ssh-add -t $key_ttl > /dev/null 2>&1
  fi
}

# Timed GTK dialogs; use like "timer 25m your note here".
timer() {
  local N=$1; shift

  echo "timer set for $N"
  sleep $N && zenity --info --title="Time's Up" --text="${*:-BING}"
}

# Log all commands typed in host-specific file.
function command_log () {
  # Save the rv
  local -i rv="$?"
  # Get the last line local
  last_line="${BASH_COMMAND}"
  local logfile="${HOME}/.shell_logs/${HOSTNAME}"
  local current_ts="$(date '+%Y%m%d %H:%M:%S')"
  if [ "$last_line" != '' ]; then
    echo "${current_ts} ${LOGNAME} Status[${rv}] SPID[${$}] PWD[${PWD}]" \
      \'${last_line#        }\' >> "${logfile}"
  fi
}

# Trap + log commands.
trap command_log DEBUG

alias shlogs="less ${HOME}/.shell_logs/${HOSTNAME}"

load-ssh-key
