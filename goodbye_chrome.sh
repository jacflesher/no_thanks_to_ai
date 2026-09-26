#!/bin/sh

PLIST=~/Library/Preferences/com.google.Chrome.plist
PASS_COUNT=0
FAIL_COUNT=0

run_check() {
  DESC="$1"
  shift
  "$@"
  if [ $? -eq 0 ]; then
    printf "✅  %s\n" "$DESC"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "🛑  %s  <-- FAILED\n" "$DESC"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

printf "🔧 Applying Chrome AI policy settings...\n\n"

run_check "GenAiDefaultSettings -> 2 (master AI switch)" \
  defaults write "$PLIST" GenAiDefaultSettings -int 2

run_check "AIModeSettings -> 1 (AI Mode omnibox)" \
  defaults write "$PLIST" AIModeSettings -int 1

run_check "GenAILocalFoundationalModelSettings -> 1 (on-device model)" \
  defaults write "$PLIST" GenAILocalFoundationalModelSettings -int 1

run_check "BuiltInAIAPIsEnabled -> false" \
  defaults write "$PLIST" BuiltInAIAPIsEnabled -bool false

run_check "HelpMeWriteSettings -> 2" \
  defaults write "$PLIST" HelpMeWriteSettings -int 2

run_check "TabOrganizerSettings -> 2" \
  defaults write "$PLIST" TabOrganizerSettings -int 2

run_check "CreateThemesSettings -> 2" \
  defaults write "$PLIST" CreateThemesSettings -int 2

run_check "HistorySearchSettings -> 2" \
  defaults write "$PLIST" HistorySearchSettings -int 2

run_check "GoogleSearchSidePanelEnabled -> false" \
  defaults write "$PLIST" GoogleSearchSidePanelEnabled -bool false

printf "\n"
printf "📊 SUMMARY: %d succeeded ✅ | %d failed 🛑\n" "$PASS_COUNT" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  printf "⚠️  One or more settings failed to write. Re-run with 'sh -x %s' to debug.\n" "$0"
else
  printf "🎉 All policy keys written successfully!\n"
fi

printf "\n"
printf "🤖 If you want AI, ask your LLM — not your browser. 😎\n"
printf "\n"
printf "👉 NEXT STEPS — please don't skip these! 👇\n"
printf "\n"
printf "1️⃣  🔁 QUIT Chrome completely (Cmd+Q) and relaunch it so policies load.\n"
printf "\n"
printf "2️⃣  🕵️  VERIFY the policies actually applied:\n"
printf "      ➡️  Go to chrome://policy\n"
printf "      ➡️  Click 'Reload policies'\n"
printf "      ➡️  Confirm each setting shows status 'OK' ✔️ (not 'Not set' ❌)\n"
printf "\n"
printf "3️⃣  🔒 CHECK chrome://settings/ai\n"
printf "      ➡️  Toggles should now be greyed out / locked 🔐\n"
printf "      ➡️  If any AREN'T locked, that feature may have a new/renamed\n"
printf "          policy key — flag it for a fix! 🚩\n"
printf "\n"
printf "4️⃣  🚩 CHECK chrome://flags\n"
printf "      ➡️  Search 'ai' and 'gemini' 🔍\n"
printf "      ➡️  Manually disable any leftover experimental flags —\n"
printf "          policies do NOT override flags! ⚠️\n"
printf "\n"
printf "5️⃣  🧩 CHECK chrome://extensions\n"
printf "      ➡️  Remove/disable any AI writing assistants, summarizers,\n"
printf "          or sidebar AI tools 🗑️\n"
printf "\n"
printf "6️⃣  🌐 CHECK Google Search itself (not just Chrome!)\n"
printf "      ➡️  Visit labs.google.com on your Google account 🧪\n"
printf "      ➡️  Leave/disable 'AI Mode' or 'AI Overviews' if listed\n"
printf "      ➡️  If it's not in Labs anymore, it's baked into default\n"
printf "          Search results — an extension may be needed to hide it 🙈\n"
printf "\n"
printf "🛡️  Remember: policies beat toggles, but flags & extensions are separate!\n"
printf "🚀 Stay AI-free (until YOU decide otherwise) 🚀\n"
