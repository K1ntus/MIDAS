Okay, here is a complex specification document for a small Python project, suitable for being fed into the MIDAS framework. It includes functional, non-functional, technical requirements, and details that would require coordination between different MIDAS agents (Architect, PO, Coder, Tester, UI/UX).

---

**Project Specification: MiniGalaxySim v1.0**

**1. Introduction & Goal**

*   **Project Name:** MiniGalaxySim
*   **Version:** 1.0
*   **Primary Goal:** Develop a simple, visually engaging 2D simulation of a small "galaxy" system in Python. The simulation will feature a central star, orbiting satellites, and randomly moving asteroids, demonstrating basic physics and animation principles.
*   **Target Platform:** Desktop (Windows, macOS, Linux) via Python execution.
*   **Target Audience:** Users interested in simple physics simulations or programming examples.

**2. High-Level Requirements (Potential Epics)**

*   **EPIC-001:** Core Simulation Engine Implementation
*   **EPIC-002:** Celestial Object Implementation (Star, Satellite, Asteroid)
*   **EPIC-003:** Visualization & Animation Layer Implementation
*   **EPIC-004:** Basic User Interaction Handling

**3. Functional Requirements (Potential Stories/Tasks)**

*   **FR1 (Core):** The system MUST simulate the passage of time using discrete time steps.
*   **FR2 (Core):** The simulation MUST be pausable and resumable via user input.
*   **FR3 (Star):** The simulation MUST display a single, large, static central star at the center of the simulation area.
*   **FR4 (Satellite):** The simulation MUST simulate `N` satellites (configurable, default N=5).
*   **FR5 (Satellite):** Each satellite MUST orbit the central star following basic circular orbital mechanics (gravity approximation: constant speed, constant radius orbit). Satellite speeds should vary inversely with their orbital radius (further satellites move slower).
*   **FR6 (Satellite):** Initial satellite orbits MUST have varying radii and starting angles to avoid immediate overlap. Orbital radii should be within reasonable bounds (e.g., 15% to 45% of the screen half-width).
*   **FR7 (Asteroid):** The simulation MUST simulate `M` asteroids (configurable, default M=15).
*   **FR8 (Asteroid):** Asteroids MUST be initialized with random positions within the simulation area (avoiding immediate overlap with the star) and random velocity vectors (random direction and speed within a predefined range).
*   **FR9 (Asteroid):** Asteroids MUST move in straight lines according to their initial velocity vector.
*   **FR10 (Asteroid):** Asteroids MUST wrap around the screen boundaries (i.e., an asteroid exiting the right edge reappears on the left edge at the same vertical position, and similarly for top/bottom edges).
*   **FR11 (Visualization):** The simulation MUST be rendered in a dedicated graphical window.
*   **FR12 (Visualization):** The central star MUST be visually distinct (e.g., large yellow circle).
*   **FR13 (Visualization):** Satellites MUST be visually distinct from the star and asteroids (e.g., medium blue circles).
*   **FR14 (Visualization):** Asteroids MUST be visually distinct (e.g., small, irregular grey shapes or simple grey circles).
*   **FR15 (Interaction):** The simulation MUST pause/resume when the `SPACEBAR` key is pressed.
*   **FR16 (Interaction):** The application MUST close gracefully when the window's close button is clicked or a standard quit event occurs.

**4. Non-Functional Requirements**

*   **NFR1 (Performance):** The simulation MUST maintain a minimum frame rate of 30 FPS on target hardware (assume mid-range modern desktop) with default object counts (N=5, M=15).
*   **NFR2 (Usability):** Controls MUST be simple and intuitive (single key for pause/resume).
*   **NFR3 (Maintainability):** Code MUST be written in an object-oriented style, separating simulation logic from visualization concerns where practical.
*   **NFR4 (Maintainability):** Code MUST adhere to the PEP 8 style guide.
*   **NFR5 (Maintainability):** Key simulation parameters (number of satellites `N`, number of asteroids `M`, simulation speed multiplier, window dimensions) MUST be easily configurable via constants near the top of the main script or in a separate configuration file.
*   **NFR6 (Robustness):** The application should handle basic window events (resize, minimize) without crashing, although visual updates during resize are not required for v1.0.

**5. Technical Constraints & Stack**

*   **TC1 (Language):** Python 3.8 or higher.
*   **TC2 (Core Library):** Pygame MUST be used for visualization, event handling, and the main game loop.
*   **TC3 (Math Library):** Standard Python math library is sufficient. NumPy MAY be used for vector operations if deemed beneficial by the Architect/Coder for clarity or performance, but is not strictly required.
*   **TC4 (Structure):** A Git repository MUST be used for version control. Commit messages SHOULD reference relevant JIRA task IDs.

**6. Visualization & UI/UX Details**

*   **V1 (Window):** Default window size: 800x600 pixels. Window title: "MiniGalaxySim v1.0".
*   **V2 (Background):** Static black background.
*   **V3 (Star Appearance):** Solid yellow circle, radius approx 5% of window width. Centered.
*   **V4 (Satellite Appearance):** Solid blue circles, radius approx 1% of window width.
*   **V5 (Asteroid Appearance):** Solid grey circles (simplest) or basic irregular polygons, max dimension approx 0.8% of window width.
*   **V6 (Animation):** Motion should appear smooth.

**7. Data Model (Conceptual)**

*   **`SimulationState`:** `is_paused` (boolean), `delta_time` (float).
*   **`Star`:** `position` (Vector2D).
*   **`Satellite`:** `position` (Vector2D), `orbit_radius` (float), `angular_velocity` (float). (Position calculated based on radius, angle derived from angular velocity * time).
*   **`Asteroid`:** `position` (Vector2D), `velocity` (Vector2D).
*   **`World`:** `dimensions` (width, height), list of `satellites`, list of `asteroids`.

**8. Deliverables**

*   Source code in a Git repository.
*   Basic `README.md` explaining how to install dependencies (Pygame) and run the simulation.
*   JIRA project populated with Epics, Stories, and Tasks reflecting the work done.
*   Confluence page(s) linked to Epics containing relevant design decisions or architectural diagrams (if any).

**9. Future Considerations (Out of Scope for v1.0)**

*   Elliptical orbits for satellites.
*   Gravitational interaction *between* satellites (N-body problem).
*   Collisions between asteroids / between asteroids and satellites.
*   Zoom and pan functionality.
*   Saving/loading simulation state.
*   More complex visual effects (particle trails, star glow).

---

This spec provides enough detail for the **MIDAS Planner** to create Epics, the **Architect** to potentially suggest class structures, the **Product Owner** to break down into Stories/Tasks, the **UI/UX** agent to confirm visual details, the **Coder** to implement the logic, and the **Tester** to define test cases based on the FRs and NFRs.