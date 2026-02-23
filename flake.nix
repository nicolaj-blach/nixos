{
	description = "NixOS Flake";
	inputs = {
		nixpkgs.url = "nixpkgs/nixos-25.11";

    elephant.url = "github:abenz1267/elephant";
    
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };
	};

	outputs = { self, nixpkgs, ... }@inputs: {
		nixosConfigurations.personal-laptop = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";

      specialArgs = { inherit inputs; };

			modules = [
				./configuration.nix
			];
		};
	};
}
