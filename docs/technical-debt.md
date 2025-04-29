# Technical Debt

## [Unversioned] - 2025-04-29

*   **Missing Implementation: `MIDAS Orchestrator Agent`**
    *   **Description:** The agent definition for the `MIDAS Orchestrator Agent` (specified in `docs/midas.specs.md`, Section 5.1) has not been created or implemented in `.roo/agents/midas-orchestrator.agent.md`. The core logic for identifying ready issues, retrieving context, determining target agents, dispatching tasks, and managing internal state needs to be translated into agent instructions.
    *   **Version:** Unversioned
    *   **Date Added:** 2025-04-29

*   **Missing Implementation: `Common Rules File Structure` (RooCode Enhancement)**
    *   **Description:** The `Common Rules File Structure` mechanism (specified in `docs/midas.specs.md`, Section 5.4) requires modifications to the RooCode agent loading/preprocessing logic to prepend common rules from `.roo/agents/_common_rules.md` to specific agent definitions. This is an enhancement needed in the RooCode platform itself.
    *   **Version:** Unversioned
    *   **Date Added:** 2025-04-29

*   **Missing Implementation: `Template Usage Mechanism` (Agent Updates)**
    *   **Description:** Agents responsible for creating GitHub issues (e.g., Planner, PO) need to be updated to incorporate the `Template Usage Mechanism` instructions (specified in `docs/midas.specs.md`, Section 5.3), including identifying, loading, and populating templates before calling `github/create_issue`.
    *   **Version:** Unversioned
    *   **Date Added:** 2025-04-29

*   **Undefined Implementation: Orchestrator State Management**
    *   **Description:** The specification (`docs/midas.specs.md`, Section 5.1) highlights the need for robust internal state management for the `MIDAS Orchestrator Agent` to track dispatched tasks and handle restarts, but the specific mechanism (e.g., file-based, database) is not defined.
    *   **Version:** Unversioned
    *   **Date Added:** 2025-04-29

*   **Undefined Implementation: Workflow Configuration**
    *   **Description:** The `MIDAS Orchestrator Agent` requires workflow configuration (label sequences, agent mapping) as input (`docs/midas.specs.md`, Section 5.1), but the format and location of this configuration file/data are not specified.
    *   **Version:** Unversioned
    *   **Date Added:** 2025-04-29

*   **Missing Implementation: Agent Workflow Label Updates**
    *   **Description:** Agents participating in the GitHub MCP Orchestration Workflow (`docs/midas.specs.md`, Section 5.2) need their definitions explicitly updated to include the mandatory first step (add "in-progress" label, remove "ready" label) and final step (remove "in-progress" label, add next "ready" label) using `github/update_issue`.
    *   **Version:** Unversioned
    *   **Date Added:** 2025-04-29