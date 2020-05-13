#!/usr/bin/env bash
set -e

GOCD_URL=${GOCD_URL:-gocd.example.com}
PROJECT_NAME=simple-go-server
export VERSION=${VERSION:-1.2}
export BRANCH_NAME="release-$VERSION"

# Update version in the template
body=$(cat template.gocd.json | jq '. | {name: (.name + "-" + $ENV.VERSION), stages: .stages}')
template_name=$(echo $body | jq -r '.name')
curl -s -k -D - "https://$GOCD_URL/go/api/admin/templates/$template_name" -H 'Accept: application/vnd.go.cd.v7+json' > response

# Create or update template
status_code=$(grep 'HTTP/1.1' response | awk '{print $2}')
etag=$(grep 'ETag:' response | awk '{print $2}')

if [ "$status_code" == "404" ]; then
    curl -s -k -X POST "https://$GOCD_URL/go/api/admin/templates" \
    -H 'Accept: application/vnd.go.cd.v7+json' \
    -H 'Content-Type: application/json' \
    -d "$(echo $body)"
else    
    curl -s -k -X PUT "https://$GOCD_URL/go/api/admin/templates/$template_name" \
    -H 'Accept: application/vnd.go.cd.v7+json' \
    -H 'Content-Type: application/json' \
    -H "If-Match: $etag" \
    -d "$(echo $body)"     
fi

# Build pipeline yaml file
yq d $PROJECT_NAME.gocd.yaml 'pipelines.*.stages' | \
    yq w - "pipelines.$PROJECT_NAME.template" "$template_name" | \
    yq w - "pipelines.$PROJECT_NAME.materials.*.branch" "$BRANCH_NAME" | \
    sed "s/$PROJECT_NAME:/$PROJECT_NAME-release:/g" > "$PROJECT_NAME-release.gocd.yaml"

set +e
ssh -o StrictHostKeyChecking=no git@github.com
set -e

git clone git@github.com:shakirshakiel/release-pipelines.git
git config --global user.name "gocd"
git config --global user.email "gocd@gocd.org"
git config --global push.default simple

cd release-pipelines 

if [ -z "$(git ls-remote --heads origin $BRANCH_NAME)" ]; then
    git checkout $BRANCH_NAME    
else
    git checkout -b $BRANCH_NAME
    git push origin $BRANCH_NAME   
    git checkout master 
    git branch -D $BRANCH_NAME
    git checkout $BRANCH_NAME --track
fi

mv "../$PROJECT_NAME-release.gocd.yaml" .
git add . 

if [ -z "$(git status --porcelain)" ]; then 
    echo "Pipelines are upto date"
else
    git commit -m "AUTO: Add $PROJECT_NAME-release.gocd.yaml"
    git push
fi