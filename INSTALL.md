# HuewizPi — Containerized Installation & Configuration Guide

**HuewizPi** is built exclusively around container orchestration using **balenaOS** and **Docker Compose**. Everything runs in isolated containers—you never need to install packages manually on the host OS.

---

## 1. Prerequisites

Before starting, make sure you have:
1. A free **[balenaCloud](https://dashboard.balena-cloud.com/)** account (free for up to 10 devices).
2. A **Raspberry Pi** (Pi 3B+, Pi 4, or Pi 5) and a microSD card (16 GB+ recommended).
3. **[balenaEtcher](https://etcher.balena.io/)** installed on your computer to flash the OS image.

---

## 2. Option A: One-Click Deploy via balenaCloud (Recommended)

This is the easiest way to deploy and automatically keep HuewizPi updated:

1. **Launch the Deploy Wizard:**  
   Click the **[Deploy with balena](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/HuewizPi)** button.
2. **Create Your Fleet:**
   * Give your fleet a name (e.g., `huewizpi-home`).
   * Select your exact **Default device type** (e.g., *Raspberry Pi 4 (using 64bit OS)*).
   * Click **Create and deploy**.
3. **Add Your Raspberry Pi:**
   * Once redirected to your fleet dashboard, click **Add device**.
   * Select **Development** or **Production** edition, and enter your home **Wi-Fi credentials** (or leave blank if using Ethernet).
   * Click **Download balenaOS** to get your custom `.img.zip` file.
4. **Flash & Boot:**
   * Open **balenaEtcher**, select the downloaded image, choose your microSD card, and click **Flash!**.
   * Insert the SD card into your Raspberry Pi and power it on.
   * Within a few minutes, your Pi will appear **Online** in balenaCloud and automatically pull the HuewizPi multi-container stack.

---

## 3. Option B: Local / Custom Push via balena CLI

If you want to customize `docker-compose.yml` or push changes from your local machine without modifying the GitHub repo:

1. Install the **[balena CLI](https://docs.balena.io/reference/balena-cli/)** on your computer.
2. Clone the repository and log in:
   ```bash
   git clone https://github.com/b23prodtm/HuewizPi.git
   cd HuewizPi
   balena login
   ```
3. Push the container stack directly to your fleet (or to a local device in Development mode):
   ```bash
   balena push <YOUR_FLEET_NAME>
   ```

---

## 4. Container & Environment Configuration

All settings are managed cleanly via **Device Variables** (or **Fleet Variables**) inside your balenaCloud dashboard—no SSH file editing required:

1. Open your device page in **balenaCloud** and navigate to **Device Variables**.
2. Configure the relevant variables for your setup (such as Wi-Fi Access Point SSID/passphrase, timezone `TZ`, or USB Zigbee device path).
3. Updating any variable automatically restarts the affected container with the new configuration.

### USB Zigbee Dongle Mapping (Optional)
Because HuewizPi runs in privileged/mapped containers on balenaOS:
* Plug your USB Zigbee dongle (ConBee II, Sonoff, etc.) into the Raspberry Pi.
* It is automatically exposed to the container stack under `/dev/ttyACM0` or `/dev/ttyUSB0`.

---

## 5. Pairing with Apple HomeKit

Once all services show **Running** in your balenaCloud dashboard:

1. Enable **Public Device URL** in balenaCloud or connect via your Pi's local IP address:  
   `http://<YOUR-RASPBERRY-PI-IP>:8581`
2. Log in to the **Homebridge UI** (default: `admin` / `admin` — **change your password immediately**).
3. Install any desired Homebridge plugins (e.g., `homebridge-hue` for Philips Hue Bridge integration, or audio/media plugins) directly from the **Plugins** tab.
4. On your iPhone or iPad, open the **Apple Home** app, tap **+ → Add Accessory**, and scan the **QR Code** displayed on the Homebridge dashboard.

---

## 6. Container Management & Troubleshooting

Everything can be monitored directly from the **balenaCloud Dashboard**:

* **Live Container Logs:** Use the **Logs** panel on your device page to inspect real-time output from Homebridge, the network/AP container, or Zigbee services.
* **Restart a Single Service:** In the **Services** list, click the restart icon next to any individual container without rebooting the entire Raspberry Pi.
* **HomeKit "No Response":** Ensure your Raspberry Pi and iPhone/Apple Home Hub (Apple TV or HomePod) are on the same local subnet so mDNS / Bonjour discovery works across containers (`network_mode: host`).