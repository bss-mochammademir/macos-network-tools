const functions = require('@google-cloud/functions-framework');

functions.http('getPolicy', (req, res) => {
  // 1. Basic Auth / Tenant ID check (Placeholder)
  // const tenantId = req.query.tenant_id || "DEFAULT";

  // 2. Construct the Response
  const policy = {
    meta: {
      version: 1,
      last_updated: new Date().toISOString(),
      tenant_id: "DEFAULT_TENANT_GCP"
    },
    policy: {
      enforcement_mode: "soft", // Changed to "soft" to FORCE Meeting Mode OFF
      global_whitelist: [
        // User Requested
        "CloudflareWARP", "WARP", "language_server", "Antigravity Hel", "Antigravity",
        "netbiosd", "apsd", "rapportd", "syspolicyd", "symptomsd",

        // Critical Communication Check
        "zoom", "zoom.us", "unshare",
        "Teams", "Microsoft Teams",
        "Slack", "Slack Helper",
        "Webex", "Cisco Webex Meeting",
        "Skype",
        "FaceTime",

        // Browsers
        "Google Chrome", "Google Chrome Helper", "Chrome",
        "Safari", "Safari Networking",
        "Firefox", "org.mozilla.firefox",
        "Arc", "company.thebrowser.Browser",

        // VPN & Security
        "Tailscale", "IPNExtension",
        "Cloudflare",
        "AnyConnect", "Cisco Secure Client",
        "GlobalProtect", "PanGPS",

        // System Core
        "NetPulse",
        "ControlCenter", "SystemUIServer", "WindowServer", "loginwindow",
        "trustd", "mDNSResponder", "mDNSResponderHelper",
        "hidd", "coreaudiod", "bluetoothd", "airportd",
        "kernel_task", "launchd", "UserEventAgent"
      ],
      features: {
        meeting_mode: true,
        hardening: true
      }
    }
  };

  // 3. Send Response
  res.status(200).json(policy);
});
