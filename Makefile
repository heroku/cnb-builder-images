.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

build:
	@pack builder create heroku/builder:20 --config builder-20/builder.toml --pull-policy always
	@pack builder create heroku/builder:22 --config builder-22/builder.toml --pull-policy always
	@pack builder create heroku/builder:24 --config builder-24/builder.toml --pull-policy always
	@pack builder create salesforce-functions --config salesforce-functions/builder.toml --pull-policy always
