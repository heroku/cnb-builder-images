.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

build:
	@pack create-builder heroku/buildpacks:18 --config builder-18.toml --pull-policy if-not-present
	@pack create-builder heroku/buildpacks:20 --config builder-20.toml --pull-policy if-not-present
	@pack create-builder heroku/buildpacks:22 --config builder-22.toml --pull-policy if-not-present
	@docker tag heroku/buildpacks:20 heroku/buildpacks:latest

publish: build
	@docker push heroku/buildpacks:18
	@docker push heroku/buildpacks:20
	@docker push heroku/buildpacks:22
	@docker push heroku/buildpacks:latest
