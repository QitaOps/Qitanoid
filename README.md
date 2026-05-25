<div align="center">

<img src="https://qitanoid.com/logo2.png" alt="Qitanoid" height="80" />

### Self-hosted browser automation hub for Selenium & Playwright

[![Website](https://img.shields.io/badge/qitanoid.com-0066FF?style=flat-square)](https://qitanoid.com)
[![Helm Chart](https://img.shields.io/badge/Helm_Chart-0f80c1?style=flat-square&logo=helm&logoColor=white)](https://qitanoid.com/helm)
[![Docker](https://img.shields.io/badge/Docker_Hub-2496ed?style=flat-square&logo=docker&logoColor=white)](https://hub.docker.com/u/aidevtech)
[![Telegram](https://img.shields.io/badge/Community-2CA5E0?style=flat-square&logo=telegram&logoColor=white)](https://t.me/+K76u7Z9JA1Q1NTY0)

</div>

---

Run **Chrome, Firefox and Edge** as isolated containers or Kubernetes Pods. Drop-in replacement for Selenium Grid — no changes to your tests required.

```bash
# Docker — up in 30 seconds
docker compose up -d
# → http://localhost:4444/wd/hub
```

## Install

<details>
<summary><b>Docker Compose</b></summary>

```bash
curl -O https://qitanoid.com/docker-compose.yml
docker compose up -d
```

See [documents/README_PRODUCTION.md](documents/README_PRODUCTION.md) for production configuration.
</details>

<details>
<summary><b>Kubernetes / Helm</b></summary>

```bash
helm repo add qitanoid https://qitanoid.com/helm
helm repo update
kubectl create namespace qitanoid
helm upgrade --install qitanoid qitanoid/qitanoid -n qitanoid -f values.yaml
```

Minimal [`values.yaml`](deploy/helm/qitanoid/values.yaml):

```yaml
hub:
  adminToken: "your-secret-token"
  browserCPUs: "0.5"
  browserMemory: "1Gi"
service:
  type: LoadBalancer
ui:
  enabled: true
  runtimeConfig:
    apiBaseUrl: "http://<HUB_IP>"
    wsBaseUrl:  "ws://<HUB_IP>"
    adminToken: "your-secret-token"
  service:
    type: LoadBalancer
```

See [Deploy guide](documents/README_DEPLOY.md) · [GKE](documents/README_KUBERNETES.md) · [OpenShift](documents/README_OPENSHIFT.md)
</details>

## Usage

**Selenium**

```java
// Java
ChromeOptions options = new ChromeOptions();
options.setCapability("browserVersion", "147.0.7727.55");
options.setCapability("qitanoid:record", true);
// Use plain constructor — RemoteWebDriver.builder() triggers CDP and will fail
WebDriver driver = new RemoteWebDriver(new URL("http://hub/wd/hub"), options);
```

```python
# Python
options = webdriver.ChromeOptions()
options.set_capability("browserVersion", "147.0.7727.55")
options.set_capability("qitanoid:record", True)
driver = webdriver.Remote("http://hub/wd/hub", options=options)
```

**Playwright**

```javascript
// JS — use connect(), not connectOverCDP()
const browser = await chromium.connect(
  'ws://hub/playwright/ws?browser=chrome&version=playwright-147.0.7727.55'
);
```

```python
# Python — use connect(), not connect_over_cdp()
browser = p.chromium.connect(
  'ws://hub/playwright/ws?browser=chrome&version=playwright-147.0.7727.55'
)
```

## Capabilities

| Key | Type | Description |
|---|---|---|
| `browserVersion` | `string` | Browser version tag |
| `qitanoid:record` | `bool` | Record session as MP4 |
| `qitanoid:screenResolution` | `string` | Resolution, e.g. `1920x1080` |
| `qitanoid:sessionName` | `string` | Label shown in dashboard |

## Pricing

Free for **5 parallel sessions**. Paid plans from **$20/month** → [qitanoid.com/#pricing](https://qitanoid.com/#pricing)

## Community

[Telegram](https://t.me/+K76u7Z9JA1Q1NTY0) · [qitanoid.com](https://qitanoid.com)

