#!/usr/bin/env sh
set -eu

CY_REPO="${CY_REPO:-suryasekhar06jemsbond-lab/cyber}"
CY_VERSION="${CY_VERSION:-latest}"
CY_INSTALL_DIR="${CY_INSTALL_DIR:-$HOME/.local/bin}"
CY_BINARY_NAME="${CY_BINARY_NAME:-cy}"
CY_ASSET="${CY_ASSET:-}"

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

  CY_ASSET="cy-${os}-${arch}.tar.gz"
fi

if [ "$CY_VERSION" = "latest" ]; then
  download_url="https://github.com/${CY_REPO}/releases/latest/download/${CY_ASSET}"
else
  download_url="https://github.com/${CY_REPO}/releases/download/${CY_VERSION}/${CY_ASSET}"
fi

need_cmd tar
need_cmd mktemp

if command -v curl >/dev/null 2>&1; then
  downloader="curl"
elif command -v wget >/dev/null 2>&1; then
  downloader="wget"
else
  echo "Error: curl or wget is required for download" >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive_path="$tmp_dir/$CY_ASSET"

printf 'Downloading %s\n' "$download_url"
if [ "$downloader" = "curl" ]; then
  curl -fsSL "$download_url" -o "$archive_path"
else
  wget -q "$download_url" -O "$archive_path"
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
  echo "Error: binary '$CY_BINARY_NAME' not found in downloaded archive" >&2
  exit 1
fi

mkdir -p "$CY_INSTALL_DIR"
install -m 755 "$binary_path" "$CY_INSTALL_DIR/$CY_BINARY_NAME"

printf 'Installed %s to %s\n' "$CY_BINARY_NAME" "$CY_INSTALL_DIR/$CY_BINARY_NAME"

case ":$PATH:" in
  *":$CY_INSTALL_DIR:"*)
    ;;
  *)
    printf 'Add this to PATH: export PATH="%s:$PATH"\n' "$CY_INSTALL_DIR"
    ;;
esac

"$CY_INSTALL_DIR/$CY_BINARY_NAME" --version || true
