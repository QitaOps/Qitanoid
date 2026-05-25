# Qitanoid Android On Linux/KVM

This guide is the production path for Android emulator workloads in Qitanoid.

It assumes:
- A Linux host, ideally Ubuntu 22.04 or 24.04.
- Docker Engine running directly on that host.
- Hardware virtualization enabled in BIOS/UEFI.
- `/dev/kvm` available on the host.

Why this is required:
- The upstream `budtmo/docker-android` project expects Ubuntu/Linux with virtualization support and recommends `/dev/kvm` for emulator startup.
- Android Emulator on Linux uses KVM for VM acceleration.

References:
- [budtmo/docker-android README](https://github.com/budtmo/docker-android)
- [Android Emulator acceleration on Linux](https://developer.android.com/studio/run/emulator-acceleration)

## 1. Prepare the host

Run the preflight script:

```bash
./deploy/android/check-kvm-host.sh
```

The host should satisfy all of these:
- `uname -s` is `Linux`
- CPU reports `vmx` or `svm`
- `/dev/kvm` exists
- Docker server is reachable
- Docker server OS is Linux

On Ubuntu/Debian, install KVM tooling if needed:

```bash
sudo apt-get update
sudo apt-get install -y cpu-checker qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
sudo kvm-ok
```

Expected `kvm-ok` output includes:

```text
INFO: /dev/kvm exists
KVM acceleration can be used
```

If `/dev/kvm` exists but is not accessible to Docker workloads, fix ownership:

```bash
sudo chgrp kvm /dev/kvm
sudo chmod 660 /dev/kvm
sudo usermod -aG kvm "$USER"
```

Then log out and back in.

## 2. Build the Android image

Build on a Linux `amd64` host:

```bash
docker build -t aidevtech/android-appium:14.0 -f docker/android.appium.Dockerfile .
```

If you want to publish it:

```bash
docker tag aidevtech/android-appium:14.0 registry.example.com/aidevtech/android-appium:14.0
docker push registry.example.com/aidevtech/android-appium:14.0
```

## 3. Smoke test the emulator image directly

Use the helper:

```bash
./deploy/android/smoke-android-container.sh aidevtech/android-appium:14.0
```

This verifies:
- container start
- Appium status on `4723`
- noVNC page on `6080`
- whether an Android device is visible to `adb`

What success looks like:
- `curl http://127.0.0.1:4723/status` returns `ready: true`
- `curl -I http://127.0.0.1:6080` returns `200 OK`
- `adb devices -l` inside the container shows at least one emulator

If Appium is ready but no device appears, the emulator itself did not boot. On Linux this usually means KVM is missing, inaccessible, or nested virtualization is disabled.

## 4. Run the full hub with Android support

Use the Android-ready compose file:

```bash
docker compose -f docker-compose.android-kvm.yml up -d
```

This starts:
- `hub`
- `dashboard`

Optional direct emulator smoke container:

```bash
docker compose -f docker-compose.android-kvm.yml --profile smoke up android-smoke
```

## 5. Configure Android target in Qitanoid

Your `browsers.json` should include an Android target similar to:

```json
{
  "android": {
    "kind": "android",
    "display_name": "Android",
    "default": "14.0",
    "versions": {
      "14.0": {
        "image": "aidevtech/android-appium:14.0",
        "port": "4723",
        "engine": "appium",
        "platform_name": "Android",
        "automation_name": "UiAutomator2",
        "device_name": "Pixel 6",
        "stream_mode": "web",
        "stream_port": "6080",
        "vnc_port": "5900",
        "exposed_ports": ["4723", "5900", "6080", "5554", "5555"],
        "use_hub_entrypoint": false,
        "requires_kvm": true,
        "privileged": true,
        "env": {
          "APPIUM": "true",
          "WEB_VNC": "true",
          "EMULATOR_DEVICE": "Pixel 6"
        }
      }
    }
  }
}
```

## 6. Verify end-to-end through the hub

Start the hub and create a session:

```bash
curl -sS -X POST http://127.0.0.1:4444/appium/wd/hub/session \
  -H 'Content-Type: application/json' \
  -d '{
    "capabilities": {
      "alwaysMatch": {
        "platformName": "Android",
        "appium:automationName": "UiAutomator2",
        "appium:deviceName": "Pixel 6",
        "appium:platformVersion": "14.0",
        "qitanoid:target": "android"
      }
    }
  }'
```

Then verify:
- `GET /api/sessions` shows an Android session
- dashboard can open the embedded Android stream
- Appium commands succeed after session creation

## 7. Capacity and scheduling advice

Android emulator containers need more headroom than browser-only sessions.

Recommended starting point per emulator node:
- 8+ vCPU
- 16+ GB RAM
- SSD-backed storage
- one emulator per KVM-capable host until you benchmark your images

Recommended Qitanoid runtime settings for emulator-heavy nodes:

```env
QITANOID_BROWSER_SHM_SIZE=2g
QITANOID_BROWSER_MEMORY=8g
QITANOID_BROWSER_CPUS=4
QITANOID_BROWSER_PIDS_LIMIT=1024
```

Those limits currently apply to child runtime containers in general, so dedicate Android nodes if you want different sizing from browser-only nodes.

## 8. Known failure modes

`Could not find a connected Android device`
- Appium is up, but the emulator never booted.
- Check `/dev/kvm`, BIOS virtualization, nested virtualization, and host architecture.

`/dev/kvm: permission denied`
- Fix group ownership and permissions.
- Confirm the Docker daemon can create child containers with `--device /dev/kvm`.

noVNC opens but shows a blank or static screen
- The VNC stack is up, but the emulator/display process failed.
- Inspect container logs and `adb devices -l`.

Very slow boot or random crashes
- Usually software emulation or cross-architecture emulation.
- Do not run this on macOS Docker Desktop as your production emulator host.
