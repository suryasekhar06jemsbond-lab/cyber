#!/usr/bin/env sh
set -eu

TARGET=""
BINARY="./build/cy"
OUT_DIR="./dist"

usage() {
  echo "Usage: $0 --target <linux-x64|linux-arm64|macos-x64|macos-arm64> [--binary path] [--out-dir dir]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      TARGET="$2"
      shift 2
      ;;
    --binary)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      BINARY="$2"
      shift 2
      ;;
    --out-dir)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      OUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  usage
  exit 1
fi

if [ ! -f "$BINARY" ]; then
  echo "Error: binary not found: $BINARY" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

archive_name="cy-${TARGET}.tar.gz"
archive_path="$OUT_DIR/$archive_name"
hash_path="$archive_path.sha256"

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

cp "$BINARY" "$tmp_dir/cy"
chmod +x "$tmp_dir/cy"

tar -C "$tmp_dir" -czf "$archive_path" cy

calc_sha256() {
  file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return
  fi
  echo "Error: sha256sum/shasum not found" >&2
  exit 1
}

hash_value=$(calc_sha256 "$archive_path")
printf '%s  %s\n' "$hash_value" "$archive_name" > "$hash_path"

printf 'Created %s\n' "$archive_path"
printf 'Created %s\n' "$hash_path"
