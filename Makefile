.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

build:
	@docker pull heroku/heroku:18-build
	@docker build -f Dockerfile.build -t heroku/pack:18-build .
	@docker build -f Dockerfile.run -t heroku/pack:18 .
	@docker build -f Dockerfile.cache -t heroku/buildpacks:cache .
	-pack delete-stack heroku-18
	@pack add-stack heroku-18 --build-image heroku/pack:18-build --run-image heroku/pack:18
	@pack create-builder heroku/buildpacks:18 -s heroku-18 --builder-config builder.toml --no-pull
	@docker tag heroku/buildpacks:18 heroku/buildpacks:latest

publish: build
	@docker push heroku/pack:18-build
	@docker push heroku/pack:18
	@docker push heroku/buildpacks:18
	@docker push heroku/buildpacks:latest
	@docker push heroku/buildpacks:cache
