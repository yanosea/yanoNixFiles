#!/usr/bin/env bash
set -e

# steam workshop wallpapers location
WALLPAPER_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
# process management directory
PID_DIR="$HOME/.local/share/wallpaper-engine"
# default to video-only mode (can be overridden with --all)
INCLUDE_ALL_TYPES=false
# default rotation interval in minutes
DEFAULT_INTERVAL=10
# process startup wait time
STARTUP_WAIT=0.5

# color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # no color

#
# get wallpaper type for display
# returns type string like [Scene], [GIF], [Video-MP4]
#
get_wallpaper_type() {
  local wallpaper_id="$1"
  if [ -f "$WALLPAPER_DIR/$wallpaper_id/scene.pkg" ]; then
    echo "[Scene]"
  elif [ -f "$WALLPAPER_DIR/$wallpaper_id/gifscene.pkg" ]; then
    echo "[GIF]"
  else
    # check for video files
    local video_file=$(find "$WALLPAPER_DIR/$wallpaper_id" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mkv" \) | head -1 2>/dev/null)
    if [ -n "$video_file" ]; then
      local ext=$(echo "$video_file" | sed 's/.*\.//' | tr '[:lower:]' '[:upper:]')
      echo "[Video-$ext]"
    else
      echo "[Unknown]"
    fi
  fi
}

#
# check if wallpaper is a video type
# returns 0 if video, 1 otherwise
#
is_video_wallpaper() {
  local wallpaper_id="$1"
  local video_file=$(find "$WALLPAPER_DIR/$wallpaper_id" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.mkv" \) | head -1 2>/dev/null)
  [ -n "$video_file" ]
}

#
# get filtered wallpapers based on type preference
# returns array of wallpaper IDs
#
get_filtered_wallpapers() {
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo -e "${RED}❌ Error: Wallpaper directory not found: ${CYAN}$WALLPAPER_DIR${NC}"
    return 1
  fi
  # get list of available wallpapers (numeric ids only)
  all_wallpapers=($(ls -1 "$WALLPAPER_DIR" | grep -E '^[0-9]+$' | sort -n))
  # filter wallpapers based on type preference
  wallpapers=()
  for wallpaper_id in "${all_wallpapers[@]}"; do
    if [ "$INCLUDE_ALL_TYPES" = "true" ]; then
      wallpapers+=("$wallpaper_id")
    elif is_video_wallpaper "$wallpaper_id"; then
      wallpapers+=("$wallpaper_id")
    fi
  done
  if [ ${#wallpapers[@]} -eq 0 ]; then
    if [ "$INCLUDE_ALL_TYPES" = "false" ]; then
      echo -e "${RED}❌ Error: No video wallpapers found${NC}"
      echo -e "${BLUE}💡 Tip: Use -a or --all to include all wallpaper types${NC}"
    else
      echo -e "${RED}❌ Error: No wallpapers found${NC}"
    fi
    return 1
  fi
  printf '%s\n' "${wallpapers[@]}"
}

#
# display help message with all available options and subcommands
#
show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS|SUBCOMMAND]

Wallpaper Engine Manager

OPTIONS:
    -a, --all               Include all wallpaper types (default: video only)
    -i, --interactive       Start in interactive selection mode
    -l, --list              List available wallpapers
    -q, --quit              Quit running wallpaper-engine
    -s, --status            Check wallpaper-engine status
    -h, --help              Show this help message

SUBCOMMANDS:
    all                     Include all wallpaper types in selection
    interactive             Start in interactive selection mode
    list                    List available wallpapers
    quit                    Quit running wallpaper-engine
    status                  Check wallpaper-engine status
    help                    Show this help message

Run without arguments to start random mode (rotates every 10 minutes).
Use -i or --interactive for manual wallpaper selection.

FILES:
    PID directory: $PID_DIR
    PID files: wallpaper-<MONITOR>.pid
    Log files: wallpaper-<MONITOR>.log
    Rotation script: wallpaper-rotate.pid
EOF
}

#
# check process status for all monitors
# scans pid files and verifies if processes are actually running
#
check_status() {
  local found_any=false
  # check all pid files for running wallpaper processes
  for pid_file in "$PID_DIR"/wallpaper-*.pid; do
    if [ -f "$pid_file" ]; then
      # extract monitor name from pid filename
      local monitor=$(basename "$pid_file" .pid | sed 's/wallpaper-//')
      local pid=$(cat "$pid_file")
      # verify process is actually running
      if kill -0 "$pid" 2>/dev/null; then
        echo -e "${GREEN}✅ wallpaper-engine is running on ${CYAN}$monitor${NC} ${GRAY}(PID: $pid)${NC}"
        found_any=true
      else
        # clean up stale pid file
        echo -e "${YELLOW}⚡ PID file exists for ${CYAN}$monitor${NC}, but process is not running"
        rm -f "$pid_file"
      fi
    fi
  done
  # report if no processes found
  if [ "$found_any" = false ]; then
    echo -e "${YELLOW}⚡ No wallpaper-engine processes are running${NC}"
    return 1
  fi
  return 0
}

#
# list available wallpapers with type information
# displays wallpaper ids with compatibility indicators
#
list_wallpapers() {
  # check wallpaper directory exists
  if [ ! -d "$WALLPAPER_DIR" ]; then
    echo -e "${RED}❌ Error: Wallpaper directory not found: ${CYAN}$WALLPAPER_DIR${NC}"
    return 1
  fi
  echo -e "${BLUE}📁 Available wallpapers:${NC}"
  # get directory list (numbers only)
  local wallpapers=($(ls -1 "$WALLPAPER_DIR" | grep -E '^[0-9]+$' | sort -n))
  if [ ${#wallpapers[@]} -eq 0 ]; then
    echo -e "  ${GRAY}None${NC}"
    return 1
  fi
  # iterate through wallpapers and show details
  for wallpaper_id in "${wallpapers[@]}"; do
    local project_json="$WALLPAPER_DIR/$wallpaper_id/project.json"
    local title=""
    local description=""
    local type_info=""
    # parse json if available
    if [ -f "$project_json" ]; then
      if command -v jq >/dev/null 2>&1; then
        title=$(jq -r '.title // ""' "$project_json" 2>/dev/null)
        description=$(jq -r '.description // ""' "$project_json" 2>/dev/null)
      else
        # fallback to sed with better regex
        title=$(sed -n 's/.*"title"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$project_json" 2>/dev/null)
        description=$(sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$project_json" 2>/dev/null)
      fi
      type_info=$(get_wallpaper_type "$wallpaper_id")
    fi
    # format output based on available information
    if [ -n "$title" ] && [ -n "$description" ]; then
      echo "  - $title - $description $type_info ($wallpaper_id)"
    elif [ -n "$title" ]; then
      echo "  - $title $type_info ($wallpaper_id)"
    else
      echo "  - $wallpaper_id $type_info"
    fi
  done
}

#
# quit all wallpaper processes
# terminates all running wallpaper-engine processes
#
quit_wallpaper() {
  # stop rotation script if running
  local rotate_pid_file="$PID_DIR/wallpaper-rotate.pid"
  if [ -f "$rotate_pid_file" ]; then
    local rotate_pid=$(cat "$rotate_pid_file")
    if kill -0 "$rotate_pid" 2>/dev/null; then
      echo -e "${BLUE}🔄 Stopping wallpaper rotation...${NC}"
      kill -9 "$rotate_pid" 2>/dev/null || true
      echo -e "${GREEN}✅ Rotation stopped${NC}"
    fi
    rm -f "$rotate_pid_file"
  fi
  # find all running wallpaper processes
  local running_monitors=()
  local running_pids=()
  for pid_file in "$PID_DIR"/wallpaper-*.pid; do
    if [ -f "$pid_file" ]; then
      local monitor=$(basename "$pid_file" .pid | sed 's/wallpaper-//')
      local pid=$(cat "$pid_file")
      # verify process is still running
      if kill -0 "$pid" 2>/dev/null; then
        running_monitors+=("$monitor")
        if [[ ! " ${running_pids[*]} " =~ " $pid " ]]; then
          running_pids+=("$pid")
        fi
      else
        # clean up stale pid file
        rm -f "$pid_file"
      fi
    fi
  done
  # handle case when no tracked processes are running
  if [ ${#running_monitors[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚡ No wallpaper-engine processes are running${NC}"
    # search for untracked processes by name
    local pids=$(pgrep -f "linux-wallpaperengine" 2>/dev/null || true)
    if [ -n "$pids" ]; then
      echo -e "${BLUE}🔍 Found untracked linux-wallpaperengine processes:${NC}"
      ps -p $pids -o pid,cmd --no-headers | while read pid cmd; do
        echo -e "  ${GRAY}PID: $pid${NC}"
      done
      if gum confirm "Quit these processes?"; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        echo -e "${GREEN}✅ Processes terminated${NC}"
      fi
    else
      echo -e "${GRAY}No linux-wallpaperengine processes found${NC}"
    fi
    return 0
  fi
  # show current running wallpapers
  echo -e "${BLUE}🖥️  Terminating wallpapers on all monitors:${NC}"
  for monitor in "${running_monitors[@]}"; do
    local pid_file="$PID_DIR/wallpaper-$monitor.pid"
    local pid=$(cat "$pid_file")
    echo -e "  ${CYAN}$monitor${NC} ${GRAY}(PID: $pid)${NC}"
  done
  echo ""
  # terminate all wallpaper processes
  echo -e "${BLUE}🔄 Terminating all wallpapers...${NC}"
  for pid in "${running_pids[@]}"; do
    kill -9 "$pid" 2>/dev/null || true
  done
  # clean up all pid files
  for monitor in "${running_monitors[@]}"; do
    local pid_file="$PID_DIR/wallpaper-$monitor.pid"
    rm -f "$pid_file"
  done
  echo -e "${GREEN}✅ All wallpapers terminated${NC}"
}

#
# launch wallpaper with specific id on all monitors
# handles process management and error checking
#
launch_wallpaper_with_id() {
  local wallpaper_id="$1"
  local is_random_mode="${2:-false}"
  # get available monitors from hyprctl
  monitors=($(hyprctl monitors | grep -E '^Monitor ' | awk '{print $2}' | sort))
  if [ ${#monitors[@]} -eq 0 ]; then
    echo -e "${RED}❌ Error: No monitors found${NC}"
    return 1
  fi
  # terminate existing wallpapers
  local existing_pids=()
  for monitor in "${monitors[@]}"; do
    local pid_file="$PID_DIR/wallpaper-$monitor.pid"
    if [ -f "$pid_file" ]; then
      local existing_pid=$(cat "$pid_file")
      if kill -0 "$existing_pid" 2>/dev/null; then
        existing_pids+=("$existing_pid")
      fi
      rm -f "$pid_file"
    fi
  done
  # gracefully terminate existing processes with fade effect
  if [ ${#existing_pids[@]} -gt 0 ]; then
    # first send SIGTERM to allow fade effect
    for pid in "${existing_pids[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
    # force kill any remaining processes
    for pid in "${existing_pids[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
      fi
    done
  fi
  # build command with multiple --screen-root options and additional flags
  local cmd_args=("$wallpaper_id" "--fps" "120" "--no-fullscreen-pause" "--silent" "--scaling" "fill")
  for monitor in "${monitors[@]}"; do
    cmd_args+=("--screen-root" "$monitor")
  done
  # prepare log file
  local log_file="$PID_DIR/wallpaper-all.log"
  # launch wallpaper engine in background
  nohup linux-wallpaperengine "${cmd_args[@]}" >"$log_file" 2>&1 &
  wallpaper_pid=$!
  # save pid to files for all monitors
  for monitor in "${monitors[@]}"; do
    local pid_file="$PID_DIR/wallpaper-$monitor.pid"
    echo "$wallpaper_pid" >"$pid_file"
  done
  # wait a moment for process to start
  sleep $STARTUP_WAIT
  # verify process started successfully
  if kill -0 "$wallpaper_pid" 2>/dev/null; then
    if [ "$is_random_mode" = "false" ]; then
      echo -e "${GREEN}✅ wallpaper-engine started successfully on all monitors${NC} ${GRAY}(PID: $wallpaper_pid)${NC}"
      echo -e "${GRAY}📄 Log file: $log_file${NC}"
    fi
    return 0
  else
    # clean up pid files
    for monitor in "${monitors[@]}"; do
      local pid_file="$PID_DIR/wallpaper-$monitor.pid"
      rm -f "$pid_file"
    done
    if [ "$is_random_mode" = "false" ]; then
      echo -e "${RED}❌ Error: Failed to start wallpaper-engine${NC}"
      echo ""
      echo -e "${BLUE}📄 Log output:${NC}"
      tail -n 10 "$log_file" 2>/dev/null || echo -e "${GRAY}No log available${NC}"
      echo ""
      echo -e "${BLUE}🔔 Note: Some wallpaper formats (like GIF) may not be supported by linux-wallpaperengine.${NC}"
      echo -e "    ${GRAY}Try selecting a different wallpaper.${NC}"
    fi
    return 1
  fi
}

#
# launch wallpaper engine interactively
# guides user through wallpaper and monitor selection
#
launch_wallpaper() {
  # create pid directory if it doesn't exist
  mkdir -p "$PID_DIR"
  # get filtered wallpapers
  wallpapers=($(get_filtered_wallpapers))
  if [ $? -ne 0 ]; then
    return 1
  fi
  # prepare wallpaper options with type indicators
  wallpaper_options=()
  declare -A wallpaper_map
  for wallpaper_id in "${wallpapers[@]}"; do
    # determine wallpaper type based on files present
    type_info=$(get_wallpaper_type "$wallpaper_id")
    # create display string and mapping
    local display_string="$wallpaper_id $type_info"
    wallpaper_options+=("$display_string")
    wallpaper_map["$display_string"]="$wallpaper_id"
  done
  # wallpaper selection interface
  echo -e "${BLUE}📁 Select wallpaper:${NC}"
  selected_wallpaper_option=$(printf '%s\n' "${wallpaper_options[@]}" | gum choose --cursor="→ " --header="")
  if [ -z "$selected_wallpaper_option" ]; then
    echo -e "${YELLOW}❌ Cancelled${NC}"
    return 1
  fi
  # extract wallpaper id from selection
  selected_wallpaper="${wallpaper_map["$selected_wallpaper_option"]}"
  echo -e "${GREEN}✅ Selected wallpaper: ${CYAN}$selected_wallpaper${NC}"
  echo
  # get available monitors from hyprctl
  monitors=($(hyprctl monitors | grep -E '^Monitor ' | awk '{print $2}' | sort))
  if [ ${#monitors[@]} -eq 0 ]; then
    echo -e "${RED}❌ Error: No monitors found${NC}"
    return 1
  fi
  echo -e "${BLUE}🖥️  Applying to all monitors: ${CYAN}${monitors[*]}${NC}"
  echo
  # check for existing wallpaper processes
  local existing_processes=()
  for monitor in "${monitors[@]}"; do
    local pid_file="$PID_DIR/wallpaper-$monitor.pid"
    if [ -f "$pid_file" ]; then
      local existing_pid=$(cat "$pid_file")
      if kill -0 "$existing_pid" 2>/dev/null; then
        existing_processes+=("$monitor:$existing_pid")
      else
        # clean up stale pid file
        rm -f "$pid_file"
      fi
    fi
  done
  # handle existing processes
  if [ ${#existing_processes[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚡ Wallpaper-engine is already running on some monitors:${NC}"
    for process in "${existing_processes[@]}"; do
      local monitor=$(echo "$process" | cut -d':' -f1)
      local pid=$(echo "$process" | cut -d':' -f2)
      echo -e "  ${CYAN}$monitor${NC} ${GRAY}(PID: $pid)${NC}"
    done
    if gum confirm "Replace existing wallpapers?"; then
      echo -e "${BLUE}🔄 Terminating existing wallpapers...${NC}"
      for process in "${existing_processes[@]}"; do
        local monitor=$(echo "$process" | cut -d':' -f1)
        local pid=$(echo "$process" | cut -d':' -f2)
        local pid_file="$PID_DIR/wallpaper-$monitor.pid"
        kill -9 "$pid" 2>/dev/null || true
        rm -f "$pid_file"
      done
      echo -e "${GREEN}✅ Existing wallpapers terminated${NC}"
    else
      echo -e "${YELLOW}❌ Cancelled${NC}"
      return 1
    fi
  fi
  # launch wallpaper with selected id
  echo -e "${BLUE}📦 Running in background...${NC}"
  if launch_wallpaper_with_id "$selected_wallpaper" "false"; then
    echo ""
    echo -e "${BLUE}💡 To quit wallpapers, run:${NC}"
    echo -e "   ${GRAY}$(basename "$0") -q${NC}"
    return 0
  else
    return 1
  fi
}

#
# launch random wallpaper with automatic rotation
# rotates wallpaper at specified interval (default 10 minutes)
#
launch_random_wallpaper() {
  # get interval from argument (default value)
  local interval_minutes="${1:-$DEFAULT_INTERVAL}"
  # validate interval is a positive number
  if ! [[ $interval_minutes =~ ^[0-9]+$ ]] || [ "$interval_minutes" -eq 0 ]; then
    echo -e "${RED}❌ Error: Invalid interval. Must be a positive number of minutes${NC}"
    return 1
  fi
  # create pid directory if it doesn't exist
  mkdir -p "$PID_DIR"
  # get filtered wallpapers
  wallpapers=($(get_filtered_wallpapers))
  if [ $? -ne 0 ]; then
    return 1
  fi
  echo -e "${BLUE}🎲 Starting random wallpaper mode...${NC}"
  if [ "$INCLUDE_ALL_TYPES" = "false" ]; then
    echo -e "${GRAY}Using video wallpapers only (${#wallpapers[@]} found)${NC}"
  else
    echo -e "${GRAY}Using all wallpaper types (${#wallpapers[@]} found)${NC}"
  fi
  echo -e "${GRAY}Wallpapers will rotate every ${interval_minutes} minute(s)${NC}"
  echo ""
  # stop existing rotation script if running
  local rotate_pid_file="$PID_DIR/wallpaper-rotate.pid"
  if [ -f "$rotate_pid_file" ]; then
    local old_pid=$(cat "$rotate_pid_file")
    if kill -0 "$old_pid" 2>/dev/null; then
      kill -9 "$old_pid" 2>/dev/null || true
    fi
    rm -f "$rotate_pid_file"
  fi
  # create rotation script
  cat >"$PID_DIR/rotate.sh" <<'ROTATE_SCRIPT'
#!/usr/bin/env bash
# wallpaper rotation script
while true; do
	# get filtered wallpapers
	wallpapers=($("SCRIPT_PATH_PLACEHOLDER" get-wallpapers))
	if [ ${#wallpapers[@]} -eq 0 ]; then
		exit 1
	fi
	# select random wallpaper with infinite retry logic
	retry_count=0
	while true; do
		# select random wallpaper
		random_index=$((RANDOM % ${#wallpapers[@]}))
		selected_wallpaper="${wallpapers[$random_index]}"
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] Trying wallpaper: $selected_wallpaper (attempt $((retry_count + 1)))"
		# launch wallpaper
		"SCRIPT_PATH_PLACEHOLDER" internal-launch "$selected_wallpaper" "true"
		if [ $? -eq 0 ]; then
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully launched wallpaper: $selected_wallpaper"
			break
		else
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to launch wallpaper: $selected_wallpaper, retrying..."
			retry_count=$((retry_count + 1))
		fi
	done
	# wait specified interval before next rotation
	sleep INTERVAL_SECONDS_PLACEHOLDER
done
ROTATE_SCRIPT
  # calculate interval in seconds
  local interval_seconds=$((interval_minutes * 60))
  # replace placeholders in rotation script
  sed -i "s|SCRIPT_PATH_PLACEHOLDER|$(realpath "$0")|g" "$PID_DIR/rotate.sh"
  sed -i "s|INTERVAL_SECONDS_PLACEHOLDER|$interval_seconds|g" "$PID_DIR/rotate.sh"
  chmod +x "$PID_DIR/rotate.sh"
  # start rotation script in background
  nohup "$PID_DIR/rotate.sh" >"$PID_DIR/rotate.log" 2>&1 &
  rotate_pid=$!
  echo "$rotate_pid" >"$rotate_pid_file"
  echo -e "${GREEN}✅ Random wallpaper rotation started${NC} ${GRAY}(PID: $rotate_pid)${NC}"
  echo -e "${GRAY}📄 Rotation log: $PID_DIR/rotate.log${NC}"
  echo ""
  echo -e "${BLUE}💡 To stop wallpapers and rotation:${NC}"
  echo -e "   ${GRAY}$(basename "$0") -q${NC}"
}

#
# internal command to launch wallpaper without output
# used by rotation script
#
internal_launch() {
  local wallpaper_id="$1"
  local is_random="$2"
  launch_wallpaper_with_id "$wallpaper_id" "$is_random"
  return $?
}

#
# parse command line arguments and execute appropriate action
# supports both short and long option formats plus subcommands
#
case "${1:-}" in
-h | --help | help | h)
  show_help
  exit 0
  ;;
-a | --all | all | a)
  # include all wallpaper types
  INCLUDE_ALL_TYPES=true
  shift
  # check if next argument is a subcommand
  case "${1:-}" in
  interactive | i)
    launch_wallpaper
    ;;
  *)
    # default to random mode with all types
    launch_random_wallpaper "${1:-$DEFAULT_INTERVAL}"
    ;;
  esac
  exit $?
  ;;
-i | --interactive | interactive | i)
  # launch interactive mode
  launch_wallpaper
  exit $?
  ;;
-q | --quit | quit | q)
  quit_wallpaper
  exit $?
  ;;
-s | --status | status | s)
  check_status
  exit $?
  ;;
-l | --list | list | l)
  list_wallpapers
  exit $?
  ;;
get-wallpapers)
  # internal command for rotation script
  get_filtered_wallpapers 2>/dev/null
  exit $?
  ;;
internal-launch)
  # internal command for rotation script
  internal_launch "$2" "$3"
  exit $?
  ;;
"")
  # default to random mode when no arguments
  launch_random_wallpaper "$DEFAULT_INTERVAL"
  exit $?
  ;;
*)
  # check if it's a number (minutes for random mode)
  if [[ $1 =~ ^[0-9]+$ ]]; then
    launch_random_wallpaper "$1"
    exit $?
  else
    echo -e "${RED}Unknown option or subcommand: $1${NC}"
    show_help
    exit 1
  fi
  ;;
esac
