#!/usr/bin/env bash

buildpacks_dir="$(cd $(dirname $0); pwd)" # absolute path
cnb_shim_version="v0.0.2"

fetch_shim() {
  shim_dir="${1:?}"
  curl -sfL "https://github.com/heroku/cnb-shim/releases/download/${cnb_shim_version}/cnb-shim-${cnb_shim_version}.tgz" | tar xz -C "${shim_dir}"
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
[buildpack]
id = "heroku/${buildpack}"
version = "$cnb_shim_version.0.1"
name = "${buildpack_name}"

[[stacks]]
id = "heroku-18"
TOML

  bash "${buildpack_dir}"/bin/install "${buildpack_toml}" "https://buildpack-registry.s3.amazonaws.com/buildpacks/heroku/${buildpack}.tgz"
  rm "${buildpack_toml}"
}

shim_dir="$(mktemp -d)"
fetch_shim "${shim_dir}"
install_buildpack "nodejs" "Node.js" "${shim_dir}"
rm -rf "${shim_dir}"
