#!/bin/bash

# --- Configuration ---
SOURCE_DIR="Downloads"    # <-- CHANGE THIS to your source directory
DEST_DIR="Downloads.hashes" # <-- CHANGE THIS to your destination directory
# ---------------------

# Check if the source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist." >&2
    exit 1
fi

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Use find to process all regular files in the source directory tree
echo "Starting hash calculation and file creation..."

find "$SOURCE_DIR" -type f -print0 | while IFS= read -r -d $'\0' FILE
do
    # 1. Calculate the SHA256 hash
    # The output is like: [hash]  [filename]
    HASH_OUTPUT=$(sha256sum "$FILE")
    
    # Extract only the hash value (the first column)
    HASH=$(echo "$HASH_OUTPUT" | awk '{print $1}')

    # 2. Determine the relative path of the file from the source
    # This ensures the destination directory structure mirrors the source.
    RELATIVE_PATH="${FILE#$SOURCE_DIR/}"
    
    # 3. Create the necessary subdirectory structure in the destination
    # Get the directory part of the relative path
    DEST_SUBDIR=$(dirname "$RELATIVE_PATH")
    mkdir -p "$DEST_DIR/$DEST_SUBDIR"

    # 4. Construct the new filename with the hash appended
    FILENAME=$(basename "$FILE")
    NEW_FILENAME="${FILENAME}.${HASH}"

    # 5. Create the 0-byte file in the destination directory
    touch "$DEST_DIR/$DEST_SUBDIR/$NEW_FILENAME" -r "$FILE"
    
    echo "Processed: $RELATIVE_PATH -> $NEW_FILENAME"

done

echo "Script finished. Files created in '$DEST_DIR'."
