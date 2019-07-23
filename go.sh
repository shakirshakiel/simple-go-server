#!/usr/bin/env bash

set -e

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="${SOURCE_DIR##*/}"

function main {
  case "$1" in

  depinstall) depinstall;;
  setup) setup;;
  build) build;;
  run) run;;
  unitTest) unitTest "${@:2}";;
  lint) lint;;
  *)
    exit 1
    ;;

  esac
}

function depinstall {
  echo 'Installing dependencies...'
  runCommandInBuildContainer dep ensure
}

function setup {
  echo 'Downloading dependencies...'
  runCommandInBuildContainer dep ensure -vendor-only
}

function assureSetup {
  [ -d $SOURCE_DIR/vendor ] || setup
}

function build {
  echo 'Building application...'
  assureSetup
  runCommandInBuildContainer sh -c "go build -o infrastructure/app/app main/main.go"

  echo 'Building application image...'
  GIT_HASH=$(git rev-parse --short=8 HEAD)
  docker build -t "shakirshakiel/goserver:$GIT_HASH" "$SOURCE_DIR/infrastructure/app"
}

function run {
  echo 'Running application...'
  assureSetup
  runCommandInContainer "$SOURCE_DIR/infrastructure/run.yml" app
}

function unitTest {
  echo 'Running unit tests...'
  assureSetup
  runCommandInBuildContainer sh -c "go test ./main"
}

function lint {
  echo 'Running linter...'
  assureSetup
  runCommandInBuildContainer sh -c "go list ./main | xargs go vet -v"
}

function runCommandInBuildContainer {
  runCommandInContainer "$SOURCE_DIR/infrastructure/build-env.yml" build-env "$@"
}

function runCommandInContainer {
  env=$1
  container=$2
  command=( "${@:3}" )

  docker-compose --project-name "$PROJECT_NAME" -f "$env" run --service-ports --rm "$container" "${command[@]}"
}

main "$@"
