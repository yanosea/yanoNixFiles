#
# credentials settings (sops-managed)
#

# anthropic api
export ANTHROPIC_API_KEY=$(cat $XDG_DATA_HOME/sops/ANTHROPIC_API_KEY 2>/dev/null || echo "")
# openai api
export OPENAI_API_KEY=$(cat $XDG_DATA_HOME/sops/OPENAI_API_KEY 2>/dev/null || echo "")
# spotify api
export SPOTIFY_ID=$(cat $XDG_DATA_HOME/sops/SPOTIFY_ID 2>/dev/null || echo "")
export SPOTIFY_REDIRECT_URI=$(cat $XDG_DATA_HOME/sops/SPOTIFY_REDIRECT_URI 2>/dev/null || echo "")
export SPOTIFY_REFRESH_TOKEN=$(cat $XDG_DATA_HOME/sops/SPOTIFY_REFRESH_TOKEN 2>/dev/null || echo "")
export SPOTIFY_SECRET=$(cat $XDG_DATA_HOME/sops/SPOTIFY_SECRET 2>/dev/null || echo "")
# tavily api
export TAVILY_API_KEY=$(cat $XDG_DATA_HOME/sops/TAVILY_API_KEY 2>/dev/null || echo "")
# trello api
export TRELLO_KEY=$(cat $XDG_DATA_HOME/sops/TRELLO_KEY 2>/dev/null || echo "")
export TRELLO_TOKEN=$(cat $XDG_DATA_HOME/sops/TRELLO_TOKEN 2>/dev/null || echo "")
export TRELLO_USER=$(cat $XDG_DATA_HOME/sops/TRELLO_USER 2>/dev/null || echo "")

