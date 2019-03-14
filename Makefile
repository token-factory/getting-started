SHELL := /bin/bash

test-stellar:
	cd ./examples/stellar; npm install;node index.js

.PHONY: login image push-image test
