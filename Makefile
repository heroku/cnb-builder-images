.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

build:
	@docker pull heroku/heroku:18-build
	@docker build -f Dockerfile.build -t heroku/pack:18-build .
	@docker build -f Dockerfile.run -t heroku/pack:18 .
	@pack create-builder heroku/buildpacks:18 --builder-config builder.toml --no-pull
	@pack create-builder heroku/spring-boot-buildpacks:18 --builder-config spring-boot-builder.toml --no-pull
	@docker tag heroku/buildpacks:18 heroku/buildpacks:latest
	@docker tag heroku/spring-boot-buildpacks:18 heroku/spring-boot-buildpacks:latest

publish: build
	@docker push heroku/pack:18-build
	@docker push heroku/pack:18
	@docker push heroku/buildpacks:18
	@docker push heroku/buildpacks:latest
	@docker push heroku/spring-boot-buildpacks:18
	@docker push heroku/spring-boot-buildpacks:latest

build-ci:
	@docker build -f Dockerfile.ci -t heroku/pack-runner:latest .
	@docker push heroku/pack-runner:latest

.PHONY: install-buildpacks build publish build-ci create-builder-fn-local deps
