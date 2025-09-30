#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Serena MCP Server Installer${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script installs Serena MCP Server for the current project's Claude Code configuration."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Adds Serena MCP Server to the current project only"
  echo "  - Configures it with IDE assistant context and project path"
  echo "  - Does not affect global or other project configurations"
  echo ""
  echo -e "${YELLOW}After installation:${CLEAR}"
  echo "  Run ${GREEN}/mcp__serena__initial_instructions${CLEAR} in Claude Code to get started"
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

echo -e "${YELLOW}Serena MCP Server Installer${CLEAR}"

# check if claude command is available
if ! command -v claude &>/dev/null; then
  echo -e "${RED}Error: 'claude' command not found.${CLEAR}"
  echo "Please ensure Claude Code is installed and available in PATH..."
  exit 1
fi

# check if uvx command is available
if ! command -v uvx &>/dev/null; then
  echo -e "${RED}Error: 'uvx' command not found.${CLEAR}"
  echo "Please ensure uv is installed and available in PATH..."
  exit 1
fi

# confirm with user
echo -e -n "Do you want to install Serena MCP Server to this project? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Installation aborted${CLEAR}"
  exit 0
fi

# run the installation command
echo ""
echo "Installing Serena MCP Server to current project..."
if claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project "$(pwd)"; then
  echo ""
  echo -e "${GREEN}Serena MCP Server has been successfully installed to this project!${CLEAR}"
  echo ""
  echo -e "${YELLOW}Note:${CLEAR}"
  echo "  - Restart Claude Code for changes to take effect"
  echo "  - This only adds Serena MCP to the current project"
  echo ""
  echo -e "${YELLOW}Next step:${CLEAR}"
  echo -e "  Run ${GREEN}/mcp__serena__initial_instructions${CLEAR} in Claude Code to get started with Serena"
else
  echo ""
  echo -e "${RED}Failed to install Serena MCP Server.${CLEAR}"
  echo "Please check the error messages above and try again..."
  exit 1
fi
