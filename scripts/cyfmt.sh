#!/usr/bin/env sh
set -eu

target=${1:-.}

format_file() {
  file="$1"
  tmp=$(mktemp)
  awk '{
    gsub(/\r/, "");
    gsub(/\t/, "    ");
    sub(/[[:space:]]+$/, "");
    print;
  }' "$file" > "$tmp"
  mv "$tmp" "$file"
}

if [ -f "$target" ]; then
  format_file "$target"
else
  find "$target" -type f -name '*.cy' | while IFS= read -r file; do
    format_file "$file"
  done
fi

echo "Formatting complete"
