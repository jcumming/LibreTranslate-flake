{
  description = "NixOS libretranslation module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    # todo
    # [ ] systemd service init of downloading models
    # [ ] api key database

    formatter.x86_64-linux = pkgs.alejandra;

    packages.x86_64-linux.libretranslate = pkgs.python3Packages.libretranslate;

    nixosModule.default = (import ./module/libretranslate.nix);

    checks.x86_64-linux.test = pkgs.nixosTest {
      name = "minimal-test";

      nodes.machine = { config, pkgs, ...  }: {
        imports = [ self.nixosModule.default ];

        services.libretranslate = { 
          enable = true;
          debug = true;
          host = "127.0.0.1";
          port = 5000;
        };

        system.stateVersion = "23.11";
      };

      testScript = ''
        machine.wait_for_unit("libretranslate.service")
        machine.succeed("curl http://127.0.0.1:5000")
        #machine.fail("su -- root -c 'which firefox'")
      '';
    };
  };
}
