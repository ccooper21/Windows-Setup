#!/bin/bash

find ./Definitions -maxdepth 1  -name "Base -*.yaml" -not -name ".*" -print0 | while IFS= read -r -d $'\0' file; do
  echo "Processing definition file \"${file}\"..."
  ../Tools/Fetch/fetch.sh "${file}" Downloads/ 
done

echo "Finished processing all definition files."
