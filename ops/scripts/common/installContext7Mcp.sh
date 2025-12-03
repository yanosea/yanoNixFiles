#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Context7 MCP Server Installer${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script installs Context7 MCP Server for the current project's Claude Code configuration."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Adds Context7 MCP Server to the current project only"
  echo "  - Provides up-to-date library documentation in your prompts"
  echo "  - Does not affect global or other project configurations"
  echo ""
  echo -e "${YELLOW}After installation:${CLEAR}"
  echo "  Add 'use context7' to your prompts to fetch latest library docs"
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

echo -e "${YELLOW}Context7 MCP Server Installer${CLEAR}"

# check if claude command is available
if ! command -v claude &>/dev/null; then
  echo -e "${RED}Error: 'claude' command not found.${CLEAR}"
  echo "Please ensure Claude Code is installed and available in PATH..."
  exit 1
fi

# check if npx command is available
if ! command -v npx &>/dev/null; then
  echo -e "${RED}Error: 'npx' command not found.${CLEAR}"
  echo "Please ensure npm is installed and available in PATH..."
  exit 1
fi

# confirm with user
echo -e -n "Do you want to install Context7 MCP Server to this project? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Installation aborted${CLEAR}"
  exit 0
fi

# install context7 mcp server
echo ""
echo "Installing Context7 MCP Server to current project..."

if claude mcp add context7 -- npx -y @upstash/context7-mcp@latest; then
  INSTALL_SUCCESS=true
else
  INSTALL_SUCCESS=false
fi

# display result
if [ "$INSTALL_SUCCESS" = true ]; then
  echo ""
  echo -e "${GREEN}Context7 MCP Server has been successfully installed to this project!${CLEAR}"
  echo ""
  echo -e "${YELLOW}Usage:${CLEAR}"
  echo "  Add 'use context7' to your prompts to fetch latest library documentation"
  echo ""
  echo -e "${YELLOW}Example:${CLEAR}"
  echo "  'use context7 to explain React hooks'"
  echo "  'use context7 for Next.js App Router documentation'"
  echo ""
  echo -e "${YELLOW}Notes:${CLEAR}"
  echo "  - Restart Claude Code for changes to take effect"
  echo "  - This configuration is scoped to the current project only"
  echo "  - Rate limit: 60 requests/hour without API key"
  echo "  - For higher limits, get an API key at https://context7.com/dashboard"
  echo ""
  echo -e "${YELLOW}Available tools:${CLEAR}"
  echo "  - resolve-library-id: Find Context7 library IDs"
  echo "  - get-library-docs: Fetch documentation for a library"
else
  echo ""
  echo -e "${RED}Failed to install Context7 MCP Server.${CLEAR}"
  echo "Please check the error messages above and try again..."
  echo ""
  echo -e "${YELLOW}Troubleshooting:${CLEAR}"
  echo "  - Check Node.js version: node --version (requires v18.0.0+)"
  echo "  - Verify npx is available: npx --version"
  echo "  - Check network connection (Context7 requires internet access)"
  echo ""
  echo -e "${YELLOW}Manual installation:${CLEAR}"
  echo "  claude mcp add context7 -- npx -y @upstash/context7-mcp@latest"
  exit 1
fi
