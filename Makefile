.PHONY: install uninstall sync status configure

## Install counterpart toolbox locally (dev mode — uses this repo directly)
install:
	mkdir -p ~/.local/bin
	ln -sf "$(PWD)/counterpart" ~/.local/bin/counterpart
	chmod +x counterpart
	@bash -c '\
		RC=~/.zshrc; \
		if grep -qF "# >>> counterpart-toolbox" "$$RC" 2>/dev/null; then \
			echo "Hook already in $$RC — skipping"; \
		else \
			printf "\n# >>> counterpart-toolbox\nexport PATH=\"\$${HOME}/.local/bin:\$${PATH}\"\n_CT_TOOLBOX=\"$(PWD)\"\nif [[ -f \"\$${_CT_TOOLBOX}/lib/update-check.sh\" ]]; then\n  source \"\$${_CT_TOOLBOX}/lib/update-check.sh\"\n  _ct_update_check 2>/dev/null || true\nfi\nunset _CT_TOOLBOX\n# <<< counterpart-toolbox\n" >> "$$RC"; \
			echo "Added hook to $$RC"; \
		fi'
	@echo ""
	@echo "Done. Reload your shell: source ~/.zshrc"
	@echo "Then run: counterpart sync"

## Remove symlink, shell hook, config, and cloned repo
uninstall:
	bash counterpart uninstall --yes

## Run sync against local generated/ (dev shortcut)
sync:
	bash counterpart sync --source ../counterpart-plugins/generated

## Show status
status:
	bash counterpart status

## Re-run configure
configure:
	bash counterpart configure
