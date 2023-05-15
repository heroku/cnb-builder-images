.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

build:
	@pack builder create heroku/buildpacks:20 --config buildpacks-20/builder.toml --pull-policy always
	@pack builder create heroku/builder:22 --config builder-22/builder.toml --pull-policy always
	@pack builder create heroku/builder-classic:22 --config builder-classic-22/builder.toml --pull-policy always

publish: build
	@docker push heroku/buildpacks:20
	@docker push heroku/builder:22
	@docker push heroku/builder-classic:22
