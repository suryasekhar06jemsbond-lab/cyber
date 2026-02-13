#!/usr/bin/env sh
set -eu

manifest="cy.pkg"

usage() {
  cat <<'USAGE'
Usage: cypm <command> [args]
Commands:
  init [project]
  add <name> <path> [version] [deps_csv]
  dep <name> <deps_csv>
  version <name> <version>
  remove <name>
  list
  path <name>
  resolve [roots_csv]

Version examples:
  1.2.3
Dependency examples:
  core@^1.0.0,util@>=2.1.0,fmt@1.4.2
USAGE
}

ensure_manifest() {
  if [ ! -f "$manifest" ]; then
    echo "Error: $manifest not found. Run: cypm init" >&2
    exit 1
  fi
}

trim_spaces() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

normalize_csv() {
  v=$(trim_spaces "$1")
  printf '%s' "$v" | sed 's/[[:space:]]//g'
}

is_semver() {
  printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
}

list_package_names() {
  {
    grep '^pkg\.' "$manifest" 2>/dev/null | sed -E 's/^pkg\.([^=]+)=.*$/\1/' || true
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$manifest" 2>/dev/null | \
      grep -v '^project=' | grep -v '^pkg\.' | grep -v '^ver\.' | grep -v '^deps\.' | sed -E 's/=.*$//' || true
  } | awk 'NF { if (!seen[$0]++) print $0 }'
}

get_pkg_path() {
  name=$1
  line=$(grep "^pkg\.${name}=" "$manifest" 2>/dev/null | tail -n1 || true)
  if [ -z "$line" ]; then
    line=$(grep "^${name}=" "$manifest" 2>/dev/null | tail -n1 || true)
  fi
  [ -n "$line" ] || return 1
  printf '%s\n' "${line#*=}"
}

get_pkg_version() {
  name=$1
  line=$(grep "^ver\.${name}=" "$manifest" 2>/dev/null | tail -n1 || true)
  if [ -z "$line" ]; then
    printf '0.0.0\n'
    return 0
  fi
  printf '%s\n' "${line#*=}"
}

get_pkg_deps() {
  name=$1
  line=$(grep "^deps\.${name}=" "$manifest" 2>/dev/null | tail -n1 || true)
  if [ -z "$line" ]; then
    printf '\n'
    return 0
  fi
  printf '%s\n' "${line#*=}"
}

write_manifest() {
  project=$1
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT

  {
    echo "# cy package manifest"
    echo "project=$project"
    list_package_names | while IFS= read -r name; do
      [ -n "$name" ] || continue
      path=$(get_pkg_path "$name" || true)
      [ -n "$path" ] || continue
      ver=$(get_pkg_version "$name")
      deps=$(get_pkg_deps "$name")
      deps=$(normalize_csv "$deps")
      echo "pkg.$name=$path"
      echo "ver.$name=$ver"
      echo "deps.$name=$deps"
    done
  } > "$tmp"

  mv "$tmp" "$manifest"
  trap - EXIT
}

project_name() {
  project=$(grep '^project=' "$manifest" 2>/dev/null | head -n1 | sed 's/^project=//' || true)
  [ -n "$project" ] || project="cy-project"
  printf '%s\n' "$project"
}

cmd=${1:-}
case "$cmd" in
  init)
    project=${2:-cy-project}
    if [ -f "$manifest" ]; then
      echo "$manifest already exists"
      exit 0
    fi
    {
      echo "# cy package manifest"
      echo "project=$project"
    } > "$manifest"
    echo "Created $manifest"
    ;;

  add)
    ensure_manifest
    name=${2:-}
    path=${3:-}
    arg3=${4:-}
    arg4=${5:-}
    [ -n "$name" ] && [ -n "$path" ] || { usage; exit 1; }

    ver="0.0.0"
    deps=""
    if [ -n "$arg3" ]; then
      if is_semver "$arg3"; then
        ver="$arg3"
        deps=${arg4:-}
      else
        deps="$arg3"
        if [ -n "$arg4" ]; then
          if is_semver "$arg4"; then
            ver="$arg4"
          else
            echo "Error: fourth argument must be a semver version when third argument is deps" >&2
            exit 1
          fi
        fi
      fi
    fi
    deps=$(normalize_csv "$deps")

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    grep -v "^pkg\.${name}=" "$manifest" | grep -v "^ver\.${name}=" | grep -v "^deps\.${name}=" | \
      grep -v "^${name}=" > "$tmp" || true
    mv "$tmp" "$manifest"
    trap - EXIT

    {
      echo "pkg.$name=$path"
      echo "ver.$name=$ver"
      echo "deps.$name=$deps"
    } >> "$manifest"

    write_manifest "$(project_name)"
    echo "Added $name -> $path (version $ver)"
    ;;

  dep)
    ensure_manifest
    name=${2:-}
    deps=${3:-}
    [ -n "$name" ] || { usage; exit 1; }

    if ! get_pkg_path "$name" >/dev/null 2>&1; then
      echo "Error: package '$name' not found" >&2
      exit 1
    fi

    deps=$(normalize_csv "$deps")

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    grep -v "^deps\.${name}=" "$manifest" > "$tmp" || true
    mv "$tmp" "$manifest"
    trap - EXIT

    echo "deps.$name=$deps" >> "$manifest"
    write_manifest "$(project_name)"
    echo "Updated dependencies for $name"
    ;;

  version)
    ensure_manifest
    name=${2:-}
    ver=${3:-}
    [ -n "$name" ] && [ -n "$ver" ] || { usage; exit 1; }
    if ! is_semver "$ver"; then
      echo "Error: version must match MAJOR.MINOR.PATCH" >&2
      exit 1
    fi

    if ! get_pkg_path "$name" >/dev/null 2>&1; then
      echo "Error: package '$name' not found" >&2
      exit 1
    fi

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    grep -v "^ver\.${name}=" "$manifest" > "$tmp" || true
    mv "$tmp" "$manifest"
    trap - EXIT

    echo "ver.$name=$ver" >> "$manifest"
    write_manifest "$(project_name)"
    echo "Updated version for $name to $ver"
    ;;

  remove)
    ensure_manifest
    name=${2:-}
    [ -n "$name" ] || { usage; exit 1; }

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    grep -v "^pkg\.${name}=" "$manifest" | grep -v "^ver\.${name}=" | grep -v "^deps\.${name}=" | \
      grep -v "^${name}=" > "$tmp" || true
    mv "$tmp" "$manifest"
    trap - EXIT

    write_manifest "$(project_name)"
    echo "Removed $name"
    ;;

  list)
    ensure_manifest
    list_package_names | while IFS= read -r name; do
      [ -n "$name" ] || continue
      path=$(get_pkg_path "$name" || true)
      [ -n "$path" ] || continue
      ver=$(get_pkg_version "$name")
      deps=$(normalize_csv "$(get_pkg_deps "$name")")
      if [ -n "$deps" ]; then
        echo "$name=$path version=$ver deps=$deps"
      else
        echo "$name=$path version=$ver"
      fi
    done
    ;;

  path)
    ensure_manifest
    name=${2:-}
    [ -n "$name" ] || { usage; exit 1; }
    path=$(get_pkg_path "$name" || true)
    [ -n "$path" ] || { echo "Error: package '$name' not found" >&2; exit 1; }
    echo "$path"
    ;;

  resolve)
    ensure_manifest
    roots=$(normalize_csv "${2:-}")

    awk -F= -v roots="$roots" '
      function trim(s) {
        gsub(/^[ \t\r\n]+/, "", s)
        gsub(/[ \t\r\n]+$/, "", s)
        return s
      }

      function is_semver(v) {
        return v ~ /^[0-9]+\.[0-9]+\.[0-9]+$/
      }

      function split_semver(v, out, n) {
        n = split(v, out, ".")
        if (n != 3) return 0
        return 1
      }

      function cmp_semver(a, b, A, B, i) {
        split_semver(a, A)
        split_semver(b, B)
        for (i = 1; i <= 3; i++) {
          if ((A[i] + 0) < (B[i] + 0)) return -1
          if ((A[i] + 0) > (B[i] + 0)) return 1
        }
        return 0
      }

      function next_major(v, S) {
        split_semver(v, S)
        return (S[1] + 1) ".0.0"
      }

      function next_minor(v, S) {
        split_semver(v, S)
        return S[1] "." (S[2] + 1) ".0"
      }

      function next_patch(v, S) {
        split_semver(v, S)
        return S[1] "." S[2] "." (S[3] + 1)
      }

      function constraint_ok(ver, c, base, S, lo, hi) {
        c = trim(c)
        if (c == "") return 1

        if (substr(c, 1, 2) == ">=") {
          base = substr(c, 3)
          if (!is_semver(base)) return 0
          return cmp_semver(ver, base) >= 0
        }
        if (substr(c, 1, 2) == "<=") {
          base = substr(c, 3)
          if (!is_semver(base)) return 0
          return cmp_semver(ver, base) <= 0
        }
        if (substr(c, 1, 1) == ">") {
          base = substr(c, 2)
          if (!is_semver(base)) return 0
          return cmp_semver(ver, base) > 0
        }
        if (substr(c, 1, 1) == "<") {
          base = substr(c, 2)
          if (!is_semver(base)) return 0
          return cmp_semver(ver, base) < 0
        }
        if (substr(c, 1, 1) == "=") {
          base = substr(c, 2)
          if (!is_semver(base)) return 0
          return cmp_semver(ver, base) == 0
        }
        if (substr(c, 1, 1) == "^") {
          base = substr(c, 2)
          if (!is_semver(base)) return 0
          split_semver(base, S)
          lo = base
          if (S[1] + 0 > 0) {
            hi = next_major(base)
          } else if (S[2] + 0 > 0) {
            hi = "0." (S[2] + 1) ".0"
          } else {
            hi = "0.0." (S[3] + 1)
          }
          return cmp_semver(ver, lo) >= 0 && cmp_semver(ver, hi) < 0
        }
        if (substr(c, 1, 1) == "~") {
          base = substr(c, 2)
          if (!is_semver(base)) return 0
          lo = base
          hi = next_minor(base)
          return cmp_semver(ver, lo) >= 0 && cmp_semver(ver, hi) < 0
        }

        if (!is_semver(c)) return 0
        return cmp_semver(ver, c) == 0
      }

      function add_pkg(name, path) {
        name = trim(name)
        if (name == "") return
        if (!(name in pkg)) order[++order_n] = name
        pkg[name] = trim(path)
      }

      function add_constraint(dep, c, src) {
        key = dep SUBSEP (++constraint_n[dep])
        constraint_val[key] = c
        constraint_src[key] = src
      }

      function visit(name, n, dep_arr, i, token, at, dep, c, dep_ver, key, idx) {
        name = trim(name)
        if (name == "") return

        if (!(name in pkg)) {
          printf("Error: package '\''%s'\'' not found\n", name) > "/dev/stderr"
          has_error = 1
          return
        }

        if (state[name] == 1) {
          printf("Error: dependency cycle detected at '\''%s'\''\n", name) > "/dev/stderr"
          has_error = 1
          return
        }
        if (state[name] == 2) return

        state[name] = 1

        n = split(deps[name], dep_arr, ",")
        for (i = 1; i <= n; i++) {
          token = trim(dep_arr[i])
          if (token == "") continue

          at = index(token, "@")
          if (at > 0) {
            dep = trim(substr(token, 1, at - 1))
            c = trim(substr(token, at + 1))
          } else {
            dep = token
            c = ""
          }

          if (!(dep in pkg)) {
            printf("Error: package '\''%s'\'' depends on missing package '\''%s'\''\n", name, dep) > "/dev/stderr"
            has_error = 1
            continue
          }

          dep_ver = version[dep]
          add_constraint(dep, c, name)
          if (c != "" && !constraint_ok(dep_ver, c)) {
            printf("Error: version conflict: %s requires %s@%s but %s is %s\n", name, dep, c, dep, dep_ver) > "/dev/stderr"
            has_error = 1
            continue
          }

          visit(dep)
        }

        state[name] = 2
        if (!(name in emitted)) {
          emitted[name] = 1
          resolved[++resolved_n] = name
        }
      }

      /^#/ || /^[[:space:]]*$/ { next }
      /^project=/ { next }

      /^pkg\./ {
        name = $1
        sub(/^pkg\./, "", name)
        add_pkg(name, $2)
        next
      }

      /^ver\./ {
        name = $1
        sub(/^ver\./, "", name)
        version[name] = trim($2)
        next
      }

      /^deps\./ {
        name = $1
        sub(/^deps\./, "", name)
        deps[name] = trim($2)
        next
      }

      {
        if ($1 ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
          add_pkg($1, $2)
        }
      }

      END {
        for (i = 1; i <= order_n; i++) {
          name = order[i]
          if (!(name in version) || trim(version[name]) == "") version[name] = "0.0.0"
          if (!is_semver(version[name])) {
            printf("Error: package %s has invalid version %s\n", name, version[name]) > "/dev/stderr"
            has_error = 1
          }
        }

        if (has_error) exit 1

        if (roots == "") {
          for (i = 1; i <= order_n; i++) visit(order[i])
        } else {
          n = split(roots, root_arr, ",")
          for (i = 1; i <= n; i++) visit(root_arr[i])
        }

        if (has_error) exit 1
        for (i = 1; i <= resolved_n; i++) print resolved[i]
      }
    ' "$manifest"
    ;;

  *)
    usage
    exit 1
    ;;
esac
