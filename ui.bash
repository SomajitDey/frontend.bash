  #!/usr/bin/env bash
  # A basic UI terminal that does the following:
  # Display a viewport file (a regular file or sym-link) that is updated by other process(es)
  # Give user an input prompt and echo everything the user types there
  # Output the user-input
  
  # TODO: fold -w $WIDTH -s $viewport or fmt for line-wrapping and reformatting the viewport
  # TODO: tail and head or awk to print logical lines
  
  export viewport="/tmp/viewport.txt"
  export readline_buffer="/tmp/readline_buffer.tmp"
  export this_pid="$$"

  launch_bg(){
    # Launch process that polls viewport for updates and repaints screen if needed
    (
      local chkptfile=/tmp/chkpt; touch "${chkptfile}"
      until [[ "${viewport}" -nt "${chkptfile}" ]] || ! kill -0 "${this_pid}"; do
        sleep 0.5 # Polling interval in seconds
      done
      kill -0 "${this_pid}" 2>/dev/null && repaint &
    )&
    
    # Launch process to echo user-input and the readline prompt
    tail --quiet --f=name --pid="$!" "${readline_buffer}" >/dev/tty 2>/dev/null &
  } 2>/dev/null

  readline(){
    while read -re -p"Type here: " 2>"${readline_buffer}"; do
      rm -f "${readline_buffer}"; touch "${viewport}" # So that there is new prompt immediately
      echo "${REPLY}"
    done
  }

  repaint(){
    tput clear
    cat "${viewport}" <(echo -e \\n)
    launch_bg
  } >/dev/tty
  
  rm -f "${readline_buffer}"
  trap 'tput rmcup' exit
  tput smcup
  repaint
  
  readline

  exit
    