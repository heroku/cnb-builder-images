#!/usr/bin/env bash

buildpacks_dir="$(cd $(dirname $0); pwd)" # absolute path
cnb_shim_version="0.2"

fetch_shim() {
  shim_dir="${1:?}"
  curl -sfL "https://github.com/heroku/cnb-shim/releases/download/v${cnb_shim_version}/cnb-shim-v${cnb_shim_version}.tgz" | tar xz -C "${shim_dir}"
}

install_buildpack() {
  buildpack="${1:?}"
  buildpack_name="${2:?}"
  shim_dir="${3:?}"

  buildpack_dir="${buildpacks_dir}/${buildpack}"
  rm -rf "${buildpack_dir}"
  cp -R "${shim_dir}" "${buildpack_dir}"

  buildpack_toml="$(mktemp)"
  cat > "${buildpack_toml}" << TOML
api = "0.2"

[buildpack]
id = "heroku/${buildpack}"
version = "${cnb_shim_version}.2"
name = "${buildpack_name}"

[[stacks]]
id = "heroku-18"
TOML

  bash "${buildpack_dir}"/bin/install "${buildpack_toml}" "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku/${buildpack}.tgz"
  rm "${buildpack_toml}"
}

shim_dir="$(mktemp -d)"
fetch_shim "${shim_dir}"
install_buildpack "python" "Python" "${shim_dir}"
install_buildpack "gradle" "Gradle" "${shim_dir}"
install_buildpack "scala" "Scala" "${shim_dir}"
install_buildpack "php" "PHP" "${shim_dir}"
install_buildpack "go" "Go" "${shim_dir}"
rm -rf "${shim_dir}"
