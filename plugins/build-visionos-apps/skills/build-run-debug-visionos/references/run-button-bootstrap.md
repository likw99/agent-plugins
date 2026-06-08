# Run Button Bootstrap (visionOS)

Canonical bootstrap contract for the visionOS Build plugin's local run loop.

When a project does not already have a visionOS run entrypoint:

1. Create one project-local `script/build_and_run.sh`.
2. Make it executable.
3. Use it as the single boot + build + install + launch entrypoint.
4. Support optional `--logs`, `--debug`, `--device`, and `--verify` flags.
5. Write `.codex/environments/environment.toml` so the Codex app exposes a `Run`
   action wired to that script.

visionOS apps are bundle apps that run in the Simulator or on device. There is no
raw-executable launch path (unlike a SwiftPM CLI). The script always targets a
simulator destination by default.

## `script/build_and_run.sh`

Customize `SCHEME`, `BUNDLE_ID`, and either `WORKSPACE` or `PROJECT` for the
project. Keep the default no-flag path simple: boot, build, install, launch.

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- project-specific config ---
WORKSPACE=""                       # e.g. "HiPtah.xcworkspace" (leave empty if using PROJECT)
PROJECT="HiPtah/HiPtah.xcodeproj"  # e.g. "HiPtah/HiPtah.xcodeproj"
SCHEME="HiPtah"
BUNDLE_ID="com.example.HiPtah"
SIM_NAME="Apple Vision Pro"
CONFIG="Debug"
# --------------------------------

MODE="${1:-run}"
DERIVED="$(pwd)/.build/derived"

if [[ -n "$WORKSPACE" ]]; then
  CONTAINER=(-workspace "$WORKSPACE")
else
  CONTAINER=(-project "$PROJECT")
fi

DEST="platform=visionOS Simulator,name=${SIM_NAME}"

echo "==> Booting simulator: ${SIM_NAME}"
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true
open -a Simulator || true

echo "==> Building ${SCHEME} (${CONFIG})"
xcodebuild "${CONTAINER[@]}" -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination "$DEST" -derivedDataPath "$DERIVED" build

APP_PATH="$(find "$DERIVED/Build/Products" -maxdepth 2 -name '*.app' -type d | head -1)"
if [[ -z "$APP_PATH" ]]; then
  echo "ERROR: built .app not found under $DERIVED/Build/Products" >&2
  exit 1
fi
echo "==> Built: $APP_PATH"

echo "==> Installing + launching $BUNDLE_ID"
xcrun simctl install booted "$APP_PATH"
xcrun simctl terminate booted "$BUNDLE_ID" 2>/dev/null || true

case "$MODE" in
  run)
    xcrun simctl launch booted "$BUNDLE_ID"
    ;;
  logs)
    xcrun simctl launch booted "$BUNDLE_ID"
    echo "==> Streaming logs (Ctrl-C to stop)"
    xcrun simctl spawn booted log stream --level debug \
      --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  debug)
    # Launch suspended and attach lldb
    xcrun simctl launch --wait-for-debugger booted "$BUNDLE_ID"
    echo "==> App waiting for debugger. Attach with: lldb -p <pid>"
    ;;
  verify)
    xcrun simctl launch booted "$BUNDLE_ID"
    sleep 2
    xcrun simctl spawn booted launchctl list | grep -q "$BUNDLE_ID" \
      && echo "VERIFY: $BUNDLE_ID is running" \
      || { echo "VERIFY: $BUNDLE_ID not running" >&2; exit 1; }
    ;;
  device)
    echo "==> Device builds: select your Apple Vision Pro in Xcode and run, or"
    echo "    use 'xcodebuild ... -destination \"platform=visionOS,name=<device>\"'"
    echo "    plus 'xcrun devicectl device install/launch' for on-device deploy."
    ;;
  *)
    echo "Unknown mode: $MODE (use: run|logs|debug|verify|device)" >&2
    exit 2
    ;;
esac
```

Notes:
- Keep `--logs` for lifecycle, immersive-space, and authorization debugging.
- For on-device deploy, prefer running from Xcode first to handle pairing,
  provisioning, and trust; `xcrun devicectl` covers scripted install/launch once
  the device is paired.
- If `xcodebuild` reports a missing visionOS SDK, install the visionOS platform
  in Xcode (Settings > Components) before retrying.

## `.codex/environments/environment.toml`

Place at the project root **after** the script exists. If the file already
exists, update the `Run` action's command instead of adding a duplicate.

```toml
[[actions]]
name = "Run"
command = "./script/build_and_run.sh"

[[actions]]
name = "Run (logs)"
command = "./script/build_and_run.sh logs"
```

This is what gives the Codex app a Run button wired to the script. Keep this
Codex environment config separate from Swift app source files.
