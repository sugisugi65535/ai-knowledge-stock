.PHONY: build-local destroy-local build-aws destroy-aws destory-aws put-secrets-aws

build-local:
	./script/build-local

destroy-local:
	./script/destroy-local

build-aws:
	./script/build-aws

destroy-aws:
	./script/destroy-aws

destory-aws:
	./script/destroy-aws

put-secrets-aws:
	./script/put-secrets-aws
