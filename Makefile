fmt:
	stylua main.lua config core data entities scenes systems ui

lint:
	luacheck .

check: lint
