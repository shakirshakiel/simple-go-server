#!/usr/bin/env bash
set -e

GOCD_URL=${GOCD_URL:-gocd.example.com}
export VERSION=${VERSION:-1.0}

# Update version in the template
body=$(cat template.gocd.json | jq '. | {name: (.name + "-" + $ENV.VERSION), stages: .stages}')
name=$(echo $body | jq -r '.name')
curl -s -k -D - "https://$GOCD_URL/go/api/admin/templates/$name" -H 'Accept: application/vnd.go.cd.v7+json' > response

# Create or update template
status_code=$(grep 'HTTP/1.1' response | awk '{print $2}')
etag=$(grep 'ETag:' response | awk '{print $2}')

if [ "$status_code" == "404" ]; then
    curl -s -k -X POST "https://$GOCD_URL/go/api/admin/templates" \
    -H 'Accept: application/vnd.go.cd.v7+json' \
    -H 'Content-Type: application/json' \
    -d "$(echo $body)"
else    
    curl -s -k -X PUT "https://$GOCD_URL/go/api/admin/templates/$name" \
    -H 'Accept: application/vnd.go.cd.v7+json' \
    -H 'Content-Type: application/json' \
    -H "If-Match: $etag" \
    -d "$(echo $body)"     
fi

# 
