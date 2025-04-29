
<!--
MIDAS Pull Request Body Template
================================
Instructions for Agent (e.g., MIDAS Coder):
- This template guides the construction of the Pull Request description body.
- Replace placeholders like '[ ]' with specific information about the changes.
- Ensure issue links use keywords like 'Closes', 'Fixes', 'Resolves' to automatically link/close issues upon merging.
- Be clear about the changes made and how they were tested.
- Use Markdown formatting appropriately.
-->

## 📝 Description

[Provide a clear and concise description of the changes introduced by this Pull Request. Explain the 'what' and 'why' of the change.]

## 🔗 Related Issues

*   **Closes:** #[Issue Number for the primary Task/Story/Bug being addressed]
*   **Related:** #[Optional: Link to any other related issues, like parent Story/Epic, using '#ISSUENUMBER']

## ✅ Changes Made

[Summarize the key changes implemented in this PR. Use bullet points.]

*   [Implemented feature X according to specifications.]
*   [Refactored the Y module for improved readability.]
*   [Added unit tests for the Z service.]
*   [Updated database schema with migration script.]

## 🧪 Testing Done

[Describe how these changes were tested.]

*   **Unit Tests:** [Added/Updated X unit tests. All pass.] (`execute_command` output snippet optional)
*   **Integration Tests:** [Added/Updated Y integration tests. All pass.]
*   **Manual Testing Steps:**
    1. [Performed action A, verified expected outcome B.]
    2. [Tested edge case C, confirmed correct handling.]
*   **Local Environment:** [Tested locally on [OS/Setup details], build successful.]

## 📸 Screenshots / GIF (If Applicable)

[If changes affect the UI, include screenshots or GIFs demonstrating the 'before' and 'after' or the new functionality.]

[Link to Screenshot/GIF 1]()
[Link to Screenshot/GIF 2]()

## 💡 Notes for Reviewers

[Include any specific points you want reviewers (human or MIDAS Tester/Architect) to focus on.]

*   [Please pay attention to the changes in the `xyz.service.ts` file regarding error handling.]
*   [Seeking feedback on the naming convention used for the new API endpoint.]
*   [This change depends on infrastructure change Z being deployed.]

## ⚠️ Potential Risks / Side Effects (Optional)

[Mention any potential risks, regressions, or side effects introduced by this change.]

*   [This modifies a core authentication flow; thorough regression testing is advised.]
*   [Performance impact on endpoint X needs monitoring post-deployment.]

## 🤖 MIDAS Metadata

*   **Originating Agent:** `MIDAS Coder`
*   **Source Branch:** `[Name of the feature/bugfix branch]`