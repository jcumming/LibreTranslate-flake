
LibreTranslate Flake
====================

Status: Very rough. 

This is a nix flake that runs [LibreTranslate](https://libretranslate.com) as a local service. 

To enable it in a flake.nix:

```nix

    ...

    inputs.LibreTranslate.url = "github:jcumming/LibreTranslate-flake";

    ...

    outputs = { self, nixpkgs, LibreTranslate, ... }: 

        nixosConfigurations.vane = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = attrs;
            modules = [./machines/vane/configuration.nix LibreTranslate.nixosModules.default];
        };
```

And configure it in configuration.nix:

```nix
        services.libretranslate = {
          enable = true;
          debug = true;
          host = "127.0.0.1";
          port = 5000;
        };
```

TODO
----

- [x] systemd unit 
- [x] options
- [ ] enable testing somehow? 
- [ ] test api keys
- [ ] sample nginx config 
- [ ] upstream this flake into the repo

