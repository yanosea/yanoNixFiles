jj-fetch-wait() {
  while true; do
    local output
    output=$(jj git fetch 2>&1)
    if echo "$output" | grep -q "Nothing changed"; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] No changes yet..."
      sleep 5
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Updated!"
      echo "$output"
      jj rebase -d main
      break
    fi
  done
}

gh-pr-merge-wait() {
  local pr_number="$1"

  if [[ -z "$pr_number" ]]; then
    echo -n "PR number: "
    read -r pr_number
    if [[ -z "$pr_number" ]]; then
      echo "Error: PR number is required"
      return 1
    fi
  fi

  while ! gh pr merge "$pr_number" 2>/dev/null; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Not mergeable yet..."
    sleep 30
  done
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Merged!"
}
