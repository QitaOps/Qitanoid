# Qitanoid Production Guide

## Runtime target

- Primary target: Linux Docker hosts or Kubernetes Linux nodes.
- Recommended architecture: `linux/amd64`.
- `macOS` and `Windows` should be treated as development environments, not production browser hosts.
- Android emulator workloads additionally require KVM acceleration exposed to the Docker daemon and child emulator containers.

For Android emulator rollout details, use [`README_ANDROID_KVM.md`](/Users/alexey/projects/qitaopsqa/README_ANDROID_KVM.md).

For cluster-native rollout details, use [`README_KUBERNETES.md`](/Users/alexey/projects/qitaopsqa/README_KUBERNETES.md) and [`README_OPENSHIFT.md`](/Users/alexey/projects/qitaopsqa/README_OPENSHIFT.md).

## Minimum deployment posture

1. Build and push versioned browser images.
2. Run the hub with baked runtime scripts by setting `QITANOID_BAKED_RUNTIME=true`.
3. Mount persistent storage for `browsers.json` and recorded videos.
4. Set `QITANOID_ADMIN_TOKEN` for destructive or administrative API calls.
5. Put the hub behind TLS termination and an authenticated reverse proxy.
6. Verify licenses with an Ed25519 public key by setting `QITANOID_LICENSE_PUBLIC_KEY_FILE` or `QITANOID_LICENSE_PUBLIC_KEY`.
7. For Android emulator targets, expose `/dev/kvm` to the hub host and allow the hub to create privileged child containers when required.

## Recommended environment

Use [`.env.production.example`](/Users/alexey/projects/qitaopsqa/.env.production.example) as the backend template and [`frontend/.env.production.example`](/Users/alexey/projects/qitaopsqa/frontend/.env.production.example) for the frontend build.

Key settings:

- `QITANOID_ADMIN_TOKEN`
  Protects admin/destructive endpoints such as session delete, video delete, and browsers config read/write.
- `QITANOID_LICENSE_PUBLIC_KEY_FILE`
  Verifies signed `QITANOID-LICENSE-V2` licenses with an Ed25519 public key stored on disk.
- `QITANOID_BAKED_RUNTIME=true`
  Required when the container image already contains `entrypoint.sh` and `record.sh`.
- `QITANOID_BROWSER_SHM_SIZE=2g`
  Strongly recommended for Chromium-based browsers.
- `QITANOID_BROWSER_MEMORY=4g`
  Recommended baseline per browser container.
- `QITANOID_BROWSER_CPUS=2`
  Recommended baseline per browser container.
- `QITANOID_ORCHESTRATOR=kubernetes` or `openshift`
  Switches the session runtime from Docker containers to in-cluster pods.
- Android emulator targets should generally be scheduled on dedicated Linux/KVM nodes.

## Frontend build

For a normal user-facing dashboard:

```bash
cd frontend
cp .env.production.example .env.production
npm ci
npm run build
```

For a private admin dashboard, you may inject `VITE_QITANOID_ADMIN_TOKEN`, but only if that frontend is not publicly exposed.

## Backend verification

Run these before a release:

```bash
go test . ./cmd/... ./pkg/...
npm --prefix frontend run build
npm --prefix frontend audit --omit=dev
npm --prefix landing audit --omit=dev
"$(go env GOPATH)/bin/govulncheck" . ./cmd/... ./pkg/...
```

## License workflow

Generate a signing keypair:

```bash
go run ./cmd/keygen -generate-keypair -private-key deploy/licenses/license-private.pem -public-key deploy/licenses/license-public.pem
```

Generate a signed production license:

```bash
go run ./cmd/keygen -private-key deploy/licenses/license-private.pem -sessions 50 -days 365 -o deploy/licenses/license-50.key
```

Then configure the hub with:

- `QITANOID_LICENSE_PUBLIC_KEY_FILE=/etc/qitanoid/license-public.pem`
- the signed license value stored in `browsers.json`

## Operational notes

- `/healthz` is a liveness endpoint.
- `/readyz` is a readiness endpoint.
- `/metrics` exposes Prometheus metrics.
- `/api/browsers` now redacts the stored license value in responses.
- Browser settings and destructive endpoints should not be exposed without an admin token or external auth.

## Residual risks

- The new v2 license format uses Ed25519 signatures and removes the old shared-secret weakness, but licensing is still a commercial control. Do not rely on it as your only security boundary.
- Public browser automation infrastructure should still sit behind ingress auth, TLS, and request-level monitoring.
- For very high concurrency, move from a single Docker host to Kubernetes with externalized session state and object storage.
- The current Kubernetes/OpenShift deployment remains single-replica because active sessions are still held in memory.
