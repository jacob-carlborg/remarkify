#!/bin/bash

set -ex

function build {
  dub build -b release
  strip remarkify
}

function version {
  git describe --tags
}

function arch {
  uname -m
}

function os {
  os=$(uname | tr '[:upper:]' '[:lower:]')
  [ $os = 'darwin' ] && echo 'macos' || echo $os
}

function release_name {
  echo "remarkify-$(version)-$(os)-$(arch)"
}

function archive {
  tar Jcf "$(release_name)".tar.xz remarkify
}

build
archive
