import os
from pathlib import Path
from typing import List

# Define the templates to be created
template_names: List[str] = [
    "product_roadmap",
    "project_goals",
    "epic_overview",
    "user_story_template",
    "definition_of_done",
    "sprint_planning_goals", # Combined sprint planning + goals
    "architecture_decision_record",
    "technical_design_document",
    "system_architecture_overview",
    "how_to_guide",
    "test_strategy",
    "decision_log",
]

# Define the target directory relative to the script location or project root
# Assuming script is run from project root (d:/Travail/Professional/MIDAS)
template_dir = Path(".roo/templates/confluence")

def create_templates() -> None:
    """Creates empty placeholder markdown files for Confluence templates."""
    print(f"Ensuring template directory exists: {template_dir}")
    template_dir.mkdir(parents=True, exist_ok=True)

    print("Creating placeholder template files...")
    for name in template_names:
        file_path = template_dir / f"{name}.template.md"
        if not file_path.exists():
            print(f"  Creating: {file_path}")
            try:
                with open(file_path, "w", encoding="utf-8") as f:
                    # Simple placeholder content
                    f.write(f"# Template: {name.replace('_', ' ').title()}\n\n")
                    f.write("*(This is a placeholder template)*\n")
                print(f"    Success.")
            except IOError as e:
                print(f"    ERROR creating {file_path}: {e}")
        else:
            print(f"  Skipping (already exists): {file_path}")

    print("Template generation script finished.")

if __name__ == "__main__":
    create_templates()