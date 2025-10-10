#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Claude Code Spec-Driven Development Uninstaller${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script removes Claude Code Spec-Driven Development framework from the current directory."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Removes ./CLAUDE.md from the current directory"
  echo "  - Removes ./.claude/commands/kiro/ directory"
  echo "  - Removes ./.kiro/ directory if it exists"
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

echo -e "${YELLOW}Claude Code Spec-Driven Development Uninstaller${CLEAR}"

# check if CLAUDE.md or .claude/commands/kiro exists
if [[ ! -f "./CLAUDE.md" ]] && [[ ! -d "./.claude/commands/kiro" ]]; then
  echo -e "${YELLOW}Claude Code Spec-Driven Development is not installed in this directory.${CLEAR}"
  exit 0
fi

# show what will be removed
echo ""
echo -e "${YELLOW}The following files/directories will be removed:${CLEAR}"
[[ -f "./CLAUDE.md" ]] && echo "  - ./CLAUDE.md"
[[ -d "./.claude/commands/kiro" ]] && echo "  - ./.claude/commands/kiro/"
[[ -d "./.kiro" ]] && echo "  - ./.kiro/ (steering and specs)"
echo ""

# confirm with user
echo -e -n "Do you want to uninstall Claude Code Spec-Driven Development from this directory? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Uninstallation aborted${CLEAR}"
  exit 0
fi

# remove files and directories
echo ""
echo "Removing Claude Code Spec-Driven Development from current directory..."

ERRORS=0

if [[ -f "./CLAUDE.md" ]]; then
  if rm "./CLAUDE.md"; then
    echo "  ✓ Removed ./CLAUDE.md"
  else
    echo -e "  ${RED}✗ Failed to remove ./CLAUDE.md${CLEAR}"
    ERRORS=$((ERRORS + 1))
  fi
fi

if [[ -d "./.claude/commands/kiro" ]]; then
  if rm -rf "./.claude/commands/kiro"; then
    echo "  ✓ Removed ./.claude/commands/kiro/"
  else
    echo -e "  ${RED}✗ Failed to remove ./.claude/commands/kiro/${CLEAR}"
    ERRORS=$((ERRORS + 1))
  fi
fi

if [[ -d "./.kiro" ]]; then
  if rm -rf "./.kiro"; then
    echo "  ✓ Removed ./.kiro/"
  else
    echo -e "  ${RED}✗ Failed to remove ./.kiro/${CLEAR}"
    ERRORS=$((ERRORS + 1))
  fi
fi

echo ""

if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}Claude Code Spec-Driven Development has been successfully uninstalled!${CLEAR}"
else
  echo -e "${RED}Failed to uninstall some components.${CLEAR}"
  echo "Please check the error messages above and try again..."
  exit 1
fi
