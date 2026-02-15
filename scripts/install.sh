#!/usr/bin/env sh
set -eu

NYX_REPO="${NYX_REPO:-suryasekhar06jemsbond-lab/cyber}"
NYX_VERSION="${NYX_VERSION:-latest}"
NYX_INSTALL_DIR="${NYX_INSTALL_DIR:-$HOME/.local/bin}"
NYX_HOME="${NYX_HOME:-$HOME/.local/share/nyx}"
NYX_BINARY_NAME="${NYX_BINARY_NAME:-nyx}"
NYX_ASSET="${NYX_ASSET:-}"
NYX_FORCE="${NYX_FORCE:-0}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

if [ -z "$NYX_ASSET" ]; then
  os_raw=$(uname -s)
  arch_raw=$(uname -m)

  case "$os_raw" in
    Linux) os="linux" ;;
    Darwin) os="macos" ;;
    *)
      echo "Error: unsupported OS: $os_raw" >&2
      exit 1
      ;;
  esac

  case "$arch_raw" in
    x86_64|amd64) arch="x64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      echo "Error: unsupported CPU architecture: $arch_raw" >&2
      exit 1
      ;;
  esac

  NYX_ASSET="nyx-${os}-${arch}.tar.gz"
fi

if [ "$NYX_VERSION" = "latest" ]; then
  base_url="https://github.com/${NYX_REPO}/releases/latest/download"
else
  base_url="https://github.com/${NYX_REPO}/releases/download/${NYX_VERSION}"
fi

download_url="${base_url}/${NYX_ASSET}"
hash_url="${base_url}/${NYX_ASSET}.sha256"

need_cmd tar
need_cmd mktemp
need_cmd install

if command -v curl >/dev/null 2>&1; then
  downloader="curl"
elif command -v wget >/dev/null 2>&1; then
  downloader="wget"
else
  echo "Error: curl or wget is required for download" >&2
  exit 1
fi

download_file() {
  url="$1"
  out="$2"
  if [ "$downloader" = "curl" ]; then
    curl -fsSL "$url" -o "$out"
  else
    wget -q "$url" -O "$out"
  fi
}

parse_hash_file() {
  file="$1"
  awk 'NF { print $1; exit }' "$file" 2>/dev/null | tr -d '\r'
}

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
  echo ""
}

copy_dir_replace() {
  src="$1"
  dst="$2"
  [ -d "$src" ] || return 0
  rm -rf "$dst"
  dst_parent=$(dirname "$dst")
  mkdir -p "$dst_parent"
  cp -R "$src" "$dst"
}

copy_file_if_exists() {
  src="$1"
  dst="$2"
  [ -f "$src" ] || return 0
  dst_parent=$(dirname "$dst")
  mkdir -p "$dst_parent"
  cp "$src" "$dst"
}

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive_path="$tmp_dir/$NYX_ASSET"
hash_path="$tmp_dir/$NYX_ASSET.sha256"
state_path="$NYX_HOME/install-state"
dest_binary="$NYX_INSTALL_DIR/$NYX_BINARY_NAME"

installed_hash=""
installed_version=""
installed_asset=""
if [ -f "$state_path" ]; then
  installed_hash=$(awk -F= '/^sha256=/{print $2; exit}' "$state_path" | tr -d '\r')
  installed_version=$(awk -F= '/^version=/{print $2; exit}' "$state_path" | tr -d '\r')
  installed_asset=$(awk -F= '/^asset=/{print $2; exit}' "$state_path" | tr -d '\r')
fi

if [ "$NYX_FORCE" != "1" ] && [ "$NYX_VERSION" != "latest" ] && [ "$installed_version" = "$NYX_VERSION" ] && \
   [ "$installed_asset" = "$NYX_ASSET" ] && [ -x "$dest_binary" ]; then
  printf 'Nyx %s is already installed at %s\n' "$NYX_VERSION" "$dest_binary"
  "$dest_binary" --version || true
  exit 0
fi

remote_hash=""
if [ "$NYX_FORCE" != "1" ]; then
  if download_file "$hash_url" "$hash_path" >/dev/null 2>&1; then
    remote_hash=$(parse_hash_file "$hash_path")
  fi
fi

if [ "$NYX_FORCE" != "1" ] && [ -n "$remote_hash" ] && [ "$remote_hash" = "$installed_hash" ] && [ -x "$dest_binary" ]; then
  printf 'Nyx is already up to date at %s (sha256=%s)\n' "$dest_binary" "$remote_hash"
  "$dest_binary" --version || true
  exit 0
fi

printf 'Downloading %s\n' "$download_url"
if ! download_file "$download_url" "$archive_path"; then
  exit 1
fi

mkdir -p "$tmp_dir/unpack"
tar -xzf "$archive_path" -C "$tmp_dir/unpack"

binary_path="$tmp_dir/unpack/$NYX_BINARY_NAME"
if [ ! -f "$binary_path" ]; then
  found=$(find "$tmp_dir/unpack" -type f -name "$NYX_BINARY_NAME" | head -n 1 || true)
  if [ -n "$found" ]; then
    binary_path="$found"
  fi
fi

if [ ! -f "$binary_path" ]; then
  echo "Error: binary '$NYX_BINARY_NAME' not found in downloaded archive" >&2
  exit 1
fi

mkdir -p "$NYX_INSTALL_DIR"
mkdir -p "$NYX_HOME"

support_binary="$NYX_HOME/$NYX_BINARY_NAME"
cp "$binary_path" "$support_binary"
chmod +x "$support_binary"
install -m 755 "$support_binary" "$dest_binary"

copy_dir_replace "$tmp_dir/unpack/scripts" "$NYX_HOME/scripts"
copy_dir_replace "$tmp_dir/unpack/stdlib" "$NYX_HOME/stdlib"
copy_dir_replace "$tmp_dir/unpack/compiler" "$NYX_HOME/compiler"
copy_dir_replace "$tmp_dir/unpack/examples" "$NYX_HOME/examples"
copy_dir_replace "$tmp_dir/unpack/docs" "$NYX_HOME/docs"
copy_file_if_exists "$tmp_dir/unpack/README.md" "$NYX_HOME/README.md"

for tool in nypm nyfmt nylint nydbg; do
  if [ -f "$NYX_HOME/scripts/$tool.sh" ]; then
    chmod +x "$NYX_HOME/scripts/$tool.sh"
    ln -sf "$NYX_HOME/scripts/$tool.sh" "$NYX_INSTALL_DIR/$tool"
    ln -sf "$NYX_HOME/scripts/$tool.sh" "$NYX_INSTALL_DIR/$tool.sh"
  fi
done

if [ -z "$remote_hash" ]; then
  remote_hash=$(calc_sha256 "$archive_path")
fi
if [ -n "$remote_hash" ]; then
  cat > "$state_path" <<EOF
repo=$NYX_REPO
version=$NYX_VERSION
asset=$NYX_ASSET
sha256=$remote_hash
installed_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
EOF
fi

printf 'Installed %s to %s\n' "$NYX_BINARY_NAME" "$dest_binary"
printf 'Installed support files to %s\n' "$NYX_HOME"

case ":$PATH:" in
  *":$NYX_INSTALL_DIR:"*)
    ;;
  *)
    printf 'Add this to PATH: export PATH="%s:$PATH"\n' "$NYX_INSTALL_DIR"
    ;;
esac

"$dest_binary" --version || true
