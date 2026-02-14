#!/usr/bin/env sh
set -eu

CY_REPO="${CY_REPO:-suryasekhar06jemsbond-lab/cyber}"
CY_VERSION="${CY_VERSION:-latest}"
CY_INSTALL_DIR="${CY_INSTALL_DIR:-$HOME/.local/bin}"
CY_HOME="${CY_HOME:-$HOME/.local/share/cyper}"
CY_BINARY_NAME="${CY_BINARY_NAME:-cyper}"
CY_ASSET="${CY_ASSET:-}"
CY_FORCE="${CY_FORCE:-0}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

if [ -z "$CY_ASSET" ]; then
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

  CY_ASSET="cyper-${os}-${arch}.tar.gz"
fi

if [ "$CY_VERSION" = "latest" ]; then
  base_url="https://github.com/${CY_REPO}/releases/latest/download"
else
  base_url="https://github.com/${CY_REPO}/releases/download/${CY_VERSION}"
fi

download_url="${base_url}/${CY_ASSET}"
hash_url="${base_url}/${CY_ASSET}.sha256"

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

archive_path="$tmp_dir/$CY_ASSET"
hash_path="$tmp_dir/$CY_ASSET.sha256"
state_path="$CY_HOME/install-state"
dest_binary="$CY_INSTALL_DIR/$CY_BINARY_NAME"

installed_hash=""
installed_version=""
installed_asset=""
if [ -f "$state_path" ]; then
  installed_hash=$(awk -F= '/^sha256=/{print $2; exit}' "$state_path" | tr -d '\r')
  installed_version=$(awk -F= '/^version=/{print $2; exit}' "$state_path" | tr -d '\r')
  installed_asset=$(awk -F= '/^asset=/{print $2; exit}' "$state_path" | tr -d '\r')
fi

if [ "$CY_FORCE" != "1" ] && [ "$CY_VERSION" != "latest" ] && [ "$installed_version" = "$CY_VERSION" ] && \
   [ "$installed_asset" = "$CY_ASSET" ] && [ -x "$dest_binary" ]; then
  printf 'Cyper %s is already installed at %s\n' "$CY_VERSION" "$dest_binary"
  "$dest_binary" --version || true
  exit 0
fi

remote_hash=""
if [ "$CY_FORCE" != "1" ]; then
  if download_file "$hash_url" "$hash_path" >/dev/null 2>&1; then
    remote_hash=$(parse_hash_file "$hash_path")
  fi
fi

if [ "$CY_FORCE" != "1" ] && [ -n "$remote_hash" ] && [ "$remote_hash" = "$installed_hash" ] && [ -x "$dest_binary" ]; then
  printf 'Cyper is already up to date at %s (sha256=%s)\n' "$dest_binary" "$remote_hash"
  "$dest_binary" --version || true
  exit 0
fi

printf 'Downloading %s\n' "$download_url"
if ! download_file "$download_url" "$archive_path"; then
  if [ "$CY_ASSET" != "${CY_ASSET#cyper-}" ]; then
    legacy_asset=$(printf '%s' "$CY_ASSET" | sed 's/^cyper-/cy-/')
    if [ "$CY_VERSION" = "latest" ]; then
      legacy_url="https://github.com/${CY_REPO}/releases/latest/download/${legacy_asset}"
    else
      legacy_url="https://github.com/${CY_REPO}/releases/download/${CY_VERSION}/${legacy_asset}"
    fi
    printf 'Primary asset unavailable, retrying legacy asset %s\n' "$legacy_url"
    CY_ASSET="$legacy_asset"
    download_file "$legacy_url" "$archive_path"
  else
    exit 1
  fi
fi

mkdir -p "$tmp_dir/unpack"
tar -xzf "$archive_path" -C "$tmp_dir/unpack"

binary_path="$tmp_dir/unpack/$CY_BINARY_NAME"
if [ ! -f "$binary_path" ]; then
  found=$(find "$tmp_dir/unpack" -type f -name "$CY_BINARY_NAME" | head -n 1 || true)
  if [ -n "$found" ]; then
    binary_path="$found"
  fi
fi

if [ ! -f "$binary_path" ]; then
  if [ "$CY_BINARY_NAME" = "cyper" ]; then
    found=$(find "$tmp_dir/unpack" -type f -name "cy" | head -n 1 || true)
    if [ -n "$found" ]; then
      binary_path="$found"
    fi
  fi
fi

if [ ! -f "$binary_path" ]; then
  echo "Error: binary '$CY_BINARY_NAME' not found in downloaded archive" >&2
  exit 1
fi

mkdir -p "$CY_INSTALL_DIR"
mkdir -p "$CY_HOME"

support_binary="$CY_HOME/$CY_BINARY_NAME"
cp "$binary_path" "$support_binary"
chmod +x "$support_binary"
install -m 755 "$support_binary" "$dest_binary"

if [ "$CY_BINARY_NAME" = "cyper" ]; then
  install -m 755 "$support_binary" "$CY_INSTALL_DIR/cy"
elif [ "$CY_BINARY_NAME" = "cy" ]; then
  install -m 755 "$support_binary" "$CY_INSTALL_DIR/cyper"
fi

copy_dir_replace "$tmp_dir/unpack/scripts" "$CY_HOME/scripts"
copy_dir_replace "$tmp_dir/unpack/stdlib" "$CY_HOME/stdlib"
copy_dir_replace "$tmp_dir/unpack/compiler" "$CY_HOME/compiler"
copy_dir_replace "$tmp_dir/unpack/examples" "$CY_HOME/examples"
copy_dir_replace "$tmp_dir/unpack/docs" "$CY_HOME/docs"
copy_file_if_exists "$tmp_dir/unpack/README.md" "$CY_HOME/README.md"

for tool in cypm cyfmt cylint cydbg; do
  if [ -f "$CY_HOME/scripts/$tool.sh" ]; then
    install -m 755 "$CY_HOME/scripts/$tool.sh" "$CY_INSTALL_DIR/$tool"
    install -m 755 "$CY_HOME/scripts/$tool.sh" "$CY_INSTALL_DIR/$tool.sh"
  fi
done

if [ -z "$remote_hash" ]; then
  remote_hash=$(calc_sha256 "$archive_path")
fi
if [ -n "$remote_hash" ]; then
  cat > "$state_path" <<EOF
repo=$CY_REPO
version=$CY_VERSION
asset=$CY_ASSET
sha256=$remote_hash
installed_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
EOF
fi

printf 'Installed %s to %s\n' "$CY_BINARY_NAME" "$dest_binary"
printf 'Installed support files to %s\n' "$CY_HOME"

case ":$PATH:" in
  *":$CY_INSTALL_DIR:"*)
    ;;
  *)
    printf 'Add this to PATH: export PATH="%s:$PATH"\n' "$CY_INSTALL_DIR"
    ;;
esac

"$dest_binary" --version || true
