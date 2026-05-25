<div align="center">
  <img src="https://qitanoid.com/logo.png" alt="Qitanoid" width="180" />
  <h1>Qitanoid</h1>
  <p><strong>Self-hosted browser automation hub for Selenium and Playwright</strong></p>

  <p>
    <a href="https://qitanoid.com"><img src="https://img.shields.io/badge/website-qitanoid.com-blue?style=flat-square" alt="Website"></a>
    <a href="https://qitanoid.com/helm/index.yaml"><img src="https://img.shields.io/badge/helm-chart-0f80c1?style=flat-square&logo=helm" alt="Helm Chart"></a>
    <a href="https://hub.docker.com/u/aidevtech"><img src="https://img.shields.io/badge/docker-aidevtech-2496ed?style=flat-square&logo=docker" alt="Docker Hub"></a>
    <a href="https://t.me/+K76u7Z9JA1Q1NTY0"><img src="https://img.shields.io/badge/telegram-community-2CA5E0?style=flat-square&logo=telegram" alt="Telegram"></a>
  </p>
</div>

---

Qitanoid is a **drop-in replacement for Selenium Grid** that runs browser sessions as isolated Docker containers or Kubernetes Pods. Connect your existing Selenium or Playwright tests without changing a single line of test code.

```
RemoteWebDriver driver = new RemoteWebDriver(new URL("http://your-hub/wd/hub"), options);
```

---

## ✨ Features

| Feature | Details |
|---|---|
| 🌐 **Multi-browser** | Chrome, Firefox, Edge — all versions side by side |
| 🎭 **Selenium + Playwright** | Both protocols on one hub |
| 📹 **Video recording** | Per-session MP4, stored locally or to S3 |
| 🖥️ **VNC / noVNC** | Live session preview in the browser |
| 📊 **Web Dashboard** | Real-time sessions, nodes, recordings UI |
| ☸️ **Kubernetes-native** | Sessions run as ephemeral Pods, auto-cleaned |
| 🐳 **Docker Compose** | Single-file local setup, zero dependencies |
| 📱 **Android (coming soon)** | Appium Android sessions via KVM |
| 🔑 **License-based scaling** | Free up to 5 parallel sessions, paid tiers from $20/mo |

---

## 🚀 Quick Start

### Docker Compose (local)

```bash
curl -O https://qitanoid.com/docker-compose.yml
docker compose up -d
```

Hub is ready at `http://localhost:4444`.

### Kubernetes / Helm

```bash
helm repo add qitanoid https://qitanoid.com/helm
helm repo update

kubectl create namespace qitanoid

helm upgrade --install qitanoid qitanoid/qitanoid \
  -n qitanoid \
  --set hub.adminToken="your-secret-token" \
  --set service.type=LoadBalancer
```

---

## 🧪 Running Tests

### Selenium — Java

```java
ChromeOptions options = new ChromeOptions();
options.setCapability("browserVersion", "147.0.7727.55");
options.setCapability("qitanoid:record", true);
options.setCapability("qitanoid:screenResolution", "1920x1080");

// Important: use plain constructor, NOT RemoteWebDriver.builder()
// builder() triggers CDP/BiDi handshake which fails on remote hubs
WebDriver driver = new RemoteWebDriver(
    new URL("http://your-hub/wd/hub"), options);
```

### Selenium — Python

```python
from selenium import webdriver

options = webdriver.ChromeOptions()
options.set_capability("browserVersion", "147.0.7727.55")
options.set_capability("qitanoid:record", True)
options.set_capability("qitanoid:screenResolution", "1920x1080")

driver = webdriver.Remote("http://your-hub/wd/hub", options=options)
```

### Selenium — JavaScript

```javascript
const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

const options = new chrome.Options();
options.set('browserVersion', '147.0.7727.55');
options.set('qitanoid:record', true);

const driver = await new Builder()
  .usingServer('http://your-hub/wd/hub')
  .withCapabilities(options)
  .build();
```

### Playwright — JavaScript

```javascript
const { chromium } = require('playwright');

// Use connect(), NOT connectOverCDP()
const browser = await chromium.connect(
  'ws://your-hub/playwright/ws?browser=chrome&version=playwright-147.0.7727.55'
);
const page = await browser.newContext().then(c => c.newPage());
```

### Playwright — Python

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    # Use connect(), NOT connect_over_cdp()
    browser = p.chromium.connect(
        'ws://your-hub/playwright/ws?browser=chrome&version=playwright-147.0.7727.55'
    )
    page = browser.new_context().new_page()
```

---

## ⚙️ Capabilities Reference

| Capability | Type | Example | Description |
|---|---|---|---|
| `browserVersion` | string | `"147.0.7727.55"` | Exact browser version |
| `qitanoid:record` | boolean | `true` | Enable MP4 video recording |
| `qitanoid:screenResolution` | string | `"1920x1080"` | Desktop resolution |
| `qitanoid:sessionName` | string | `"login-test"` | Label shown in Web UI |
| `qitanoid:idleTimeout` | string | `"5m"` | Override idle timeout |

---

## 🗂️ Deployment Options

| Platform | Guide |
|---|---|
| Docker Compose | [README_PRODUCTION.md](documents/README_PRODUCTION.md) |
| Kubernetes / Helm | [README_DEPLOY.md](documents/README_DEPLOY.md) |
| GKE (Google Kubernetes Engine) | [README_KUBERNETES.md](documents/README_KUBERNETES.md) |
| OpenShift | [README_OPENSHIFT.md](documents/README_OPENSHIFT.md) |
| Helm chart values | [values.yaml](deploy/helm/qitanoid/values.yaml) |

---

## 📦 Helm Chart

Official chart published at **`https://qitanoid.com/helm`**.

```bash
helm repo add qitanoid https://qitanoid.com/helm
helm search repo qitanoid
```

Minimal `values.yaml`:

```yaml
hub:
  adminToken: "your-secret-token"
  sessionIdleTimeout: 10m
  browserCPUs: "0.5"
  browserMemory: "1Gi"

redis:
  enabled: true

service:
  type: LoadBalancer

persistence:
  enabled: false

ui:
  enabled: true
  runtimeConfig:
    apiBaseUrl: "http://<HUB_IP>"
    wsBaseUrl:  "ws://<HUB_IP>"
    adminToken: "your-secret-token"
  service:
    type: LoadBalancer
```

> ⚠️ **Cloud NAT required on GKE/EKS/AKS.** Browser pods need outbound internet access.
> Without NAT, all external page loads will time out.

---

## 📹 Video Recording Storage

| Backend | Configuration |
|---|---|
| Local directory | `VIDEO_DIR=/app/recordings` |
| AWS S3 | `S3_ENDPOINT` + `S3_BUCKET` + `S3_ACCESS_KEY` + `S3_SECRET_KEY` |
| Google Cloud Storage | `S3_ENDPOINT=https://storage.googleapis.com` |
| MinIO (self-hosted) | `S3_ENDPOINT=http://minio:9000` |

---

## 💰 Pricing

| Plan | Sessions | Price |
|---|---|---|
| Starter | 5 | **Free** |
| Launch | 10 | $20/mo |
| Team | 20 | $40/mo |
| Scale | 30 | $60/mo |
| Business | 50 | $100/mo |
| Enterprise | 100 | $300/mo |
| Enterprise+ | Unlimited | Custom |

See [qitanoid.com/#pricing](https://qitanoid.com/#pricing) for full details.

---

## 💬 Community & Support

- 📘 **Documentation**: [qitanoid.com](https://qitanoid.com)
- 💬 **Telegram**: [t.me/+K76u7Z9JA1Q1NTY0](https://t.me/+K76u7Z9JA1Q1NTY0)
- 📧 **Contact**: [qitanoid.com](https://qitanoid.com)

---

## 📄 License

Free for up to **5 parallel sessions**. Paid licenses unlock more capacity.  
Commercial use requires a valid license key.
