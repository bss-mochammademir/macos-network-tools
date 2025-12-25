# 🚀 Phase 4: Cloud Sync & Policy Management

**Status**: Planning
**Focus**: Identity & Centralized Configuration

Phase 4 transforms NetPulse from a standalone utility into a managed enterprise agent. The goal is to bind the local agent to a corporate identity (SSO) and enable remote configuration of policies.

## Key Objectives

### 1. Identity & Access (SSO)
- **Authentication**: Integrate with a Cloud Identity Provider (IdP) to bind the agent to a specific user email/tenant.
- **Tenant Isolation**: Ensure policies are fetched only for the user's specific organization (Tenant ID).
- **Session Management**: Handle token refresh and secure storage of identity claims (JWT).

### 2. Cloud Policy Engine
- **Remote Configuration**: Fetch `policy_config.json` from a remote endpoint instead of relying solely on local defaults.
- **Global Whitelist**: Centrally managed list of "Critical Apps" (e.g., Corporate VPN, EDR, MDM) that cannot be paused by the user.
- **Feature Flags**: Remotely enable/disable features (like "Meeting Mode" or "Hardening") based on user group.

### 3. Sync & Reporting
- **Heartbeat**: Periodic check-in to report agent status (Healthy/Throttled/Hardened).
- **Config Sync**: Automatically apply policy updates without requiring an app restart.

## Technical Architecture

### Frontend (macOS Agent)
- **Auth Library**: OpenID Connect (OIDC) or Firebase Auth via REST API for lightweight integration.
- **Policy Fetcher**: `URLSession` background tasks to poll for config updates (ETag support for efficiency).
- **Secure Storage**: Store Refresh Tokens and Lullaby Hash in **Keychain** (migrating from `policy_config.json`).

### Backend (Cloud)
- **Endpoint**: `https://api.netpulse.io/v1/policy` (or Google Cloud Function).
- **Database**: Firestore/PostgreSQL to store Tenant configurations and User <-> Policy mappings.
- **Auth Middleware**: Verify JWT signature before serving policy data.

## User Stories
- **As an IT Admin**, I want to add "Zoom" to the Global Whitelist so that no employee accidentally pauses it during a meeting.
- **As a User**, I want my "Meeting Mode" preferences to sync across my MacBook Pro and iMac without setting them up twice.
- **As a Security Officer**, I want to ensure that "Hardened Mode" is forced ON for all Finance department users.

## Testing Remote Policy Updates

### Quick Test: Change Enforcement Mode
To test remote policy enforcement without redeploying:

1. **Edit the Cloud Function**:
   ```bash
   # Navigate to backend functions
   cd backend/functions
   
   # Edit index.js
   nano index.js  # or use your preferred editor
   ```

2. **Modify `enforcement_mode`** (line 15):
   ```javascript
   enforcement_mode: "focus",  // Options: "monitor_only", "soft", "focus", "strict"
   ```

3. **Deploy the update**:
   ```bash
   gcloud functions deploy getPolicy \
     --runtime nodejs20 \
     --trigger-http \
     --allow-unauthenticated \
     --region asia-southeast2 \
     --source backend/functions \
     --gen2
   ```

4. **Wait for client to sync** (max 60 seconds)
   - The NetPulse app polls every 60 seconds
   - Watch the Meeting Mode button toggle automatically

### Available Enforcement Modes
| Mode | Effect | Use Case |
|------|--------|----------|
| `monitor_only` | Normal operation, no restrictions | Default state |
| `soft` | Explicitly disable Meeting Mode | Override user settings |
| `focus` | Force Meeting Mode ON | Company-wide meetings |
| `strict` | PDP Compliance Mode | High-security scenarios |

### Modifying the Whitelist
Edit `global_whitelist` array in `backend/functions/index.js`:
```javascript
global_whitelist: [
  "CloudflareWARP",
  "language_server",
  "Antigravity Hel",
  "zoom",
  "Teams",
  // Add your apps here
]
```

### Testing Workflow
1. **Baseline**: Deploy with `enforcement_mode: "monitor_only"`
2. **Trigger**: Change to `"focus"` and redeploy
3. **Observe**: Client activates Meeting Mode within 60s
4. **Revert**: Change back to `"monitor_only"`
5. **Verify**: Client deactivates Meeting Mode within 60s

## Success Metrics
- [x] Agent successfully fetches remote policy on startup
- [x] Agent applies remote whitelist updates within 60 seconds
- [x] Remote enforcement mode changes are reflected automatically
- [ ] "Hardened Mode" cannot be disabled if remote policy dictates `force_hardened: true`
