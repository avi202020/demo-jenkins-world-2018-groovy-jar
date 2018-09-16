#!/bin/bash

set -auxeEo pipefail
rm -rf dist
mkdir -p dist
# move unstashed artifacts to dist
mv build/libs/* ./dist/
# archive the API documentation
(
  cd build/docs/groovydoc/
  tar -czf ../../../dist/html-api-docs.tar.gz *
)
cd dist/

# create checksums of all of the files
find * -maxdepth 0 -type f | while read file; do
  sha256sum "${file}" > "${file}.sha256sum"
done
