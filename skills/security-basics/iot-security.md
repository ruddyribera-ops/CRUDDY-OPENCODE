# IoT Security

Securing Internet of Things devices — embedded systems, firmware, protocols, and the unique challenges of constrained devices.

## IoT Architecture Layers

```
┌─────────────────────────────────────────────┐
│          Cloud / Backend Services           │
│        (data aggregation, ML, storage)      │
└──────────────────────┬──────────────────────┘
                       │ HTTPS / MQTT / CoAP
┌──────────────────────┴──────────────────────┐
│              Gateway / Controller            │
│         (hub, router, edge device)          │
└──────────────────────┬──────────────────────┘
                       │ Zigbee / Z-Wave / BLE / WiFi
┌──────────────────────┴──────────────────────┐
│            IoT Devices                       │
│  (sensors, actuators, cameras, smart plugs)   │
└─────────────────────────────────────────────┘
```

## Common IoT Protocols

| Protocol | Port | Encryption | Best For |
|----------|------|------------|---------|
| **MQTT** | 1883 (plain), 8883 (TLS) | Optional (TLS optional on 1883) | Low-power pub/sub, home automation |
| **CoAP** | 5683 (UDP) | DTLS optional | Constrained devices, M2M |
| **HTTP/REST** | 80/443 | TLS | Web-integrated devices |
| **XMPP** | 5222 | TLS optional | Device-to-device messaging |
| **AMQP** | 5672 | TLS/StartTLS | Enterprise messaging |
| **WebSocket** | 80/443 | WSS (TLS) | Real-time bidirectional |
| **gRPC** | 50051 | TLS always | High-performance services |

### MQTT Security

```python
# Wrong: anonymous MQTT broker (common in consumer IoT)
# mosquitto.conf (INSECURE):
# allow_anonymous true
# listener 1883

# Correct MQTT configuration:
# mosquitto.conf
listener 8883
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
require_certificate true
use_identity_as_username true

# Client connection (Python):
import paho.mqtt.client as mqtt

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to broker")
    else:
        print(f"Connection failed: {rc}")

client = mqtt.Client()
client.tls_set(ca_certs="/etc/ssl/certs/ca.crt",
               certfile="/path/to/client.crt",
               keyfile="/path/to/client.key")
client.username_pw_set("device001", "strong_password")
client.on_connect = on_connect
client.connect("broker.example.com", 8883, 60)
```

### CoAP (Constrained Application Protocol)

```python
# CoAP uses DTLS for security (Certificate-based or PSK)
# RFC 7252 defines CoAP security

# Python aiocoap example:
import asyncio
from aiocoap import Context, Code

async def main():
    # DTLS with PSK (Pre-Shared Key) for constrained devices
    ctx = await Context.create_client_correlation_context()
    
    # Use Edward25519 for constrained devices (small key size, high security)
    # Ed25519: 32-byte public key, EdDSA signature algorithm
    
    request = Message(code=Code.GET, uri='coaps://device.local/sensor/temp')
    response = await ctx.request(request).response
    print(response.payload)
```

## Firmware Security

### Firmware Extraction

```bash
# Extract firmware from device:
# 1. UART/JTAG debugging (hardware)
# 2. Flash chip directly with SPI programmer
# 3. Update file from vendor website

# Binwalk — extract files from firmware image:
binwalk -e firmware.bin

# Firmwalk for entropy analysis (detects encrypted sections):
binwalk -E firmware.bin  # entropy graph

# Find cryptographic constants (AES, RSA signatures):
binwalk -R 'AES' firmware.bin
```

### Firmware Analysis

```bash
# Firmwalker — automated firmware analysis:
/path/to/firmwalker.sh firmware.bin ./output/

# Extract and analyze filesystem:
cd firmware.bin.extracted
ls -la squashfs-root/
cat squashfs-root/etc/shadow  # look for weak passwords

# Check for hardcoded credentials:
grep -r "password" squashfs-root/etc/
grep -r "api_key" squashfs-root/

# Find backdoors (unexpected listeners):
netstat -tulpn squashfs-root/proc/net/tcp

# Check for SSH keys left on device:
ls -la squashfs-root/etc/dropbear/
```

### Firmware Hardening Checklist

| Check | What to Look For |
|-------|-----------------|
| **Default credentials** | Root accounts with no password or known weak passwords |
| **Hardcoded secrets** | API keys, AWS tokens, private keys embedded in firmware |
| **Telnet enabled** | Unencrypted remote access left on by default |
| **Debug ports** | UART/JTAG exposed on PCB without password protection |
| **Unsigned firmware** | No cryptographic signature verification on update |
| **Outdated components** | Old OpenSSL, BusyBox, SSH versions with known CVEs |
| **Plaintext config** | Credentials stored in plain text in config files |

### Secure Boot

```
Secure Boot Chain:
1. ROM (immutable, device manufacturer burnt)
   ↓ (hardware root of trust)
2. Bootloader (signed by manufacturer, verified by ROM)
   ↓ (if signature valid)
3. Kernel/OS (signed, verified by bootloader)
   ↓ (if signature valid)
4. Application (signed, verified by OS)
   ↓ (if signature valid)
5. Data partitions (encrypted, keys bound to secure boot chain)
```

- **Root of Trust**: Immutable ROM with known-good public key burned in
- **Chain of Trust**: Each stage verifies the next before executing
- **Anti-rollback**: Prevent downgrading to vulnerable firmware versions

## Zigbee Security

```
Zigbee Security Layers:
- Network key: encrypts all broadcast/multicast traffic
- Link key: encrypts unicast between two devices (AES-128)
- Trust center: issues network key, authenticates new devices

Common issues:
- Factory default network key (all devices same key)
- No APS layer encryption on some devices
- "Install codes" not used in consumer devices
```

**Hardening Zigbee:**
```bash
# Use install codes (unique per-device link key derived from a shared secret)
# Pre-shared install code: 16-byte random + 16-byte CRC
# Both sides derive link key from install code + counter

# Prefer Zigbee 3.0 (has cryptographic improvements over older versions)
# Disable TC link key broadcast (option 2 in ZCL)
# Use Global Trust Center Link Key: Z2M specific but prevents some attacks
```

## Bluetooth Low Energy (BLE) Security

| Attack | Description | Mitigation |
|--------|-------------|------------|
| **Blueborne** | BLE chip remote code execution | Patch BLE firmware |
| **BLEEDINGBIT** | Chips with Aruba APs, overflow in BLE stack | Patch AP firmware |
| **KNOB attack** | Force negotiate 1 byte entropy for LTK | Enforce 16-byte minimum key |
| **Passkey injection** | Observe passkey during pairing, inject | Use LE Secure Connections |
| **BLE phishing** | Clone device, trick user to pair | Pairing confirmation, bonded device whitelist |

**BLE Hardening:**
```bash
# Use LE Secure Connections (pairing method 4 - numeric comparison)
# Minimum key strength: 16 bytes (no STK with lower entropy)

# For devices: bonding with reject list for untrusted devices
# For hubs: reject connections from non-whitelisted devices

# Monitor for unexpected advertising (reconnaissance)
# hcitool lescan | grep -E "^[0-9A-F:]{17}"
```

## Network Segmentation for IoT

```
DMZ / IoT VLAN Architecture:
[Internet] → [Router/FW] → [VLAN 10: IoT devices]
                           → [VLAN 20: Smart home controllers]
                           → [VLAN 30: Guest devices]
                           → [Main LAN: Trusted devices]
```

```bash
# VLAN separation (example for OpenWrt router):
# Firewall zones:
# - iot: WAN + LAN zone
# - trusted: LAN only

# iptables rules to prevent IoT → trusted communication:
iptables -A FORWARD -i iot0 -o trusted0 -j DROP
iptables -A FORWARD -i trusted0 -o iot0 -j ACCEPT  # allow response traffic

# Only allow IoT devices to communicate with specific cloud endpoints
iptables -A FORWARD -i iot0 -d 0.0.0.0/0 -j DROP
iptables -A FORWARD -i iot0 -d 52.0.0.0/8 -j ACCEPT  # allowed cloud range
```

**Rules for IoT VLAN:**
- IoT cannot initiate connections to trusted LAN
- IoT can only reach internet, not local network
- IoT cannot reach management interfaces of router
- Block mDNS/UPnP from crossing VLANs

## Unique IoT Constraints & Tradeoffs

| Constraint | Implication | Recommended Approach |
|-------------|-------------|----------------------|
| **Limited RAM/ROM** | Cannot run full TLS stack, limited crypto libraries | Use pre-shared keys (PSK), smaller key sizes where appropriate |
| **Battery powered** | Cannot do heavy computation or constant encryption | Use wake-on-wireless,ECC for signatures, asymmetric crypto only during pairing |
| **No screen/UX** | Cannot do OTP or out-of-band verification | Use secure pairing (NFC tap, BLE during setup) |
| **Long device lifespan** | May outlive cloud services, crypto agility needed | Plan for algorithm deprecation, field-updatable firmware |
| **Manufacturing cost** | No secure element (TPM), keys in firmware | Use TRNG with anti-cloning measures, burn keys during manufacturing |

## OTA (Over-The-Air) Update Security

```python
# Secure OTA update process:
# 1. Sign firmware binary with Ed25519 private key (manufacturer offline key)
# 2. Include: signature + firmware version + target device type + timestamp
# 3. Device: verify signature before flashing
# 4. Device: check version number (reject downgrades)
# 5. Device: apply firmware only after full signature verification
# 6. Device: boot into new firmware, verify again (self-measurement)

# Wrong approach (insecure):
# HTTP download + checksum only → attacker can replace binary
# No signature → attacker can flash any firmware
# Version not checked → attacker can downgrade to vulnerable version
```

## IoT Security Checklist

- [ ] Default credentials changed to strong unique passwords
- [ ] Telnet/SSH disabled or password-protected
- [ ] TLS for all cloud communication (not plaintext MQTT 1883)
- [ ] MQTT: use TLS + client certificates, disable anonymous
- [ ] CoAP: use DTLS with PSK or certificates
- [ ] WiFi: use WPA2/WPA3 with strong PSK, enterprise auth preferred
- [ ] Zigbee: use install codes, prefer Zigbee 3.0
- [ ] BLE: use LE Secure Connections, bond whitelist
- [ ] Firmware: signature verification on update
- [ ] Firmware: anti-rollback (version check)
- [ ] Secure boot chain implemented (hardware root of trust)
- [ ] No hardcoded credentials in firmware (or use encrypted storage)
- [ ] IoT devices on isolated VLAN, no trusted LAN access
- [ ] mDNS/UPnP blocked at firewall between VLANs
- [ ] IoT traffic to cloud allowed, local LAN blocked
- [ ] Regular firmware updates (monitor CVE feeds for your devices)
- [ ] Remote console access logged and monitored
- [ ] Physical debug ports (UART/JTAG) disabled or password-protected