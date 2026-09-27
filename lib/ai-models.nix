# claude model tiers, most capable first
let
  # the aliases claude code ships (`fable`, `opus`) already follow the newest
  # release of each tier, but `ANTHROPIC_DEFAULT_*_MODEL` rejects an alias and
  # takes a full id only, so the current id of each tier is pinned here.
  # check-model-drift.sh reports at session start when a tier has a newer one
  tiers = [
    {
      name = "fable";
      id = "claude-fable-5-1";
    }
    {
      name = "opus";
      id = "claude-opus-5-5";
    }
  ];
in
{
  inherit tiers;
  # plan mode runs on the top tier; leaving a whole session there is what burns
  # its share, so execution and subagents drop to the next one
  plan = (builtins.head tiers).id;
  run = (builtins.elemAt tiers 1).id;
}
