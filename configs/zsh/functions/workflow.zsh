jj-sync-wait() {
  while true; do
    local output
    output=$(jj sync 2>&1)
    if echo "$output" | grep -q "Nothing changed"; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] No changes yet..."
      sleep 5
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Synced!"
      echo "$output"
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

  while true; do
    gh pr merge "$pr_number"
    local state
    state=$(gh pr view "$pr_number" --json state --jq '.state')
    if [[ "$state" == "MERGED" ]]; then
      break
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Not mergeable yet..."
    sleep 30
  done
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Merged!"
}
