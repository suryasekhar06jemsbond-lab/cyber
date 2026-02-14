#!/usr/bin/env sh
set -eu

TARGET=""
BINARY="./build/nyx"
OUT_DIR="./dist"
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

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

archive_name="nyx-${TARGET}.tar.gz"
archive_path="$OUT_DIR/$archive_name"
hash_path="$archive_path.sha256"

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

cp "$BINARY" "$tmp_dir/nyx"
chmod +x "$tmp_dir/nyx"

mkdir -p "$tmp_dir/scripts"
mkdir -p "$tmp_dir/compiler"

copy_file_if_exists() {
  src="$1"
  dst="$2"
  [ -f "$src" ] || return 0
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"
  cp "$src" "$dst"
}

copy_dir_if_exists() {
  src="$1"
  dst="$2"
  [ -d "$src" ] || return 0
  dst_parent=$(dirname "$dst")
  mkdir -p "$dst_parent"
  cp -R "$src" "$dst"
}

for script_name in cydbg.sh cyfmt.sh cylint.sh cypm.sh cydbg.ps1 cyfmt.ps1 cylint.ps1 cypm.ps1; do
  copy_file_if_exists "$ROOT_DIR/scripts/$script_name" "$tmp_dir/scripts/$script_name"
done

copy_file_if_exists "$ROOT_DIR/compiler/bootstrap.nx" "$tmp_dir/compiler/bootstrap.nx"
copy_file_if_exists "$ROOT_DIR/compiler/v3_seed.nx" "$tmp_dir/compiler/v3_seed.nx"
copy_dir_if_exists "$ROOT_DIR/stdlib" "$tmp_dir/stdlib"
copy_dir_if_exists "$ROOT_DIR/examples" "$tmp_dir/examples"
copy_file_if_exists "$ROOT_DIR/README.md" "$tmp_dir/README.md"
copy_file_if_exists "$ROOT_DIR/docs/LANGUAGE_SPEC.md" "$tmp_dir/docs/LANGUAGE_SPEC.md"

for sh_tool in cydbg cyfmt cylint cypm; do
  if [ -f "$tmp_dir/scripts/$sh_tool.sh" ]; then
    chmod +x "$tmp_dir/scripts/$sh_tool.sh"
  fi
done

tar -C "$tmp_dir" -czf "$archive_path" .

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
