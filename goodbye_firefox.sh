#!/bin/sh

# Firefox AI & Telemetry Disablement Script for macOS
# ---------------------------------------------------------------

POLICIES_DIR="/Applications/Firefox.app/Contents/Resources/distribution"
POLICIES_FILE="$POLICIES_DIR/policies.json"

PROFILE_DIR=$(find "$HOME/Library/Application Support/Firefox/Profiles" -name "*.default-release" 2>/dev/null | head -n 1)
USER_JS=""
if [ -n "$PROFILE_DIR" ]; then
  USER_JS="$PROFILE_DIR/user.js"
fi

PASS_COUNT=0
FAIL_COUNT=0

run_check() {
  DESC="$1"
  shift
  "$@" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    printf "✅  %s\n" "$DESC"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "🛑  %s  <-- FAILED\n" "$DESC"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

printf "🔧 Step 1: Checking Firefox Installation...\n\n"

if [ ! -d "/Applications/Firefox.app" ]; then
  printf "🛑  Firefox is not installed in /Applications/Firefox.app.\n"
  printf "    ➡️  Please install Firefox and run this script again.\n"
  exit 1
fi
printf "✅  Firefox application bundle detected\n\n"

printf "🔧 Step 2: Applying Enterprise Policies (policies.json)...\n\n"

apply_policies() {
  mkdir -p "$POLICIES_DIR"
  cat << 'EOF' > "$POLICIES_FILE"
{
  "policies": {
    "DisableFirefoxStudies": true,
    "DisableTelemetry": true,
    "FirefoxAI": false,
    "Preferences": {
      "browser.ml.enable": false,
      "browser.ml.chat.enabled": false,
      "browser.ml.chat.sidebar": false,
      "browser.tabs.firefox-view.ai-summaries.enabled": false,
      "browser.search.suggest.enabled.private": false,
      "messaging-system.rfx.ai-prompts": false
    }
  }
}
EOF
}

run_check "Write enterprise policies.json" apply_policies

printf "\n🔧 Step 3: Patching Profile user.js for persistent local overrides...\n\n"

if [ -z "$PROFILE_DIR" ] || [ ! -d "$PROFILE_DIR" ]; then
  printf "🛑  Could not locate active Firefox profile folder.\n"
  printf "    ➡️  Open Firefox once to generate your profile directory.\n"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  apply_user_js() {
    cat << 'EOF' >> "$USER_JS"

// Disable Firefox AI Chatbot & On-Device ML Model Features
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.chat.sidebar", false);
user_pref("browser.ml.chat.provider", "");
user_pref("browser.tabs.firefox-view.ai-summaries.enabled", false);

// Disable Firefox Pocket / Recommended Content AI Integrations
user_pref("extensions.pocket.enabled", false);
user_pref("identity.fxaccounts.toolbar.enabled", false);

// Disable Telemetry & Background Experiments
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("experiments.activeExperiment", false);
EOF
  }

  run_check "Append preferences to $USER_JS" apply_user_js
fi

printf "\n"
printf "📊 SUMMARY: %d succeeded ✅ | %d failed 🛑\n" "$PASS_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  printf "⚠️  One or more steps failed. Re-run with 'sh -x %s' to debug.\n" "$0"
else
  printf "🎉 Firefox AI features and policies configured successfully!\n"
fi

printf "\n"
printf "🤖 If you want AI, ask your LLM — not your browser. 😎\n"
printf "\n"
printf "👉 NEXT STEPS — please don't skip these! 👇\n"
printf "\n"
printf "1️⃣  🔁 QUIT Firefox completely (Cmd+Q) and relaunch it.\n"
printf "\n"
printf "2️⃣  🕵️  VERIFY Enterprise Policies loaded correctly:\n"
printf "      ➡️  Go to about:policies\n"
printf "      ➡️  Confirm 'Active' policies reflect DisableTelemetry & FirefoxAI.\n"
printf "\n"
printf "3️⃣  🔒 CHECK about:config\n"
printf "      ➡️  Search 'browser.ml.enable' 🔍\n"
printf "      ➡️  Confirm the status is set to 'false' (locked by policy/user.js) 🔐\n"
printf "\n"
printf "4️⃣  🧩 CHECK Firefox Extensions\n"
printf "      ➡️  Go to about:addons\n"
printf "      ➡️  Remove any third-party AI sidebars, page summarizers, or translate tools 🗑️\n"
printf "\n"
printf "5️⃣  🌐 CHECK Search Engine AI Overviews\n"
printf "      ➡️  Enterprise policies do not edit engine-level web results (Google/Bing).\n"
printf "      ➡️  Use an extension or custom CSS to block inline search engine AI summaries if needed 🙈\n"
printf "\n"
printf "🛡️  Policies beat toggles, but user profiles require Firefox to be closed during script execution!\n"
printf "🚀 Stay AI-free (until YOU decide otherwise) 🚀\n"