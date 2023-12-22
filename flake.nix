{
  description = "NixOS libretranslation module";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
  in {
    nixosModule.default = import ./module/libretranslate.nix;

    formatter.x86_64-linux = pkgs.alejandra;
    packages.x86_64-linux.libretranslate = pkgs.python3Packages.libretranslate;
    checks.x86_64-linux.vm-simple = import ./checks/vm-simple.nix {inherit self pkgs;};
  };
}
