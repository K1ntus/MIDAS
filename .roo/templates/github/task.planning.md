<!--
MIDAS Task Issue Template
========================
Instructions for Agent (e.g., MIDAS Product Owner, Coder):
- Replace placeholders like '[ ]' with specific information.
- Focus on a single, concrete technical step required to complete a Story.
- Be specific about *what* needs to be done technically.
- Define technical acceptance criteria (e.g., tests pass, API endpoint works).
- Ensure the Parent Issue link points correctly to the Story.
- Link to specific code locations, API docs, or technical designs.
- Use Markdown formatting appropriately (especially for code snippets).
- The title MUST start with "[TASK] ".
-->

## 🎯 Description

[Describe the specific technical task to be performed. Be explicit and action-oriented.]
*   Example 1: "Implement the `/api/users/password-reset` POST endpoint."
*   Example 2: "Create database migration script to add `password_reset_token` and `token_expiry` columns to the `users` table."
*   Example 3: "Write unit tests for the PasswordResetService."

## 🤔 Motivation / Goal

[Briefly state why this task is needed – usually to support the parent Story.]
*   Example: "Required component for implementing password reset functionality (Story #567)."

## 🛠️ Implementation Details / Requirements

[Provide specific technical details, steps, or requirements for completing the task.]

*   Requirement 1: [e.g., Endpoint should accept `email` in JSON body.]
*   Requirement 2: [e.g., Generate a cryptographically secure unique token.]
*   Requirement 3: [e.g., Store token hash and expiry (24 hours) in the database.]
*   Requirement 4: [e.g., Call the EmailService to send the reset link.]
*   Requirement 5: [e.g., Return `200 OK` on success, appropriate errors (400, 404, 500) otherwise.]
*   Code Location: [e.g., `src/api/auth/reset_controller.py`]
*   ... (Add as needed)

## ✅ Acceptance Criteria

[Define technical conditions for task completion. Often involves tests or specific outputs.]

*   [ ] Unit tests covering success and error cases for the new service/endpoint pass.
*   [ ] Integration test confirms the endpoint correctly interacts with the database and email service (mock).
*   [ ] Code adheres to project coding standards and passes linting.
*   [ ] Endpoint is documented (e.g., OpenAPI spec updated).
*   [ ] Manual test: Sending a request with a valid email results in a `200 OK` and a (mocked) email being triggered.
*   ... (Add as needed)

## 🔗 Context & Links

*   **Parent Issue:** [Link to the parent Story using '#ISSUENUMBER'. This is mandatory.]
*   **Related Documentation:**
    *   [Link to specific API documentation]
    *   [Link to relevant section in technical design doc]
    *   [Link to parent Story (#ISSUENUMBER)]
*   **Related Issues:** [Link to dependent Tasks (e.g., database migration task) or related Tasks using '#ISSUENUMBER'.]

## 💡 Technical Notes / Considerations (Optional)

[Include implementation hints, libraries to use, potential edge cases, performance considerations.]

*   [Note 1: Use `secure-random-library` for token generation.]
*   [Note 2: Ensure database transaction wraps token storage and email trigger.]

## 🤖 MIDAS Metadata

*   **Originating Agent:** `[Name of the MIDAS Agent creating this issue (e.g., MIDAS Product Owner, MIDAS Coder)]`
*   **Source/Trigger:** [e.g., "Decomposition of Story #567", "Task identified during implementation of Task #890"]