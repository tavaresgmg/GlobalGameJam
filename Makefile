fmt:
	stylua .

lint:
	luacheck .

check: lint
