
## Specification Set 2: Other Architectural Elements

These elements define the workflow, agent responsibilities, and configuration structures within the MIDAS framework running on RooCode.

**Element 1: `MIDAS Orchestrator Agent` Definition**

*   **Purpose:** To act as the central coordinator for the MIDAS workflow, monitoring GitHub for ready tasks and dispatching them to the appropriate specialized agents. Runs periodically or is triggered upon task completion signals (indirectly via state changes).
*   **Core Logic/Responsibilities (Instructions within `.roo/agents/midas-orchestrator.agent.md`):**
    1.  **Identify Ready Issues:**
        *   Load workflow configuration defining the sequence of `status:*` labels (e.g., `Ready-for-Dev` -> `Dev-In-Progress` -> `Ready-for-Test` -> ...).
        *   For each "ready" state (e.g., `status:Ready-for-Dev`), construct a query for the GitHub MCP tool (`github/search_issues` or `github/list_issues`).
        *   The query should filter for issues with the specific "ready" label (e.g., `label:status:Ready-for-Dev`) AND *without* the corresponding "in-progress" label (e.g., `NOT label:status:Dev-In-Progress`). It should also filter by `label:Type:*` (Task, Story, etc.) as defined by the workflow stage.
        *   Exclude issues known to be currently assigned/in-progress by MIDAS (requires internal state tracking, see below).
        *   Execute the query via `use_mcp_tool`.
    2.  **Process Ready Issues:**
        *   For each issue returned by the query:
            *   Extract the issue number.
            *   **Retrieve Context:**
                *   Use `github/get_issue` and `github/get_issue_comments` to fetch essential details.
                *   Specifically look for a designated comment or field (if using Projects v2 custom fields via MCP) containing the `determined_docs_strategy` and `determined_docs_path`. Report an error if missing.
                *   If the trigger label implies a PR (e.g., `Ready-for-Test`), use `github/list_linked_pull_requests` or parse comments to find the relevant PR URL/number.
            *   **Determine Target Agent:** Based on the "ready" label found (e.g., `status:Ready-for-Dev`), consult the configured label-to-agent mapping to find the target agent role (e.g., `midas/coder`).
            *   **Dispatch Task:** Use RooCode's `new_task` capability:
                *   Target: The determined agent role (e.g., `midas/coder`).
                *   Payload: A dictionary containing `issue_number`, `docs_strategy`, `docs_path`, and potentially `pr_url` or other necessary context.
            *   **Update Internal State:** Mark this issue number as "dispatched" or "in-progress" internally to avoid re-dispatching it on the next cycle.
    3.  **(Optional) Task Completion Handling:** The orchestrator *could* also query for issues that have moved from an "in-progress" state to a "completed" or the *next* "ready" state, and update its internal tracking accordingly. Alternatively, tracking relies solely on filtering out issues with "in-progress" labels during the initial query.
*   **Key Inputs:**
    *   Workflow configuration (label sequences, agent mapping).
    *   Results from GitHub MCP queries.
    *   Internal state of currently dispatched/in-progress tasks.
*   **Key Outputs/Side Effects:**
    *   `new_task` calls to specialized agents.
    *   Updates to its internal state tracking.
*   **Dependencies:**
    *   RooCode environment (`new_task` capability).
    *   GitHub MCP server (`search_issues`, `get_issue`, `get_issue_comments`, potentially `list_linked_pull_requests`).
    *   MIDAS Configuration.
*   **Key Considerations:**
    *   Efficiency and reliability of GitHub queries (API rate limits).
    *   Polling frequency vs. workflow latency.
    *   Robustness of internal state management (how to handle orchestrator restarts?).
    *   Handling errors during context retrieval or task dispatching.

**Element 2: GitHub MCP Orchestration Workflow**

*   **Purpose:** To define the standard sequence of events and state transitions managed via GitHub issue labels and the GitHub MCP, driving the workflow forward without an external webhook monitor.
*   **Core Logic/Sequence:**
    1.  **Initial State:** An issue exists in GitHub with a starting label (e.g., `status:Needs-Refinement`, `status:Ready-for-Dev`).
    2.  **Orchestrator Detection:** The `MIDAS Orchestrator Agent` polls GitHub via MCP, identifies the issue based on its "ready" status label, and confirms it's not already being processed.
    3.  **Agent Activation:** Orchestrator gathers context and triggers the appropriate agent (e.g., PO, Coder) via `new_task`.
    4.  **Agent Execution & Status Update (Start):** The activated agent *immediately* (as one of its first steps) updates the GitHub issue via MCP (`github/update_issue`) to add the corresponding "in-progress" label (e.g., `status:Refinement-In-Progress`, `status:Dev-In-Progress`) and removes the previous "ready" label. This prevents the Orchestrator from re-dispatching the same task.
    5.  **Agent Work:** The agent performs its core tasks (refining, coding, testing), potentially interacting further with GitHub MCP, FS MCP, Git MCP, or code-based components (`ContextOptimizer`, `RobustnessChecker`).
    6.  **Agent Completion & Status Update (End):** Upon successful completion of its primary responsibility, the agent's *final crucial action* is to update the GitHub issue via MCP (`github/update_issue`):
        *   Remove the "in-progress" label (e.g., `status:Dev-In-Progress`).
        *   Add the label indicating readiness for the *next* stage (e.g., `status:Ready-for-Test`).
    7.  **Cycle Repeats:** The Orchestrator, on its next polling cycle, detects the new "ready" label (`status:Ready-for-Test`) and activates the next agent (Tester), starting the process again.
*   **Inputs:** Agent actions triggering label changes via GitHub MCP.
*   **Outputs:** Sequential activation of agents based on detected label changes.
*   **Dependencies:** Reliable GitHub MCP `update_issue` and `search/list_issues` functionality; Agents consistently performing the status update steps (start and end); Orchestrator correctly interpreting labels.
*   **Key Considerations:** Potential latency introduced by polling intervals; ensuring the start/end label updates are atomic parts of agent execution; handling cases where an agent fails *after* adding the "in-progress" label but *before* completing.

**Element 3: Template Usage Mechanism**

*   **Purpose:** To ensure consistency and completeness in GitHub issue bodies by leveraging predefined templates.
*   **Implementation Method:** Modify agent definition files (`.roo/agents/*.agent.md`) for agents creating issues.
*   **Required Instructions within Agent Definitions:**
    *   **Identify Template:** "Determine the correct template path based on the issue type being created (e.g., for a Story, use `.roo/templates/github/story.planning.md`)."
    *   **Load Template:** "Use the `read_file` tool to load the content of the identified template file."
    *   **Populate Template:** "Analyze the loaded template content. Systematically replace all placeholders (e.g., `[Describe the user story...]`, `[Link to the parent Epic...]`, `[Define clear, specific...]`) with the specific information gathered or generated for this new issue. Ensure all required sections are filled."
    *   **Use in API Call:** "When calling the `github/create_issue` tool via `use_mcp_tool`, provide the fully populated template string as the value for the `body` parameter."
*   **Inputs (for the Agent):** Internal data needed to fill the template (e.g., Story description, AC, Epic link), path to the template file.
*   **Outputs (Side Effect):** GitHub issue created with a body formatted according to the template.
*   **Dependencies:** `read_file` tool accessible to the agent; `github/create_issue` tool (via MCP); Templates existing at predefined paths within the `.roo` structure.
*   **Key Considerations:** Robust handling if template files are missing or corrupted; ensuring agent's internal data maps correctly to template placeholders; managing template evolution.

**Element 4: Common Rules File Structure**

*   **Purpose:** To centralize standard rules and instructions applicable to most/all agents, reducing redundancy and improving maintainability.
*   **Implementation Method:** Requires enhancement to the RooCode agent loading mechanism.
    1.  **File Creation:** Create a file named `.roo/agents/_common_rules.md`. Populate it with sections like "Global Rules", "MANDATORY RULES", standard error handling procedures, tool usage guidelines, loop detection warnings, GitHub interaction conventions (labeling, commenting), etc.
    2.  **RooCode Preprocessing Logic:** Before RooCode feeds an agent definition (e.g., `midas-coder.agent.md`) to the LLM, it must perform these steps:
        *   Read the content of `.roo/agents/_common_rules.md`.
        *   Read the content of the specific agent file (e.g., `midas-coder.agent.md`).
        *   **Concatenate:** Prepend the entire content of `_common_rules.md` to the content of the specific agent file.
        *   Provide the resulting combined text to the LLM as its system prompt / instructions.
*   **Inputs:** `_common_rules.md` file, specific agent definition `.md` file.
*   **Outputs:** A single, combined instruction set provided to the LLM for agent execution.
*   **Dependencies:** Modification to RooCode's internal agent processing/loading logic.
*   **Key Considerations:** Ensuring the concatenation order makes logical sense for the LLM; managing potential conflicts if specific agents need to override a common rule (requires more complex merging logic than simple prepending); clearly documenting this mechanism for users defining custom agents.