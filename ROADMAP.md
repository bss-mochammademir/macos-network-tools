# 🗺️ NetPulse Roadmap: The ZTNA Vision

This document outlines the future evolution of NetPulse, moving from a local productivity tool to a centralized management and security platform.

## 🚀 Phase 4: Cloud Sync & Policy Management
**Objective**: Synchronize settings and whitelists across multiple devices for a single user.
- **User Accounts**: Integration with SSO (Google, Microsoft) for profile management.
- **Global Whitelist**: Centrally managed whitelist that updates across all instances of NetPulse.
- **Activity Logging**: (Optional/Privacy-First) Local logging of meeting mode efficiency stats.

## 🏢 Phase 5: IT Admin Portal (NetPulse Enterprise)
**Objective**: Enable IT administrators to manage network stability for remote teams.
- **Centralized Dashboard**: A web interface to view the network health of the entire fleet.
- **Push Policies**: Remote activation of "Meeting Mode" or "Critical Focus Mode" during organization-wide events.
- **Alerting**: Notifications for IT admins when bandwidth bottlenecks are detected at scale.

## 🛡️ Phase 6: ZTNA Lite (Zero Trust Access)
**Objective**: Integrate network monitoring with device security and access control.
- **Conditional Access**: Block access to specific internal resources if a device's network environment is deemed "unstable" or "high-risk."
- **Posture Checking**: Ensure specific security apps are running before allowing high-bandwidth corporate tools to activate.
- **Encrypted Tunnels**: Direct integration with VPN/ZTNA providers (like Cloudflare or Tailscale) to optimize routing for meeting apps.

## 🏗️ Phase 7: Tamper Resistance (Agent Self-Protection)
**Objective**: Ensure the NetPulse agent remains persistent and secure from unauthorized modification or termination.
- **`launchd` Persistence**: Installation as a system-wide LaunchDaemon with `KeepAlive` to ensure it auto-restarts if killed.
- **Privileged Helper Tools**: Offloading critical monitoring and firewall tasks to a root-owned background helper.
- **Endpoint Security (ES) Integration**: Utilizing macOS `EndpointSecurity` framework to monitor and block attempts to `SIGKILL` the process or delete its core configuration files.
- **Admin-Locked Uninstall**: Requiring a "Tamper Protection" password or MDM (Mobile Device Management) profile to uninstall or disable the agent.

## 🧠 Phase 8: Micro-Scalable Posturing (Context-Aware HIP)
**Objective**: Dynamically scale network capabilities based on the real-time "Health Score" of the device.
- **Dynamic Throttling**: Instead of hard Allow/Deny, NetPulse can "throttle" total bandwidth if security patches are missing or mandatory agents are inactive.
- **App-Specific Compliance**: Detect if unauthorized apps (e.g., non-encrypted chat tools) are installed and automatically apply "Smart Pause" to them while allowing corporate tools.
- **HIP-to-Preset Mapping**: 
    - *Healthy*: Full bandwidth, all whitelisted apps.
    - *At-Risk*: Throttled to 1MB/s, background noise paused.
    - *Non-Compliant*: "Quarantine Preset" (only VPN & Security updates allowed).
- **Fast Integrity Check**: Using `mdfind` and `NSWorkspace` for lightweight, non-intrusive inventory scanning that doesn't bog down the system.

---
*NetPulse: Stabilizing the future of remote work.*
