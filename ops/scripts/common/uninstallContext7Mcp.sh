#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Context7 MCP Server Uninstaller${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script removes Context7 MCP Server from the current project's Claude Code configuration."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Removes Context7 MCP Server from the current project only"
  echo "  - Preserves all other MCP server configurations"
  echo "  - Does not affect global or other project configurations"
  echo ""
  exit 0
}

# process command line arguments
for arg in "$@"; do
  case $arg in
  -h | --help)
    show_help
    ;;
  esac
done

echo -e "${YELLOW}Context7 MCP Server Uninstaller${CLEAR}"

# check if claude command is available
if ! command -v claude &>/dev/null; then
  echo -e "${RED}Error: 'claude' command not found.${CLEAR}"
  echo "Please install Claude Code CLI to proceed with uninstallation..."
  exit 1
fi

# check if context7 is installed in current project
if ! claude mcp list | grep -q "context7"; then
  echo -e "${YELLOW}Context7 MCP Server is not installed in this project.${CLEAR}"
  exit 0
fi

# confirm with user
echo -e -n "Do you want to uninstall Context7 MCP Server from this project? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Uninstallation aborted${CLEAR}"
  exit 0
fi

# remove context7 from current project
echo ""
echo "Removing Context7 MCP Server from current project..."
if claude mcp remove context7; then
  echo ""
  echo -e "${GREEN}Context7 MCP Server has been successfully uninstalled from this project!${CLEAR}"
  echo ""
  echo -e "${YELLOW}Note:${CLEAR}"
  echo "  - Restart Claude Code for changes to take effect"
  echo "  - This only removes Context7 MCP from the current project"
else
  echo ""
  echo -e "${RED}Failed to uninstall Context7 MCP Server.${CLEAR}"
  echo "Please check the error messages above and try again..."
  exit 1
fi
