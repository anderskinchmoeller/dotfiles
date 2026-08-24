#!/usr/bin/env bash

set -e

echo "=== Yabai Scripting Addition Installer ==="

# --- 1. Check SIP status ---
echo "[1/6] Tjekker SIP-status..."
SIP_STATUS=$(csrutil status 2>/dev/null || true)

if ! echo "$SIP_STATUS" | grep -q "without debug"; then
    echo "⚠️  SIP er ikke slået delvist fra."
    echo "    Kør i Recovery OS:"
    echo "        csrutil enable --without debug"
    exit 1
fi
echo "✔ SIP er korrekt konfigureret."

# --- 2. Stop yabai service ---
echo "[2/6] Stopper eksisterende yabai-service..."
brew services stop yabai 2>/dev/null || true
sudo launchctl unload /Library/LaunchDaemons/com.koekeishiya.yabai.plist 2>/dev/null || true
echo "✔ yabai stoppet."

# --- 3. Install SA ---
echo "[3/6] Installerer scripting addition..."
sudo yabai --install-sa
if [ ! -d "/System/Library/ScriptingAdditions/yabai.osax" ]; then
    echo "❌ SA blev ikke installeret korrekt."
    exit 1
fi
echo "✔ SA installeret."

# --- 4. Import certificate + sign SA ---
echo "[4/6] Signerer scripting addition..."

if [ ! -f "$HOME/.yabai/yabai-cert.p12" ]; then
    echo "❌ Certifikat mangler: ~/.yabai/yabai-cert.p12"
    echo "    Generér det med:"
    echo "        ./create-cert.sh"
    exit 1
fi

sudo security create-keychain -p "" yabai 2>/dev/null || true
sudo security import "$HOME/.yabai/yabai-cert.p12" \
    -k ~/Library/Keychains/yabai -P "" -T /usr/bin/codesign

sudo codesign -fs "yabai-cert" /System/Library/ScriptingAdditions/yabai.osax
echo "✔ SA signeret."

# --- 5. Install + start launchd service ---
echo "[5/6] Installerer launchd-service..."
sudo yabai --install-service
sudo launchctl load /Library/LaunchDaemons/com.koekeishiya.yabai.plist
sudo launchctl start com.koekeishiya.yabai
echo "✔ launchd-service aktiv."

# --- 6. Verify SA ---
echo "[6/6] Verificerer scripting addition..."
OUT=$(yabai -m query --windows || true)

if echo "$OUT" | grep -q "is-floating"; then
    echo "🎉 Scripting addition virker!"
else
    echo "⚠️ SA ser ikke ud til at være aktiv."
    echo "    Tjek rettigheder i System Settings:"
    echo "        - Accessibility"
    echo "        - Full Disk Access"
    echo "        - Screen Recording"
fi

echo "=== Færdig ==="

