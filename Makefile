PLENARY_DIR ?= /tmp/plenary.nvim
PANVIMDOC_DIR ?= /tmp/panvimdoc

.PHONY: test plenary lint panvimdoc docs

plenary:
	@if [ ! -d "$(PLENARY_DIR)" ]; then \
		git clone --depth 1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_DIR); \
	fi

test: plenary
	PLENARY_DIR=$(PLENARY_DIR) nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

lint:
	stylua --check lua/ tests/

panvimdoc:
	@if [ ! -d "$(PANVIMDOC_DIR)" ]; then \
		git clone --depth 1 https://github.com/kdheepak/panvimdoc $(PANVIMDOC_DIR); \
	fi

docs: panvimdoc
	$(PANVIMDOC_DIR)/panvimdoc.sh \
		--project-name gh-navigator.nvim \
		--input-file README.md \
		--vim-version "NVIM v0.10.0" \
		--toc true \
		--treesitter true \
		--doc-mapping-project-name false
