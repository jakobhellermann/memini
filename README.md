# memini

Drop-in shell command memoizer

```sh
$ memini sh -c 'nix eval nixpkgs#pkgs --apply "builtins.attrNames" --json | jq ".[]" -r '
> Creating new cache entry with TTL of 1h 
7z2hashcat
AAAAAASomeThingsFailToEvaluate
AMB-plugins
...
zziplib
zzuf


$ memini sh -c 'nix eval nixpkgs#pkgs --apply "builtins.attrNames" --json | jq ".[]" -r '
> Using cache (19s old)
7z2hashcat
...
```

```sh
$ memini
Command: ls 
Age: 45min 22s
Result: build flake.lock flake.nix justfile lockfile.jdn project.janet src 

Command: error
Age: 43min 20s
Result: -

Command: sh -c nix eval nixpkgs#pkgs --apply "builtins.attrNames" --json | jq ".[]" -r  
Age: 8min 38s
Result: 7z2hashcat AAAAAASomeThingsFailToEvaluate AMB-plugins ArchiSteamFarm AusweisApp2 BeatSaberModManager CHOWTapeModel ChowCentaur ChowKick ChowPhaser CoinMP CuboCore DisnixWe...

Command: date +%M%H%S
Age: 6min 26s
Result: 22:24:55
```