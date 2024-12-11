update-lockfile:
    nix develop -c bash -c jpm deps; jpm make-lockfile
