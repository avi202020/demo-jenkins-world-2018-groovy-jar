#!/bin/bash

# Automatically delete temporary files when the script exits (even on error)
function cleanup_on() {
  [ -z "${TMP_DIR}" ] || rm -rf "${TMP_DIR}"
}
trap cleanup_on EXIT

set -auxeEo pipefail
# test for variables that should be set
[ -n "${JERVIS_ORG:-}" ]
[ -n "${JERVIS_PROJECT:-}" ]
[ -n "${TAG_NAME:-}" ]
[ -n "${GITHUB_TOKEN}" ]

export TMP_DIR=$(mktemp -d)
export PATH="${TMP_DIR}:${PATH}"
# install dependent tool to release to GitHub
if ! type -P github-release; then
  pushd "${TMP_DIR}"
  wget -O- https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2 | bzip2 -d | tar -x
  find . -type f -name 'github-release' -exec mv {} ./ +
  popd
fi

cd dist/

LAST_PATCH="${TAG_NAME##*.}"
(( LAST_PATCH-- ))

# create released
github-release release \
  --user "${JERVIS_ORG}" \
  --repo "${JERVIS_PROJECT}" \
  --tag "${TAG_NAME}" \
  --name "Release groovy-gradle-seed ${TAG_NAME}" \
  --description - <<EOF
# Release notes

This change was automatically released by Jenkins.  See my [Jenkins World 2018
demo][demo].

See [git changelog][changelog] since the last release
${TAG_NAME%.*}.${LAST_PATCH}.

Published by [\`${JOB_NAME}\` build #${BUILD_NUMBER}][build].

[build]: ${RUN_DISPLAY_URL}
[changelog]: https://github.com/${JERVIS_ORG}/${JERVIS_PROJECT}/compare/${TAG_NAME%.*}.${LAST_PATCH}...${TAG_NAME}
[demo]: https://github.com/samrocketman/demo-jenkins-world-2018-jenkins-bootstrap
EOF

# upload the release to GitHub in parallel
find * -maxdepth 0 -type f |
  xargs -P0 -n1 -I{} github-release upload \
    --user "${JERVIS_ORG}" \
    --repo "${JERVIS_PROJECT}" \
    --tag "${TAG_NAME}" \
    --name '{}' --file '{}'
