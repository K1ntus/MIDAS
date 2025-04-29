
# Project MIDAS: Agentic AI Framework Specification (Atlassian Integrated - Revision 4)

## 1. Introduction & Goals

**Primary Goal:** To establish an agentic AI framework (MIDAS) running *within* the RooCode environment that enables efficient, reliable automation of software development tasks, optimizing for cost and robustness, while seamlessly integrating with **Jira** for hierarchical task management and **Confluence** for documentation and shared context memory.

**Key Emphasis:**
*   Facilitate effective **collaboration between specialized agents** using Jira issues/comments and a shared Confluence "Memory Bank".
*   Implement a primarily **synchronous handoff mechanism** for core workflow progression between agents.
*   Leverage **Jira statuses** for triggering review/side tasks via a focused Orchestrator.
*   Utilize **Jira custom fields** for state management (locking).
*   Rely on the `mcp-atlassian` MCP server for Jira/Confluence interactions and potentially `github` MCP for PR management only.

## 2. Guiding Principles

*   **Atlassian Native:** Treat Jira and Confluence as the central hubs for task tracking, status, communication, documentation, and shared agent memory.
*   **Synchronous Core Flow:** Prioritize direct `new_task` calls for handoffs between main sequential roles to reduce latency and reliance on polling.
*   **Robust Locking:** Implement atomic locking via Jira custom fields to prevent concurrent agent actions on the same issue.
*   **Centralized Context:** Utilize Jira issues and dedicated Confluence "Memory Bank" pages for persistent context sharing.
*   **Cost Efficiency:** Embed token optimization strategies within agent instructions (summarization hints, relevance checks).
*   **Reliability:** Define clear error handling protocols and mandate checks for `execute_command` success.
*   **Specialization & Collaboration:** Employ specialized agents communicating via Jira comments and the shared Memory Bank.
*   **RooCode Synergy:** Operate seamlessly within RooCode, leveraging its capabilities.

## 3. Core Architecture & Mechanisms

MIDAS operates within RooCode, using its LLM access, file system, terminal, and MCP client capabilities.

### 3.1 Handoff Model

*   **Synchronous (Primary):** For sequential roles (Planner -> PO, PO -> Coder, Coder -> Tester), the completing agent updates the Jira status, calls `new_task` for the next agent, and clears its lock.
*   **Orchestrator-Driven (Secondary):** The `MIDAS Orchestrator Agent` is responsible for:
    *   **Initial Dispatch:** Finding issues in initial "Ready" states (e.g., `Needs Refinement`) via Jira polling and dispatching the first agent.
    *   **Review/Side Task Dispatch:** Finding issues with specific "Needs Review/Action" statuses (e.g., `Needs Arch Review`, `Needs Security Review`) via Jira polling and dispatching the appropriate specialist agent.

### 3.2 Jira State Management (`MIDAS Agent Lock`)

*   **Mechanism:** A **required** Jira custom field: `MIDAS Agent Lock` (Text Field).
*   **Protocol:**
    1.  **Check:** Before acting on an issue (Orchestrator dispatching or Agent starting work), use `jira_get_issue` to check the `MIDAS Agent Lock` field.
    2.  **Abort if Locked:** If the field contains a value, the current process MUST STOP (log conflict/skip).
    3.  **Lock:** If clear, IMMEDIATELY call `jira_update_issue` to set the field value (e.g., `midas-agent-role:taskID:timestamp`).
    4.  **Abort if Lock Fails:** If the update fails (e.g., race condition), the current process MUST STOP.
    5.  **Unlock:** Upon successful completion OR encountering an error, the agent's final action (after status updates/comments) MUST be to clear the `MIDAS Agent Lock` field via `jira_update_issue`.

### 3.3 Context Passing (Jira + Confluence Memory Bank)

*   **Jira Issue:** Source for description, AC, comments, standard fields (status, parent), and **required Custom Fields**:
    *   `MIDAS Agent Lock` (Text)
    *   `MIDAS Memory Bank URL` (URL) - Link to the shared Confluence page.
*   **Confluence "Memory Bank" Page:** See Section 6 for detailed specification. A dedicated, structured Confluence page per workflow instance (e.g., Epic) for shared context, intermediate results, configuration details, etc. Agents read the *entire* page, parse relevant sections, and *atomically update* it (`confluence_update_page` with full modified content).

### 3.4 Error Handling Protocol

*   If any agent action fails (tool call, internal logic):
    1.  Log detailed error via `jira_add_comment` on the relevant Jira issue.
    2.  Transition the issue to a designated 'Failed' or 'Blocked' Jira status via `jira_transition_issue`.
    3.  Clear the `MIDAS Agent Lock` field via `jira_update_issue`.
    4.  Terminate the current agent task.

### 3.5 `execute_command` Brittleness Mitigation

*   **Common Rule:** Mandate checking return codes and capturing stdout/stderr for all `execute_command` calls. On failure, execute the Error Handling Protocol (Section 3.4).
*   **Documentation:** Setup instructions must list all potential CLI tools used by agents.

### 3.6 GitHub PR Management (Minimal)

*   The `github` MCP server is used *only* by the Coder agent for `create_pull_request` and potentially `merge_pull_request`.
*   Linking PRs to Jira issues relies solely on the Coder adding the PR URL in a `jira_add_comment`. No automated mapping or status sync based on PRs is implemented in this version.

## 4. Workflow Overview (Simplified)

1.  **(Optional) User -> Planner:** Creates Epic, Spec Doc, Memory Bank. -> *Sets Status: Needs Refinement*.
2.  **Orchestrator:** Detects `Needs Refinement`. -> *Dispatches PO*.
3.  **Product Owner:** Locks Epic. Decomposes -> Stories/Tasks. -> *Sets Task Status: Ready for Dev*. -> *Calls `new_task(Coder)`*. -> Unlocks Epic.
4.  **Coder:** Locks Task. Codes, commits, pushes. -> *(Optional) Creates How-To guide (Confluence)*. -> *Creates PR*. -> *Comments PR Link*. -> *Updates Memory Bank*. -> *Sets Status: Ready for Test*. -> *Calls `new_task(Tester)`*. -> Unlocks Task.
5.  **Tester:** Locks Task. Tests. -> *(Pass)* -> *Sets Status: Verified*. -> Unlocks Task. | *(Fail)* -> *Creates Bug issue*. -> *Sets Task Status: Open*. -> Unlocks Task.
6.  **(Manual/CI):** Code Merge. -> *Manual Status Update: Ready for Deploy*.
7.  **Orchestrator:** Detects `Ready for Deploy`. -> *Dispatches DevOps*.
8.  **DevOps Engineer:** Locks Issue. Deploys. -> *Updates Status: Deployed/Failed*. -> Unlocks Issue.
*   *Review Loops (Architect, UI/UX, Security):* Triggered by Orchestrator based on "Needs Review" statuses set by other agents. Reviewer locks the issue, performs review, comments, updates status, unlocks.

## 5. Component Specification

### 5.1 `_common_rules.md` (Atlassian Version - Summary)

*   Includes updated rules from previous response focusing on:
    *   Jira Status for primary handoffs (clarifying sync vs. Orchestrator triggers).
    *   Jira/Confluence for issue/doc management (avoiding duplicates).
    *   Tool usage (`mcp-atlassian`, `read_file`, `execute_command`).
    *   Jira `MIDAS Agent Lock` protocol adherence.
    *   Confluence Memory Bank interaction protocol.
    *   Standard Error Handling Protocol.
    *   `execute_command` safety checks.
    *   Context Retrieval (Jira fields/comments, Memory Bank page).
    *   Jira issue structure & Confluence template usage.
    *   Git workflow & PR commenting for linking.
    *   Clarification via `ask_followup_question` or `jira_add_comment`.

### 5.2 `MIDAS Orchestrator Agent` (Revised Role)

*   **Purpose:** Initial dispatch for workflows and dispatch for review/side-tasks based on Jira status polling. Handles stuck task detection (optional).
*   **Process:**
    1.  Load config (status->agent map for *initial/review* states, project keys, field IDs).
    2.  For each configured trigger status (`Needs Refinement`, `Ready for Dev` [if manual], `Needs Arch Review`, etc.):
        *   `jira_search` for issues in that status.
        *   For each found issue:
            *   **Pre-Dispatch Check & Lock:** Check `MIDAS Agent Lock` via `jira_get_issue`. Skip if locked. Attempt lock via `jira_update_issue`. Skip if lock fails.
            *   **Context Check:** `jira_get_issue` for required fields (e.g., `MIDAS Memory Bank URL`). If missing -> Error Comment, Set Status Failed, Clear Lock, Skip.
            *   **Determine Agent & Payload:** Find agent from config. Payload is minimal (`issue_key`).
            *   **Dispatch:** Call `new_task`. If fails -> Error Comment, Set Status Failed, Clear Lock.
            *   *(Orchestrator does NOT clear lock on successful dispatch).*
*   **Stuck Task Detection:** (Separate Agent/Process) Periodically query for issues locked + "In Progress" status > threshold -> Add warning comment / Escalate.

### 5.3 `MIDAS Strategic Planner`

*   **Process:**
    1.  `(Activation)` **Lock** triggering request/task issue.
    2.  Check existing Epics (`jira_search`).
    3.  Analyze spec (`read_file` if path). Clarify (`ask_followup_question`).
    4.  Confirm new Epics (`ask_followup_question`).
    5.  For each new Epic:
        *   `jira_create_issue` (Type: Epic, Status: 'To Do'). **Store Key.**
        *   Create Confluence "Memory Bank" page (Title: "MIDAS Memory Bank - [Epic Key]"). Get URL.
        *   `jira_update_issue` (Epic) to set `MIDAS Memory Bank URL` custom field.
        *   `confluence_update_page` (Memory Bank) to add initial context (`docs_strategy`, `docs_path`).
        *   Load spec template (`read_file`), populate, `confluence_create_page` (Spec Doc).
        *   `jira_add_comment` (Epic) linking to Spec Doc.
    6.  Analyze dependencies (`jira_create_issue_link`).
    7.  `jira_transition_issue` (Epic) to 'Needs Refinement'.
    8.  `(Completion)` **Unlock** triggering issue.

### 5.4 `MIDAS Product Owner`

*   **Process:**
    1.  `(Activation)` Receive Epic `issue_key`. **Lock** Epic (`jira_update_issue`).
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL). `confluence_get_page` (Memory Bank).
    3.  `jira_transition_issue` (Epic) to 'Refinement'.
    4.  Decompose Epic -> Stories (`jira_create_issue`, link parent, Status 'To Do'). Add AC.
    5.  Decompose Stories -> Tasks (`jira_create_issue`, link parent, Status 'To Do'). Detail steps.
    6.  **Quality Gate:** Review created items. Add summary comment to Epic.
    7.  **Dependency Analysis:** Review all Tasks for Epic, use `jira_create_issue_link` ('Blocks').
    8.  **Check Async Feedback:** Check comments on Epic/Stories. Handle blocking feedback (transition relevant item, comment). Acknowledge non-blocking.
    9.  `jira_transition_issue` (Epic) to 'Refinement Complete'.
    10. **Task Readiness & Handoff:** For each Task ready (check dependencies/feedback):
        *   `jira_transition_issue` (Task) to 'Ready for Dev'.
        *   **(Sync Handoff):** Call `new_task(agent=midas/coder, payload={issue_key: task_key})`.
    11. `(Completion)` **Unlock** Epic.

### 5.5 `MIDAS Architect`

*   **Process:**
    1.  `(Activation)` Receive `issue_key`. **Lock** issue.
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL, branch). `confluence_get_page` (Memory Bank).
    3.  `(Code Access)` If branch provided, `execute_command(git checkout...)`. Handle errors per protocol.
    4.  Check existing docs (`confluence_search`).
    5.  Analyze.
    6.  **Provide Feedback:**
        *   `jira_add_comment` using **standardized format** (e.g., "Arch Review: [Status]. Findings: [...]. Recommendations: [...]. See Confluence: [Link if created]").
        *   *Optionally:* Create/update Confluence Spec/ADR pages, link in comment.
    7.  `jira_transition_issue` (back to previous status or 'Arch Review Complete').
    8.  `(Completion)` **Unlock** issue.

### 5.6 `MIDAS Coder`

*   **Process:**
    1.  `(Activation)` Receive Task `issue_key`. **Lock** Task.
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL). `confluence_get_page` (Memory Bank).
    3.  `jira_transition_issue` (Task) to 'In Progress'.
    4.  `execute_command(git pull)`, `execute_command(git checkout -b feature/<ISSUE_KEY>)`. Handle errors.
    5.  Code/Debug. `execute_command` (build, lint, unit tests). **On failure:** Error Comment, `jira_create_issue` (Bug, link), Transition Task 'Open', Unlock Task, Exit.
    6.  `execute_command(git add .)`, `execute_command(git commit -m "feat(<ISSUE_KEY>): ...")`, `execute_command(git push origin feature/<ISSUE_KEY>)`. Handle errors.
    7.  Use `github` MCP: `create_pull_request`. Store PR URL.
    8.  `jira_add_comment` (Task) with PR URL.
    9.  `(Optional) How-To Guide:` `read_file` template, `confluence_create_page`, link in Task comment & Memory Bank.
    10. **Update Memory Bank:** `confluence_update_page` with implementation notes, config details.
    11. **Set Status & Handoff:**
        *   `jira_transition_issue` (Task) to 'Ready for Test'.
        *   **(Sync Handoff):** Call `new_task(agent=midas/tester, payload={issue_key: task_key, branch: 'feature/<ISSUE_KEY>', pr_url: '...'})`.
    12. `(Completion)` **Unlock** Task.
    13. `(Feedback Loop)` Activated again if Tester reopens Task. GOTO 1.

### 5.7 `MIDAS Tester`

*   **Process:**
    1.  `(Activation)` Receive `issue_key`, `branch`, `pr_url`. **Lock** Task.
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL, parent Story key). `confluence_get_page` (Memory Bank). `jira_get_issue` (Story for AC).
    3.  `jira_transition_issue` (Task) to 'Testing In Progress'.
    4.  Get env URL (from Memory Bank or request via `jira_add_comment` to DevOps, potentially requiring a wait/poll loop on comments or a status change like `Waiting for Env`).
    5.  `execute_command(git checkout BRANCH_NAME)`. Handle errors.
    6.  Execute tests (`execute_command`). Handle errors.
    7.  **AC Traceability:** Review Story AC. Confirm test coverage.
    8.  **Pass:**
        *   `jira_add_comment` ("Testing passed. AC verified.").
        *   `jira_transition_issue` (Task) to 'Verified'.
    9.  **Fail:**
        *   **Test Failure Diagnostics:** Capture logs/output.
        *   `jira_search` (existing bugs).
        *   `jira_create_issue` (Bug, link Task, include logs).
        *   `jira_add_comment` (Task, Fail + link Bug).
        *   `jira_transition_issue` (Task) to 'Open'.
    10. `(Completion/Failure)` **Unlock** Task.

### 5.8 `MIDAS Security Specialist`

*   **Process:**
    1.  `(Activation)` Receive `issue_key`. **Lock** issue.
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL, branch). `confluence_get_page` (Memory Bank).
    3.  `(Code Access)` `execute_command(git checkout...)`. Handle errors.
    4.  Run scans (`execute_command`). Review code. Handle tool errors.
    5.  `jira_search` (existing vulnerabilities).
    6.  `jira_create_issue` (Vulnerability/Bug, link parent, follow reporting standard).
    7.  `jira_add_comment` (Original issue, summary).
    8.  `jira_transition_issue` (back or 'Security Review Complete').
    9.  `(Completion)` **Unlock** issue.

### 5.9 `MIDAS DevOps Engineer`

*   **Process:**
    1.  `(Activation)` Receive `issue_key`. **Lock** issue.
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL, commit hash from Memory Bank/comment). `confluence_get_page` (Memory Bank).
    3.  Verify gates (`jira_search` for linked Test issue status='Verified'). Handle failures.
    4.  `execute_command` (IaC/deploy/rollback). Use `ask_followup_question` for critical. Handle script errors.
    5.  `jira_add_comment` (status/URL). `confluence_update_page` (Memory Bank with env details).
    6.  `jira_transition_issue` ('Deployed'/'Failed').
    7.  `(Completion/Failure)` **Unlock** issue.

### 5.10 `MIDAS UI/UX Designer`

*   **Process:**
    1.  `(Activation)` Receive `issue_key`. **Lock** issue.
    2.  Retrieve context (`jira_get_issue` incl. Memory Bank URL, preview URL/branch from comment/Memory Bank). `confluence_get_page` (Memory Bank).
    3.  **Provide Specs/Feedback:**
        *   **(Confluence Emphasis):** For specs, create/update Confluence page (`confluence_create_page`/`update`).
        *   `jira_add_comment` summarizing work, linking to Confluence/external tools. Update Memory Bank.
    4.  **Review Implementation:** (If triggered) `jira_add_comment` with feedback.
    5.  `jira_transition_issue` (back or 'UX Complete').
    6.  `(Completion)` **Unlock** issue.

## 6. Confluence Memory Bank Specification

*   **Purpose:** Shared, persistent context storage for a workflow instance (e.g., Epic), supplementing Jira.
*   **Creation:** By Planner agent, linked from root Jira issue via `MIDAS Memory Bank URL` custom field.
*   **Naming:** "MIDAS Memory Bank - [Root Issue Key]" (e.g., "MIDAS Memory Bank - PROJ-123").
*   **Structure:** Markdown format. Use H2 headings (`##`) for distinct context types or agent contributions. Include **timestamps** for entries. Examples:
    ```markdown
    # MIDAS Memory Bank - PROJ-123
    _Last Updated: YYYY-MM-DD HH:MM UTC by midas-coder_

    ## Core Context
    *   Root_Issue: PROJ-123
    *   Docs_Strategy: Hugo
    *   Docs_Path: content/docs/proj123
    *   Target_Repository: org/repo
    *   Target_Deployment_Env: staging

    ## Architect Decision (YYYY-MM-DD HH:MM)
    Approved use of Redis for caching user sessions. See ADR-007.

    ## Coder Notes - Task PROJ-456 (YYYY-MM-DD HH:MM)
    Encountered complexity in legacy auth module. Proposing refactor in Task PROJ-459. Current branch includes temporary workaround.

    ## DevOps Deployment - Staging (YYYY-MM-DD HH:MM)
    *   Commit_Hash: a1b2c3d4
    *   Environment_URL: https://staging.example.com/proj123
    *   Status: Success
    ```
*   **Agent Interaction:**
    1.  Retrieve URL from Jira issue's `MIDAS Memory Bank URL` field.
    2.  `confluence_get_page` to read the *entire current content*.
    3.  Parse content to find relevant info / check for existing sections.
    4.  Modify content in memory (append new section, update existing section). Add timestamp and agent role to new entries. Update "Last Updated" timestamp at top.
    5.  `confluence_update_page` with the *entire modified content*. Implement basic retry logic if update fails (re-fetch, re-apply changes, try update again once).

## 7. Configuration Requirements

*   **Jira:** Project Key(s), Issue Type names (Epic, Story, Task, Bug, etc.), Workflow Status names, Custom Field IDs (`MIDAS Agent Lock`, `MIDAS Memory Bank URL`).
*   **Confluence:** Space Key(s).
*   **`mcp-atlassian`:** Server URL, Authentication (API Token).
*   **`github` (Optional):** Server URL, Authentication (PAT for PRs).
*   **RooCode:** LLM configurations (API keys, endpoints), model selection defaults/overrides.
*   **MIDAS:** Paths to `.roo/templates/docs/`, potentially Orchestrator polling interval, stuck task threshold.

## 8. Template Usage (Confluence)

*   Agents creating standard Confluence docs (ADRs, Specs):
    1.  Identify template path (e.g., `.roo/templates/docs/architecture_decision_record.template.md`).
    2.  `read_file` to load template Markdown.
    3.  Populate placeholders in memory.
    4.  `confluence_create_page` with populated Markdown content.

## 9. Setup & Dependencies

*   **Prerequisites:** RooCode, `git`, `curl`, `docker` (likely for MCP servers).
*   **MCP Servers:** `mcp-atlassian` MUST be running and configured in RooCode. `github` MCP needed if using PR creation. Filesystem/Git MCPs might be needed by specific agent `execute_command` tasks.
*   **RooCode Config:** Configure LLMs, MCP connections (incl. Atlassian API token).
*   **Jira/Confluence Setup:** Create projects, spaces, custom fields, workflows as required.
*   **Agent Definitions:** Place updated `.roo/agents/*.agent.md` files.
*   **Templates:** Place `.roo/templates/docs/*.md` files.
*   **CLI Dependencies:** Install all tools potentially invoked via `execute_command` in the RooCode execution environment.

