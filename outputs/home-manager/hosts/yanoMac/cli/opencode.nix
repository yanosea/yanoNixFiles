# home opencode module (the background service the cli talks to)
{ pkgs, ... }:
{
  # launchd
  launchd = {
    enable = true;
    agents = {
      # without this agent the first cli to run spawns the service with its own
      # env, and a shell without the keys below leaves premium and firecrawl
      # unlisted until the service restarts
      opencode = {
        enable = true;
        config = {
          # a login shell for the same PATH and XDG dirs as a terminal; the
          # firecrawl, premium and tavily keys are otherwise only exported by
          # interactive zsh. wait4path waits for sops-nix to decrypt them.
          # `serve --service` stays in the foreground, hence exec
          ProgramArguments = [
            "${pkgs.zsh}/bin/zsh"
            "-lc"
            ''/bin/wait4path "$XDG_DATA_HOME/sops/OPENCODE_PREMIUM_API_KEY" && export FIRECRAWL_API_KEY="$(cat "$XDG_DATA_HOME/sops/FIRECRAWL_API_KEY" 2>/dev/null)" OPENCODE_PREMIUM_API_KEY="$(cat "$XDG_DATA_HOME/sops/OPENCODE_PREMIUM_API_KEY" 2>/dev/null)" TAVILY_API_KEY="$(cat "$XDG_DATA_HOME/sops/TAVILY_API_KEY" 2>/dev/null)"; exec ${pkgs.opencode}/bin/opencode serve --service''
          ];
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "/tmp/opencode-service.error.log";
          StandardOutPath = "/tmp/opencode-service.log";
        };
      };
    };
  };
}
