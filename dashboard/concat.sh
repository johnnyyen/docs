#!/bin/bash

# Define the directory to search. Defaults to the current directory if not provided.
SEARCH_DIR="${1:-.}"

# Define the output file name.
OUTPUT_FILE="combined.mdx"

# Find all .mdx files and concatenate them into the output file.
find "$SEARCH_DIR" -type f -name "*.mdx" -print0 | sort -z | xargs -0 cat -- > "$OUTPUT_FILE"

echo "All .mdx files have been concatenated into $OUTPUT_FILE"
