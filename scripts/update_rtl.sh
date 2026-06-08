#!/bin/bash

# Description: 
#   This script replaces the target directory contents with files from a remote source.
#   The remote source path is now configurable via command-line argument.
#
# Usage:
#   ./script.sh <remote_source_path> <top_name>
#
# Parameters:
#   remote_source_path - Full path of the source directory on the remote host
#                        (e.g. "user@host:/path/to/source")
#   top_name           - Top module name (without extension). After sync, if
#                        <top_name>.sv exists it will be renamed to <top_name>.v.

set -e  # Exit immediately on error

# Validate input parameters
if [ $# -ne 2 ]; then
    echo "Error: Remote source path and top name must be provided as arguments"
    echo "Usage: $0 <remote_source_path> <top_name>"
    exit 1
fi

remote_source_path="$1/"
top_name="$2"

# Get current script directory
current_dir=$(dirname "$(readlink -f "$0")")
cd "$current_dir" || exit 1

target_dir="$current_dir/../src/rtl/"

echo "Current directory: $current_dir"
echo "Target directory: $target_dir"
echo "Remote source: $remote_source_path"

# Make target directory if it does not exist
mkdir -p "$target_dir"

# Sync files
echo "Starting sync from remote source..."
rsync -avz --delete --progress "$remote_source_path" "$target_dir"

echo "Sync completed successfully."

# Check and rename top module file
sv_file="${target_dir}${top_name}.sv"
v_file="${target_dir}${top_name}.v"

if [ -f "$sv_file" ]; then
    echo "Found ${top_name}.sv, renaming to ${top_name}.v ..."
    mv "$sv_file" "$v_file"
elif [ -f "$v_file" ]; then
    echo "Found ${top_name}.v already, no rename needed."
else
    echo "Warning: Neither ${top_name}.sv nor ${top_name}.v found in ${target_dir}"
fi


echo "Update process finished."
