import os
from pathlib import Path
from typing import List, Tuple

# Define the agent roles and their corresponding file prefixes
# Format: (Role Name for Header, file_prefix)
agent_roles: List[Tuple[str, str]] = [
    ("MIDAS Strategic Planner", "strategic_planner"),
    ("MIDAS Product Owner", "product_owner"),
    ("MIDAS Architect", "architect"),
    ("MIDAS Coder", "coder"), # Includes Debugger role
    ("MIDAS Tester", "tester"),
    ("MIDAS Security Specialist", "security_specialist"),
    ("MIDAS DevOps Engineer", "devops_engineer"),
    ("MIDAS UI/UX Designer", "ui_ux_designer"),
]

# Define the target directory relative to the script location or project root
# Assuming script is run from project root (d:/Travail/Professional/MIDAS)
agent_dir = Path(".roo/agents")

def create_agent_files() -> None:
    """Creates empty placeholder markdown files for MIDAS agents."""
    print(f"Ensuring agent directory exists: {agent_dir}")
    agent_dir.mkdir(parents=True, exist_ok=True)

    print("Creating placeholder agent definition files...")
    for role_name, prefix in agent_roles:
        file_name = f"{prefix}.agent.md"
        file_path = agent_dir / file_name
        if not file_path.exists():
            print(f"  Creating: {file_path}")
            try:
                with open(file_path, "w", encoding="utf-8") as f:
                    # Simple placeholder content
                    f.write(f"# Agent: {role_name}\n\n")
                    f.write("## Description\n\n*(Placeholder)*\n\n")
                    f.write("## Instructions\n\n*(Placeholder)*\n\n")
                    f.write("## Tools\n\n*(Placeholder)*\n\n")
                    f.write("## Model Configuration\n\n*(Placeholder)*\n")
                print(f"    Success.")
            except IOError as e:
                print(f"    ERROR creating {file_path}: {e}")
        else:
            print(f"  Skipping (already exists): {file_path}")

    print("Agent placeholder generation script finished.")

if __name__ == "__main__":
    create_agent_files()