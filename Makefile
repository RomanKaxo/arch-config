.PHONY: check test audit
check:
	./arch-config check --profile generic
	./arch-config check --profile current-pc

test:
	python3 -m unittest discover -s tests -v

audit:
	python3 tools/audit.py
