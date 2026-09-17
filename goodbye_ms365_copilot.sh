#!/bin/sh

# Microsoft 365 / Copilot disablement checklist for macOS
# ---------------------------------------------------------------
# This script is intentionally read-only: it detects installed apps,
# reports versions, checks known Office privacy preferences, and prints
# the click-through steps needed to disable Copilot.

PASS_COUNT=0
WARN_COUNT=0
INFO_COUNT=0

printf "🔧 Microsoft 365 AI / Copilot audit starting...\n"
printf "🛡️  This script will not change Office settings.\n\n"

pass() {
  printf "✅  %s\n" "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  printf "🛑  %s\n" "$1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

info() {
  printf "ℹ️  %s\n" "$1"
  INFO_COUNT=$((INFO_COUNT + 1))
}

find_app() {
  APP_NAME="$1"

  for APP_PATH in \
    "/Applications/$APP_NAME.app" \
    "$HOME/Applications/$APP_NAME.app" \
    "/Applications/Microsoft Office/$APP_NAME.app"; do
    if [ -d "$APP_PATH" ]; then
      printf "%s" "$APP_PATH"
      return 0
    fi
  done

  return 1
}

app_version() {
  APP_PATH="$1"
  /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null
}

version_at_least() {
  # Usage: version_at_least actual required
  ACTUAL="$1"
  REQUIRED="$2"

  awk -v actual="$ACTUAL" -v required="$REQUIRED" '
    BEGIN {
      n = split(actual, a, ".")
      m = split(required, r, ".")
      max = (n > m ? n : m)
      for (i = 1; i <= max; i++) {
        av = (a[i] == "" ? 0 : a[i] + 0)
        rv = (r[i] == "" ? 0 : r[i] + 0)
        if (av > rv) exit 0
        if (av < rv) exit 1
      }
      exit 0
    }'
}

report_app() {
  APP_LABEL="$1"
  APP_NAME="$2"
  MIN_VERSION="$3"
  APP_PATH=$(find_app "$APP_NAME")

  if [ -n "$APP_PATH" ]; then
    VERSION=$(app_version "$APP_PATH")
    if [ -z "$VERSION" ]; then
      VERSION="unknown"
    fi

    printf "\n📦 %s\n" "$APP_LABEL"
    printf "   📍 Installed: %s\n" "$APP_PATH"
    printf "   🔢 Version:   %s\n" "$VERSION"

    if [ "$MIN_VERSION" = "none" ]; then
      info "$APP_LABEL detected; use the privacy/Copilot checklist below."
    elif [ "$VERSION" = "unknown" ]; then
      warn "$APP_LABEL version could not be read; check for updates manually."
    elif version_at_least "$VERSION" "$MIN_VERSION"; then
      pass "$APP_LABEL meets the documented minimum version $MIN_VERSION for its Copilot control."
    else
      warn "$APP_LABEL is below documented minimum $MIN_VERSION; update Microsoft 365 first."
    fi
  else
    info "$APP_LABEL not detected."
  fi
}

printf "🔎 Step 1: Detecting Microsoft 365 apps...\n"
report_app "Word" "Microsoft Word" "16.93"
report_app "Excel" "Microsoft Excel" "16.93.2"
report_app "PowerPoint" "Microsoft PowerPoint" "16.93.2"
report_app "Outlook" "Microsoft Outlook" "16.95.3"
report_app "OneNote" "Microsoft OneNote" "none"
report_app "Teams" "Microsoft Teams" "none"
report_app "Copilot app" "Microsoft Copilot" "none"

printf "\n🔎 Step 2: Reading known Office privacy preferences...\n"

read_pref() {
  PREF_NAME="$1"
  PREF_LABEL="$2"
  PREF_VALUE=$(defaults read com.microsoft.office "$PREF_NAME" 2>/dev/null)

  if [ "$PREF_VALUE" = "0" ] || [ "$PREF_VALUE" = "false" ] || [ "$PREF_VALUE" = "FALSE" ]; then
    pass "$PREF_LABEL is disabled ($PREF_NAME = $PREF_VALUE)"
  elif [ "$PREF_VALUE" = "1" ] || [ "$PREF_VALUE" = "true" ] || [ "$PREF_VALUE" = "TRUE" ]; then
    warn "$PREF_LABEL is enabled ($PREF_NAME = $PREF_VALUE)"
  elif [ -n "$PREF_VALUE" ]; then
    info "$PREF_LABEL has value '$PREF_VALUE' ($PREF_NAME)"
  else
    info "$PREF_LABEL is not explicitly set ($PREF_NAME)"
  fi
}

read_pref "OfficeExperiencesAnalyzingContentPreference" "Experiences that analyze content"
read_pref "ConnectedOfficeExperiencesPreference" "Most connected experiences"
read_pref "OptionalConnectedExperiencesPreference" "Optional connected experiences"
read_pref "OfficeExperiencesDownloadingContentPreference" "Experiences that download online content"

printf "\n"
printf "📊 AUDIT SUMMARY: %d passed ✅ | %d warnings 🛑 | %d informational ℹ️\n" "$PASS_COUNT" "$WARN_COUNT" "$INFO_COUNT"

printf "\n"
printf "👉 NEXT STEPS — Microsoft’s supported Mac controls 👇\n\n"

printf "1️⃣  🔁 Quit all Microsoft 365 apps completely, then reopen each one.\n"
printf "    Use Cmd+Q; closing a window is not enough.\n\n"

printf "2️⃣  📝 WORD / 📊 EXCEL / 📽️ POWERPOINT\n"
printf "    In each app separately:\n"
printf "      ➡️  App menu at the top of the screen\n"
printf "      ➡️  Preferences\n"
printf "      ➡️  Authoring and Proofing Tools\n"
printf "      ➡️  Copilot\n"
printf "      ➡️  Clear 'Enable Copilot'\n"
printf "      ➡️  Close and restart the app\n"
printf "    ⚠️  The setting is separate for each app and device.\n\n"

printf "3️⃣  📬 OUTLOOK\n"
printf "    ➡️  Update Outlook to at least version 16.95.3\n"
printf "    ➡️  Open Quick Settings\n"
printf "    ➡️  Select Copilot\n"
printf "    ➡️  Turn off 'Turn on Copilot'\n"
printf "    ℹ️  Outlook’s setting applies to that account across devices.\n\n"

printf "4️⃣  🛑 FALLBACK: disable content-analyzing connected experiences\n"
printf "    Use this if an app does not show an Enable Copilot checkbox:\n"
printf "      ➡️  Open Word, Excel, or another Office app\n"
printf "      ➡️  App menu → Preferences → Personal Settings → Privacy\n"
printf "      ➡️  Connected Experiences → Manage Connected Experiences\n"
printf "      ➡️  Clear 'Turn on experiences that analyze your content'\n"
printf "      ➡️  OK, then restart the Office apps\n"
printf "    ⚠️  This also disables features such as PowerPoint Designer,\n"
printf "        text predictions, suggested replies, and similar features.\n\n"

printf "5️⃣  ☢️  OPTIONAL NUCLEAR OPTION: disable most connected experiences\n"
printf "    In the same Privacy screen, clear 'All connected experiences'\n"
printf "    only if you also accept losing online collaboration, online\n"
printf "    content, templates, and other connected Office functionality.\n\n"

printf "6️⃣  🌐 CHECK WEB-BASED MICROSOFT 365\n"
printf "    Browser settings do not automatically disable Copilot at\n"
printf "    Microsoft365.com, Outlook on the web, or other web apps.\n"
printf "    Check each service’s Settings / Copilot control separately.\n\n"

printf "7️⃣  🏢 WORK OR SCHOOL ACCOUNT?\n"
printf "    If settings are unavailable, greyed out, or return after restart,\n"
printf "    they may be controlled by your organization’s Microsoft 365 admin.\n\n"

printf "🛡️  This script is an audit and reminder tool—not an enforcement policy.\n"
printf "🚀 Microsoft 365 Copilot audit complete.\n"
