  #!/usr/bin/env bash
  # A basic UI terminal that does the following:
  # Display a viewport file (a regular file or sym-link) that is updated by other process(es)
  # Give user an input prompt and echo everything the user types there
  # Commit the user-input to an inputlog (which can be a regular file, sym-link or pipe)
  
  # TODO: fold -w $WIDTH -s $viewport or fmt for line-wrapping and reformatting the viewport
  # TODO: tail and head or awk to print logical lines
  
  export viewport="/tmp/viewport.txt"
  export inputlog="/tmp/input.log"
  export input_buffer="/tmp/input.tmp"
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
    tail --quiet --f=name --pid="$!" "${input_buffer}" 2>/dev/null &
  } 2>/dev/null

  readline(){
    while read -re 2> "${input_buffer}"; do
      rm -f "${input_buffer}"; touch "${viewport}" # So that there is new prompt immediately
      [[ -n "${REPLY}" ]] && echo "${REPLY}" >> "${inputlog}"
    done
  }

  repaint(){
    tput clear
    cat "${viewport}"
    echo -e \\n
    echo -n "Type here: " 
    launch_bg
  }
  
  rm -f "${input_buffer}"
  trap 'tput rmcup' exit
  tput smcup
  repaint
  
  readline

  exit
    