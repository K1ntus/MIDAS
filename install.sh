{ \
echo "🚀 Starting MIDAS Framework Installation..."; \
echo "------------------------------------------"; \
\
# --- Dependency Checks --- \
echo "Checking dependencies..."; \
MISSING_DEPS=""; \
command -v curl >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS} curl"; \
command -v unzip >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS} unzip"; \
command -v git >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS} git"; \
USE_SVN=false; \
if command -v svn >/dev/null 2>&1; then USE_SVN=true; else echo "Optional 'svn' not found, will use ZIP download method."; fi; \
\
if [ -n "$MISSING_DEPS" ]; then echo "❌ Error: Missing essential dependencies:${MISSING_DEPS}. Please install them and retry." >&2; exit 1; fi; \
echo "✅ Basic dependencies found."; \
\
# --- Directory Setup --- \
echo "Creating .roo directories..."; \
mkdir -p .roo/agents .roo/templates || { echo "❌ Error: Failed to create .roo directories." >&2; exit 1; }; \
echo "⚠️ Note: Existing files in .roo/agents and .roo/templates might be overwritten."; \
\
# --- Download Agent/Template Files --- \
AGENT_URL_BASE="https://github.com/K1ntus/MIDAS/trunk/master/.roo"; \
AGENT_DIR=".roo/agents"; \
TEMPLATE_DIR=".roo/templates"; \
\
if $USE_SVN; then \
  echo "Attempting download using SVN..."; \
  svn export --force "${AGENT_URL_BASE}/agents" "$AGENT_DIR" && \
  svn export --force "${AGENT_URL_BASE}/templates" "$TEMPLATE_DIR" || \
  { echo "❌ Error: Failed to download files using SVN." >&2; exit 1; }; \
else \
  echo "Attempting download using ZIP archive (may be slower)..."; \
  TMP_DIR=$(mktemp -d); \
  ZIP_URL="https://github.com/K1ntus/MIDAS/archive/refs/heads/master.zip"; \
  ZIP_FILE="${TMP_DIR}/midas_master.zip"; \
  EXTRACT_DIR="${TMP_DIR}/midas_extracted"; \
  REPO_EXTRACTED_NAME="MIDAS-master"; \
  \
  echo "Downloading archive from ${ZIP_URL}..."; \
  curl -L "$ZIP_URL" -o "$ZIP_FILE" || { echo "❌ Error: Failed to download ZIP archive." >&2; rm -rf "$TMP_DIR"; exit 1; }; \
  \
  echo "Extracting archive..."; \
  unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR" || { echo "❌ Error: Failed to extract ZIP archive." >&2; rm -rf "$TMP_DIR"; exit 1; }; \
  \
  echo "Copying agent definitions..."; \
  cp -r "${EXTRACT_DIR}/${REPO_EXTRACTED_NAME}/.roo/agents/." "$AGENT_DIR/" || { echo "❌ Error: Failed to copy agent files." >&2; rm -rf "$TMP_DIR"; exit 1; }; \
  \
  echo "Copying template definitions..."; \
  cp -r "${EXTRACT_DIR}/${REPO_EXTRACTED_NAME}/.roo/templates/." "$TEMPLATE_DIR/" || { echo "❌ Error: Failed to copy template files." >&2; rm -rf "$TMP_DIR"; exit 1; }; \
  \
  echo "Cleaning up temporary files..."; \
  rm -rf "$TMP_DIR"; \
fi; \
\
echo "✅ Agent and Template files downloaded successfully."; \
echo "------------------------------------------"; \
\
# --- Post-Installation Instructions --- \
echo " I M P O R T A N T   N E X T   S T E P S "; \
echo "=========================================="; \
echo "1. 🚀 SETUP EXTERNAL MCP SERVERS:"; \
echo "   MIDAS requires external MCP servers for Filesystem, Git, and GitHub access."; \
echo "   - Find reference implementations (e.g., from Anthropic's MCP GitHub org)."; \
echo "   - Follow their instructions to build/run them locally (e.g., using Docker)."; \
echo "   - For GitHub MCP: You MUST generate a GitHub Personal Access Token (PAT)"; \
echo "     with appropriate scopes ('repo', 'project', 'read:org') and configure"; \
echo "     the GitHub MCP server to use it securely."; \
echo ""; \
echo "2. ⚙️ CONFIGURE RooCode:"; \
echo "   - Open your RooCode settings/configuration."; \
echo "   - Add connections to the running Filesystem, Git, and GitHub MCP servers."; \
echo "   - Ensure the connection details (ports, potentially auth for GitHub) are correct."; \
echo ""; \
echo "3. 🛠️ INSTALL AGENT COMMAND-LINE DEPENDENCIES:"; \
echo "   - Some MIDAS agents might use 'execute_command'. Ensure tools potentially"; \
echo "     needed are installed in your RooCode execution environment, such as:"; \
echo "     'node', 'python', 'docker', 'terraform', 'mmdc' (Mermaid CLI), security scanners, etc."; \
echo "   - Check agent definitions (.roo/agents/*.agent.md) for specific tool hints."; \
echo ""; \
echo "4. ✨ (Optional) REVIEW COMMON RULES:"; \
echo "   - If '.roo/agents/_common_rules.md' was downloaded, ensure your RooCode environment"; \
echo "     is configured to prepend its content to specific agent definitions before"; \
echo "     sending them to the LLM (This might require a RooCode update/feature)."; \
echo ""; \
echo "5. 🎉 START USING MIDAS:"; \
echo "   - You should now be able to initiate MIDAS workflows via RooCode commands."; \
echo "=========================================="; \
echo "✅ MIDAS setup script finished."; \
}