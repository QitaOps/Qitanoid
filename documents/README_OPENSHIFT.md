# Qitanoid on OpenShift

This guide deploys the Qitanoid hub on OpenShift and uses in-cluster session pods for Selenium, Playwright, and Android/Appium runtimes.

## Scope

- The hub stays single replica because active sessions are still stored in memory.
- Browser and Android session pods are created dynamically by the hub.
- Android emulator pods require worker nodes with `/dev/kvm`.
- OpenShift needs SCC grants for both the hub and the Android-capable session pods.

Relevant platform constraints from the official docs:
- OpenShift Routes expose services externally: [OpenShift Route API](https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html/network_apis/route-route-openshift-io-v1)
- SCCs control privileged containers, host directory volumes, and privilege escalation: [OpenShift SCC](https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/authentication_and_authorization/managing-pod-security-policies)

## 1. Select the Project

```bash
oc new-project qitanoid
```

## 2. Bootstrap ConfigMaps

Use `oc` as the kubectl binary:

```bash
KUBECTL_BIN=oc ./deploy/k8s/sync-browser-bootstrap.sh
KUBECTL_BIN=oc ./deploy/k8s/sync-runtime-configmap.sh
```

## 3. Label KVM Nodes

```bash
oc label node <kvm-node-name> qitanoid.io/kvm=true
```

## 4. Deploy the Hub

```bash
oc apply -f deploy/openshift/qitanoid-hub.yaml
```

## 5. Grant SCC Access

```bash
./deploy/openshift/grant-scc.sh
```

This script grants:

- `anyuid` to `qitanoid-hub`
- `privileged` to `qitanoid-session`

That matches the current hub image, which runs as root by default, and the Android session pods, which need host `/dev/kvm` access.

## 6. Create the Route

```bash
oc apply -f deploy/openshift/qitanoid-route.yaml
oc get route qitanoid-hub
```

## 7. Verify

```bash
oc get pods
oc logs deploy/qitanoid-hub
curl http://qitanoid-hub:4444/readyz
```

Then create a Selenium or Appium session through the hub and verify a `qitanoid-session-*` pod appears in the project.

## Notes

- If your cluster policy forbids the built-in `privileged` SCC, create a custom SCC with hostPath and privileged access for `/dev/kvm`, then bind it to `qitanoid-session`.
- If your browser images are rebuilt with baked runtime scripts, set `QITANOID_BAKED_RUNTIME=true` and the runtime ConfigMap becomes optional.
- The plain Kubernetes flow is documented in [README_KUBERNETES.md](/Users/alexey/projects/qitaopsqa/README_KUBERNETES.md).
