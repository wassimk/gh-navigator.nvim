PLENARY_DIR ?= /tmp/plenary.nvim

.PHONY: test plenary lint

plenary:
	@if [ ! -d "$(PLENARY_DIR)" ]; then \
		git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR); \
	fi

test: plenary
	PLENARY_DIR=$(PLENARY_DIR) nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

lint:
	stylua --check lua/ tests/
