---
title: "Sprint [Number] - Planning & Goals"
weight: 8 # Adjust weight for ordering
geekdocAnchor: true
---

# Sprint [Number] - Planning & Goals

**Sprint Dates:** [Start Date] - [End Date]

**Planning Meeting Date:** YYYY-MM-DD

## 1. Sprint Goal

*Clearly state the primary goal the team aims to achieve during this sprint. This should be a concise, high-level objective that provides focus.*

**Example:** "Implement the core user authentication flow and enable basic profile viewing."

## 2. Team Capacity

*Estimate the available team capacity for this sprint.*

*   **Total Team Members:** [Number]
*   **Sprint Duration (Working Days):** [Number]
*   **Planned Leave/Holidays (Person-Days):** [Number]
*   **Other Commitments (Meetings, Support - Person-Days):** [Number]
*   **Estimated Focus Factor:** [e.g., 0.7 - 0.9]
*   **Calculated Capacity (Story Points / Ideal Days):** [Calculated Value]

{{< hint type=info >}}
Capacity planning helps ensure the team commits to a realistic amount of work. Adjust the calculation method based on team practices (Story Points, Ideal Days, etc.).
{{< /hint >}}

## 3. Committed Sprint Backlog

*List the Product Backlog Items (User Stories, Tasks, Bugs) committed to this sprint.*

| ID / Key      | Title                                       | Type      | Estimate (Points/Days) | Assignee(s) | Notes / Link                               |
| :------------ | :------------------------------------------ | :-------- | :--------------------- | :---------- | :----------------------------------------- |
| STORY-123     | As a user, I want to log in...              | Story     | 5                      | Dev A, Dev B| [Link to Story]()                          |
| TASK-456      | Set up CI/CD pipeline for auth service      | Task      | 3                      | Dev C       | [Link to Task]()                           |
| BUG-789       | Fix incorrect password reset link           | Bug       | 2                      | Dev A       | Related to STORY-100, [Link to Bug]()      |
| STORY-125     | As a user, I want to view my profile...     | Story     | 8                      | Dev B, Dev C| Depends on STORY-123, [Link to Story]() |
| ...           | ...                                         | ...       | ...                    | ...         | ...                                        |
| **Total:**    |                                             |           | **[Sum]**              |             |                                            |

## 4. Potential Risks / Dependencies

*Identify any potential risks or dependencies identified during planning that could impact the sprint goal.*

*   **Risk:** [e.g., Uncertainty about external API performance]
    *   *Mitigation:* [e.g., Build mock service for initial development]
*   **Dependency:** [e.g., Requires design assets from UX team by Day 3]

---

*This document captures the plan and goals agreed upon during the Sprint Planning meeting.*