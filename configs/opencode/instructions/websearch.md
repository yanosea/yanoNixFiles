# Web search order

Use the first available path, in this order:

1. Tavily: the `tavily` skill driving the `tvly` CLI.
2. Firecrawl: the `firecrawl-search` skill driving the `firecrawl` CLI.
3. The built-in `websearch` tool, which runs Hosted Web Search and is billed per
   successful search.

Move to the next step only when the current one is unavailable: missing CLI,
auth error, rate limit, or exhausted credits. No other search provider.

`webfetch` is not part of this order. Use it for a URL you already know.

This order overrides the "always use me" wording in the Tavily and Firecrawl
skills.
