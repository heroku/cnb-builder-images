.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

install-buildpacks:
	@bash buildpacks/install.sh

build: install-buildpacks
	@docker pull heroku/heroku:18-build
	@docker build -f Dockerfile.build -t heroku/pack:18-build .
	@docker build -f Dockerfile.run -t heroku/pack:18 .
	@pack create-builder heroku/buildpacks:18 --builder-config builder.toml --no-pull
	@docker tag heroku/buildpacks:18 heroku/buildpacks:latest

publish: build
	@docker push heroku/pack:18-build
	@docker push heroku/pack:18
	@docker push heroku/buildpacks:18
	@docker push heroku/buildpacks:latest

test: install-buildpacks
	@docker pull heroku/heroku:18-build
	@docker build -f Dockerfile.build -t heroku/pack:18-build-test .
	@docker build -f Dockerfile.run -t heroku/pack:18-test .
	@pack create-builder heroku/buildpacks:18-test --builder-config builder.toml --no-pull
	@git clone git@github.com:heroku/go-getting-started
	@pack build heroku/go-getting-started:test --path go-getting-started/ --builder heroku/buildpacks:18-test
