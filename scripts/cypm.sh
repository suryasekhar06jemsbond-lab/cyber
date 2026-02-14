#!/usr/bin/env sh
set -eu

manifest="ny.pkg"
lockfile="ny.lock"
registry_config="nypm.config"

usage() {
  cat <<'USAGE'
Usage: nypm <command> [args]
Commands:
  init [project]
  add <name> <path> [version] [deps_csv]
  add-remote <name> [constraint]
  dep <name> <deps_csv>
  version <name> <version>
  remove <name>
  list
  path <name>
  search [pattern]
  publish <name> <version> <path> [deps_csv]
  registry [get|set <path_or_url>]
  resolve [roots_csv]
  lock [roots_csv]
  verify-lock
  install [roots_csv] [target_dir]
  doctor

Version examples:
  1.2.3
Dependency examples:
  core@^1.0.0,util@>=2.1.0,fmt@1.4.2
Note:
  quote constraints containing > or < in POSIX shells
USAGE
}

ensure_manifest() {
  if [ ! -f "$manifest" ]; then
    echo "Error: $manifest not found. Run: nypm init" >&2
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
    echo "# ny package manifest"
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
  [ -n "$project" ] || project="ny-project"
  printf '%s\n' "$project"
}

registry_get_source() {
  line=$(grep '^registry=' "$registry_config" 2>/dev/null | tail -n1 || true)
  if [ -n "$line" ]; then
    printf '%s\n' "${line#registry=}"
    return 0
  fi
  printf 'ny.registry\n'
}

registry_set_source() {
  src=$1
  {
    echo "# nypm configuration"
    echo "registry=$src"
  } > "$registry_config"
}

registry_is_url() {
  case "$1" in
    http://*|https://*) return 0 ;;
    *) return 1 ;;
  esac
}

path_is_absolute() {
  p=$1
  case "$p" in
    /*) return 0 ;;
  esac
  printf '%s' "$p" | grep -Eq '^[A-Za-z]:[\\/]'
}

registry_fetch_to_file() {
  src=$1
  out=$2
  if registry_is_url "$src"; then
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$src" -o "$out"
      return 0
    fi
    if command -v wget >/dev/null 2>&1; then
      wget -qO "$out" "$src"
      return 0
    fi
    echo "Error: neither curl nor wget is available to fetch registry URL" >&2
    return 1
  fi

  [ -f "$src" ] || {
    echo "Error: registry source not found: $src" >&2
    return 1
  }
  cp "$src" "$out"
}

registry_entry_resolve_source() {
  registry_src=$1
  entry_src=$2

  if registry_is_url "$entry_src"; then
    printf '%s\n' "$entry_src"
    return 0
  fi
  if path_is_absolute "$entry_src"; then
    printf '%s\n' "$entry_src"
    return 0
  fi

  if registry_is_url "$registry_src"; then
    base=${registry_src%/*}
    printf '%s/%s\n' "$base" "$entry_src"
    return 0
  fi

  base_dir=$(dirname "$registry_src")
  if [ "$base_dir" = "." ]; then
    base_dir=$(pwd)
  fi
  printf '%s/%s\n' "$base_dir" "$entry_src"
}

semver_cmp() {
  a=$1
  b=$2
  awk -v a="$a" -v b="$b" '
    function split_sem(v, out, n) {
      n = split(v, out, ".")
      return n == 3
    }
    BEGIN {
      if (!split_sem(a, A) || !split_sem(b, B)) {
        print 0
        exit
      }
      for (i = 1; i <= 3; i++) {
        if ((A[i] + 0) < (B[i] + 0)) { print -1; exit }
        if ((A[i] + 0) > (B[i] + 0)) { print 1; exit }
      }
      print 0
    }
  '
}

semver_next_major() {
  v=$1
  awk -v v="$v" '
    BEGIN {
      n = split(v, S, ".")
      if (n != 3) { print ""; exit }
      print (S[1] + 1) ".0.0"
    }
  '
}

semver_next_minor() {
  v=$1
  awk -v v="$v" '
    BEGIN {
      n = split(v, S, ".")
      if (n != 3) { print ""; exit }
      print S[1] "." (S[2] + 1) ".0"
    }
  '
}

constraint_ok_sh() {
  ver=$1
  c=$(trim_spaces "$2")
  [ -z "$c" ] && return 0

  case "$c" in
    '>='*)
      base=${c#>=}
      is_semver "$base" || return 1
      [ "$(semver_cmp "$ver" "$base")" -ge 0 ]
      return
      ;;
    '<='*)
      base=${c#<=}
      is_semver "$base" || return 1
      [ "$(semver_cmp "$ver" "$base")" -le 0 ]
      return
      ;;
    '>'*)
      base=${c#>}
      is_semver "$base" || return 1
      [ "$(semver_cmp "$ver" "$base")" -gt 0 ]
      return
      ;;
    '<'*)
      base=${c#<}
      is_semver "$base" || return 1
      [ "$(semver_cmp "$ver" "$base")" -lt 0 ]
      return
      ;;
    '='*)
      base=${c#=}
      is_semver "$base" || return 1
      [ "$(semver_cmp "$ver" "$base")" -eq 0 ]
      return
      ;;
    '^'*)
      base=${c#^}
      is_semver "$base" || return 1
      lo=$base
      maj=$(printf '%s\n' "$base" | cut -d. -f1)
      min=$(printf '%s\n' "$base" | cut -d. -f2)
      pat=$(printf '%s\n' "$base" | cut -d. -f3)
      if [ "$maj" -gt 0 ]; then
        hi=$(semver_next_major "$base")
      elif [ "$min" -gt 0 ]; then
        hi="0.$((min + 1)).0"
      else
        hi="0.0.$((pat + 1))"
      fi
      [ "$(semver_cmp "$ver" "$lo")" -ge 0 ] && [ "$(semver_cmp "$ver" "$hi")" -lt 0 ]
      return
      ;;
    '~'*)
      base=${c#~}
      is_semver "$base" || return 1
      lo=$base
      hi=$(semver_next_minor "$base")
      [ "$(semver_cmp "$ver" "$lo")" -ge 0 ] && [ "$(semver_cmp "$ver" "$hi")" -lt 0 ]
      return
      ;;
  esac

  is_semver "$c" || return 1
  [ "$(semver_cmp "$ver" "$c")" -eq 0 ]
}

cmd=${1:-}
case "$cmd" in
  init)
    project=${2:-ny-project}
    if [ -f "$manifest" ]; then
      echo "$manifest already exists"
      exit 0
    fi
    {
      echo "# ny package manifest"
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

  add-remote)
    ensure_manifest
    name=${2:-}
    constraint=${3:-}
    [ -n "$name" ] || { usage; exit 1; }

    registry_src=$(registry_get_source)
    reg_tmp=$(mktemp)
    trap 'rm -f "$reg_tmp"' EXIT
    registry_fetch_to_file "$registry_src" "$reg_tmp"

    best_ver=""
    best_source=""
    best_deps=""

    while IFS='|' read -r r_name r_ver r_source r_deps _; do
      r_name=$(trim_spaces "${r_name:-}")
      r_ver=$(trim_spaces "${r_ver:-}")
      r_source=$(trim_spaces "${r_source:-}")
      r_deps=$(normalize_csv "${r_deps:-}")
      [ -n "$r_name" ] || continue
      [ "$r_name" = "$name" ] || continue
      is_semver "$r_ver" || continue
      [ -n "$r_source" ] || continue

      if ! constraint_ok_sh "$r_ver" "$constraint"; then
        continue
      fi

      if [ -z "$best_ver" ] || [ "$(semver_cmp "$r_ver" "$best_ver")" -gt 0 ]; then
        best_ver="$r_ver"
        best_source="$r_source"
        best_deps="$r_deps"
      fi
    done < "$reg_tmp"

    rm -f "$reg_tmp"
    trap - EXIT

    if [ -z "$best_ver" ]; then
      if [ -n "$constraint" ]; then
        echo "Error: no registry match for $name@$constraint" >&2
      else
        echo "Error: no registry match for $name" >&2
      fi
      exit 1
    fi

    resolved_source=$(registry_entry_resolve_source "$registry_src" "$best_source")
    if [ -n "$best_deps" ]; then
      "$0" add "$name" "$resolved_source" "$best_ver" "$best_deps"
    else
      "$0" add "$name" "$resolved_source" "$best_ver"
    fi
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

  registry)
    subcmd=${2:-get}
    case "$subcmd" in
      get)
        registry_get_source
        ;;
      set)
        src=${3:-}
        [ -n "$src" ] || { echo "Error: registry set expects <path_or_url>" >&2; exit 1; }
        registry_set_source "$src"
        echo "Registry set to $src"
        ;;
      *)
        echo "Error: unknown registry subcommand '$subcmd'" >&2
        usage >&2
        exit 1
        ;;
    esac
    ;;

  search)
    pattern=${2:-}
    registry_src=$(registry_get_source)
    reg_tmp=$(mktemp)
    trap 'rm -f "$reg_tmp"' EXIT
    registry_fetch_to_file "$registry_src" "$reg_tmp"

    while IFS='|' read -r r_name r_ver r_source r_deps _; do
      r_name=$(trim_spaces "${r_name:-}")
      r_ver=$(trim_spaces "${r_ver:-}")
      r_source=$(trim_spaces "${r_source:-}")
      r_deps=$(normalize_csv "${r_deps:-}")
      [ -n "$r_name" ] || continue
      [ -n "$r_ver" ] || continue
      [ -n "$r_source" ] || continue
      if [ -n "$pattern" ]; then
        if ! printf '%s %s %s\n' "$r_name" "$r_ver" "$r_source" | grep -i -- "$pattern" >/dev/null 2>&1; then
          continue
        fi
      fi
      if [ -n "$r_deps" ]; then
        echo "$r_name version=$r_ver source=$r_source deps=$r_deps"
      else
        echo "$r_name version=$r_ver source=$r_source"
      fi
    done < "$reg_tmp"

    rm -f "$reg_tmp"
    trap - EXIT
    ;;

  publish)
    name=${2:-}
    ver=${3:-}
    src_path=${4:-}
    deps=$(normalize_csv "${5:-}")
    [ -n "$name" ] && [ -n "$ver" ] && [ -n "$src_path" ] || { usage; exit 1; }
    is_semver "$ver" || { echo "Error: version must match MAJOR.MINOR.PATCH" >&2; exit 1; }
    [ -e "$src_path" ] || { echo "Error: publish path not found: $src_path" >&2; exit 1; }

    registry_src=$(registry_get_source)
    if registry_is_url "$registry_src"; then
      echo "Error: publish supports only file registry sources" >&2
      exit 1
    fi

    mkdir -p "$(dirname "$registry_src")"
    [ -f "$registry_src" ] || : > "$registry_src"

    tmp=$(mktemp)
    trap 'rm -f "$tmp"' EXIT
    awk -F'|' -v n="$name" -v v="$ver" '
      /^[[:space:]]*$/ { print; next }
      /^[[:space:]]*#/ { print; next }
      {
        if ($1 == n && $2 == v) next
        print
      }
    ' "$registry_src" > "$tmp"
    printf '%s|%s|%s|%s\n' "$name" "$ver" "$src_path" "$deps" >> "$tmp"
    mv "$tmp" "$registry_src"
    trap - EXIT
    echo "Published $name $ver to $registry_src"
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

  lock)
    ensure_manifest
    roots=$(normalize_csv "${2:-}")
    resolved=$("$0" resolve "$roots")

    {
      echo "# ny lockfile v1"
      if [ -n "$roots" ]; then
        echo "roots=$roots"
      else
        echo "roots=*"
      fi

      printf '%s\n' "$resolved" | while IFS= read -r name; do
        [ -n "$name" ] || continue
        path=$(get_pkg_path "$name" || true)
        [ -n "$path" ] || continue
        ver=$(get_pkg_version "$name")
        echo "pkg.$name=$path"
        echo "ver.$name=$ver"
      done
    } > "$lockfile"

    echo "Wrote $lockfile"
    ;;

  verify-lock)
    ensure_manifest
    if [ ! -f "$lockfile" ]; then
      echo "Error: $lockfile not found. Run: nypm lock" >&2
      exit 1
    fi

    err=0
    while IFS= read -r line; do
      case "$line" in
        pkg.*=*)
          name=${line#pkg.}
          name=${name%%=*}
          locked_path=${line#*=}
          current_path=$(get_pkg_path "$name" || true)
          if [ -z "$current_path" ]; then
            echo "Error: lock references missing package '$name'" >&2
            err=1
            continue
          fi
          if [ "$locked_path" != "$current_path" ]; then
            echo "Error: lock path mismatch for '$name': lock=$locked_path manifest=$current_path" >&2
            err=1
          fi
          if [ ! -e "$locked_path" ]; then
            echo "Error: locked path does not exist for '$name': $locked_path" >&2
            err=1
          fi
          ;;
        ver.*=*)
          name=${line#ver.}
          name=${name%%=*}
          locked_ver=${line#*=}
          current_ver=$(get_pkg_version "$name")
          if [ "$locked_ver" != "$current_ver" ]; then
            echo "Error: lock version mismatch for '$name': lock=$locked_ver manifest=$current_ver" >&2
            err=1
          fi
          ;;
      esac
    done < "$lockfile"

    if [ "$err" -ne 0 ]; then
      exit 1
    fi
    echo "Lockfile verified"
    ;;

  install)
    ensure_manifest
    roots=$(normalize_csv "${2:-}")
    target=${3:-.nydeps}
    resolved=$("$0" resolve "$roots")

    mkdir -p "$target"
    log_file="$target/.install-log"
    : > "$log_file"

    err=0
    resolved_tmp=$(mktemp)
    trap 'rm -f "$resolved_tmp"' EXIT
    printf '%s\n' "$resolved" > "$resolved_tmp"
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      path=$(get_pkg_path "$name" || true)
      ver=$(get_pkg_version "$name")
      if [ -z "$path" ]; then
        echo "Error: package '$name' not found" >&2
        err=1
        continue
      fi
      if [ ! -e "$path" ]; then
        echo "Error: package path for '$name' does not exist: $path" >&2
        err=1
        continue
      fi

      dest="$target/$name"
      rm -rf "$dest"
      if [ -d "$path" ]; then
        cp -R "$path" "$dest"
      else
        cp "$path" "$dest"
      fi
      echo "$name $ver $path" >> "$log_file"
    done < "$resolved_tmp"
    rm -f "$resolved_tmp"
    trap - EXIT

    if [ "$err" -ne 0 ]; then
      exit 1
    fi
    echo "Installed packages to $target"
    ;;

  doctor)
    ensure_manifest
    err=0
    list_tmp=$(mktemp)
    trap 'rm -f "$list_tmp"' EXIT
    list_package_names > "$list_tmp"

    while IFS= read -r name; do
      [ -n "$name" ] || continue

      path=$(get_pkg_path "$name" || true)
      ver=$(get_pkg_version "$name")
      deps=$(normalize_csv "$(get_pkg_deps "$name")")

      if [ -z "$path" ]; then
        echo "Error: package '$name' has no path entry" >&2
        err=1
      elif [ ! -e "$path" ]; then
        echo "Error: package '$name' path does not exist: $path" >&2
        err=1
      fi

      if ! is_semver "$ver"; then
        echo "Error: package '$name' has invalid version '$ver'" >&2
        err=1
      fi

      if [ -n "$deps" ]; then
        old_ifs=$IFS
        IFS=','
        set -- $deps
        IFS=$old_ifs
        for spec in "$@"; do
          dep_name=${spec%%@*}
          [ -n "$dep_name" ] || continue
          if ! get_pkg_path "$dep_name" >/dev/null 2>&1; then
            echo "Error: package '$name' depends on missing package '$dep_name'" >&2
            err=1
          fi
        done
      fi
    done < "$list_tmp"
    rm -f "$list_tmp"
    trap - EXIT

    if ! "$0" resolve >/dev/null 2>&1; then
      echo "Error: dependency resolution failed" >&2
      err=1
    fi

    lock_state="missing"
    if [ -f "$lockfile" ]; then
      lock_state="present"
      if ! "$0" verify-lock >/dev/null 2>&1; then
        echo "Error: lockfile verification failed" >&2
        err=1
      else
        lock_state="verified"
      fi
    fi

    if [ "$err" -ne 0 ]; then
      exit 1
    fi
    echo "Doctor OK: lockfile=$lock_state"
    ;;

  *)
    usage
    exit 1
    ;;
esac
