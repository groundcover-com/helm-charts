SCHEMA_ROOT="${SCHEMA_ROOT:-/etc/temporal/schema/postgresql/v12}"

resolve_sql_env() {
  SQL_HOST="${SQL_HOST:-$TEMPORAL_STORE_HOST}"
  SQL_PORT="${SQL_PORT:-${TEMPORAL_STORE_PORT:-5432}}"
  SQL_USER="${SQL_USER:-$TEMPORAL_STORE_USER}"
  SQL_PASSWORD="${SQL_PASSWORD:-$TEMPORAL_STORE_PASSWORD}"
  TEMPORAL_DB="${TEMPORAL_DB:-$TEMPORAL_STORE_DATABASE}"
  VISIBILITY_DB="${VISIBILITY_DB:-$TEMPORAL_VISIBILITY_DATABASE}"
  export PGPASSWORD="${PGPASSWORD:-$SQL_PASSWORD}"
}

version_ge() {
  local a_major a_minor b_major b_minor
  a_major=${1%%.*}
  a_minor=${1#*.}
  a_minor=${a_minor%%.*}
  b_major=${2%%.*}
  b_minor=${2#*.}
  b_minor=${b_minor%%.*}
  a_minor=${a_minor:-0}
  b_minor=${b_minor:-0}
  if [ "$a_major" -gt "$b_major" ]; then
    return 0
  fi
  if [ "$a_major" -lt "$b_major" ]; then
    return 1
  fi
  [ "$a_minor" -ge "$b_minor" ]
}

assert_admin_tools_image() {
  local kind ver dir
  for kind in temporal visibility; do
    if [ "$kind" = temporal ]; then
      ver="${REQUIRED_TEMPORAL_SCHEMA}"
    else
      ver="${REQUIRED_VISIBILITY_SCHEMA}"
    fi
    dir="${SCHEMA_ROOT}/${kind}/versioned/v${ver}"
    if [ ! -d "$dir" ]; then
      echo "admin-tools image is stale: missing ${kind} schema v${ver} at ${dir}" >&2
      echo "present versions:" >&2
      ls "${SCHEMA_ROOT}/${kind}/versioned" >&2 || true
      return 1
    fi
  done
}

assert_database_schema() {
  local db required current
  resolve_sql_env
  db="${TEMPORAL_DB}"
  required="${REQUIRED_TEMPORAL_SCHEMA}"
  current=$(psql -h "$SQL_HOST" -p "$SQL_PORT" -U "$SQL_USER" -d "$db" -tAc "SELECT curr_version FROM schema_version")
  if [ -z "$current" ] || ! version_ge "$current" "$required"; then
    echo "schema version on ${db} is '${current}', required >= ${required}" >&2
    return 1
  fi
  db="${VISIBILITY_DB}"
  required="${REQUIRED_VISIBILITY_SCHEMA}"
  current=$(psql -h "$SQL_HOST" -p "$SQL_PORT" -U "$SQL_USER" -d "$db" -tAc "SELECT curr_version FROM schema_version")
  if [ -z "$current" ] || ! version_ge "$current" "$required"; then
    echo "schema version on ${db} is '${current}', required >= ${required}" >&2
    return 1
  fi
}

wait_for_database_schema() {
  local max="${WAIT_FOR_SCHEMA_ATTEMPTS:-120}"
  local sleep_s="${WAIT_FOR_SCHEMA_SLEEP:-5}"
  local i=0
  resolve_sql_env
  while [ "$i" -lt "$max" ]; do
    if assert_database_schema; then
      return 0
    fi
    i=$((i+1))
    echo "Attempt $i/${max}: schema not ready yet, waiting..."
    sleep "$sleep_s"
  done
  echo "timed out waiting for required schema versions" >&2
  return 1
}
