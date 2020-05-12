#!/usr/bin/env bash
set -e

GOCD_URL=${GOCD_URL:-gocd.example.com}

curl -s -k "https://$GOCD_URL/go/api/admin/pipelines/simple-go-server" \
    -H 'Accept: application/vnd.go.cd.v10+json' | jq '. | {name: .name, stages: .stages}' > template.gocd.json
