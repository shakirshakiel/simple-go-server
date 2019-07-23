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
  echoGreenText 'Installing dependencies...'
  runCommandInBuildContainer dep ensure
}

function setup {
  echoGreenText 'Downloading dependencies...'
  runCommandInBuildContainer dep ensure -vendor-only
}

function assureSetup {
  [ -d $SOURCE_DIR/vendor ] || setup
}

function build {
  echoGreenText 'Building application...'
  assureSetup
  runCommandInBuildContainer sh -c "go build -o infrastructure/dev/app/app main/main.go"

  echoGreenText 'Building application image...'
  GIT_HASH=$(git rev-parse --short=8 HEAD)
  docker build -t "shakirshakiel/goserver:$GIT_HASH" "$SOURCE_DIR/infrastructure/dev/app"
}

function run {
  echoGreenText 'Running application...'
  assureSetup
  runCommandInContainer "$SOURCE_DIR/infrastructure/dev/run.yml" app
}

function unitTest {
  echoGreenText 'Running unit tests...'
  assureSetup
  runCommandInBuildContainer sh -c "ginkgo $@ -cover -tags unitTests ./..."
}

function lint {
  echoGreenText 'Running linter...'
  assureSetup
  runCommandInBuildContainer sh -c "go list ./... | grep -v vendor | xargs go vet -v"
}

function runCommandInBuildContainer {
  runCommandInContainer "$SOURCE_DIR/infrastructure/dev/build-env.yml" build-env "$@"
}

function runCommandInContainer {
  env=$1
  container=$2
  command=( "${@:3}" )

  docker-compose --project-name "$PROJECT_NAME" -f "$env" run --service-ports --rm "$container" "${command[@]}"
}

function echoGreenText {
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
    echo "${@}"
  else
    RESET=$(tput sgr0)
    GREEN=$(tput setaf 2)

    echo "${GREEN}${@}${RESET}"
  fi
}

function echoRedText {
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
    echo "${@}"
  else
    RESET=$(tput sgr0)
    RED=$(tput setaf 1)

    echo "${RED}${@}${RESET}"
  fi
}

function echoWhiteText {
  if [[ "${TERM:-dumb}" == "dumb" ]]; then
     echo "${@}"
  else
    RESET=$(tput sgr0)
    WHITE=$(tput setaf 7)

    echo "${WHITE}${@}${RESET}"
  fi
}

main "$@"
