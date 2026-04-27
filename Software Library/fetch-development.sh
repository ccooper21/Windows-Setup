#!/bin/bash

find ./Definitions -maxdepth 1  -name "Development -*.yaml" -not -name ".*" -print0 \
  | sort --zero-terminated \
  | while IFS= read -r -d $'\0' file; do
  echo "Processing definition file \"${file}\"..."
  ../Tools/Fetch/fetch.sh "${file}" Downloads/ 
done

echo "Finished processing all definition files."
