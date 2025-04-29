
# Project MIDAS: Specification Addendum - Label-Driven Workflow Automation

## 1. Objective

To enhance the MIDAS framework's orchestration capabilities by implementing an automated, event-driven workflow based on GitHub Issue label changes. This system will trigger agent handoffs (`new_task`) automatically when an issue's `status:` label is updated to indicate readiness for the next phase, improving robustness and reducing the reliance on agents explicitly calling `new_task` at the end of their process.

## 2. Core Mechanism: MIDAS Workflow Monitor

*   **Concept:** A monitoring component or process (the "MIDAS Workflow Monitor") will operate within the MIDAS/RooCode environment. Its primary function is to listen for specific GitHub Issue events (specifically, label changes) and trigger the appropriate next agent task.
*   **Implementation:** This monitor will likely leverage **GitHub Webhooks**.
    *   A webhook must be configured on the target GitHub repository, subscribed to the `issues` event, specifically listening for the `labeled` action.
    *   The webhook payload URL must point to an endpoint exposed by the MIDAS/RooCode environment capable of receiving and processing these events.
*   **Alternative (Fallback):** If webhook setup is impractical, a less efficient polling mechanism could be implemented where the Monitor periodically queries GitHub for issues whose `status:` labels have changed since the last check.

## 3. Label-to-Agent Mapping

A central configuration (e.g., within RooCode settings or a MIDAS config file) will define the mapping between specific `status:` labels and the target agent role that should be activated.

**Table: Status Label to Next Agent Mapping**

| Status Label (`status:*`)     | Next Responsible Agent Role (`midas/*`) | Trigger Condition                               |
| :---------------------------- | :-------------------------------------- | :---------------------------------------------- |
| `status:Backlog`              | `midas/product_owner`                   | Issue created or assigned this label initially. |
| `status:Needs-Refinement`     | `midas/product_owner`                   | Label applied (often manually or by Planner).   |
| `status:Ready-for-Dev`        | `midas/coder`                           | Label applied (by PO after refinement/Task creation, or Tester after bug report). |
| `status:Ready-for-Test`       | `midas/tester`                          | Label applied (by Coder after PR creation).     |
| `status:Ready-for-Merge`      | `midas/coder` or `midas/devops`\*       | Label applied (by Tester after verification).   |
| `status:Ready-for-Deploy`     | `midas/devops_engineer`                 | Label applied (after merge, potentially by Coder or CI/CD automation). |
| `status:Needs-Clarification`  | (Depends on Comment/Context)\*\*        | Label applied. Monitor might notify PO or relevant agent based on comment. |
| `status:Needs-Arch-Review`    | `midas/architect`                       | Label applied (by PO/Coder).                    |
| `status:Needs-UX-Review`      | `midas/ui_ux_designer`                  | Label applied (by PO/Coder).                    |
| `status:Needs-Security-Review`| `midas/security_specialist`             | Label applied (by Coder/Tester/Arch).           |
| `status:Needs-DevOps-Action`  | `midas/devops_engineer`                 | Label applied (by Coder/Tester).                |
| `status:Needs-Human-Input`    | (No agent triggered - Monitor alerts)   | Label applied. Monitor flags for human attention. |
| `status:Blocked`              | (No agent triggered - Monitor alerts)   | Label applied. Monitor might flag for PO attention. |

*\* **Merge Responsibility:** The agent responsible for merging (`Ready-for-Merge`) depends on the project's workflow (e.g., Coder merges their own PR after approval, or DevOps handles merges). This mapping should be configurable.*
*\*\* **Clarification Handling:** For `Needs-Clarification`, the Monitor's action might be less direct. It could potentially parse the issue comment to see *who* is needed and notify them, or simply alert the Product Owner to manage the clarification request.*

## 4. Automated Handoff Workflow

1.  **Label Change:** An agent (e.g., Coder) completes its primary task on a GitHub Issue (e.g., Task #T101) and updates its label using `github/update_issue` (e.g., from `status:Dev-In-Progress` to `status:Ready-for-Test`).
2.  **Webhook Event:** GitHub sends a webhook event payload (containing the issue details and the added label) to the MIDAS Workflow Monitor's endpoint.
3.  **Monitor Processing:**
    *   The Monitor receives and parses the webhook payload.
    *   It identifies the issue number and the *newly added* `status:` label.
    *   It consults the **Label-to-Agent Mapping** configuration.
4.  **Context Gathering:**
    *   The Monitor retrieves the essential context needed for the `new_task` payload. Minimally, this is the **GitHub Issue number**.
    *   If the trigger label implies context like a Pull Request (e.g., `status:Ready-for-Test`, `status:Ready-for-Merge`), the Monitor should attempt to extract the relevant PR number/URL (e.g., from the webhook event data if available, or by querying the issue's linked PRs via `github/get_issue`/`github/list_linked_pull_requests`).
    *   **Note:** Context like `determined_docs_strategy` and `determined_docs_path` is *not* expected to be passed by the Monitor. The receiving agent remains responsible for retrieving this from the issue context (e.g., designated comments) as per prior specifications.
5.  **Trigger `new_task`:**
    *   If the new label maps to a target agent role, the Monitor invokes RooCode's `new_task` capability.
    *   **Target:** The agent role determined from the mapping (e.g., `midas/tester`).
    *   **Payload:** Includes the retrieved context (e.g., `issue_number: 101`, `pr_url: "..."`).
6.  **Agent Activation:** RooCode activates the target agent (e.g., `midas-tester`) with the provided payload, initiating the next phase of the workflow.

## 5. Impact on Agent Definitions (`.roo/agents/*.agent.md`)

All existing agent definitions MUST be updated to reflect this label-driven workflow:

*   **Label Setting is Crucial:** Agents MUST reliably set the correct `status:` label on the relevant GitHub Issue as the final step of their primary responsibility using `github/update_issue`. This action becomes the primary trigger for the next step.
*   **Reduce Direct `new_task` Handoffs:** Agents should generally *remove* explicit calls to `new_task` that were previously used to hand off to the *next primary role* in the sequence (e.g., Coder calling `new_task` for Tester). The Monitor now handles these transitions based on the label change.
*   **Retain `new_task` for Specific Cases (If Any):** Direct `new_task` calls might be retained *only* for exceptional cases outside the standard label flow, if explicitly designed (e.g., an agent spawning a parallel sub-task that doesn't follow the main status progression). *Recommendation: Minimize these exceptions.*
*   **Asynchronous Requests Unchanged:** The mechanism for using `github/add_issue_comment` to request information or reviews *within* a phase (e.g., Coder -> Arch, PO -> UX) remains the same. The corresponding `status:Needs-*-Review` labels should be set by the *requester* to signal the need and potentially trigger the Monitor to activate the reviewing agent.
*   **Handling Activation:** Agents must be robust to being activated via `new_task` triggered by the Monitor, receiving the minimal context (Issue #, potentially PR #) in the payload, and then proceeding to fetch further necessary context from the issue itself (body, comments, linked items) using `github` tools.

## 6. Robustness Considerations

*   **Webhook Delivery:** Implement appropriate error handling and potentially logging for the webhook endpoint. Consider a fallback polling mechanism if webhook delivery proves unreliable.
*   **Monitor Errors:** If the Monitor fails to process an event or trigger `new_task`, it should log the error clearly. Retry logic could be implemented within the Monitor.
*   **State Consistency:** Ensure agents accurately set labels. If an agent fails *after* setting the label but *before* completing underlying actions (e.g., file writes), the system might trigger the next step prematurely. Agent logic should aim for atomicity where possible or include recovery steps.
*   **Manual Label Changes:** The webhook approach naturally supports manual label changes by users, triggering the corresponding agent workflow.

## 7. Implementation Notes

*   The MIDAS Workflow Monitor needs to be implemented as a service or background process within the RooCode environment capable of hosting a web endpoint for the webhook.
*   Secure handling of the webhook secret (if used) is essential.
*   The Label-to-Agent mapping needs to be easily configurable.
