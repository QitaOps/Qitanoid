# Qitanoid Hub

Qitanoid Hub is a self-hosted control plane for browser automation.

It provisions isolated Selenium, Playwright, and Appium runtimes on demand, exposes live VNC and streaming, stores video and artifacts, and gives you one UI for sessions and operations.

## What It Covers

- Selenium WebDriver sessions
- Playwright CDP sessions
- Appium / Android sessions
- live VNC and stream access
- video recording
- artifacts and audit trail
- optional distributed workers with remote agents
- optional Kubernetes / OpenShift deployment

## Deployment Paths

- simple Docker install: [client-deploy/docker-compose.yml](/Users/alexey/projects/qitaopsqa/client-deploy/docker-compose.yml)
- deployment overview: [README_DEPLOY.md](/Users/alexey/projects/qitaopsqa/README_DEPLOY.md)
- remote agents: [README_AGENT.md](/Users/alexey/projects/qitaopsqa/README_AGENT.md)
- Helm / Kubernetes: [README_HELM.md](/Users/alexey/projects/qitaopsqa/README_HELM.md)
- Kubernetes manifests: [README_KUBERNETES.md](/Users/alexey/projects/qitaopsqa/README_KUBERNETES.md)
- OpenShift: [README_OPENSHIFT.md](/Users/alexey/projects/qitaopsqa/README_OPENSHIFT.md)
- production notes: [README_PRODUCTION.md](/Users/alexey/projects/qitaopsqa/README_PRODUCTION.md)
- Android KVM notes: [README_ANDROID_KVM.md](/Users/alexey/projects/qitaopsqa/README_ANDROID_KVM.md)

## Quick Start

Use the simple Docker path first.

```bash
cd /Users/alexey/projects/qitaopsqa/client-deploy
docker compose up -d
```

Then open:

- UI: `http://localhost:8080`
- Selenium: `http://localhost:4444/wd/hub`
- Playwright: `ws://localhost:4444/playwright/ws`
- Appium: `http://localhost:4444/appium/wd/hub`

If `./config/browsers.json` does not exist, the hub creates a default one on startup.

## Connection Examples

### Selenium

```javascript
const { Builder, Capabilities } = require('selenium-webdriver');

async function run() {
  const capabilities = Capabilities.chrome();
  capabilities.set('browserName', 'chrome');
  capabilities.set('browserVersion', 'latest');
  capabilities.set('qitanoid:record', true);

  const driver = await new Builder()
    .usingServer('http://localhost:4444/wd/hub')
    .withCapabilities(capabilities)
    .build();

  await driver.get('https://example.com');
  await driver.quit();
}

run();
```

### Playwright

```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.connectOverCDP(
    'ws://localhost:4444/playwright/ws?browser=chrome&version=playwright'
  );

  const context = browser.contexts()[0];
  const page = context.pages()[0];
  await page.goto('https://example.com');
  await browser.close();
})();
```

### Appium

Post to `http://localhost:4444/appium/wd/hub/session`:

```json
{
  "capabilities": {
    "alwaysMatch": {
      "platformName": "Android",
      "appium:automationName": "UiAutomator2",
      "appium:deviceName": "Pixel 6",
      "appium:platformVersion": "14.0"
    }
  }
}
```

## Runtime Notes

- `QITANOID_CONTAINER_HOST=host.docker.internal` is typically needed on Docker Desktop.
- `QITANOID_CONTAINER_HOST=127.0.0.1` is typically right on Linux hosts.
- `QITANOID_BAKED_RUNTIME=true` tells the hub to use helper scripts already baked into runtime images.

## Main Product Areas

- sessions and live control
- browser and target catalog
- templates
- artifacts
- videos
- audit
- optional nodes / agents

## Repository Pointers

- server entrypoint: [cmd/qitanoid-hub/main.go](/Users/alexey/projects/qitaopsqa/cmd/qitanoid-hub/main.go)
- simple install: [docker-compose.yml](/Users/alexey/projects/qitaopsqa/client-deploy/docker-compose.yml)
- central distributed install: [docker-compose.central.yml](/Users/alexey/projects/qitaopsqa/deploy/compose/docker-compose.central.yml)
- remote agent install: [docker-compose.agent.yml](/Users/alexey/projects/qitaopsqa/deploy/compose/docker-compose.agent.yml)
- architecture notes: [ARCHITECTURE_HUB.md](/Users/alexey/projects/qitaopsqa/ARCHITECTURE_HUB.md)
