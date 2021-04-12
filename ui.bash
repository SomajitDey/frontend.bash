  #!/usr/bin/env bash
  # A basic UI terminal
  # Display a viewport file that is updated by other process(es)
  # Give user an input prompt and echo everything user types there
  # Relay user input to an inputlog file (which can be a regular file or pipe)
  
  # Ingredients:
  # read -re 2>$tmpfile AND tail -F -n+1 $tmpfile (to echo user input as and when needed)
  # fold -w $WIDTH -s $viewport or fmt for line-wrapping and reformatting the viewport
  # tail and head or awk to print logical lines
  # [[ $viewport nt $chkptfile ]] to know if viewport has been updated lately (requires polling every 1s)
  # Use inotify (requires installation of inotify-tools) or use the rather resource-hungry hence stupid
  # while sleep 1; do currhash="$(sha256sum LICENSE | cut -d ' ' -f 1)"; [[ $currhash != $oldhash ]] && date && oldhash=$currhash; done
  
  export viewport=/tmp/viewport
  export tmpfile=/tmp/input
  export pidfile=/tmp/pid

  prompt(){
    ( echo $BASHPID > $pidfile
      local chkptfile=/tmp/chkpt; touch $chkptfile
      until [[ "$viewport" -nt "$chkptfile" ]]; do sleep 0.1; done
      handler &
    )&
    tail --quiet --f=name --pid=$! $tmpfile 2>/dev/null &
  } 2>/dev/null

  readline(){
    while read -re 2>$tmpfile; do
      [[ -n "$REPLY" ]] && echo "$REPLY" >> $viewport
    done
  }

  handler(){
    tput clear
    cat $viewport
    echo -e \\n
    echo -n "Type here: " 
    prompt
  }
  
  rm -f $tmpfile
  trap 'pkill -KILL --parent $(cat $pidfile); pkill -KILL --pidfile ${pidfile}; tput rmcup' exit
  tput smcup
  handler
  
  readline

  exit
    