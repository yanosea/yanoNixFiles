# home openclaw-feeds module (the news: real-world topics openclaw reads)
{
  lib,
  pkgs,
  ...
}:
let
  # the per-run core, spliced in once FEEDS_DIR is set.
  # each section is appended to a temp file that replaces latest.md at the
  # end, so openclaw never reads a half-written one. a failing source leaves
  # its section as 取得失敗 instead of aborting the run
  feedsLib = ''
    # 1 skips the grok sections (for tests)
    : "''${FEEDS_SKIP_GROK:=}"
    # seconds per grok call
    FEEDS_GROK_TIMEOUT="''${FEEDS_GROK_TIMEOUT:-900}"
    # grok hooks see this and do nothing (no repo edits, no injected triage)
    export OPENCLAW_FEEDS=1
    mkdir -p "$FEEDS_DIR"
    stamp=$(date +%Y-%m-%d-%H)
    tmp=$(mktemp "$FEEDS_DIR/.latest.XXXXXX")
    # grok section bodies and cwds
    work=$(mktemp -d)
    trap 'rm -rf "$tmp" "$work"' EXIT
    # on INT/TERM take the grok jobs down too, then exit through EXIT
    trap 'trap "" INT TERM; kill 0; exit 143' INT TERM
    # section <heading> <body>
    section() {
      printf '\n## %s\n%s\n' "$1" "$2" >>"$tmp"
    }
    # ask_grok <prompt> <cwd>: grok's answer as markdown
    # .text starts with grok's own progress notes (the list often follows
    # them on the same line after 。), so cut them before the first list
    # item, drop a trailing plugin note, demote headings, and reject short
    # or placeholder answers
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
      jq -er '
        .text // ""
        | ([match("(^|\n|。)(\\*\\*)?1\\. ")][0]) as $m
        | (if $m then .[$m.offset:] | ltrimstr("\n") | ltrimstr("。") else . end)
        | split("\n\n")
        | (if (.[-1] // "" | test("プラグイン|マーケットプレイス|marketplace|plugin"; "i")) then .[:-1] else . end)
        | join("\n\n")
        | gsub("(?<a>^|\n)#+ "; "\(.a)")
        | if length < 80 or test("example\\.com|x\\.com/example") or (.[:200] | test("調査中"))
          then error("bad answer") else . end' "$2.json"
    }
    # grok_body <prompt>: the section body, 取得失敗 on any error
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
      [ "$rc" -eq 0 ] || body="取得失敗"
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
    def kinds: ["weather", "grok", "releases", "zenn", "qiita", "hn", "lobsters", "github-rising", "cli-tui"];
    def str: type == "string" and length > 0;
    def has_kind($k; $x): ($k | index($x)) != null;
    if length != 1 then "the config must be one json object"
    else .[0]
    | if type != "object" then "the config must be a json object"
      else
        (if .title | str then empty else "title must be a non-empty string" end),
        (if (.outDir | str) and (.outDir | startswith("/")) then empty else "outDir must be an absolute path" end),
        (if (.sections | type) == "array" and (.sections | length) > 0 then
          .sections | to_entries[] | "sections[\(.key)]" as $at | .value
          | if type != "object" then "\($at) must be an object"
            else
              (if .heading | str then empty else "\($at).heading must be a non-empty string" end),
              ((.kind | if type == "array" then . else [.] end) as $k
              | if ($k | length) == 0 then "\($at).kind is empty"
                elif any($k[]; . as $x | all(kinds[]; . != $x)) then "\($at).kind must be one of \(kinds | join(", "))"
                elif ($k | unique | length) != ($k | length) then "\($at).kind repeats a kind"
                elif (.kind | type) == "array" and has_kind($k; "cli-tui") then "\($at): cli-tui has its own sub-headings, so it cannot be in a kind list"
                else
                  (if has_kind($k; "weather") and (.url | str | not) then "\($at).url is required for weather" else empty end),
                  (if has_kind($k; "grok") or has_kind($k; "cli-tui") then
                    if has("prompt") and has("promptFile") then "\($at): prompt and promptFile cannot both be given"
                    elif has("promptFile") then (if .promptFile | str then empty else "\($at).promptFile must be a non-empty string" end)
                    elif .prompt | str then empty
                    else "\($at).prompt or .promptFile is required for \($k | join(", "))" end
                  else empty end),
                  (if has_kind($k; "releases") and ((.repos | type) != "array" or (.repos | length) == 0 or any(.repos[]; str | not)) then "\($at).repos must be a non-empty list of owner/name" else empty end)
                end)
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
    # prompts (inline or in a promptFile) and the weather url live in the
    # config (the workspace is private), so this public command carries none
    # of them
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
      # a promptFile is relative to the config's directory unless absolute.
      # checked here too, so a missing file stops the run before outDir
      config_dir=$(dirname -- "$config")
      # prompt_path <promptFile>: its path
      prompt_path() {
        case "$1" in
          /*) printf '%s\n' "$1" ;;
          *) printf '%s\n' "$config_dir/$1" ;;
        esac
      }
      problems=""
      while IFS=$'\t' read -r at file; do
        [ -n "$at" ] || continue
        path=$(prompt_path "$file")
        if [ ! -f "$path" ] || [ ! -r "$path" ]; then
          problems+="$at.promptFile: $path: no such file"$'\n'
        elif [ ! -s "$path" ]; then
          problems+="$at.promptFile: $path is empty"$'\n'
        fi
      done < <(jq -r '.sections | to_entries[] | select(.value.promptFile != null) | "sections[\(.key)]\t\(.value.promptFile)"' "$config")
      if [ -n "$problems" ]; then
        while IFS= read -r problem; do
          [ -z "$problem" ] || printf 'openclaw-feeds: %s: %s\n' "$config" "$problem" >&2
        done <<<"$problems"
        exit 2
      fi
      # <年> and <月> in a prompt become this year and month in JST, e.g. 2026
      # and 10月
      year=$(TZ=Asia/Tokyo date +%Y)
      month="$(TZ=Asia/Tokyo date +%-m)月"
      FEEDS_DIR=$(jq -r .outDir "$config")
      # overrides for tests
      : "''${FEEDS_WEATHER_URL:=}"
      FEEDS_HN_URL="''${FEEDS_HN_URL:-https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=10}"
      FEEDS_LOBSTERS_URL="''${FEEDS_LOBSTERS_URL:-https://lobste.rs/hottest.json}"
      FEEDS_ZENN_URL="''${FEEDS_ZENN_URL:-https://zenn.dev/api/articles?order=daily&count=10}"
      FEEDS_QIITA_URL="''${FEEDS_QIITA_URL:-https://qiita.com/popular-items/feed}"
      ${feedsLib}
      printf '# %s %s\n' "$(jq -r .title "$config")" "$(date '+%Y-%m-%d %H:%M')" >"$tmp"
      # config values go from jq straight into variables and are never
      # re-parsed by the shell, so quotes, ｜, $ and newlines are safe
      # field <i> <jq path>: a value of section i
      field() {
        jq -r --argjson i "$1" ".sections[\$i]$2" "$config"
      }
      # kinds_of <i>: the kinds of section i, one per line
      kinds_of() {
        field "$1" '.kind | if type == "array" then .[] else . end'
      }
      # prompt_of <i>: the prompt of section i (inline or from its file)
      prompt_of() {
        local file prompt
        file=$(field "$1" '.promptFile // ""')
        if [ -n "$file" ]; then
          prompt=$(cat -- "$(prompt_path "$file")")
        else
          prompt=$(field "$1" .prompt)
        fi
        prompt=''${prompt//"<年>"/"$year"}
        printf '%s' "''${prompt//"<月>"/"$month"}"
      }
      nsec=$(jq '.sections | length' "$config")
      # the sub-heading of each kind when a section lists several
      declare -A subheading=(
        [weather]="天気"
        [grok]="X の話題"
        [releases]="新しいリリース"
        [zenn]="Zenn"
        [qiita]="Qiita"
        [hn]="Hacker News"
        [lobsters]="Lobsters"
        [github-rising]="GitHub で伸びているリポジトリ"
      )
      # the grok calls run in the background while the apis are read
      for ((i = 0; i < nsec; i++)); do
        mapfile -t kinds < <(kinds_of "$i")
        for kind in "''${kinds[@]}"; do
          case "$kind" in
            grok | cli-tui)
              if [ -n "$FEEDS_SKIP_GROK" ]; then
                echo "取得しない（FEEDS_SKIP_GROK）" >"$work/grok.$i"
              else
                grok_body "$(prompt_of "$i")" >"$work/grok.$i" &
              fi
              ;;
          esac
        done
      done
      grok_read() {
        local body
        body=$(cat "$work/grok.$1" 2>/dev/null) || true
        printf '%s\n' "''${body:-取得失敗}"
      }
      # list <url> <jq filter>: one markdown line per item, 取得失敗 when the
      # source is down or its shape changed (jq -e fails on no output)
      list() {
        local out
        out=$(curl -fsS --max-time 30 "$1" | jq -er "$2" 2>/dev/null) || out="取得失敗"
        printf '%s\n' "$out"
      }
      # gh_search <query> <n>: newest repos by stars as json lines
      gh_search() {
        gh api -X GET search/repositories -f q="$1" -f sort=stars -f per_page="$2" 2>/dev/null |
          jq -ec '.items[]' 2>/dev/null
      }
      repo_line='"- ★\(.stargazers_count) \(.full_name) — \(.description // "説明なし") \(.html_url)"'
      # releases since the last successful run (a day on the first run).
      # the new mark is taken before asking so a release made meanwhile is
      # seen next time, and written only once latest.md is in place
      since=$(cat "$FEEDS_DIR/.releases-since" 2>/dev/null) || since=""
      [ -n "$since" ] || since=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
      releases_mark=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      releases_seen=0
      week_ago=$(date -d '7 days ago' +%Y-%m-%d)
      month_ago=$(date -d '30 days ago' +%Y-%m-%d)
      # fetch <i> <kind>: sets out to the body of one kind (cli-tui: only
      # its github part). runs in this shell so releases can clear the mark
      fetch() {
        local repo repos releases releases_ok releases_failed topic cli_repos cli_failed
        case "$2" in
          weather)
            if ! out=$(curl -fsS --max-time 30 "''${FEEDS_WEATHER_URL:-$(field "$1" .url)}" | jq -er '
              def wmo: {
                "0": "快晴", "1": "晴れ", "2": "晴れ時々くもり", "3": "くもり",
                "45": "霧", "48": "霧",
                "51": "霧雨", "53": "霧雨", "55": "霧雨",
                "61": "雨（弱）", "63": "雨（中）", "65": "雨（強）",
                "66": "着氷性の雨", "67": "着氷性の雨",
                "71": "雪", "73": "雪", "75": "雪", "77": "霧雪",
                "80": "にわか雨", "81": "にわか雨", "82": "にわか雨",
                "85": "にわか雪", "86": "にわか雪",
                "95": "雷雨", "96": "雹を伴う雷雨", "99": "雹を伴う雷雨"
              }[tostring] // "コード \(.)";
              .current as $c | .daily as $d
              | "現在 \($c.temperature_2m)°C・\($c.weather_code | wmo)／今日 \($d.weather_code[0] | wmo)、最高 \($d.temperature_2m_max[0])°C・最低 \($d.temperature_2m_min[0])°C、降水確率 \($d.precipitation_probability_max[0])%"'); then
              out="取得失敗"
            fi
            ;;
          releases)
            releases_seen=1
            releases="" releases_ok=0 releases_failed=""
            mapfile -t repos < <(field "$1" '.repos[]')
            for repo in "''${repos[@]}"; do
              # no output is fine here (nothing new), so no jq -e. prereleases and
              # neovim's rolling nightly tag would show up every run, so skip them
              if out=$(gh api "repos/$repo/releases?per_page=5" 2>/dev/null | jq -r --arg since "$since" --arg repo "$repo" '
                if type == "array" then . else error("not a list") end
                | .[] | select(.published_at != null and .published_at > $since)
                | select((.prerelease | not) and .tag_name != "nightly")
                | "- \($repo) \(.tag_name)（\(.published_at | fromdateiso8601 | strflocaltime("%Y-%m-%d"))）\(.html_url)"' 2>/dev/null); then
                releases_ok=$((releases_ok + 1))
                [ -z "$out" ] || releases+="$out"$'\n'
              else
                releases_failed+="- $repo 取得失敗"$'\n'
              fi
            done
            if [ "$releases_ok" -eq 0 ]; then
              releases="取得失敗"
              # keep the old mark so the next run asks again
              releases_mark=""
            else
              [ -n "$releases" ] || releases="新しいリリースなし"$'\n'
              releases+="$releases_failed"
            fi
            # drop the trailing newline
            out=$(printf '%s' "$releases")
            ;;
          zenn)
            out=$(list "$FEEDS_ZENN_URL" '.articles[:10][] | "- ♥\(.liked_count) \(.title) https://zenn.dev\(.path)"')
            ;;
          qiita)
            # atom via yq; a lone entry comes back as an object, not a list
            out=$(curl -fsS --max-time 30 "$FEEDS_QIITA_URL" 2>/dev/null | yq -p xml -o json 2>/dev/null | jq -er '
              .feed.entry | (if type == "array" then . else [.] end) | .[:10][]
              | (.link | if type == "array" then (map(select(."+@rel" == "alternate"))[0] // .[0]) else . end) as $l
              | "- \(.title) \($l."+@href" | sub("\\?utm_.*$"; ""))"' 2>/dev/null) || out="取得失敗"
            ;;
          hn)
            out=$(list "$FEEDS_HN_URL" '.hits[:10][] | "- ▲\(.points) \(.title) \(if (.url // "") == "" then "https://news.ycombinator.com/item?id=\(.objectID)" else .url end)"')
            ;;
          lobsters)
            out=$(list "$FEEDS_LOBSTERS_URL" '.[:10][] | "- ▲\(.score) \(.title) \(if (.url // "") == "" then .short_id_url else .url end)"')
            ;;
          github-rising)
            out=$(gh_search "created:>$week_ago" 10 | jq -er "$repo_line") || out="取得失敗"
            ;;
          cli-tui)
            # the cli and tui searches overlap, so keep each repo once
            cli_repos="" cli_failed=""
            for topic in cli tui; do
              if out=$(gh_search "created:>$month_ago topic:$topic" 5); then
                cli_repos+="$out"$'\n'
              else
                cli_failed+="- topic:$topic 取得失敗"$'\n'
              fi
            done
            if [ -z "$cli_repos" ]; then
              out="取得失敗"
            else
              out=$(printf '%s' "$cli_repos" | jq -rs "unique_by(.full_name) | sort_by(-.stargazers_count) | .[] | $repo_line")
              out=$(printf '%s\n%s' "$out" "$cli_failed")
            fi
            ;;
        esac
      }
      declare -A bodies=()
      for ((i = 0; i < nsec; i++)); do
        mapfile -t kinds < <(kinds_of "$i")
        for kind in "''${kinds[@]}"; do
          # a grok body is read once its call is done
          if [ "$kind" != grok ]; then
            out=""
            fetch "$i" "$kind"
            bodies["$i.$kind"]=$out
          fi
        done
      done
      wait
      for ((i = 0; i < nsec; i++)); do
        mapfile -t kinds < <(kinds_of "$i")
        several=$(field "$i" '.kind | type == "array"')
        body=""
        for kind in "''${kinds[@]}"; do
          case "$kind" in
            grok) out=$(grok_read "$i") ;;
            cli-tui) out="### X の話題"$'\n'"$(grok_read "$i")"$'\n\n'"### GitHub の新しい CLI・TUI（30 日以内）"$'\n'"''${bodies["$i.$kind"]}" ;;
            *) out=''${bodies["$i.$kind"]} ;;
          esac
          if [ "$several" = true ]; then
            out="### ''${subheading[$kind]}"$'\n'"$out"
          fi
          body+="''${body:+$'\n\n'}$out"
        done
        section "$(field "$i" .heading)" "$body"
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
