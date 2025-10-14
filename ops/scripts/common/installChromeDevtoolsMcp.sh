#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Chrome DevTools MCP Server Installer${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script installs Chrome DevTools MCP Server for the current project's Claude Code configuration."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Adds Chrome DevTools MCP Server to the current project only"
  echo "  - Configures it for browser automation and testing"
  echo "  - Does not affect global or other project configurations"
  echo ""
  echo -e "${YELLOW}After installation:${CLEAR}"
  echo "  Chrome DevTools MCP commands will be available in Claude Code"
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

echo -e "${YELLOW}Chrome DevTools MCP Server Installer${CLEAR}"

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
echo -e -n "Do you want to install Chrome DevTools MCP Server to this project? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Installation aborted${CLEAR}"
  exit 0
fi

# detect platform and set Chrome path
echo ""
echo "Installing Chrome DevTools MCP Server to current project..."

# check if macOS
if [[ $OSTYPE == "darwin"* ]]; then
  echo -e "${GREEN}macOS detected:${CLEAR} Using Chrome auto-detection"
  if claude mcp add chrome-devtools npx -- chrome-devtools-mcp@latest --headless --isolated; then
    INSTALL_SUCCESS=true
  else
    INSTALL_SUCCESS=false
  fi
else
  # nix explicitly specify `/opt/google/chrome/chrome`
  CHROME_PATH="/opt/google/chrome/chrome"
  if [ -f "$CHROME_PATH" ]; then
    echo -e "${GREEN}Chrome detected:${CLEAR} $CHROME_PATH"
    if claude mcp add chrome-devtools npx -- chrome-devtools-mcp@latest --headless --isolated --executable-path="$CHROME_PATH"; then
      INSTALL_SUCCESS=true
    else
      INSTALL_SUCCESS=false
    fi
  else
    echo -e "${RED}Error: Chrome not found at $CHROME_PATH${CLEAR}"
    echo "Please ensure Google Chrome is installed via Nix:"
    echo "  Add 'pkgs.google-chrome' to your Nix configuration"
    echo "  Then rebuild your system: nixos-rebuild switch (NixOS)"
    echo "  Or: home-manager switch (Home Manager)"
    exit 1
  fi
fi

# display result
if [ "$INSTALL_SUCCESS" = true ]; then
  echo ""
  echo -e "${GREEN}Chrome DevTools MCP Server has been successfully installed to this project!${CLEAR}"
  echo ""
  echo -e "${YELLOW}Configuration:${CLEAR}"
  echo "  - Mode: Headless + Isolated"
  if [[ $OSTYPE == "darwin"* ]]; then
    echo "  - Platform: macOS"
    echo "  - Chrome executable: Auto-detected"
  else
    echo "  - Platform: Nix/Linux"
    echo "  - Chrome executable: /opt/google/chrome/chrome"
  fi
  echo ""
  echo -e "${YELLOW}Notes:${CLEAR}"
  echo "  - Restart Claude Code for changes to take effect"
  echo "  - This configuration is scoped to the current project only"
  echo "  - Headless mode: Browser runs without UI (recommended)"
  echo "  - Isolated mode: Temporary user-data-dir with auto-cleanup"
  echo ""
  echo -e "${YELLOW}Available features:${CLEAR}"
  echo "  - Browser automation and testing"
  echo "  - Page navigation and interaction"
  echo "  - Network request monitoring"
  echo "  - Performance profiling"
  echo "  - Screenshot and snapshot capture"
else
  echo ""
  echo -e "${RED}Failed to install Chrome DevTools MCP Server.${CLEAR}"
  echo "Please check the error messages above and try again..."
  echo ""
  echo -e "${YELLOW}Troubleshooting:${CLEAR}"
  echo "  - Check Node.js version: node --version (requires v20.19+)"
  echo "  - Verify npx is available: npx --version"
  echo ""
  if [[ $OSTYPE == "darwin"* ]]; then
    echo -e "${YELLOW}macOS installation:${CLEAR}"
    echo "  - Download from: https://www.google.com/chrome/"
    echo "  - Default location: /Applications/Google Chrome.app"
  else
    echo -e "${YELLOW}Nix/Linux installation:${CLEAR}"
    echo "  - Add to configuration: pkgs.google-chrome"
    echo "  - NixOS: nixos-rebuild switch"
    echo "  - Home Manager: home-manager switch"
    echo "  - Expected location: /opt/google/chrome/chrome"
  fi
  exit 1
fi
