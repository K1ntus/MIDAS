**Subject: Initiate Full Project Workflow - MiniGalaxySim v1.0**

**Request:**

Please initiate and manage the complete end-to-end development workflow using the **MIDAS framework** for the project specified below:

**Project:** MiniGalaxySim v1.0

**Core Goal:** Develop a simple, visually engaging 2D simulation of a small "galaxy" system (central star, orbiting satellites, moving asteroids) in Python using Pygame, according to the detailed specification.

**Detailed Specification Location:**
`./minigalaxysim_v1.0.spec.md`

**Required Project Identifiers:**
*   Target Git Repository URL: `git@github.com:3D-Organizer/Midas-custo.git`

**Instructions for MIDAS:**

1.  **Activate `MIDAS Strategic Planner`:** Have the Planner access and analyze the specification at the provided location.
2.  **Planner Actions:**
    *   Identify and create the high-level github Epics (e.g., Core Engine, Celestial Objects, Visualization, Interaction) within the `MGS` project.
    *   Generate corresponding Confluence overview pages within the `MGSPEC` space, ensuring they follow FUAM principles, use appropriate templates (if available), and are linked correctly to the created github Epics.
    *   Analyze and document initial high-level dependencies between Epics.
3.  **Handoff to `MIDAS Product Owner`:** Once Epics and initial Confluence pages are created, the Planner should hand off the relevant Epic Keys and Confluence URLs to the Product Owner.
4.  **PO Actions:**
    *   Retrieve Epic details and read Confluence specs.
    *   Decompose Epics into detailed github Stories and Tasks with clear Acceptance Criteria within the `MGS` project.
    *   Consult `MIDAS Architect` and `MIDAS UI/UX Designer` as needed during decomposition (e.g., for technical feasibility or visual details clarification based on the spec).
    *   Define and link dependencies between Stories/Tasks in github.
5.  **Implementation Handoff:** The Product Owner should subsequently hand off ready Tasks to the appropriate specialist agents (`MIDAS Coder`, `MIDAS Tester`, `MIDAS Security Specialist` (if security tasks are identified), `MIDAS DevOps Engineer` (if CI/CD tasks are identified)).
6.  **Full Workflow Execution:** Oversee the entire workflow execution, including implementation, testing, potential debugging, security checks, documentation updates, and code commits/pushes to the specified Git repository, ensuring github statuses are updated throughout.

**Goal:** Drive the project from this specification to a functional v1.0 state, managed entirely within the MIDAS framework, utilizing all necessary specialized agents collaboratively. Report overall progress and final completion status.