.EXPORT_ALL_VARIABLES:

SHELL=/bin/bash -o pipefail

build:
	@pack builder create salesforce-functions --config salesforce-functions/builder.toml --pull-policy always
