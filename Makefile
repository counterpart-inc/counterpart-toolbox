.PHONY: install sync status configure

## Install counterpart toolbox locally (dev mode — uses this repo directly)
install:
	mkdir -p ~/.local/bin
	ln -sf "$(PWD)/counterpart" ~/.local/bin/counterpart
	chmod +x counterpart
	@echo "Installed. Run: counterpart sync"

## Run sync
sync:
	bash counterpart sync

## Show status
status:
	bash counterpart status

## Re-run configure
configure:
	bash counterpart configure
