#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Claude Code Spec-Driven Development Installer${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script installs Claude Code Spec-Driven Development framework to the current directory."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Runs npx cc-sdd@latest --lang ja"
  echo "  - Generates ./CLAUDE.md in the current directory"
  echo "  - Generates ./.claude/commands/kiro/* in the current directory"
  echo ""
  echo -e "${YELLOW}After installation:${CLEAR}"
  echo "  Spec-driven development commands will be available (/kiro:*)"
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

echo -e "${YELLOW}Claude Code Spec-Driven Development Installer${CLEAR}"

# check if npx command is available
if ! command -v npx &>/dev/null; then
  echo -e "${RED}Error: 'npx' command not found.${CLEAR}"
  echo "Please ensure npm is installed and available in PATH..."
  exit 1
fi

# confirm with user
echo -e -n "Do you want to install Claude Code Spec-Driven Development to the current directory? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Installation aborted${CLEAR}"
  exit 0
fi

# run the installation command
echo ""
echo "Installing Claude Code Spec-Driven Development to current directory..."
if npx cc-sdd@latest --lang ja; then
  echo ""
  echo -e "${GREEN}Claude Code Spec-Driven Development has been successfully installed!${CLEAR}"
  echo ""
  echo -e "${YELLOW}Generated files:${CLEAR}"
  echo "  - ./CLAUDE.md"
  echo "  - ./.claude/commands/kiro/*"
  echo ""
  echo -e "${YELLOW}Available commands:${CLEAR}"
  echo "  - /kiro:steering - Create/update steering documents"
  echo "  - /kiro:spec-init - Initialize a new specification"
  echo "  - /kiro:spec-requirements - Generate requirements"
  echo "  - /kiro:spec-design - Create technical design"
  echo "  - /kiro:spec-tasks - Generate implementation tasks"
  echo "  - /kiro:spec-impl - Execute spec tasks"
  echo "  - /kiro:spec-status - Show specification status"
else
  echo ""
  echo -e "${RED}Failed to install Claude Code Spec-Driven Development.${CLEAR}"
  echo "Please check the error messages above and try again..."
  exit 1
fi
