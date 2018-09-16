#!/bin/bash

set -auxeEo pipefail
type -P 
mkdir -p dist
# move Jar to dist
mv build/lib/* ./dist
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
