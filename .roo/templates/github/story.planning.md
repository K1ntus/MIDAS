<!--
MIDAS Story Issue Template
=========================
Instructions for Agent (e.g., MIDAS Product Owner):
- Replace placeholders like '[ ]' with specific information.
- Focus on delivering a specific piece of user value. Use the "As a..., I want..., so that..." format if appropriate for the Description.
- Define clear, testable Acceptance Criteria.
- Ensure the Parent Issue link points correctly to the Epic.
- Link to relevant designs, detailed specs, or specific documentation sections.
- Use Markdown formatting appropriately.
- The title MUST start with "[STORY] ".
-->

## 🎯 Description

[Describe the user story or feature increment. Clearly state the user need and the functionality to be built. Example: "As a registered user, I want to reset my password via email, so that I can regain access to my account if I forget my password."]

## 🤔 Motivation / Goal

[Explain the specific user benefit or value this Story provides. How does it contribute to the parent Epic's goal?]

## 📋 Scope / Requirements

[Detail the specific functional requirements for this Story. What must the system do?]

*   Requirement 1: [e.g., User clicks 'Forgot Password' link]
*   Requirement 2: [e.g., System prompts for email address]
*   Requirement 3: [e.g., System validates email format and existence]
*   Requirement 4: [e.g., System sends a password reset link to the email]
*   ... (Add as needed)

## ✅ Acceptance Criteria

[Define clear, specific, and testable conditions for Story completion. Use checklist or Given/When/Then format.]

*   [ ] Given a user provides a valid registered email, When they request a password reset, Then they should receive an email with a unique reset link within 5 minutes.
*   [ ] Given a user provides an invalid or unregistered email, When they request a password reset, Then they should see an informative error message.
*   [ ] Given a user clicks a valid reset link from the email, When they are taken to the reset page, Then they should be prompted to enter and confirm a new password.
*   [ ] Given a user successfully sets a new password, When they try to log in with the new password, Then authentication should succeed.
*   ... (Add as needed)

## 🔗 Context & Links

*   **Parent Issue:** [Link to the parent Epic using '#ISSUENUMBER'. This is mandatory.]
*   **Related Documentation:**
    *   [Link to specific section in spec doc (e.g., `docs/specs/feature-x.md#password-reset`)]
    *   [Link to UI/UX designs/mockups (e.g., Figma link, `docs/designs/password-reset.png`)]
    *   [Link to relevant ADR (e.g., `docs/architecture/adr-002.md`)]
*   **Related Issues:** [Link to dependent, blocking, or related Stories/Tasks using '#ISSUENUMBER'.]

## 💡 Technical Notes / Considerations (Optional)

[Include pointers for implementation, potential technical challenges, dependencies (e.g., requires specific API), questions for Architect/Coder.]

*   [Note 1: Consider rate limiting email sending]
*   [Note 2: Reset token security and expiry]

## 🤖 MIDAS Metadata

*   **Originating Agent:** `[Name of the MIDAS Agent creating this issue (e.g., MIDAS Product Owner)]`
*   **Source/Trigger:** [e.g., "Decomposition of Epic #123", "Refinement session based on Story #455 feedback"]