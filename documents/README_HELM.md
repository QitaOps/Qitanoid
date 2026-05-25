# Qitanoid Helm Guide

This document covers the Helm-based deployment of Qitanoid Hub and the dashboard UI.

The chart lives in [deploy/helm/qitanoid](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid).

## What The Chart Deploys

The chart can deploy:

- `hub`: the Go control plane
- `ui`: the React dashboard behind nginx
- runtime ConfigMaps for browser session scripts
- a bootstrap `browsers.json`
- optional PVC for config and videos
- optional ingress

For local Docker Desktop on macOS, the recommended path is:

- run both `hub` and `ui` inside Kubernetes
- expose `ui` with `kubectl port-forward`
- let `ui` proxy `/api`, `/wd/hub`, `/playwright/ws`, `/appium/wd/hub`, `/vnc`, and `/stream` to the in-cluster hub

That avoids the unreliable `NodePort` behavior you hit on Docker Desktop.

## Files

- Chart: [deploy/helm/qitanoid/Chart.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/Chart.yaml)
- Base values: [deploy/helm/qitanoid/values.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values.yaml)
- Docker Desktop values: [deploy/helm/qitanoid/values-docker-desktop.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values-docker-desktop.yaml)
- Production values: [deploy/helm/qitanoid/values-k8s-production.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values-k8s-production.yaml)
- User values example: [deploy/helm/qitanoid/values-user.example.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values-user.example.yaml)
- Video PVC values: [deploy/helm/qitanoid/values-video-pvc.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values-video-pvc.yaml)
- Video S3 values: [deploy/helm/qitanoid/values-video-s3.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values-video-s3.yaml)
- Docker Desktop S3 values: [deploy/helm/qitanoid/values-video-s3-docker-desktop.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/values-video-s3-docker-desktop.yaml)
- Local MinIO manifest: [deploy/k8s/minio-local.yaml](/Users/alexey/projects/qitaopsqa/deploy/k8s/minio-local.yaml)
- Docker Desktop hostPath PV: [deploy/k8s/docker-desktop-hostpath-pv.yaml](/Users/alexey/projects/qitaopsqa/deploy/k8s/docker-desktop-hostpath-pv.yaml)
- Hub port-forward helper: [deploy/helm/qitanoid/port-forward.sh](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/port-forward.sh)
- UI port-forward helper: [deploy/helm/qitanoid/port-forward-ui.sh](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/port-forward-ui.sh)
- Hub architecture: [ARCHITECTURE_HUB.md](/Users/alexey/projects/qitaopsqa/ARCHITECTURE_HUB.md)

## Prerequisites

- Docker Desktop with Kubernetes enabled
- current context set to `docker-desktop`
- `helm`
- enough free space in Docker Desktop so the node is not in `DiskPressure`

Check that first:

```bash
kubectl config use-context docker-desktop
kubectl --context docker-desktop describe node docker-desktop | rg -n "DiskPressure|Ready"
```

You want:

- `DiskPressure False`
- `Ready True`

## Local Image Build

Build both local images from this repo:

```bash
cd /Users/alexey/projects/qitaopsqa

docker build -t qitaops/qitaopsqa:local .
docker build -t qitaops/qitaopsqa-dashboard:local -f frontend/Dockerfile.production frontend
```

The dashboard image is generic. Runtime API and WebSocket targets are injected by the chart through `config.js`, so you do not need to rebuild the UI for every cluster.

## Local Browser Images For Docker Desktop ARM64

On Apple Silicon, the Kubernetes node inside Docker Desktop is `linux/arm64`.
That means upstream `selenium/standalone-chrome` and `selenium/standalone-edge` images cannot be pulled directly for runtime pods.

The Docker Desktop profile in this repo solves that by:

- building a local `arm64` Chrome runtime on top of `selenium/standalone-chromium`
- building local `arm64` Firefox runtime images
- switching the local browser catalog to those `*-arm64-local` tags
- hiding unsupported local targets from the launch API

Build those local browser images before installing or upgrading the chart:

```bash
cd /Users/alexey/projects/qitaopsqa
./deploy/helm/qitanoid/build-local-browser-images.sh
```

What gets built:

- `qitaops/selenium-chrome:145.0.7632.116-arm64-local`
- `qitaops/playwright-chrome:145.0.7632.116-arm64-local`
- `qitaops/selenium-firefox:147.0.4-arm64-local`
- `qitaops/playwright-firefox:147.0.4-arm64-local`

Current local Docker Desktop limitations:

- `Chrome` is backed by Chromium inside the local runtime image
- `Edge` is not exposed in the local launch catalog on `arm64`
- `Android` is not exposed in this local profile

## Install Hub And UI

This is the recommended local install:

```bash
cd /Users/alexey/projects/qitaopsqa

helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml
```

What this profile does:

- uses `qitaops/qitaopsqa:local` for the hub
- uses `qitaops/qitaopsqa-dashboard:local` for the UI
- uses `browsers-docker-desktop-arm64.json` as the browser catalog
- keeps both services internal as `ClusterIP`
- disables PVC by default for easier local startup
- enables the dashboard
- lowers browser session runtime to `0.5 CPU / 2Gi RAM / 1Gi shm` so a single `docker-desktop` node can actually schedule a smoke browser pod

## Access The UI

Expose the dashboard locally:

```bash
cd /Users/alexey/projects/qitaopsqa
./deploy/helm/qitanoid/port-forward-ui.sh
```

Then open:

- [http://127.0.0.1:8080](http://127.0.0.1:8080)

The UI already proxies back to the hub, so you do not need a second browser-facing port for normal usage.

## Access The Hub Directly

If you want to hit the hub API directly from CLI or test code:

```bash
cd /Users/alexey/projects/qitaopsqa
./deploy/helm/qitanoid/port-forward.sh
```

Then use:

- Hub: `http://127.0.0.1:4444`
- Selenium: `http://127.0.0.1:4444/wd/hub`
- Playwright WS: `ws://127.0.0.1:4444/playwright/ws`
- Appium: `http://127.0.0.1:4444/appium/wd/hub`

## Verify The Install

Check workloads:

```bash
kubectl --context docker-desktop -n qitanoid get pods,svc,configmap
```

Check rollout:

```bash
kubectl --context docker-desktop -n qitanoid rollout status deploy/qitanoid
kubectl --context docker-desktop -n qitanoid rollout status deploy/qitanoid-ui
```

Check logs:

```bash
kubectl --context docker-desktop -n qitanoid logs deploy/qitanoid --tail=100
kubectl --context docker-desktop -n qitanoid logs deploy/qitanoid-ui --tail=100
```

Run Helm tests:

```bash
helm -n qitanoid --kube-context docker-desktop test qitanoid
```

Current expected behavior:

- `qitanoid` deployment healthy
- `qitanoid-ui` deployment healthy
- helm tests pass for both hub and dashboard service

## Multi-Replica Hub With Redis

If you want the hub to be safe for multiple replicas, enable Redis and scale the hub.

Example on Docker Desktop:

```bash
cd /Users/alexey/projects/qitaopsqa

helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  --set redis.enabled=true \
  --set hub.replicaCount=2
```

What this changes:

- a bundled Redis deployment is created
- session metadata is stored outside the hub process
- SSE update events are published through Redis pub/sub
- any hub replica can answer `/api/sessions` consistently

Relevant values:

- `hub.replicaCount`
- `redis.enabled`
- `hub.redis.addr`
- `hub.redis.password`
- `hub.redis.db`
- `hub.redis.prefix`
- `hub.redis.connectTimeout`

The hub now waits for Redis on startup instead of crashing immediately if Redis is a few seconds late during rollout.

## Production Install Profile

For a real Kubernetes cluster, start from:

```bash
cp ./deploy/helm/qitanoid/values-user.example.yaml ./values.user.yaml
# edit ./values.user.yaml with your host, origins, storage class, and video mode

helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  -f ./deploy/helm/qitanoid/values-k8s-production.yaml \
  -f ./values.user.yaml
```

That profile enables:

- `2` hub replicas
- `2` UI replicas
- bundled Redis
- persistence
- ingress skeleton

Before using it in a real cluster, set these in `values.user.yaml`:

- image tags
- ingress host and TLS
- admin token and secrets
- storage class
- resource requests and limits for your node size

## Video Storage Options

The chart now supports two video storage modes:

- `filesystem`: videos stay on the hub/shared volume and are served directly from that filesystem
- `s3`: videos are first written to the shared staging volume, then uploaded by the hub to an S3-compatible bucket and served back through the hub

The active switch is:

```yaml
video:
  storage:
    type: filesystem # or s3
```

### Option 1: PVC / Filesystem

Use this when you want the simplest self-hosted setup.

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  -f ./deploy/helm/qitanoid/values-k8s-production.yaml \
  -f ./deploy/helm/qitanoid/values-video-pvc.yaml
```

Behavior:

- session pods write `.mp4` files to the shared PVC
- hub lists and serves those files directly
- no external object storage is required

Requirements:

- `persistence.enabled=true`
- storage class that supports your chosen access mode

### Option 2: S3-Compatible Storage

Use this when you want long-lived recordings outside the cluster.

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  -f ./deploy/helm/qitanoid/values-k8s-production.yaml \
  -f ./deploy/helm/qitanoid/values-video-s3.yaml
```

Behavior:

- session pods still write recordings to a shared staging volume
- hub uploads finished `.mp4` files to S3 or MinIO
- `/api/videos` and `/video-files/...` continue to work through the same hub API
- local staging files can be removed automatically after successful upload

Requirements:

- `persistence.enabled=true`
- S3-compatible endpoint, bucket, access key, and secret key
- enough staging space on the PVC while uploads are in progress

Main S3 values:

- `video.storage.s3.endpoint`
- `video.storage.s3.bucket`
- `video.storage.s3.prefix`
- `video.storage.s3.useSSL`
- `video.storage.s3.autoCreateBucket`
- `video.storage.s3.deleteLocalAfterUpload`
- `video.storage.s3.accessKey`
- `video.storage.s3.secretKey`
- `video.storage.s3.existingSecret`

If `video.storage.type=s3` and `persistence.enabled=false`, the chart now fails fast because runtime pods need a shared staging volume before upload.

### Local Docker Desktop S3 Smoke Path

For the exact local smoke path used in this repo:

```bash
kubectl --context docker-desktop apply -f ./deploy/k8s/minio-local.yaml
kubectl --context docker-desktop apply -f ./deploy/k8s/docker-desktop-hostpath-pv.yaml

helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  -f ./deploy/helm/qitanoid/values-video-s3-docker-desktop.yaml \
  --set redis.enabled=true \
  --set hub.replicaCount=1
```

## Smoke Test Through The UI Proxy

Once `port-forward-ui.sh` is running:

```bash
curl http://127.0.0.1:8080/readyz
curl http://127.0.0.1:8080/api/status
```

That proves:

- browser traffic reaches the dashboard
- dashboard nginx proxy reaches the hub
- hub answers correctly through same-origin UI routing

## Smoke Test Through The Hub API

Once `port-forward.sh` is running:

Check readiness:

```bash
curl http://127.0.0.1:4444/readyz
```

Create a Selenium session:

```bash
curl -sS -X POST http://127.0.0.1:4444/wd/hub/session \
  -H 'Content-Type: application/json' \
  -d '{
    "capabilities": {
      "alwaysMatch": {
        "browserName": "chrome",
        "browserVersion": "145.0.7632.116"
      }
    }
  }'
```

Delete the session after the smoke test:

```bash
curl -sS -X DELETE http://127.0.0.1:4444/wd/hub/session/<session-id>
```

List sessions:

```bash
curl http://127.0.0.1:4444/api/sessions
```

## Hub-Only Install

If you want only the hub and no dashboard:

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  --set ui.enabled=false
```

Then expose only the hub:

```bash
./deploy/helm/qitanoid/port-forward.sh
```

## Persistent Storage

By default the Docker Desktop profile uses `emptyDir` for simpler startup.

If your local provisioner is healthy and you want persistence:

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  --set persistence.enabled=true \
  --set persistence.storageClassName=hostpath
```

Use this only if your local storage provisioner actually creates PVCs correctly.

## Admin Token

The hub supports `QITANOID_ADMIN_TOKEN` for destructive endpoints.

The chart exposes two separate concepts:

- `hub.adminToken`
  This secures the backend.
- `ui.runtimeConfig.adminToken`
  This injects the token into browser JavaScript so the dashboard can call admin endpoints.

Important:

- `ui.runtimeConfig.adminToken` is effectively public to anyone who can load that dashboard.
- only use it for a private admin UI
- do not enable it for a public dashboard

Example:

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  --set hub.adminToken='super-secret-token' \
  --set ui.runtimeConfig.adminToken='super-secret-token'
```

## Ingress

If you enable ingress and keep `ui.enabled=true`, ingress points to the UI service. The UI then proxies all backend traffic to the hub.

Example:

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  --set ingress.enabled=true \
  --set ingress.host=qitanoid.local
```

## Useful Overrides

Use your own `browsers.json`:

```bash
helm upgrade --install qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --create-namespace \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml \
  --set-file config.rawJson=/absolute/path/to/browsers.json
```

Disable the bundled UI:

```bash
--set ui.enabled=false
```

Change the UI port-forward local port:

```bash
LOCAL_PORT=9090 ./deploy/helm/qitanoid/port-forward-ui.sh
```

Change the hub port-forward local port:

```bash
LOCAL_PORT=5444 ./deploy/helm/qitanoid/port-forward.sh
```

## Troubleshooting

If pods stay `Pending`:

- check node pressure
- check image pull errors
- check PVC binding if persistence is enabled

Commands:

```bash
kubectl --context docker-desktop -n qitanoid get events --sort-by=.metadata.creationTimestamp | tail -n 40
kubectl --context docker-desktop -n qitanoid describe pod -l app.kubernetes.io/instance=qitanoid
kubectl --context docker-desktop describe node docker-desktop | rg -n "DiskPressure|Ready"
```

If UI opens but data does not load:

- confirm `qitanoid-ui` is running
- call `curl http://127.0.0.1:8080/api/status`
- check [deploy/helm/qitanoid/templates/ui-configmap-nginx.yaml](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/templates/ui-configmap-nginx.yaml)

If direct hub access is needed:

- use [deploy/helm/qitanoid/port-forward.sh](/Users/alexey/projects/qitaopsqa/deploy/helm/qitanoid/port-forward.sh)

If Android is needed:

- local Docker Desktop on macOS is not the right target
- use a Linux/KVM cluster or dedicated Android worker nodes

## Upgrade

After code changes:

```bash
docker build -t qitaops/qitaopsqa:local .
docker build -t qitaops/qitaopsqa-dashboard:local -f frontend/Dockerfile.production frontend

helm upgrade qitanoid ./deploy/helm/qitanoid \
  --namespace qitanoid \
  --kube-context docker-desktop \
  -f ./deploy/helm/qitanoid/values-docker-desktop.yaml
```

## Remove

```bash
helm uninstall qitanoid -n qitanoid --kube-context docker-desktop
kubectl --context docker-desktop delete namespace qitanoid
```
