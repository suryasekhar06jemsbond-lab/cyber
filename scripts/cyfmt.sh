#!/usr/bin/env sh
set -eu

usage() {
  cat <<'USAGE'
Usage: nyfmt [--check] [target(.ny)]
USAGE
}

check_mode=0
target="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      check_mode=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [ "$target" != "." ]; then
        echo "Error: multiple targets are not supported" >&2
        usage >&2
        exit 1
      fi
      target="$1"
      ;;
  esac
  shift
done

format_to_tmp() {
  file="$1"
  tmp="$2"
  awk '{
    gsub(/\r/, "");
    gsub(/\t/, "    ");
    sub(/[[:space:]]+$/, "");
    print;
  }' "$file" > "$tmp"
}

format_or_check_file() {
  file="$1"
  tmp=$(mktemp)
  format_to_tmp "$file" "$tmp"

  if [ "$check_mode" -eq 1 ]; then
    if ! cmp -s "$file" "$tmp"; then
      echo "Needs formatting: $file"
      check_failed=1
    fi
    rm -f "$tmp"
    return
  fi

  mv "$tmp" "$file"
}

check_failed=0

if [ -f "$target" ]; then
  format_or_check_file "$target"
elif [ -d "$target" ]; then
  file_list=$(mktemp)
  trap 'rm -f "$file_list"' EXIT
  find "$target" -type f -name '*.ny' > "$file_list"
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    format_or_check_file "$file"
  done < "$file_list"
  rm -f "$file_list"
  trap - EXIT
else
  echo "Error: target not found: $target" >&2
  exit 1
fi

if [ "$check_mode" -eq 1 ]; then
  if [ "$check_failed" -ne 0 ]; then
    exit 1
  fi
  echo "Formatting OK"
else
  echo "Formatting complete"
fi
