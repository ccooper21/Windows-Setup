#!/bin/bash

# Function to update directory modification time
update_dir_mtime() {
    local dir="$1"
    local latest_mtime=$(find "$dir" -type f -printf '%T@\n' | sort -nr | head -n 1)

    if [[ -n "$latest_mtime" ]]; then
        # Convert timestamp to a format touch can understand (YYYYMMDDhhmm.ss)
        local formatted_mtime=$(date -d "@$latest_mtime" +%Y%m%d%H%M.%S)
        echo "Updating modification time for directory: $dir to $formatted_mtime"
        touch -m -t "$formatted_mtime" "$dir"
    else
        echo "No files found in subtree of $dir, skipping update."
    fi
}

# Main script logic
echo "Starting directory modification date update..."

# Get all directories, sorting them so subdirectories are processed before their parents.
# This ensures that when a parent directory's time is set, it reflects the latest
# time from its fully processed children.
find . -type d | sort -r | while read -r dir; do
    # Skip the current directory if it's just "."
    if [[ "$dir" == "." ]]; then
        continue
    fi
    update_dir_mtime "$dir"
done

echo "Update complete."
