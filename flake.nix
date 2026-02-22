{
	description = "NixOS Flake";
	inputs = {
		nixpkgs.url = "nixpkgs/nixos-25.11";
	};

	outputs = { self, nixpkgs, ... }: {
		nixosConfigurations.personal-laptop = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./configuration.nix
			];
		};
	};
}
