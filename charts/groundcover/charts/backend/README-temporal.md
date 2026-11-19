# Temporal Integration in Backend Chart

## Configuration

### Production with External PostgreSQL

For production deployments using RDS or external PostgreSQL:

```yaml
global:
  temporal:
    enabled: true

backend:
  temporalConfig:
    postgres:
      host: "NONE"  # Using NONE means read from secret
      port: 5432
      database: temporal
      username: postgres
      secret:
        name: "managed-postgres-credentials"
        passwordKey: "password"
        hostKey: "host"
        portKey: "port"
        usernameKey: "username"

  # Temporal server config uses environment variable placeholders
  temporal:
    # Must provide additionalEnv with all database configuration
    server:
      frontend:
        additionalEnv:
          - name: TEMPORAL_STORE_HOST
            valueFrom:
              secretKeyRef:
                name: "managed-postgres-credentials"
                key: "host"
          - name: TEMPORAL_VISIBILITY_HOST
            valueFrom:
              secretKeyRef:
                name: "managed-postgres-credentials"
                key: "host"
          - name: TEMPORAL_STORE_PORT
            value: "5432"
          - name: TEMPORAL_VISIBILITY_PORT
            value: "5432"
          - name: TEMPORAL_STORE_DATABASE
            value: "temporal"
          - name: TEMPORAL_VISIBILITY_DATABASE
            value: "temporal_visibility"
          - name: TEMPORAL_STORE_USER
            value: "postgres"
          - name: TEMPORAL_VISIBILITY_USER
            value: "postgres"
          - name: TEMPORAL_STORE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: "managed-postgres-credentials"
                key: "password"
          - name: TEMPORAL_VISIBILITY_STORE_PASSWORD
            valueFrom:
              secretKeyRef:
                name: "managed-postgres-credentials"
                key: "password"
      history:
        additionalEnv:
          # Same as frontend - repeat all env vars
      matching:
        additionalEnv:
          # Same as frontend - repeat all env vars
      worker:
        additionalEnv:
          # Same as frontend - repeat all env vars
```

The secret must contain:
- `host`: PostgreSQL hostname
- `port`: PostgreSQL port (optional if using default 5432)
- `username`: Database username (optional if using default postgres)
- `password`: Database password

### Development with Internal PostgreSQL

For development environments using the redeploy script:

```bash
# Simply execute redeploy - the script handles all configuration
./scripts/deployments/redeploy_groundcover.sh
```

The redeploy script automatically:
- Configures temporal to use the internal PostgreSQL
- Sets up all required environment variables
- Creates the necessary databases

### Development with External PostgreSQL

To use an external PostgreSQL in dev (e.g., from another namespace):

```bash
# Set the external secret name
TEMPORAL_EXTERNAL_SECRET=your-secret-name ./scripts/deployments/redeploy_groundcover.sh
```

The secret must contain `host`, `port`, `username`, and `password` keys.

## How It Works

1. **Schema Management**:
   - `update-schema` runs from the admin-tools image (`/etc/temporal/schema/postgresql/v12/{temporal,visibility}/versioned`)
   - External Postgres: a `pre-install,pre-upgrade` hook creates databases and runs those migrations before server pods
   - Bundled Postgres: install uses a regular Job (not `post-install`) so Helm `--wait` is not blocked on Temporal readiness; upgrades use `pre-upgrade`. Server Deployments include a `wait-for-schema` initContainer that blocks until temporal v1.18 and visibility v1.13 are present
   - Before migrating, the job checks that `temporalConfig.adminTools.image` contains the required schema dirs (`temporal` v1.18 and visibility v1.13). A stale image (for example 1.29, whose visibility tree stops at v1.9) exits nonzero and Helm does not roll out Temporal servers
   - After `update-schema`, the job reads `schema_version.curr_version` on both databases and fails if either is below those required versions
   - The job is idempotent and safe to run multiple times

2. **Database Configuration**:
   - If `global.postgresql.enabled: true`, uses internal PostgreSQL
   - Otherwise, expects `temporalConfig.database.existingSecret` or explicit host/port
   - Automatically creates `temporal` and `temporal_visibility` databases

3. **Components Deployed**:
   - Frontend service (gRPC endpoint)
   - History service
   - Matching service
   - Worker service
   - Web UI
   - Admin tools

## Troubleshooting

If temporal pods are not showing up:
1. Check if `global.temporal.enabled: true` is set
2. Verify the temporal-schema-setup job completed successfully
3. If server pods stay in Init (`wait-for-schema`), the Job has not reached temporal v1.18 / visibility v1.13 — check Job logs
4. If the job logs `admin-tools image is stale`, the configured `temporalConfig.adminTools.image` is older than Temporal 1.30 (missing visibility v1.13). Pin admin-tools and server to the same 1.30-mini tag and retry
5. Check the temporal subchart is being deployed: `helm list -n <namespace>`
6. Look for errors in: `kubectl logs -n <namespace> -l app.kubernetes.io/name=temporal`

## Node Pool Requirements

Temporal requires dedicated nodes with at least:
- 8.5 CPUs total across all pods
- 8.5GB RAM total across all pods

Configure your node pool accordingly in your infrastructure.

