#!/bin/bash
# Created by Sam Gleske
# Create an automated release if one doesn't exist yet.  This script will
# simply create a tag.  Building and publishing tags is handled in a separate
# workflow.

#
# FUNCTIONS
#

function tag_exists() {
  [ -n "$(git tag --contains HEAD)" ]
}

function major_minor() {
   gawk 'BEGIN { FS="=" }; $1 == "version" { sub("-SNAPSHOT$", "", $2); print $2; exit }' gradle.properties 
}

function next_patch() {
  git tag | grep '^[0-9.]\+' | grep "^$(major_minor)" | gawk 'BEGIN { FS=".";max=0 }; { if(max<$3) { max=$3} }; END { print max+1 }'
}

#
# MAIN CODE
#

set -auxeEo pipefail

type -P gawk

if tag_exists; then
  echo 'Tag already exists containing this commit.  Skipping release...'
  git tag --contains HEAD
  exit
fi

tag="$(major_minor).$(next_patch)"
sed -i.bak "s/^version=.*/version=${tag}/" gradle.properties
git add gradle.properties
# prepare git user (if applicable)
if [ -z "$(git config --global --get user.name)" ]; then
  git config --global user.name 'Jenkins Automation'
  git config --global user.email 'no-reply@example.com'
fi
git commit -m "Release ${tag}"
git tag -am "Release ${tag}" "${tag}"
if git config --get remote.origin.url | grep '^http'; then
  git config --global url."https://${github_user}:${github_token}@github.com/".insteadOf "https://github.com/"
fi
git push origin "refs/tags/${tag}:refs/tags/${tag}"
