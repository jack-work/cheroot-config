local root = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local attr = ("%s@%s"):format(vim.env.USER, vim.uv.os_gethostname())

vim.lsp.config("nixd", {
	settings = {
		nixd = {
			nixpkgs = { expr = ("import (builtins.getFlake %q).inputs.nixpkgs { }"):format(root) },
			formatting = { command = { "nixfmt" } }, -- agrees with conform.lua
			options = {
				home_manager = {
					expr = ("(builtins.getFlake %q).homeConfigurations.%q.options"):format(root, attr),
				},
				-- flake-parts' own options, so modules/*.nix gets completion too
				flake_parts = { expr = ("(builtins.getFlake %q).debug.options"):format(root) },
			},
		},
	},
})
