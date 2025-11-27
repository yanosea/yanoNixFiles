alias nr="nix run nixpkgs\#"

_nr_expand_and_accept() {
    if [[ -n $BUFFER && ${${(z)BUFFER}[1]} == "nr" ]]; then
        BUFFER="nix run nixpkgs\\#${BUFFER#nr }"
    fi
    zle .accept-line
}

zle -N accept-line _nr_expand_and_accept
