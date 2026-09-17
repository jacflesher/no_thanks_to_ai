#!/bin/sh

SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
BACKUP_FILE="$SETTINGS_DIR/settings.json.bak.$(date +%Y%m%d%H%M%S)"
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
    printf "🛑  %s  <-- FAILED (may already be absent, that's OK)\n" "$DESC"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

printf "🔧 Step 1: Checking for 'code' CLI...\n\n"

if ! command -v code >/dev/null 2>&1; then
  printf "🛑  'code' command not found in PATH.\n"
  printf "    ➡️  Open VS Code, Cmd+Shift+P -> 'Shell Command: Install code command in PATH'\n"
  printf "    ➡️  Then re-run this script.\n"
  exit 1
fi
printf "✅  'code' CLI found\n\n"

printf "🔧 Step 2: Uninstalling Copilot extensions...\n\n"

run_check "Uninstall GitHub.copilot" \
  code --uninstall-extension GitHub.copilot

run_check "Uninstall GitHub.copilot-chat" \
  code --uninstall-extension GitHub.copilot-chat

run_check "Uninstall GitHub.copilot-labs" \
  code --uninstall-extension GitHub.copilot-labs

printf "\n🔧 Step 3: Backing up settings.json...\n\n"

if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "$BACKUP_FILE"
  if [ $? -eq 0 ]; then
    printf "✅  Backup created: %s\n" "$BACKUP_FILE"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "🛑  Backup failed! Aborting settings.json edits for safety.\n"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    SKIP_JSON_EDIT=1
  fi
else
  printf "ℹ️  No existing settings.json found — a new one will be created.\n"
  mkdir -p "$SETTINGS_DIR"
  echo '{}' > "$SETTINGS_FILE"
fi

printf "\n🔧 Step 4: Patching settings.json to disable AI features...\n\n"

if [ "$SKIP_JSON_EDIT" = "1" ]; then
  printf "🛑  Skipped settings.json edits due to failed backup.\n"
else
  if command -v jq >/dev/null 2>&1; then
    TMP_FILE=$(mktemp)
    jq '. + {
      "github.copilot.enable": {"*": false},
      "github.copilot.editor.enableAutoCompletions": false,
      "github.copilot.chat.enabled": false,
      "editor.inlineSuggest.enabled": false,
      "chat.commandCenter.enabled": false,
      "workbench.commandPalette.experimental.suggestCommands": false,
      "workbench.settings.enableNaturalLanguageSearch": false
    }' "$SETTINGS_FILE" > "$TMP_FILE" 2>/dev/null

    if [ $? -eq 0 ] && [ -s "$TMP_FILE" ]; then
      mv "$TMP_FILE" "$SETTINGS_FILE"
      printf "✅  settings.json patched with AI-disabling keys\n"
      PASS_COUNT=$((PASS_COUNT + 1))
    else
      printf "🛑  jq failed to parse settings.json (check for syntax errors/comments)\n"
      printf "    ➡️  Your original file is untouched, backup is at:\n"
      printf "        %s\n" "$BACKUP_FILE"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      rm -f "$TMP_FILE"
    fi
  else
    printf "🛑  'jq' not installed — skipping automatic settings.json edit.\n"
    printf "    ➡️  Install it with: brew install jq\n"
    printf "    ➡️  Or manually add these keys to settings.json:\n\n"
    printf '        "github.copilot.enable": { "*": false },\n'
    printf '        "github.copilot.editor.enableAutoCompletions": false,\n'
    printf '        "github.copilot.chat.enabled": false,\n'
    printf '        "editor.inlineSuggest.enabled": false,\n'
    printf '        "chat.commandCenter.enabled": false,\n'
    printf '        "workbench.commandPalette.experimental.suggestCommands": false,\n'
    printf '        "workbench.settings.enableNaturalLanguageSearch": false\n\n'
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
fi

printf "\n"
printf "📊 SUMMARY: %d succeeded ✅ | %d failed 🛑\n" "$PASS_COUNT" "$FAIL_COUNT"
printf "\n"
printf "🤖 If you want AI, ask your LLM — not your editor. 😎\n"
printf "\n"
printf "👉 NEXT STEPS — please don't skip these! 👇\n"
printf "\n"
printf "1️⃣  🔁 RESTART VS Code fully (Cmd+Q, not just close window).\n"
printf "\n"
printf "2️⃣  🧩 DOUBLE-CHECK Extensions panel (Cmd+Shift+X)\n"
printf "      ➡️  Confirm Copilot / Copilot Chat no longer appear installed\n"
printf "      ➡️  Search 'AI' in the marketplace search box to catch any\n"
printf "          other AI extensions you may have added (Codeium, Tabnine, etc.) 🔍\n"
printf "\n"
printf "3️⃣  ⚙️  VERIFY settings.json (Cmd+Shift+P -> 'Open User Settings (JSON)')\n"
printf "      ➡️  Confirm the AI-disabling keys are present and not overridden\n"
printf "          elsewhere (workspace .vscode/settings.json can override user settings!) ⚠️\n"
printf "\n"
printf "4️⃣  📁 CHECK WORKSPACE settings too\n"
printf "      ➡️  Any repo can ship its own .vscode/settings.json that\n"
printf "          re-enables Copilot for that folder only — check repos you open 🕵️\n"
printf "\n"
printf "5️⃣  🏢 IF this is a Ford-managed machine\n"
printf "      ➡️  IT-pushed extensions/policies (via MDM or Settings Sync)\n"
printf "          could silently reinstall Copilot — check with IT if it reappears\n"
printf "\n"
printf "🛡️  Backup saved at: %s\n" "$BACKUP_FILE"
printf "🚀 Happy AI-free coding (until YOU decide otherwise) 🚀\n"
