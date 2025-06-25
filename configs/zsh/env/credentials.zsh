#
# credentials environment settings (sops-managed)
#

# anthropic api
export ANTHROPIC_API_KEY=$(cat $XDG_DATA_HOME/sops/ANTHROPIC_API_KEY)
# openai api
export OPENAI_API_KEY=$(cat $XDG_DATA_HOME/sops/OPENAI_API_KEY)
# spotify api
export SPOTIFY_ID=$(cat $XDG_DATA_HOME/sops/SPOTIFY_ID)
export SPOTIFY_REDIRECT_URI=$(cat $XDG_DATA_HOME/sops/SPOTIFY_REDIRECT_URI)
export SPOTIFY_REFRESH_TOKEN=$(cat $XDG_DATA_HOME/sops/SPOTIFY_REFRESH_TOKEN)
export SPOTIFY_SECRET=$(cat $XDG_DATA_HOME/sops/SPOTIFY_SECRET)
# tavily api
export TAVILY_API_KEY=$(cat $XDG_DATA_HOME/sops/TAVILY_API_KEY)
# trello api
export TRELLO_KEY=$(cat $XDG_DATA_HOME/sops/TRELLO_KEY)
export TRELLO_TOKEN=$(cat $XDG_DATA_HOME/sops/TRELLO_TOKEN)
export TRELLO_USER=$(cat $XDG_DATA_HOME/sops/TRELLO_USER)

