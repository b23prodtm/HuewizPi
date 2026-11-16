[![Deploy with balena](https://balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/b23prodtm/HuewizPi)
[![CI](https://github.com/b23prodtm/HuewizPi/actions/workflows/balena.yml/badge.svg)](https://github.com/b23prodtm/HuewizPi/actions)

# HuewizPi — Your Containerized Universal Smart Home Hub on Raspberry Pi

**HuewizPi** turns a Raspberry Pi into an all-in-one, containerized **smart home gateway** and **IoT access point** powered by **balenaOS**. It unifies your smart lighting (**Philips Hue / Zigbee**), audio/media gear, and connected devices (**IoT**) into a single local hub, making them effortlessly controllable from the **Apple Home** app through seamless **Homebridge** orchestration.

---

## What is HuewizPi? (Beginner-Friendly)

When adding smart bulbs, plugs, sensors, or speakers from different brands, you quickly end up juggling multiple mobile apps and proprietary bridges.

**HuewizPi acts as your home's central conductor and universal translator—deployed in one click:**
* **Zero-Config Container Stack:** Powered by **balena**, every service runs inside isolated Docker containers. No Linux command-line headaches or broken dependencies—just flash your SD card and power on.
* **Works with Apple HomeKit:** Even if an accessory isn't officially certified for Apple Home, HuewizPi uses **Homebridge** to expose it to your iPhone, iPad, Mac, and **Siri** voice control.
* **Dedicated IoT Gateway:** Manages local network routing and acts as a clean access point for your smart home traffic.

---

## Key Features

* **One-Click Deployment with balena:** Automated over-the-air (OTA) updates, fleet management, and self-healing containers via balenaCloud.
* **Zigbee & Philips Hue Lighting Control:** Manage bulbs, switches, dimmers, and custom lighting scenes.
* **Universal Bridge via Homebridge:** Support for thousands of smart home accessories (outlets, blinds, sensors, multiroom audio/media devices) and the entire Homebridge plugin ecosystem.
* **Apple HomeKit Integration:** Quick pairing with the Apple Home app via QR code.
* **Containerized Network & Access Point:** Pre-configured container networking to isolate and route your IoT devices cleanly.

---

## Hardware Requirements

* **Raspberry Pi** (Pi 3B+, Pi 4, or Pi 5 recommended) with a microSD card (16 GB+ Class 10 / A1) and official power supply.
* **Network Connection:** Ethernet cable (recommended for stability) or Wi-Fi.
* *(Optional)* A USB Zigbee coordinator dongle (e.g., ConBee II, Sonoff Zigbee 3.0) or an existing Philips Hue Bridge, depending on your setup.

---

## Quick Start (One-Click Deploy)

1. Click the **"Deploy with balena"** button at the very top of this page.
2. Create or select a **balenaCloud** fleet for your Raspberry Pi model.
3. Download the pre-configured **balenaOS** image and flash it onto your microSD card (using [balenaEtcher](https://etcher.balena.io/)).
4. Insert the SD card into your Raspberry Pi and power it on—HuewizPi will automatically download and start all containers.

For detailed configuration, environment variables, and local CLI deployment, see **[INSTALL.md](INSTALL.md)**.

---

## GitHub Topics & Keywords

Recommended repository topics to improve discoverability:
`raspberry-pi` `balena` `balena-cloud` `docker-compose` `homebridge` `homekit` `smart-home` `home-automation` `philips-hue` `zigbee` `iot-gateway` `iot-hub` `apple-home`

---

## Disclaimer & Trademarks

HuewizPi is an independent open-source project and is not affiliated with, endorsed, or sponsored by Apple Inc., Signify, or balena Ltd.  
*Apple*, *HomeKit*, *iPhone*, *iPad*, *Mac*, and *Siri* are registered trademarks of Apple Inc. *Philips Hue* is a registered trademark of Signify Holding. *Zigbee* is a registered trademark of the Connectivity Standards Alliance. *balena* and *balenaOS* are trademarks of balena Ltd.