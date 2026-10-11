# Goose ACP providers use the native Claude and Codex subscription logins.
goose() (
  # Keep API/gateway routes out of this child without changing the parent shell.
  unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL \
    ANTHROPIC_CUSTOM_HEADERS ANTHROPIC_BEDROCK_BASE_URL ANTHROPIC_VERTEX_BASE_URL \
    ANTHROPIC_HOST CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX \
    CLAUDE_CODE_USE_FOUNDRY OPENAI_API_KEY OPENAI_BASE_URL CODEX_API_KEY \
    CODEX_CONFIG DEFAULT_AUTH_REQUEST MODEL_PROVIDER
  export CLAUDE_CODE_EXECUTABLE="$(whence -p claude)"
  export CODEX_PATH="$(whence -p codex)"
  export MODEL_PROVIDER=openai
  export CODEX_CONFIG='{"forced_login_method":"chatgpt","model_provider":"openai"}'
  command goose "$@"
)
