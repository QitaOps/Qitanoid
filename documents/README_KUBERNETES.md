# Qitanoid on Kubernetes

This guide deploys the Qitanoid hub on Kubernetes and uses in-cluster session pods for Selenium, Playwright, and Android/Appium runtimes.

For a faster local Docker Desktop path, use the Helm chart in [README_HELM.md](/Users/alexey/projects/qitaopsqa/README_HELM.md).

## Scope

- The hub runs as a single replica.
- Session state is still in memory, so do not scale the hub deployment horizontally yet.
- Recorded videos and `browsers.json` are stored on a shared `ReadWriteMany` PVC.
- Android emulator workloads require Linux worker nodes with `/dev/kvm`.

## Kubernetes Requirements

- Kubernetes cluster with an active Ingress controller.
- RWX storage class for the shared `qitanoid-data` PVC.
- Linux nodes for browser workloads.
- Dedicated KVM-capable Linux nodes for Android workloads.

Relevant platform constraints from the official docs:
- Kubernetes Ingress exposes HTTP and HTTPS routes to Services and requires an Ingress controller: [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- `hostPath` mounts expose host files into a Pod and should be used with care: [Kubernetes Volumes / hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)
- privileged security settings are controlled through pod security context: [Kubernetes Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)

## 1. Prepare the Namespace

```bash
kubectl create namespace qitanoid
kubectl config set-context --current --namespace=qitanoid
```

## 2. Bootstrap ConfigMaps

```bash
./deploy/k8s/sync-browser-bootstrap.sh
./deploy/k8s/sync-runtime-configmap.sh
```

`qitanoid-browser-bootstrap` seeds the first `browsers.json` into the PVC. After the hub starts, edits happen directly on persistent storage through the existing UI/API.

`qitanoid-session-runtime` publishes `docker/entrypoint.sh` and `docker/record.sh` so browser session pods can use the same runtime scripts they use on Docker today.

## 3. Label Android Nodes

Only nodes that actually expose `/dev/kvm` should receive the Android label:

```bash
kubectl label node <kvm-node-name> qitanoid.io/kvm=true
```

## 4. Deploy the Hub

```bash
kubectl apply -f deploy/k8s/qitanoid-hub.yaml
```

The deployment sets:

- `QITANOID_ORCHESTRATOR=kubernetes`
- `QITANOID_SESSION_SERVICE_ACCOUNT=qitanoid-session`
- `QITANOID_SESSION_RUNTIME_CONFIGMAP=qitanoid-session-runtime`
- `QITANOID_SESSION_VIDEO_PVC=qitanoid-data`
- `QITANOID_SESSION_KVM_NODE_SELECTOR=qitanoid.io/kvm=true`

That makes ordinary browser sessions run as in-cluster pods and Android sessions prefer nodes labeled for KVM.

## 5. Expose the Hub

Edit the host name in [deploy/k8s/qitanoid-ingress.yaml](/Users/alexey/projects/qitaopsqa/deploy/k8s/qitanoid-ingress.yaml), then apply it:

```bash
kubectl apply -f deploy/k8s/qitanoid-ingress.yaml
```

## 6. Verify

```bash
kubectl get pods
kubectl get ingress
kubectl logs deploy/qitanoid-hub
curl http://qitanoid-hub:4444/readyz
```

Then create a Selenium or Appium session through the hub. A new `qitanoid-session-*` pod should appear.

## Notes

- If your browser images already contain the Qitanoid runtime scripts, set `QITANOID_BAKED_RUNTIME=true` in the deployment and you can skip the runtime ConfigMap.
- If your storage class does not support `ReadWriteMany`, keep video recording disabled or move recordings to object storage before scaling session traffic.
- The OpenShift-specific route and SCC flow is documented in [README_OPENSHIFT.md](/Users/alexey/projects/qitaopsqa/README_OPENSHIFT.md).
