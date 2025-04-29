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
command -v docker >/dev/null 2>&1 || MISSING_DEPS="${MISSING_DEPS} docker"; \
USE_SVN=false; \
if command -v svn >/dev/null 2>&1; then USE_SVN=true; else echo "Optional 'svn' not found, will use ZIP download method."; fi; \
\
if [ -n "$MISSING_DEPS" ]; then echo "❌ Error: Missing essential dependencies:${MISSING_DEPS}. Please install them and retry." >&2; exit 1; fi; \
echo "✅ Basic dependencies found."; \
\
# --- Directory Setup --- \
echo "Creating .roo directories..."; \
mkdir -p .roo/agents .roo/templates/docs || { echo "❌ Error: Failed to create .roo directories." >&2; exit 1; }; \
# Note: .roo/templates/github is intentionally not created as templates were removed.
echo "⚠️ Note: Existing files in .roo/agents and .roo/templates/docs might be overwritten."; \
\
# --- Download Agent/Template Files --- \
AGENT_URL_BASE="https://github.com/K1ntus/MIDAS/trunk/master/.roo"; \
AGENT_DIR=".roo/agents"; \
TEMPLATE_DIR_DOCS=".roo/templates/docs"; \
# Define specific files/dirs to download to avoid fetching the (now empty) github template dir
AGENT_FILES="_common_rules.md midas-architect.agent.md midas-coder.agent.md midas-devops-engineer.agent.md midas-orchestrator.agent.md midas-product-owner.agent.md midas-security-specialist.agent.md midas-strategic-planner.agent.md midas-tester.agent.md midas-ui-ux-designer.agent.md"
DOC_TEMPLATE_FILES="architecture_decision_record.template.md decision_log.template.md epic_overview.template.md how_to_guide.template.md product_roadmap.template.md project_goals.template.md sprint_planning_goals.template.md system_architecture_overview.template.md technical_design_document.template.md test_strategy.template.md"

if $USE_SVN; then \
  echo "Attempting download using SVN..."; \
  # Download agents individually
  for agent_file in $AGENT_FILES; do \
    svn export --force "${AGENT_URL_BASE}/agents/${agent_file}" "${AGENT_DIR}/${agent_file}" || \
    { echo "❌ Error: Failed to download agent file ${agent_file} using SVN." >&2; exit 1; }; \
  done && \
  # Download doc templates individually
  for template_file in $DOC_TEMPLATE_FILES; do \
    svn export --force "${AGENT_URL_BASE}/templates/docs/${template_file}" "${TEMPLATE_DIR_DOCS}/${template_file}" || \
    { echo "❌ Error: Failed to download doc template file ${template_file} using SVN." >&2; exit 1; }; \
  done || exit 1; \
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
  echo "Copying doc template definitions..."; \
  cp -r "${EXTRACT_DIR}/${REPO_EXTRACTED_NAME}/.roo/templates/docs/." "$TEMPLATE_DIR_DOCS/" || { echo "❌ Error: Failed to copy doc template files." >&2; rm -rf "$TMP_DIR"; exit 1; }; \
  \
  echo "Cleaning up temporary files..."; \
  rm -rf "$TMP_DIR"; \
fi; \
\
echo "✅ Agent and Doc Template files downloaded successfully."; \
echo "------------------------------------------"; \
\
# --- Post-Installation Instructions --- \
echo " I M P O R T A N T   N E X T   S T E P S "; \
echo "=========================================="; \
echo "1. 🚀 SETUP EXTERNAL MCP SERVERS:"; \
echo "   MIDAS requires external MCP servers for Filesystem, Git, GitHub (for code ops),"; \
echo "   and Atlassian (Jira/Confluence) access."; \
echo "   - Find reference implementations (e.g., from Anthropic's MCP GitHub org for FS/Git/GitHub)."; \
echo "   - For Atlassian, use the 'mcp-atlassian' server (ghcr.io/sooperset/mcp-atlassian:latest)."; \
echo "   - Follow their instructions to build/run them (e.g., using Docker)."; \
echo "   - For GitHub MCP: Generate a GitHub PAT with 'repo', 'project', 'read:org' scopes."; \
echo "   - For Atlassian MCP: Generate Atlassian API Tokens (Cloud) or Personal Access Tokens (Server/DC)"; \
echo "     with appropriate Jira & Confluence permissions."; \
echo "   - Configure the MCP servers securely with these tokens/credentials."; \
echo "     Example 'mcp-atlassian' Docker run command (replace placeholders):"; \
echo "     docker run -i --rm \\"; \
echo "       -e CONFLUENCE_URL=\"https://your-company.atlassian.net/wiki\" \\"; \
echo "       -e CONFLUENCE_USERNAME=\"your.email@company.com\" \\"; \
echo "       -e CONFLUENCE_API_TOKEN=\"your_confluence_api_token\" \\"; \
echo "       -e JIRA_URL=\"https://your-company.atlassian.net\" \\"; \
echo "       -e JIRA_USERNAME=\"your.email@company.com\" \\"; \
echo "       -e JIRA_API_TOKEN=\"your_jira_api_token\" \\"; \
echo "       ghcr.io/sooperset/mcp-atlassian:latest"; \
echo "     (See mcp-atlassian docs for Server/DC and other options)"; \
echo ""; \
echo "2. ⚙️ CONFIGURE RooCode:"; \
echo "   - Open your RooCode settings/configuration."; \
echo "   - Add connections to the running Filesystem, Git, GitHub, and Atlassian MCP servers."; \
echo "   - Ensure connection details (ports, URLs, potentially auth) are correct."; \
echo ""; \
echo "3. 🔑 CONFIGURE MIDAS (Jira/Confluence Details):"; \
echo "   - MIDAS agents need your Jira Project Key(s) and Confluence Space Key(s)."; \
echo "   - These need to be configured within RooCode settings or a dedicated MIDAS config file"; \
echo "     that the agents can access (mechanism depends on RooCode capabilities)."; \
echo ""; \
echo "4. 🛠️ INSTALL AGENT COMMAND-LINE DEPENDENCIES:"; \
echo "   - Some MIDAS agents might use 'execute_command'. Ensure tools potentially"; \
echo "     needed are installed in your RooCode execution environment, such as:"; \
echo "     'node', 'python', 'docker', 'terraform', 'mmdc' (Mermaid CLI), security scanners, etc."; \
echo "   - Check agent definitions (.roo/agents/*.agent.md) for specific tool hints."; \
echo ""; \
echo "5. ✨ (Optional) REVIEW COMMON RULES:"; \
echo "   - If '.roo/agents/_common_rules.md' was downloaded, ensure your RooCode environment"; \
echo "     is configured to prepend its content to specific agent definitions before"; \
echo "     sending them to the LLM (This might require a RooCode update/feature)."; \
echo ""; \
echo "6. 🎉 START USING MIDAS:"; \
echo "   - You should now be able to initiate MIDAS workflows via RooCode commands,"; \
echo "     leveraging Jira and Confluence!"; \
echo "=========================================="; \
echo "✅ MIDAS setup script finished."; \
}