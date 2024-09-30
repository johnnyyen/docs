#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_mdx_file> <output_folder>"
    exit 1
fi

input_file="$1"
output_folder="$2"

# Create the output folder if it doesn't exist
mkdir -p "$output_folder"

# Function to sanitize filenames
sanitize_filename() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]\+/_/g' | sed 's/[^a-z0-9._-]/_/g'
}

# Extract image links and alt texts, then download and save images
grep -o '!\[[^]]*\](\([^)]*\))' "$input_file" | while read -r line; do
    # Extract alt text
    alt_text=$(echo "$line" | sed -n 's/!\[\([^]]*\)\].*/\1/p')
    # Extract URL
    url=$(echo "$line" | sed -n 's/.*](\([^)]*\))/\1/p')

    # Sanitize the alt text to create a valid base filename
    base_name=$(sanitize_filename "$alt_text")

    # Extract the filename from the URL, preserving the extension
    url_without_query="${url%%\?*}"
    decoded_url=$(printf '%b' "${url_without_query//%/\\x}")
    extension="${decoded_url##*.}"

    # Handle cases where the URL does not have an extension
    if [ "$extension" = "$decoded_url" ]; then
        # Fetch headers to determine Content-Type
        content_type=$(curl -sL -I "$url" | grep -i '^Content-Type:' | sed 's/.*: *//;s/;.*//' | tr -d '\r')
        # Map Content-Type to extension
        case "$content_type" in
            image/jpeg|image/pjpeg) extension="jpg" ;;
            image/png) extension="png" ;;
            image/gif) extension="gif" ;;
            image/webp) extension="webp" ;;
            image/svg+xml) extension="svg" ;;
            image/bmp) extension="bmp" ;;
            image/tiff) extension="tiff" ;;
            image/x-icon|image/vnd.microsoft.icon) extension="ico" ;;
            *) extension="dat" ;;
        esac
    fi

    # Construct the filename
    filename="$base_name.$extension"

    # Sanitize the filename to remove any problematic characters
    filename=$(sanitize_filename "$filename")

    # Check if the file already exists and append a counter if necessary
    if [ -f "$output_folder/$filename" ]; then
        counter=1
        while [ -f "$output_folder/${base_name}_$counter.$extension" ]; do
            counter=$((counter + 1))
        done
        filename="${base_name}_$counter.$extension"
    fi

    # Download the image
    echo "Downloading $url to $output_folder/$filename"
    curl -sL "$url" -o "$output_folder/$filename"
done