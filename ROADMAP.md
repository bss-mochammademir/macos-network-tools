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

## 🌊 Phase 9: Phased Roll-out & Enforcement Strategy
**Objective**: Enable seamless adoption without productivity disruption using a 4-stage deployment model.
1. **Enrollment (Silent Mode)**: Agent is deployed and registered. It collects baseline performance and posturing data without taking any active measures.
2. **Soft Enforcement (Risk-Aware)**: Automatically pauses or throttles high-risk domains and known insecure applications (e.g., malware delivery sites, unapproved P2P apps).
3. **Default Enforcement (Compliance-Driven)**: Implements blocks based on organizational standards (ISO 27001) and "Parental Control-style" filtering for work-life balance and focus.
4. **Strict Enforcement (PDP/Critical Mode)**: Maximum restriction focused on **Personal Data Protection (Perlindungan Data Pribadi)**. Only strictly authorized, high-security applications are allowed; all other traffic is suspended to prevent data leakage in compliance with banking-level regulations.

## ☁️ Phase 10: Private Tunneling & Cloud-Native ZTNA (GCP Integration)
**Objective**: Access on-premises applications securely without public static IPs or inbound firewall rules using Google Cloud.
- **Outbound Reverse Tunnels**: Integration with **GCP BeyondCorp Enterprise App Connectors**. Instead of opening ports, NetPulse (or a sister connector) initiates an outbound TLS tunnel to Google Cloud.
- **Identity-Aware Proxy (IAP)**: Traffic is routed through GCP's IAP, ensuring that users are authenticated and their device meets the "Health Score" (from Phase 8) before they can reach the on-prem tunnel.
- **Branch-Office-as-a-Code**: Ability to deploy small "NetPulse Tunnel Agents" on-prem that bridge the gap to the corporate VPC in GCP automatically.
- **Zero-Trust App Access**: Users access on-prem internal URLs (e.g., `http://payroll.internal`) via the secure tunnel as if they were on the local network.

## 🏦 Phase 11: Source-IP Preservation & Cryptographic Attribution (Banking Compliance)
**Objective**: Solve the regulatory "Source IP" blocker by ensuring the backend application can definitively identify the origin of every request.
- **PROXY Protocol & XFF Injection**: Configure App Connectors to inject the `PROXY protocol` (for TCP) or `X-Forwarded-For` (for HTTP) headers, passing the true client IP directly to the backend.
- **Deterministic Internal IP Mapping**: Assigning a unique, static Internal IP (via Private Service Connect) for each NetPulse agent, so the core banking system sees a consistent "Source IP" per user/device.
- **Cryptographic Request Signing**: NetPulse agent signs outgoing requests with a hardware-backed certificate (from the Secure Enclave). The backend verifies the signature, proving identity more strongly than an IP address ever could.
- **Unified Audit Logs**: Merging GCP IAP logs (Identity) with NetPulse Agent logs (Local Context) to build a "bulletproof" forensic trail that satisfies OJK/BI/Banking regulators.

## 💻 Phase 12: Cross-Platform Expansion (Windows & ChromeOS)
**Objective**: Surface the premium "Apple-ish" experience and security features to the broader organization, starting with Windows.
- **Windows Implementation (C# / .NET)**: Rebuilding the engine for Windows while strictly maintaining the "NetPulse Aesthetic."
- **TPM Integration**: Using the **Windows Trusted Platform Module (TPM)** to achieve the same hardware-backed cryptographic signing found in the macOS Secure Enclave.
- **Native Windows Control**: Utilizing Windows Filtering Platform (WFP) for high-performance network monitoring and enforcement.
- **ChromeOS Extension/App**: PWA or Android-based agent to capture the ChromeOS fleet.
- **Consistency as a Value**: Ensuring that whether on Mac or Windows, the user interface remains simple, fluid, and "premium," avoiding the cluttered feel of traditional enterprise IT software.

---
*NetPulse: Stabilizing the future of remote work.*
