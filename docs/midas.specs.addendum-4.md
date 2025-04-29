# MIDAS Specification Addendum 4: Atlassian Integration (Jira & Confluence)

## 1. Goal

This addendum details the necessary modifications to the MIDAS framework (Revision 3) to replace GitHub Issues with Jira for task tracking and GitHub repository file-based documentation with Confluence for knowledge management, leveraging the `mcp-atlassian` MCP server.

## 2. Scope & Impact Analysis

This change significantly impacts the core workflow, inter-agent communication, documentation strategy, and tooling used by most MIDAS agents.

**Key Changes:**

*   **Task Management:** All interactions involving GitHub Issues (creation, updates, comments, search, linking) must be replaced with equivalent Jira operations using `mcp-atlassian` tools (`jira_create_issue`, `jira_update_issue`, `jira_add_comment`, `jira_search`, `jira_create_issue_link`, `jira_get_issue`, `jira_transition_issue`, etc.).
*   **Documentation:** All interactions involving creating/updating Markdown documentation files within the repository (e.g., ADRs, specs, how-to guides) must be replaced with equivalent Confluence operations using `mcp-atlassian` tools (`confluence_create_page`, `confluence_update_page`, `confluence_get_page`, `confluence_search`). Linking between Jira issues and Confluence pages will be crucial.
*   **Workflow Labels:** GitHub `status:*` labels must be replaced with corresponding Jira issue statuses and potentially custom fields or labels within Jira. Workflow transitions will use `jira_transition_issue`.
*   **Context Retrieval:** The `MIDAS Orchestrator` and other agents need to fetch context (like `docs_strategy`, `docs_path`, parent links) from Jira issues (potentially custom fields) and related Confluence pages instead of GitHub issue comments/fields.
*   **Communication:** Asynchronous communication via GitHub comments (`github/add_issue_comment`) needs to be replaced with Jira comments (`jira_add_comment`). Mentions (`@midas-agent`) need adapting to Jira's user mentioning capabilities if possible, or rely on specific comment formatting/parsing.
*   **Templates:** GitHub issue templates (`.roo/templates/github/*.md`) become obsolete. New mechanisms or conventions for structuring Jira issue descriptions and Confluence page content (potentially using Confluence templates if accessible via API, or structured Markdown within agent prompts) are needed.
*   **Tooling:** Agents relying on `github` MCP tools for issue/doc management must switch to `mcp-atlassian` tools.

## 3. Affected Components & Required Changes

### 3.1 Agents (`.roo/agents/*.agent.md`)

*   **`_common_rules.md`:**
    *   Update MANDATORY RULES regarding GitHub interaction to reflect Jira/Confluence usage.
    *   Modify error handling and tool usage guidelines for `mcp-atlassian`.
*   **`midas-orchestrator.agent.md`:**
    *   **Identify Ready Issues:** Replace `github/search_issues` with `jira_search` using JQL queries based on Jira status, project keys, and potentially custom fields/labels instead of GitHub labels. Logic to exclude "in-progress" issues needs adapting to Jira statuses/fields.
    *   **Retrieve Context:** Replace `github/get_issue` and `github/get_issue_comments` with `jira_get_issue` (fetching relevant fields, including custom ones for docs strategy/path) and potentially `confluence_get_page` if documentation links are stored in Jira. Error handling for missing context needs updating.
    *   **Determine Target Agent:** Mapping logic remains similar but based on Jira status/fields.
    *   **Dispatch Task:** `new_task` payload needs to include Jira issue keys/IDs instead of GitHub numbers. Context passed (docs strategy/path) will originate from Jira/Confluence.
    *   **Internal State:** Tracking needs to use Jira issue keys/IDs.
*   **`midas-strategic-planner.agent.md`:**
    *   Replace `github/create_issue` (Epics) with `jira_create_issue` (Issue Type: Epic, potentially setting parent links).
    *   Replace `github/add_issue_comment` (for Architect interaction) with `jira_add_comment` on the relevant Jira Epic/planning issue.
    *   Replace `write_to_file` for spec docs/ADRs with `confluence_create_page` or `confluence_update_page`. Store Confluence page IDs/links in the corresponding Jira Epic (e.g., custom field or comment).
    *   Handoff to PO (`new_task`) must pass Jira Epic keys and Confluence page IDs/links.
    *   Update status using `jira_transition_issue` instead of `github/update_issue` labels.
*   **`midas-product-owner.agent.md`:**
    *   Replace `github/get_issue`, `create_issue`, `update_issue`, `create_issue_link`, `add_issue_comment` with `jira_get_issue`, `jira_create_issue` (Stories, Tasks, linking via parent field or `jira_create_issue_link`), `jira_update_issue`, `jira_add_comment` (for Architect/UI/UX interaction).
    *   Consume Jira Epic keys and Confluence context from `new_task` payload.
    *   Handoff to Performers (`new_task`) must pass Jira Task/Story keys and Confluence context.
    *   Update status using `jira_transition_issue`.
*   **`midas-architect.agent.md`:**
    *   React to Jira comment requests (`jira_add_comment`).
    *   Consume context from Jira issues (`jira_get_issue`) and Confluence pages (`confluence_get_page`).
    *   Create/update ADRs and documentation using `confluence_create_page`/`confluence_update_page`.
    *   Provide feedback via `jira_add_comment`.
    *   Remove reliance on FS tools for primary documentation; may still use FS/Git for code analysis.
*   **`midas-coder.agent.md`:**
    *   Consume Jira Task keys and Confluence context from `new_task`.
    *   Replace `github/get_issue`, `update_issue`, `add_issue_comment` with `jira_get_issue`, `jira_update_issue`, `jira_add_comment`.
    *   PR creation (`github/create_pr`) remains, but linking it to the Jira issue might require `jira_add_comment` or specific commit message conventions if automation exists.
    *   Replace optional How-To guide creation (`write_to_file`) with `confluence_create_page`.
    *   Handoff to Tester (`new_task`) must pass Jira issue key, PR URL, branch, and Confluence context.
    *   Update status using `jira_transition_issue`.
*   **`midas-tester.agent.md`:**
    *   Consume Jira issue key, PR URL, branch, Confluence context from `new_task`.
    *   Replace `github/get_issue`, `update_issue`, `add_issue_comment` with `jira_get_issue`, `jira_update_issue`, `jira_add_comment`.
    *   Bug reporting: Replace `github/create_issue` with `jira_create_issue` (Issue Type: Bug, linking to original Story/Task).
    *   Update status using `jira_transition_issue`.
*   **`midas-security-specialist.agent.md`:**
    *   Consume context from Jira/Confluence.
    *   Replace `github/create_issue` (Vulnerability) with `jira_create_issue` (Issue Type: Vulnerability/Bug, linking appropriately).
    *   Report findings via `jira_add_comment`.
*   **`midas-devops-engineer.agent.md`:**
    *   Consume context from Jira/Confluence.
    *   Replace `github/get_issue`, `update_issue`, `add_issue_comment` with `jira_get_issue`, `jira_update_issue`, `jira_add_comment`.
    *   Provide environment URLs via `jira_add_comment`.
*   **`midas-ui-ux-designer.agent.md`:**
    *   Consume context from Jira/Confluence.
    *   Replace `github/get_issue`, `add_issue_comment` with `jira_get_issue`, `jira_add_comment`.
    *   Provide feedback/specs via `jira_add_comment` or by linking to Confluence pages (`confluence_create_page`/`confluence_update_page`).

### 3.2 Templates (`.roo/templates/*`)

*   **`.roo/templates/github/*.md`:** These templates (e.g., `story.planning.md`, `task.planning.md`) become obsolete as Jira issue creation relies on parameters passed to `jira_create_issue`. Agents will need instructions on how to structure the `description` field for Jira issues, potentially incorporating key sections from the old templates into their prompts.
*   **`.roo/templates/docs/*.md`:** These templates (e.g., `architecture_decision_record.template.md`) can still be used conceptually. Agents creating Confluence pages (`confluence_create_page`) should be instructed to:
    1.  Load the relevant template content using `read_file`.
    2.  Populate the placeholders within the agent's logic.
    3.  Pass the populated Markdown content to the `content` parameter of `confluence_create_page`.

### 3.3 Configuration

*   **MCP Server Configuration:** RooCode needs to be configured to connect to the `mcp-atlassian` server, including URL and authentication details (API tokens or PATs) as described in the MCP documentation. The `github` MCP server might still be needed for code operations (PRs, commits) but not for issues/primary docs.
*   **Workflow Configuration:** The Orchestrator's configuration mapping labels to agents needs updating to map Jira statuses/fields to agents.
*   **Project/Space Keys:** Agents creating Jira issues or Confluence pages will need access to the target Jira Project Key(s) and Confluence Space Key(s). This should be part of the MIDAS configuration loaded by agents.

### 3.4 Setup Script (`install.sh` or similar)

*   Update instructions to include setup and configuration for the `mcp-atlassian` Docker container.
*   Remove instructions specific to GitHub Issue templates if they exist.
*   Emphasize the need for Jira Project Keys and Confluence Space Keys in the configuration.

## 4. Workflow Modifications

*   The core sequence (Planner -> PO -> Coder -> Tester -> DevOps) remains, but state transitions are managed by Jira statuses updated via `jira_transition_issue`.
*   The Orchestrator monitors Jira statuses instead of GitHub labels.
*   Documentation (specs, ADRs, guides) is created/updated in Confluence, and links are maintained within related Jira issues.
*   Asynchronous communication happens via Jira comments.

## 5. Open Questions & Considerations

*   **Jira Custom Fields:** How will context like `determined_docs_strategy` and `determined_docs_path` be stored in Jira? Custom fields are the most likely solution and need to be defined in Jira and accessed via the `jira_get_issue` tool (potentially requiring specific field IDs like `customfield_10010`).
*   **Confluence Templates:** Can Confluence's native templates be leveraged via the API? If not, the approach of agents loading local `.roo/templates/docs/*.md` files and passing Markdown to `confluence_create_page` is the fallback.
*   **Linking:** How robustly can Jira issues and Confluence pages be linked automatically by agents? Manual linking might be required initially. `jira_create_issue_link` might be usable if Confluence pages have a corresponding "issue" representation or if specific link types exist. Otherwise, storing URLs in comments/fields is necessary.
*   **Permissions:** Ensure the API tokens/PATs used have the necessary permissions in both Jira (create/edit issues, transition status, add comments across relevant projects) and Confluence (create/edit pages, add comments across relevant spaces).
*   **Error Handling:** Adapt error handling for `mcp-atlassian` specific errors (e.g., JQL syntax errors, Confluence permission issues).
*   **Migration:** This plan focuses on *new* workflows. Migrating existing GitHub issues and documentation is out of scope for this addendum.

## 6. Next Steps

1.  **User Validation:** Obtain approval for this addendum.
2.  **Configuration:** Set up the `mcp-atlassian` server and configure RooCode. Define necessary Jira custom fields and Confluence spaces.
3.  **Implementation:** Modify agent definitions, common rules, and setup scripts according to Section 3.
4.  **Testing:** Thoroughly test the modified workflow with Jira and Confluence.