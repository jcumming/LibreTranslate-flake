{
  self,
  pkgs,
}:
pkgs.nixosTest {
  name = "minimal-test";

  nodes.machine = {
    config,
    pkgs,
    ...
  }: {
    imports = [self.nixosModule.default];

    services.libretranslate = {
      enable = true;
      debug = true;
      host = "127.0.0.1";
      port = 5000;
      req-limit = 0;
      api-keys = true;
      api-key-files = [ (builtins.toString ./test.key) ]; # XXX: this copies the key into the store, which is world readbale, use sops-nix or a different secrets management scheme. 
    };

    system.stateVersion = "23.11";
  };

  testScript = ''
    machine.wait_for_unit("libretranslate.service")
    machine.wait_for_open_port(5000)
    machine.fail("curl http://127.0.0.1:5000")
    machine.succeed("curl http://127.0.0.1:5000 -@ API_KEY = xxxx ")
  '';
}
