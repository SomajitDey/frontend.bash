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
  
  viewport=/tmp/viewport
  tmpfile=/tmp/input
  pidfile=/tmp/pid
  echo $$ > $pidfile
  f(){ tail -qF $tmpfile 2>/dev/null & killme=$!;} 2>/dev/null
  trap '(kill -9 $killme); tput reset; cat $viewport; echo -e \\n; f' USR1
  tput smcup
  trap '(kill -9 $killme) 2>/dev/null; tput rmcup' exit
  kill -USR1 $$
  while read -re -p "Type here: " 2>$tmpfile; do
    echo "$REPLY" >> $viewport && kill -USR1 $$
  done
  exit
    