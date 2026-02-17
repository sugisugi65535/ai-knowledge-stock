.PHONY: build-local destroy-local build-aws destroy-aws

build-local:
	./script/build-local

destroy-local:
	./script/destroy-local

build-aws:
	./script/build-aws

destroy-aws:
	./script/destroy-aws
