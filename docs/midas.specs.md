# Project MIDAS: Final Plan (Revision 3)

## 1. Introduction & Goals

**Primary Goal:** To establish an agentic AI framework (MIDAS) running *within* the RooCode environment that enables efficient, reliable automation of software development tasks (including coding, architecture, debugging, UI/UX), optimizing for cost and robustness, while seamlessly integrating with **GitHub Issues** for task management and **file-based documentation within the repository**.

**Key Emphasis:** Facilitate effective **asynchronous communication and collaboration between specialized agents** using GitHub Issues, leveraging RooCode's capabilities and standard APIs.

## 2. Guiding Principles

*   **Cost Efficiency:** Prioritize minimizing LLM token consumption through intelligent context management embedded in agent instructions (summarization, relevance checks), strategic model selection, and optimized workflows.
*   **Robustness:** Build in mechanisms via agent instructions to detect and mitigate common failure modes (e.g., basic loop detection hints, hallucination grounding checks, error handling directives, HITL triggers), ensuring predictable operation relies on LLM compliance.
*   **Deep Integration:** Ensure first-class, seamless integration with the host RooCode environment and GitHub (Issues and repository files).
*   **Specialization & Collaboration:** Employ a diverse pool of specialized agents and enable effective inter-agent communication primarily via `new_task` for handoffs and GitHub Issue comments for asynchronous requests/responses.
*   **Customizability & Extensibility:** Design for flexibility, allowing projects to tailor agents, tools, prompts, and workflows.
*   **Standardization:** Leverage RooCode's built-in capabilities (MCP client, file access, LLM interaction) and standard APIs (GitHub REST/GraphQL via MCP).

## 3. Revised Core Architecture (Running within RooCode)

MIDAS runs within the RooCode environment, leveraging its existing infrastructure for UI, LLM access, file system operations, terminal execution, and MCP client functionality to interact with external MCP servers like `github`. Core MIDAS logic (Orchestration, Token Management, Robustness) is implemented via agent definitions (`.roo/agents/*.agent.md`) and RooCode's sequential task execution capabilities triggered by `new_task`.

```mermaid
graph TD
    subgraph RooCode Environment
        User --> RooCodeInterface[RooCode UI/Commands]
        RooCodeInterface --> MIDASCore[MIDAS Agents via new_task]
        MIDASCore --> RooCodeMCP[RooCode MCP Client]
        MIDASCore --> RooCodeFS[RooCode File System Access]
        MIDASCore --> RooCodeTerminal[RooCode Terminal Access]
        RooCodeMCP --> MCPServers[External MCP Servers (Filesystem, Git, github)]
    end

    subgraph MIDAS Components (Implemented via Agents/Rules)
        direction LR
        SpecIntake[Specification Intake Agent] -- new_task --> PlannerAgent[MIDAS Planner Agent]
        PlannerAgent -- GitHub Comment Request --> ArchitectAgent[MIDAS Architect Agent]
        PlannerAgent -- new_task w/ Epics --> ProductOwnerAgent[MIDAS Product Owner Agent]
        ProductOwnerAgent -- GitHub Comment Request --> ArchitectAgent
        ProductOwnerAgent -- GitHub Comment Request --> UIAgent[MIDAS UI/UX Designer Agent]
        ProductOwnerAgent -- new_task w/ Task --> CoderAgent[MIDAS Coder Agent]
        CoderAgent -- GitHub Comment Request --> ArchitectAgent
        CoderAgent -- GitHub Comment Request --> UIAgent
        CoderAgent -- new_task w/ PR --> TesterAgent[MIDAS Tester Agent]
        TesterAgent -- GitHub Comment Request --> DevOpsAgent[MIDAS DevOps Engineer Agent]

        %% Arrows indicate primary workflow handoffs or async requests %%
        PlannerAgent --> RooCodeMCP
        ProductOwnerAgent --> RooCodeMCP
        CoderAgent --> RooCodeMCP
        CoderAgent --> RooCodeFS
        CoderAgent --> RooCodeTerminal
        ArchitectAgent --> RooCodeMCP
        ArchitectAgent --> RooCodeFS
        TesterAgent --> RooCodeMCP
        TesterAgent --> RooCodeTerminal
        DevOpsAgent --> RooCodeMCP
        DevOpsAgent --> RooCodeTerminal
        SecurityAgent[MIDAS Security Specialist Agent] --> RooCodeMCP
        SecurityAgent --> RooCodeTerminal
    end

    ModelInteraction[LLM Interaction via RooCode] --> ExternalLLMs[LLMs]
    MIDASCore --> ModelInteraction

    style MIDASCore fill:#f9f,stroke:#333,stroke-width:2px
    style RooCodeEnvironment fill:#ccf,stroke:#66f,stroke-width:2px
```

## 4. Component Responsibilities

*   **RooCode Interface:** Handles user interaction, command parsing, and displaying MIDAS output within the RooCode environment.
*   **MIDAS Agents (via `new_task`):** The core logic implemented through specialized agent definitions (`.roo/agents/*.agent.md`). Each agent execution is a distinct task instance.
    *   **Agent Pool:** Defined roles include `MIDAS Strategic Planner`, `MIDAS Product Owner`, `MIDAS Architect`, `MIDAS Coder` (incl. Debugger), `MIDAS Tester`, `MIDAS Security Specialist`, `MIDAS DevOps Engineer`, `MIDAS UI/UX Designer`, and potentially `MIDAS Orchestrator Agent` (see Section 5.1). Each agent definition (`.roo/agents/*.agent.md`) contains specific instructions, tool usage protocols, collaboration points (via GitHub comments), and defined interfaces.
    *   **Orchestration:** Managed sequentially via `new_task` for role handoffs, potentially coordinated by a dedicated Orchestrator agent polling GitHub (see Section 5). Within a role's task, agents may trigger asynchronous requests to other agents via `github/add_issue_comment` on relevant issues. Dependency management relies on agents checking preconditions (e.g., waiting for a comment response) as instructed.
    *   **Token Management:** Strategies (Summarization, RAG hints, Budgeting instructions, Reactive Handoffs/Decomposition logic) are embedded within agent instructions, relying on LLM compliance and RooCode's underlying LLM interaction layer.
    *   **Robustness:** Mechanisms (Loop Detection hints, Hallucination Mitigation prompts, Error Handling instructions, HITL triggers) are defined within agent instructions, relying on agent compliance and RooCode's capabilities.
*   **RooCode Capabilities:** MIDAS leverages RooCode's native UI, LLM interaction, file system access, terminal execution, and MCP client to interact with external tools (e.g., `github` MCP server).

## 5. Orchestration, Workflow & Configuration

These elements define the workflow, agent responsibilities, and configuration structures within the MIDAS framework running on RooCode.

### 5.1 `MIDAS Orchestrator Agent` Definition

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

### 5.2 GitHub MCP Orchestration Workflow

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

### 5.3 Template Usage Mechanism

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

### 5.4 Common Rules File Structure

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

## 6. GitHub Integration Strategy (Previously Section 5)

*   **Hierarchy:** Specification -> GitHub Epic Issue -> GitHub Story Issue -> GitHub Task Issue.
*   **Tooling:** Agents utilize tools provided by the external `github` MCP server (configured in RooCode) for all GitHub Issue interactions (creation, updates, linking, searching, commenting) and RooCode FS/Git tools for file system operations.
*   **Documentation:**
    *   The `MIDAS Strategic Planner` collaborates *asynchronously* with the `MIDAS Architect` (via issue comments) to finalize specifications for Epics. The Architect creates Architectural Decision Records (ADRs).
    *   These documents are created as Markdown files within the repository (location determined by `determined_docs_path`, using templates from `.roo/templates/docs/` or strategy-specific locations) using RooCode FS tools (`write_to_file`, `read_file`).
    *   Documentation file paths are linked from their corresponding GitHub Issues where relevant (using `github/add_issue_comment`).
*   **Authentication:** Handled by RooCode's MCP client configuration for the `github` server.

## 7. Context Token Management Strategy (Detailed - Implemented via Agent Instructions) (Previously Section 6)

Managed jointly by agent instructions and RooCode's core LLM handling:

*   **Agent Instructions (Proactive & Reactive):**
    *   **Summarization:** Instruct agents to summarize lengthy prior context (issue comments, files) before including it in prompts if context size approaches limits.
    *   **Relevance Filtering (RAG Hint):** Instruct agents to prioritize retrieving and including only the most relevant snippets from large documents or codebases using search/analysis tools before calling the LLM.
    *   **Context Budgeting:** Instruct agents performing complex reasoning to be mindful of token limits and focus context on the most critical information.
    *   **Task Decomposition:** Instruct Planner/PO agents to break down inherently complex/large-context tasks into smaller, more manageable sub-tasks (Stories/Tasks).
    *   **Stateful Handoff Preparation:** Instruct agents, before completing their task (before `new_task` is called for the next role), to save essential state summaries or outputs as a comment on the primary GitHub issue being processed.
    *   **Error on Critical Loss:** Instruct agents to report an error if unavoidable truncation would remove essential context needed to proceed.
*   **RooCode Core (Assumed):** Handles basic truncation if limits are strictly exceeded after agent attempts optimization.

## 8. Inter-Agent Communication (Revised) (Previously Section 7)

Inter-agent communication relies on two primary mechanisms:

1.  **Role-to-Role Handoffs (`new_task`):**
    *   **Purpose:** Used *exclusively* when one distinct agent role has completed its phase of work and needs to trigger the next role in the sequence (e.g., Planner -> PO, PO -> Coder, Coder -> Tester). Can also be triggered by the Orchestrator agent.
    *   **Mechanism:** The sending agent's final step (or the Orchestrator's dispatch action) is to invoke RooCode's `new_task` capability, targeting the receiving agent's role.
    *   **Payload:** The `new_task` call MUST include necessary context in its payload, typically:
        *   The primary GitHub Issue number (Epic, Story, or Task) that is the focus of the handoff.
        *   The determined documentation strategy (`determined_docs_strategy`) and path (`determined_docs_path`).
        *   Any other critical identifiers (e.g., PR URL, branch name for Coder -> Tester).
        *   A status summary or pointer to a final state comment on the primary issue.

2.  **Asynchronous Requests/Responses (GitHub Issue Comments):**
    *   **Purpose:** Used for requests *within* a workflow phase or for information gathering where an immediate handoff isn't appropriate (e.g., PO requesting Architect review, Coder asking Architect for clarification, Tester requesting deploy URL from DevOps).
    *   **Mechanism:**
        *   The *requesting* agent uses the `github/add_issue_comment` tool on the relevant GitHub Issue (e.g., the Story issue for a task review).
        *   The comment MUST be clearly formatted, mentioning the target agent role (e.g., `@midas-architect Please review tasks for Story #123...`) and providing necessary details or questions.
        *   The requesting agent might then explicitly be instructed to *wait* for a response comment, periodically check, or proceed with other work if possible.
        *   The *responding* agent (when activated later, potentially via `new_task` focused on handling requests or as part of its standard workflow checking assigned issues) is instructed to:
            *   Check its assigned/relevant issues for request comments mentioning its role.
            *   Process the request.
            *   Provide the response using `github/add_issue_comment` on the same issue, often mentioning the original requester (e.g., `@midas-product-owner Review complete...`).

**Handoff Procedure Clarification:**

*   **Role-to-Role Handoffs (`new_task`):** MANDATORY for transferring primary responsibility between defined roles or for initial dispatch by the Orchestrator. Ensures clear task separation.
*   **Intra-Task Persona Shifts (`switch_mode`):** Tool should ONLY be used for temporary perspective changes *within the same task instance* (e.g., Coder briefly thinking like a Tester while writing tests), NOT for inter-agent communication or handoffs.

**Defined Agent Capabilities (Illustrative - reflects async communication):**

*(Note: "Exposes" now means the agent *can perform* this action, often triggered asynchronously. "Consumes" means it *needs information*, often retrieved asynchronously from issue comments or passed via `new_task` payload.)*

*   **`MIDAS Strategic Planner`**
    *   *Exposes Capability:* Initiating planning, Handling major changes.
    *   *Consumes:* Specification, Architect's feedback (via issue comments).
    *   *Outputs:* Epic Issues, Documentation files, Handoff to PO (`new_task` with Epic #s, docs context).
    *   *Tools:* `github` (create_issue, list_issues, add_issue_comment), RooCode FS (read_file, write_to_file).
*   **`MIDAS Product Owner`**
    *   *Exposes Capability:* Decomposing Epics, Refining Stories, Listing ready tasks, Handing off tasks.
    *   *Consumes:* Epic #s, docs context (from `new_task`), Architect feedback (via issue comments), UI/UX requirements (via issue comments).
    *   *Outputs:* Story Issues, Task Issues, Dependency links, Handoff to Performers (`new_task` with Task/Story #, docs context).
    *   *Tools:* `github` (get_issue, create_issue, update_issue, create_issue_link, add_issue_comment), RooCode FS (read_file).
*   **`MIDAS Architect`**
    *   *Exposes Capability:* Detailing Epic specs (in docs/comments), Reviewing tasks (via comments), Creating ADRs, Providing design overviews.
    *   *Consumes:* Docs context (from `new_task` payload or designated comment), Planner/PO requests (via issue comments), Infra constraints (via issue comments).
    *   *Outputs:* ADR files, Documentation updates, Review feedback (via comments).
    *   *Tools:* `github` (get_issue, add_issue_comment), RooCode FS/Git MCP/Terminal (`read_file`, `write_to_file`, `list_files`, `search_files`, `execute_command` for Mermaid/Git). *[Tooling Note: Requires Mermaid CLI or similar if generating diagrams locally via `execute_command`]*
*   **`MIDAS Coder`** (incl. Debugger)
    *   *Exposes Capability:* Implementing tasks, Debugging bugs, Reporting status, Requesting UI reviews (via PR comment).
    *   *Consumes:* Task #, docs context (from `new_task`), Design clarifications (via issue comments), UI specs (via issue comments), Bug reproduction steps (via issue comments).
    *   *Outputs:* Code changes (via PRs), How-To guides (optional), Status updates (via comments), Handoff to Tester (`new_task` with Issue #, branch, PR URL, docs context).
    *   *Tools:* `github` (get_issue, update_issue, add_issue_comment, create_pr, merge_pr [if authorized]), RooCode FS/Git MCP/Terminal (`read_file`, `write_file`, `apply_diff`, `insert_content`, `search_and_replace`, `execute_command` for build, lint, test, debug, git). *[Tooling Note: Requires project's build/test toolchain accessible via `execute_command`]*
*   **`MIDAS Tester`**
    *   *Exposes Capability:* Testing items, Reporting results (via comments/bugs), Verifying fixes, Providing reproduction steps (via comments).
    *   *Consumes:* Issue #, branch, PR URL, docs context (from `new_task`), Environment URL (via issue comments).
    *   *Outputs:* Test results/Bug reports (via comments, new issues), Updated issue status.
    *   *Tools:* `github` (get_issue, update_issue, add_issue_comment, create_issue [label: bug]), RooCode FS/Git MCP/Terminal (`read_file`, `list_files`, `execute_command` for test suites, git). *[Tooling Note: Requires test execution frameworks accessible via `execute_command`]*
*   **`MIDAS Security Specialist`**
    *   *Exposes Capability:* Performing scans, Reviewing code, Reporting findings.
    *   *Consumes:* Scope context (from `new_task`), Design overview (via issue comments), Pipeline config (via issue comments).
    *   *Outputs:* Findings summary, Vulnerability issues.
    *   *Tools:* `github` (get_issue, create_issue [label: vulnerability], add_issue_comment), RooCode FS/Git MCP/Terminal (`execute_command` for security scanners). *[Tooling Note: Requires security scanning tools accessible via `execute_command`]*
*   **`MIDAS DevOps Engineer`**
    *   *Exposes Capability:* Setting up pipelines, Deploying releases, Managing infra, Reporting status, Providing environment URLs (via comments).
    *   *Consumes:* Request context (from `new_task`), Infra requirements (via issue comments), Test results (via issue status/comments), Scan results (via issue status/comments).
    *   *Outputs:* Deployment status reports, Environment URLs (via comments).
    *   *Tools:* `github` (get_issue, update_issue, add_issue_comment), RooCode FS/Git MCP/Terminal (`execute_command` for IaC tools, CI/CD CLIs, deployment scripts). *[Tooling Note: Requires IaC tools (Terraform, Pulumi) and CI/CD CLIs accessible via `execute_command`]*
*   **`MIDAS UI/UX Designer`**
    *   *Exposes Capability:* Designing UI (providing descriptions/links), Providing design artifacts (via comments/links), Reviewing implementations (via comments), Providing requirements context (via comments), Providing specs (via comments).
    *   *Consumes:* Item context (from `new_task`), Story details (via issue comments), Review requests (via PR comments).
    *   *Outputs:* Design feedback/specs/links (via comments).
    *   *Tools:* `github` (get_issue, add_issue_comment), RooCode FS/Terminal (potentially for viewing running apps or accessing files).

## 9. Setup Automation Script (Previously Section 8)

*   **Purpose:** Simplify initial environment setup for MIDAS within RooCode.
*   **Tasks:**
    1.  Provide commands/instructions (e.g., Docker) to run required *external* MCP servers: Filesystem, Git, and `github`. Document clearly how to configure them.
    2.  Guide RooCode configuration for connecting to these external MCP servers, including secure setup of authentication (e.g., GitHub PAT) for the `github` server.
    3.  Place MIDAS agent definition files (`.roo/agents/*.agent.md`) into the `.roo/agents/` folder structure.
    4.  Place documentation template files (`.roo/templates/docs/*.md`, `.roo/templates/github/*.md`, etc.) into the appropriate `.roo/templates/` structure.
    5.  **Document required external tools:** List tools potentially needed by agents via `execute_command` (e.g., `git`, `node`, `python`, `pytest`, `eslint`, `terraform`, `docker`, `mermaid-cli`, specific security scanners) and note they must be installed in the RooCode execution environment.

## 10. Detailed Task Breakdown (Previously Section 9)

*   **Phase 1: Design & Foundation (Completed)**
    *   Task 1.1 - 1.5: Completed.
*   **Phase 2: Initial Agent Implementation & Workflow (Revised)**
    *   Task 2.1: Implement `MIDAS Strategic Planner` agent def, using GitHub comments for Architect interaction. Ensure handoff to PO includes docs context. - *Completed*
    *   Task 2.2: Implement `MIDAS Product Owner` agent def, using GitHub comments for Architect/UI/UX interaction. Expect docs context in input. - *Completed*
    *   Task 2.3: Implement `MIDAS Architect` agent def, reacting to comment requests, using docs context, writing ADRs/comments. Add tooling note. - *Completed*
    *   Task 2.4: Implement basic Token Management & Robustness *instructions* within agent defs. - *Completed*
    *   Task 2.5: Test initial workflow: Spec -> Planner -> (async Architect) -> Planner -> PO -> (async Arch/UX) -> PO -> GitHub Issues & Docs creation.
*   **Phase 3: Integration, Setup & Core Agents (Revised)**
    *   Task 3.1: Develop/Refine Setup Script per Section 9, including tool documentation.
    *   Task 3.2: Implement `MIDAS Coder` and `MIDAS Tester` agent defs, incorporating PR workflow, async communication, and tooling notes. Expect docs context. - *Completed*
    *   Task 3.3: Refine async communication protocols/comment formats based on testing.
    *   Task 3.4: Write initial user documentation (setup, config, basic planning workflow, async comms).
*   **Phase 4: Advanced Features & Refinement (Revised)**
    *   Task 4.1: Refine Token Management *instructions* in agents (e.g., more specific summarization/filtering prompts). - *Completed*
    *   Task 4.2: Refine Robustness *instructions* in agents (e.g., clearer loop checks, HITL conditions). - *Completed*
    *   Task 4.3: Refine Planner/PO decomposition logic/prompts.
    *   Task 4.4: Develop/Integrate `MIDAS Security Specialist` agent def, using async comms. Add tooling note. - *Completed*
    *   Task 4.5: Develop/Integrate `MIDAS DevOps Engineer` agent def, using async comms. Add tooling note. - *Completed*
    *   Task 4.6: Develop/Integrate `MIDAS UI/UX Designer` agent def, using async comms. Clarify artifact handling. - *Completed*
    *   Task 4.7: Implement configuration (e.g., via RooCode settings or dedicated config files) for prompts, models, GitHub repo details, doc strategy/path.
    *   Task 4.8: Implement `MIDAS Orchestrator Agent` definition (Section 5.1).
    *   Task 4.9: Implement `Common Rules File Structure` enhancement in RooCode (Section 5.4).
    *   Task 4.10: Update relevant agent definitions to use `Template Usage Mechanism` (Section 5.3).

## 11. Agent Communication & MCP Interaction Diagram (Revised Conceptual Flow) (Previously Section 10)

```mermaid
sequenceDiagram
    participant User
    participant RooCodeUI as RooCode UI/Commands
    participant RooCodeCore as RooCode Core/Rules Engine
    participant Orchestrator as MIDAS Orchestrator Agent
    participant Planner as MIDAS Planner Agent (Task 1)
    participant Architect as MIDAS Architect Agent (Task 2)
    participant ProductOwner as MIDAS Product Owner Agent (Task 3)
    participant Coder as MIDAS Coder Agent (Task 4)
    participant Tester as MIDAS Tester Agent (Task 5)
    participant RooCodeMCP as RooCode MCP Client
    participant FilesystemMCP as Filesystem MCP Server
    participant GitMCP as Git MCP Server
    participant GithubMCP as GitHub MCP Server

    User->>RooCodeUI: Initiate Task ("Plan Project Alpha")
    RooCodeUI->>RooCodeCore: new_task(agent=planner, spec=...)

    %% Planner Task %%
    activate Planner
    Note over Planner: Analyze Spec, Determine Docs Strategy
    Planner->>RooCodeCore: github/add_issue_comment (on planning issue #P1, request=@midas-architect detail epics X,Y)
    Planner->>RooCodeCore: github/create_issue (Create Epic Issues #E1, #E2, label:status:Needs-Refinement)
    Planner->>RooCodeCore: write_to_file (Create initial spec doc, link in #E1, #E2)
    Note over Planner: Planner completes, sets status:Ready-for-PO on #E1, #E2
    Planner->>RooCodeCore: github/update_issue (#E1, labels=["status:Ready-for-PO"])
    Planner->>RooCodeCore: github/update_issue (#E2, labels=["status:Ready-for-PO"])
    deactivate Planner

    %% Orchestrator Cycle %%
    activate Orchestrator
    Note over Orchestrator: Polls GitHub
    Orchestrator->>RooCodeCore: github/search_issues (query: label:status:Ready-for-PO NOT label:status:PO-In-Progress)
    Note right of Orchestrator: Finds #E1, #E2
    Orchestrator->>RooCodeCore: github/get_issue (#E1)
    Orchestrator->>RooCodeCore: github/get_issue_comments (#E1)
    Note over Orchestrator: Extracts docs context
    Orchestrator->>RooCodeCore: new_task(agent=product_owner, payload={epic: #E1, docs_strategy:'Hugo', docs_path:'content/docs'})
    Note over Orchestrator: Marks #E1 as dispatched internally
    Orchestrator->>RooCodeCore: new_task(agent=product_owner, payload={epic: #E2, docs_strategy:'Hugo', docs_path:'content/docs'})
    Note over Orchestrator: Marks #E2 as dispatched internally
    deactivate Orchestrator

    %% PO Task (Example for #E1) %%
    RooCodeCore->>ProductOwner: Activate(payload={epic: #E1, ...})
    activate ProductOwner
    ProductOwner->>RooCodeCore: github/update_issue (#E1, add label:status:PO-In-Progress, remove label:status:Ready-for-PO)
    ProductOwner->>RooCodeCore: github/get_issue (#E1)
    Note over ProductOwner: Read Epic, Check #P1 for Architect's comment (Assume available or wait)
    Note over ProductOwner: Decompose #E1 -> Story #S10, Task #T101, #T102
    ProductOwner->>RooCodeCore: github/create_issue (Create Story #S10, link to #E1)
    ProductOwner->>RooCodeCore: github/add_issue_comment (on #S10, request=@midas-architect review tasks #T101, #T102)
    ProductOwner->>RooCodeCore: github/create_issue (Create Task #T101, link to #S10, label:status:Ready-for-Dev)
    ProductOwner->>RooCodeCore: github/create_issue (Create Task #T102, link to #S10, label:status:Ready-for-Dev)
    ProductOwner->>RooCodeCore: github/update_issue (#E1, remove label:status:PO-In-Progress, add label:status:PO-Complete)
    deactivate ProductOwner

    %% Orchestrator Cycle %%
    activate Orchestrator
    Note over Orchestrator: Polls GitHub
    Orchestrator->>RooCodeCore: github/search_issues (query: label:status:Ready-for-Dev NOT label:status:Dev-In-Progress)
    Note right of Orchestrator: Finds #T101, #T102
    Orchestrator->>RooCodeCore: github/get_issue (#T101)
    Orchestrator->>RooCodeCore: github/get_issue_comments (#T101)
    Note over Orchestrator: Extracts docs context
    Orchestrator->>RooCodeCore: new_task(agent=coder, payload={task: #T101, docs_strategy:'Hugo', docs_path:'content/docs'})
    Note over Orchestrator: Marks #T101 as dispatched
    Orchestrator->>RooCodeCore: new_task(agent=coder, payload={task: #T102, docs_strategy:'Hugo', docs_path:'content/docs'})
    Note over Orchestrator: Marks #T102 as dispatched
    deactivate Orchestrator

    %% Coder Task (Example for #T101) %%
    RooCodeCore->>Coder: Activate(payload={task: #T101, ...})
    activate Coder
    Coder->>RooCodeCore: github/update_issue (#T101, add label:status:Dev-In-Progress, remove label:status:Ready-for-Dev)
    Coder->>RooCodeCore: github/get_issue (#T101)
    Note over Coder: Read Task, Check #S10 for Architect review comment (Assume available or wait)
    Coder->>RooCodeCore: read_file(...)
    Coder->>RooCodeCore: execute_command(git checkout -b feature/T101)
    Note over Coder: Write code... (LLM interactions omitted)
    Coder->>RooCodeCore: write_file(...)
    Coder->>RooCodeCore: execute_command(git add .)
    Coder->>RooCodeCore: execute_command(git commit -m "feat: Implement task T101")
    Coder->>RooCodeCore: execute_command(git push origin feature/T101)
    Coder->>RooCodeCore: github/create_pr(title="Implement T101", branch="feature/T101", base="main")
    Note right of Coder: Gets PR URL #PR5
    Coder->>RooCodeCore: github/add_issue_comment (on #T101, msg="PR #PR5 ready @midas-tester")
    Coder->>RooCodeCore: github/update_issue (#T101, remove label:status:Dev-In-Progress, add label:status:Ready-for-Test)
    deactivate Coder

    %% Orchestrator Cycle %%
    activate Orchestrator
    Note over Orchestrator: Polls GitHub
    Orchestrator->>RooCodeCore: github/search_issues (query: label:status:Ready-for-Test NOT label:status:Test-In-Progress)
    Note right of Orchestrator: Finds #T101
    Orchestrator->>RooCodeCore: github/get_issue (#T101)
    Orchestrator->>RooCodeCore: github/get_issue_comments (#T101)
    Note over Orchestrator: Extracts PR URL, branch, docs context
    Orchestrator->>RooCodeCore: new_task(agent=tester, payload={issue: #T101, pr_url: #PR5, branch:'feature/T101', docs_strategy:'Hugo', ...})
    Note over Orchestrator: Marks #T101 as dispatched
    deactivate Orchestrator

    %% Tester Task %%
    RooCodeCore->>Tester: Activate(payload={issue: #T101, ...})
    activate Tester
    Tester->>RooCodeCore: github/update_issue (#T101, add label:status:Test-In-Progress, remove label:status:Ready-for-Test)
    Tester->>RooCodeCore: github/add_issue_comment (on #PR5, request=@midas-devops-engineer provide staging URL)
    Note over Tester: Wait for/retrieve DevOps comment with URL
    Tester->>RooCodeCore: execute_command(git checkout feature/T101)
    Tester->>RooCodeCore: execute_command(run_tests --env staging_url)
    Note over Tester: Tests pass
    Tester->>RooCodeCore: github/add_issue_comment (on #PR5, msg="Tests passed. Approved.")
    Tester->>RooCodeCore: github/update_issue (#T101, remove label:status:Test-In-Progress, add label:status:Verified)
    Note over Tester: Merge might be manual or trigger DevOps/Coder task via Orchestrator detecting 'Verified'
    deactivate Tester

    RooCodeCore-->>RooCodeUI: Report Progress/Completion
    RooCodeUI-->>User: Display Status/Results
