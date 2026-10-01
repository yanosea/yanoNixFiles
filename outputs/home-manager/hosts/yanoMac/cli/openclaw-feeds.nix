# home openclaw-feeds module (the news: what openclaw reads from outside)
{
  lib,
  pkgs,
  ...
}:
let
  # the per-run core, spliced in once FEEDS_DIR is set.
  # each section is appended to a temp file that replaces latest.md at the
  # end, so openclaw never reads a half-written one. a failing source leaves
  # its part as the config's failText instead of aborting the run
  feedsLib = ''
    # 1 skips the grok parts (for tests)
    : "''${FEEDS_SKIP_GROK:=}"
    # seconds per grok call
    FEEDS_GROK_TIMEOUT="''${FEEDS_GROK_TIMEOUT:-900}"
    # grok hooks see this and do nothing (no repo edits, no injected triage)
    export OPENCLAW_FEEDS=1
    mkdir -p "$FEEDS_DIR"
    stamp=$(date +%Y-%m-%d-%H)
    tmp=$(mktemp "$FEEDS_DIR/.latest.XXXXXX")
    # grok part bodies and cwds
    work=$(mktemp -d)
    trap 'rm -rf "$tmp" "$work"' EXIT
    # on INT/TERM take the grok jobs down too, then exit through EXIT
    trap 'trap "" INT TERM; kill 0; exit 143' INT TERM
    # section <heading> <body>
    section() {
      printf '\n## %s\n%s\n' "$1" "$2" >>"$tmp"
    }
    # ask_grok <prompt> <cwd>: grok's answer, shaped by the config's
    # grokFilterFile (which errors on an answer it rejects), or the bare
    # answer when there is none
    ask_grok() {
      # --foreground keeps grok in our process group so kill 0 reaches it.
      # it only times out grok itself, so write to a file rather than a
      # pipe a leftover child could hold open. the fast model at low effort
      # returns the same links in a fraction of the time and usage of the
      # xhigh default, and matches what the agents use in chat
      local rc=0
      timeout --foreground -k 30 "$FEEDS_GROK_TIMEOUT" grok -p "$1" --model grok-4.7-build-fast --reasoning-effort low --output-format json --cwd "$2" </dev/null >"$2.json" || rc=$?
      # one line per call (retries too) so the usage of a run can be summed:
      # time, run, exit code, cost in USD, total tokens
      jq -rn --arg t "$(date '+%F %T')" --arg run "$stamp" --arg rc "$rc" '
        (try input catch {}) as $j
        | [$t, $run, $rc, ($j.total_cost_usd // "-"), ($j.usage.total_tokens // "-")]
        | @tsv' "$2.json" >>"$FEEDS_DIR/grok-usage.tsv" 2>/dev/null || true
      [ "$rc" -eq 0 ] || return "$rc"
      if [ -n "$grok_filter" ]; then
        jq -er -f "$grok_filter" "$2.json"
      else
        jq -er '.text // "" | if length == 0 then error("empty answer") else . end' "$2.json"
      fi
    }
    # grok_body <prompt>: the part body, failText on any error
    grok_body() {
      local start=$SECONDS cwd body="" rc attempt
      # bad answers come back fast: try up to 3 times, a new try only
      # within 5 minutes and if it still ends by 1200 s. never after a timeout
      for attempt in 1 2 3; do
        # its own empty cwd so grok reads no unrelated files
        cwd=$(mktemp -d "$work/cwd.$attempt.XXXXXX")
        rc=0
        body=$(ask_grok "$1" "$cwd" 2>/dev/null) || rc=$?
        if [ "$rc" -eq 0 ] || [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ] ||
          [ $((SECONDS - start)) -ge 300 ] ||
          [ $((SECONDS - start + FEEDS_GROK_TIMEOUT)) -gt 1200 ]; then
          break
        fi
      done
      [ "$rc" -eq 0 ] || body=$fail_text
      printf '%s\n' "$body"
    }
    # finish_feeds: publish the temp file and keep two days of snapshots
    finish_feeds() {
      cp "$tmp" "$FEEDS_DIR/$stamp.md"
      mv "$tmp" "$FEEDS_DIR/latest.md"
      find "$FEEDS_DIR" -maxdepth 1 -name '20*-*.md' -mtime +2 -delete
    }
  '';
  # prints one line per problem in the config, so a bad edit stops the run
  # before outDir is touched. slurped so an empty file fails too
  checkConfig = ''
    def kinds: ["grok", "http", "gh-search", "gh-releases"];
    def str: type == "string" and length > 0;
    def strs: type == "array" and length > 0 and all(.[]; str);
    def opt_str($k): if has($k) and (.[$k] | str | not) then "\($k) must be a non-empty string" else empty end;
    def need_str($k): if .[$k] | str then empty else "\($k) is required" end;
    if length != 1 then "the config must be one json object"
    else .[0]
    | if type != "object" then "the config must be a json object"
      else
        need_str("title"),
        need_str("failText"),
        (if (.outDir | str) and (.outDir | startswith("/")) then empty else "outDir must be an absolute path" end),
        opt_str("grokFilterFile"),
        (if (.sections | type) == "array" and (.sections | length) > 0 then
          .sections | to_entries[] | "sections[\(.key)]" as $at | .value
          | if type != "object" then "\($at) must be an object"
            else
              (need_str("heading") | "\($at).\(.)"),
              (if (.parts | type) == "array" and (.parts | length) > 0 then
                .parts | to_entries[] | "\($at).parts[\(.key)]" as $p | .value
                | if type != "object" then "\($p) must be an object"
                  elif (.kind as $k | kinds | index($k)) == null then "\($p).kind must be one of \(kinds | join(", "))"
                  else
                    (opt_str("subheading") | "\($p).\(.)"),
                    (if .kind == "grok" then
                      (need_str("promptFile") | "\($p).\(.)")
                    elif .kind == "http" then
                      (need_str("url") | "\($p).\(.)"),
                      (if has("format") and (.format | IN("json", "xml") | not) then "\($p).format must be json or xml" else empty end),
                      (if has("filter") == has("filterFile") then "\($p): give exactly one of filter and filterFile" else empty end),
                      (opt_str("filter"), opt_str("filterFile") | "\($p).\(.)")
                    elif .kind == "gh-search" then
                      (if .queries | strs then empty else "\($p).queries must be a non-empty list of strings" end),
                      (if (.perQuery | type) == "number" and .perQuery >= 1 then empty else "\($p).perQuery must be a positive number" end),
                      (need_str("line") | "\($p).\(.)")
                    else
                      (if .repos | strs then empty else "\($p).repos must be a non-empty list of owner/name" end),
                      (need_str("line"), need_str("emptyText"), opt_str("select") | "\($p).\(.)")
                    end)
                  end
              else "\($at).parts must be a non-empty list" end)
            end
        else "sections must be a non-empty list" end)
      end
    end
  '';
  openclaw-feeds = pkgs.writeShellApplication {
    name = "openclaw-feeds";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.gh
      pkgs.grok-build
      pkgs.jq
      pkgs.yq-go
    ];
    # everything about what is fetched and how it reads (sources, queries,
    # filters, headings, wording) lives in the config and the files it
    # names, all in the private workspace; this public command only knows
    # four generic kinds of part
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: openclaw-feeds <config.json>" >&2
        exit 2
      fi
      config=$1
      if [ ! -f "$config" ]; then
        echo "openclaw-feeds: $config: no such file" >&2
        exit 2
      fi
      if ! problems=$(jq -rs ${lib.escapeShellArg checkConfig} "$config" 2>&1); then
        printf 'openclaw-feeds: %s is not readable json: %s\n' "$config" "$problems" >&2
        exit 2
      fi
      if [ -n "$problems" ]; then
        while IFS= read -r problem; do
          printf 'openclaw-feeds: %s: %s\n' "$config" "$problem" >&2
        done <<<"$problems"
        exit 2
      fi
      # a file the config names is relative to the config's directory unless
      # absolute. checked here too, so a missing file stops the run before
      # outDir
      config_dir=$(dirname -- "$config")
      # rel_path <path>: its path
      rel_path() {
        case "$1" in
          /*) printf '%s\n' "$1" ;;
          *) printf '%s\n' "$config_dir/$1" ;;
        esac
      }
      problems=""
      while IFS=$'\t' read -r at file; do
        [ -n "$at" ] || continue
        path=$(rel_path "$file")
        if [ ! -f "$path" ] || [ ! -r "$path" ]; then
          problems+="$at: $path: no such file"$'\n'
        elif [ ! -s "$path" ]; then
          problems+="$at: $path is empty"$'\n'
        fi
      done < <(jq -r '
        (.grokFilterFile // empty | "grokFilterFile\t\(.)"),
        (.sections | to_entries[] | .key as $i | .value.parts | to_entries[] | .key as $j | .value
          | (.promptFile // empty | "sections[\($i)].parts[\($j)].promptFile\t\(.)"),
            (.filterFile // empty | "sections[\($i)].parts[\($j)].filterFile\t\(.)"))' "$config")
      if [ -n "$problems" ]; then
        while IFS= read -r problem; do
          [ -z "$problem" ] || printf 'openclaw-feeds: %s: %s\n' "$config" "$problem" >&2
        done <<<"$problems"
        exit 2
      fi
      FEEDS_DIR=$(jq -r .outDir "$config")
      fail_text=$(jq -r .failText "$config")
      grok_filter=$(jq -r '.grokFilterFile // ""' "$config")
      [ -z "$grok_filter" ] || grok_filter=$(rel_path "$grok_filter")
      ${feedsLib}
      printf '# %s %s\n' "$(jq -r .title "$config")" "$(date '+%Y-%m-%d %H:%M')" >"$tmp"
      # config values go from jq straight into variables and are never
      # re-parsed by the shell, so quotes, $ and newlines are safe
      nsec=$(jq '.sections | length' "$config")
      # nparts <i>: how many parts section i has
      nparts() {
        jq --argjson i "$1" '.sections[$i].parts | length' "$config"
      }
      # part <i> <j> <jq path>: a value of part j of section i
      part() {
        jq -r --argjson i "$1" --argjson j "$2" ".sections[\$i].parts[\$j]$3" "$config"
      }
      # the grok calls run in the background while the other parts are read
      for ((i = 0; i < nsec; i++)); do
        n=$(nparts "$i")
        for ((j = 0; j < n; j++)); do
          if [ "$(part "$i" "$j" .kind)" = grok ]; then
            if [ -n "$FEEDS_SKIP_GROK" ]; then
              echo "skipped (FEEDS_SKIP_GROK)" >"$work/grok.$i.$j"
            else
              grok_body "$(cat -- "$(rel_path "$(part "$i" "$j" .promptFile)")")" >"$work/grok.$i.$j" &
            fi
          fi
        done
      done
      # with_dates <text>: each {daysAgo:N} becomes the date N days ago
      with_dates() {
        local text=$1 n
        while [[ $text =~ \{daysAgo:([0-9]+)\} ]]; do
          n=''${BASH_REMATCH[1]}
          text=''${text//"{daysAgo:$n}"/"$(date -d "$n days ago" +%Y-%m-%d)"}
        done
        printf '%s' "$text"
      }
      # releases since the last successful run (a day on the first run).
      # the new mark is taken before asking so a release made meanwhile is
      # seen next time, and written only once latest.md is in place
      since=$(cat "$FEEDS_DIR/.releases-since" 2>/dev/null) || since=""
      [ -n "$since" ] || since=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
      releases_mark=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      releases_seen=0
      # fetch <i> <j>: sets out to the body of a non-grok part. runs in this
      # shell so gh-releases can clear the mark
      fetch() {
        local filter_file format line found failed ok q repo
        local -a filter repos queries
        case "$(part "$1" "$2" .kind)" in
          http)
            # failText when the source is down or the filter finds nothing
            # (jq -e fails on no output)
            filter_file=$(part "$1" "$2" '.filterFile // ""')
            if [ -n "$filter_file" ]; then
              filter=(-f "$(rel_path "$filter_file")")
            else
              filter=("$(part "$1" "$2" .filter)")
            fi
            format=$(part "$1" "$2" '.format // "json"')
            if [ "$format" = xml ]; then
              out=$(curl -fsS --max-time 30 "$(part "$1" "$2" .url)" 2>/dev/null | yq -p xml -o json 2>/dev/null | jq -er "''${filter[@]}" 2>/dev/null) || out=$fail_text
            else
              out=$(curl -fsS --max-time 30 "$(part "$1" "$2" .url)" 2>/dev/null | jq -er "''${filter[@]}" 2>/dev/null) || out=$fail_text
            fi
            ;;
          gh-search)
            # repos matching any query, each once, most stars first
            line=$(part "$1" "$2" .line)
            found="" failed=""
            mapfile -t queries < <(part "$1" "$2" '.queries[]')
            for q in "''${queries[@]}"; do
              q=$(with_dates "$q")
              if out=$(gh api -X GET search/repositories -f q="$q" -f sort=stars -f per_page="$(part "$1" "$2" .perQuery)" 2>/dev/null | jq -ec '.items[]' 2>/dev/null); then
                found+="$out"$'\n'
              else
                failed+="- $q $fail_text"$'\n'
              fi
            done
            if [ -z "$found" ]; then
              out=$fail_text
            else
              out=$(printf '%s' "$found" | jq -rs "unique_by(.full_name) | sort_by(-.stargazers_count) | .[] | $line")
              [ -z "$failed" ] || out=$(printf '%s\n%s' "$out" "$failed")
            fi
            ;;
          gh-releases)
            releases_seen=1
            line=$(part "$1" "$2" .line)
            found="" failed="" ok=0
            mapfile -t repos < <(part "$1" "$2" '.repos[]')
            for repo in "''${repos[@]}"; do
              # no output is fine here (nothing new), so no jq -e
              if out=$(gh api "repos/$repo/releases?per_page=5" 2>/dev/null | jq -r --arg since "$since" --arg repo "$repo" '
                if type == "array" then . else error("not a list") end
                | .[] | select(.published_at != null and .published_at > $since)
                | select('"$(part "$1" "$2" '.select // "true"')"') | '"$line" 2>/dev/null); then
                ok=$((ok + 1))
                [ -z "$out" ] || found+="$out"$'\n'
              else
                failed+="- $repo $fail_text"$'\n'
              fi
            done
            if [ "$ok" -eq 0 ]; then
              found=$fail_text
              # keep the old mark so the next run asks again
              releases_mark=""
            else
              [ -n "$found" ] || found="$(part "$1" "$2" .emptyText)"$'\n'
              found+="$failed"
            fi
            # drop the trailing newline
            out=$(printf '%s' "$found")
            ;;
        esac
      }
      declare -A bodies=()
      for ((i = 0; i < nsec; i++)); do
        n=$(nparts "$i")
        for ((j = 0; j < n; j++)); do
          # a grok body is read once its call is done
          if [ "$(part "$i" "$j" .kind)" != grok ]; then
            out=""
            fetch "$i" "$j"
            bodies["$i.$j"]=$out
          fi
        done
      done
      wait
      for ((i = 0; i < nsec; i++)); do
        n=$(nparts "$i")
        body=""
        for ((j = 0; j < n; j++)); do
          if [ "$(part "$i" "$j" .kind)" = grok ]; then
            out=$(cat "$work/grok.$i.$j" 2>/dev/null) || out=""
            out=''${out:-$fail_text}
          else
            out=''${bodies["$i.$j"]}
          fi
          sub=$(part "$i" "$j" '.subheading // ""')
          [ -z "$sub" ] || out="### $sub"$'\n'"$out"
          body+="''${body:+$'\n\n'}$out"
        done
        section "$(jq -r --argjson i "$i" '.sections[$i].heading' "$config")" "$body"
      done
      finish_feeds
      if [ "$releases_seen" -eq 1 ] && [ -n "$releases_mark" ]; then
        printf '%s\n' "$releases_mark" >"$FEEDS_DIR/.releases-since"
      fi
    '';
  };
in
{
  # openclaw.nix runs it from the gateway's scheduled jobs
  _module.args.openclawFeeds = openclaw-feeds;
  # home
  home = {
    packages = [
      openclaw-feeds
    ];
  };
}
