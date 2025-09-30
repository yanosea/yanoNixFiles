#!/usr/bin/env bash

# color settings
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CLEAR='\033[0m' # clear color

# function to display help message
show_help() {
  echo -e "${YELLOW}Nix Format Pre-commit Hook Installer${CLEAR}"
  echo ""
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help    Display this help message"
  echo ""
  echo -e "${YELLOW}Description:${CLEAR}"
  echo "  This script installs a pre-commit hook that automatically runs 'nix fmt'"
  echo "  before each commit to ensure consistent code formatting."
  echo ""
  echo -e "${YELLOW}What it does:${CLEAR}"
  echo "  - Runs 'nix fmt' on all files in the repository"
  echo "  - Re-stages only the files that were originally staged"
  echo "  - Prevents commit if nix fmt fails"
  echo ""
  echo -e "Example: ${GREEN}git commit -m \"feat: Add new feature\"${CLEAR} → ${GREEN}automatically formats code before commit${CLEAR}"
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

echo -e "${YELLOW}Nix Format Pre-commit Hook Installer${CLEAR}"

# check if current directory is a Git repository
if [ ! -d ".git" ]; then
  echo -e "${RED}Error: The current directory is not a Git repository.${CLEAR}"
  echo "Please run this script inside a Git repository..."
  exit 1
fi

# check if nix is available
if ! command -v nix &>/dev/null; then
  echo -e "${RED}Error: 'nix' command not found.${CLEAR}"
  echo "Please ensure Nix is installed and available in PATH..."
  exit 1
fi

# confirm with user
echo -e -n "Do you want to install Nix Format Pre-commit Hook to the current repository? [y/N] "
read -r response
if [[ ! $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "${YELLOW}Installation aborted${CLEAR}"
  exit 0
fi

# create pre-commit hook
mkdir -p .git/hooks

cat >.git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash

# get list of staged files before running nix fmt
staged_files=$(git diff --cached --name-only)

# run nix fmt before commit
echo "Running nix fmt..."
if ! nix fmt; then
  echo "nix fmt failed. Please fix formatting issues and try again."
  exit 1
fi

# only re-stage the files that were originally staged
if [ -n "$staged_files" ]; then
  echo "$staged_files" | xargs git add
fi

echo "nix fmt completed successfully."
EOF

# add execution permission
chmod +x .git/hooks/pre-commit

echo ""
echo -e "${GREEN}Nix Format Pre-commit Hook has been successfully installed to the current repository!${CLEAR}"
