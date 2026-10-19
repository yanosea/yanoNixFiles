# the third-party agent packages of configs/agents/plugins.conf, parsed once
# for the clis' configs and openclaw's
{ lib }:
let
  # comments and blank lines dropped; an indented line continues the row above
  rows = lib.foldl' (
    rows: line:
    if builtins.match "[[:space:]]*(#.*)?" line != null then
      rows
    else if builtins.match "[[:space:]].*" line != null then
      lib.init rows ++ [ "${lib.last rows} ${line}" ]
    else
      rows ++ [ line ]
  ) [ ] (lib.splitString "\n" (builtins.readFile ../configs/agents/plugins.conf));
  words =
    row: lib.filter (word: builtins.isString word && word != "") (builtins.split "[[:space:]]+" row);
  parse =
    row:
    let
      fields = words row;
      tokens = lib.drop 3 fields;
      # `<cli>` or `<cli>=<value>`; the value of a bare token is null
      enabled = map (
        token:
        let
          match = builtins.match "([^=]+)=(.*)" token;
        in
        if match == null then
          {
            cli = token;
            value = null;
          }
        else
          {
            cli = builtins.head match;
            value = builtins.elemAt match 1;
          }
      ) (lib.filter (token: !lib.hasPrefix "-" token) tokens);
    in
    {
      name = builtins.head fields;
      marketplace = builtins.elemAt fields 1;
      repository = builtins.elemAt fields 2;
      # every value given for each cli, in order
      clis = lib.foldl' (
        clis: entry: clis // { ${entry.cli} = (clis.${entry.cli} or [ ]) ++ [ entry.value ]; }
      ) { } enabled;
      without = map (lib.removePrefix "-") (lib.filter (lib.hasPrefix "-") tokens);
    };
  packages = map parse rows;
  for = cli: lib.filter (package: package.clis ? ${cli}) packages;
  # the one value of cli, or null when the token is bare
  valueFor = cli: package: builtins.head package.clis.${cli};
  claudeId = package: "${package.name}@${package.marketplace}";
in
{
  inherit packages claudeId valueFor;
  # the packages a cli gets, and every value each one gives it
  inherit for;
  valuesFor = cli: package: package.clis.${cli};
  # the plugins of the openclaw agents' claude to turn off
  openclawExcluded = map claudeId (
    lib.filter (package: package.clis ? claude && lib.elem "openclaw" package.without) packages
  );
  # the bare skills a cli gets (skill= packages not left out with -<cli>)
  skillsFor =
    cli: lib.filter (package: package.clis ? skill && !lib.elem cli package.without) packages;
}
