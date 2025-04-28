import json
import getpass
import os
import sys
from typing import Dict, Any, List, Optional

# --- Configuration ---
MCP_JSON_FILENAME = "mcp.json"
DEFAULT_WORKSPACE_MOUNT = "/workspace"
DEFAULT_GIT_PORT = 50052
DEFAULT_ATLASSIAN_PORT = 50053
DEFAULT_BRAVE_SEARCH_PORT = 50054 # Added port for Brave Search


def prompt_for_atlassian_credentials() -> Dict[str, str]:
    """Prompts the user for Atlassian credentials."""
    print("\n--- Atlassian Configuration ---")
    print(
        "You need an Atlassian API token. See:"
        " https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/"
    )
    atlassian_url = input("Enter your Atlassian instance URL (e.g., https://your-domain.atlassian.net): ")
    # Basic validation
    if not atlassian_url.startswith("https://"):
        print("Warning: URL should typically start with https://")
    atlassian_email = input("Enter your Atlassian account email: ")
    atlassian_token = getpass.getpass("Enter your Atlassian API token: ")
    if not atlassian_token:
        print("Warning: API Token cannot be empty.")
    return {
        "ATLASSIAN_URL": atlassian_url,
        "ATLASSIAN_USERNAME": atlassian_email,
        "ATLASSIAN_API_TOKEN": atlassian_token,
    }

def prompt_for_brave_credentials() -> Dict[str, str]:
    """Prompts the user for Brave Search API credentials."""
    print("\n--- Brave Search Configuration ---")
    print(
        "You need a Brave Search API key. See:"
        " https://brave.com/search/api/" # Placeholder URL, update if needed
    )
    # Brave Search usually only requires an API key
    brave_api_key = getpass.getpass("Enter your Brave Search API key: ")
    if not brave_api_key:
        print("Warning: API Key cannot be empty.")
    return {
        "BRAVE_SEARCH_API_KEY": brave_api_key,
    }


def generate_mcp_config() -> Dict[str, Any]:
    """Generates the MCP configuration dictionary."""
    print("Generating MCP configuration...")

    # Base structure
    mcp_config: Dict[str, Any] = {"servers": []}
    next_steps: List[str] = []

    # 1. Filesystem MCP Server (Stdio)
    mcp_config["servers"].append(
        {
            "name": "filesystem",
            "description": "Provides access to the local filesystem.",
            "type": "stdio",
            # Assumes server installed and available in PATH or via python -m
            "command": [sys.executable, "-m", "mcp_server_filesystem", "."],
            "working_directory": ".", # Relative to project root
            "enabled": True,
        }
    )
    next_steps.append(
        "- Ensure the Filesystem MCP server is installed (e.g., `pip install mcp-server-filesystem` or ensure the executable is in PATH)."
    )

    # 2. Fetch MCP Server (Stdio)
    mcp_config["servers"].append(
        {
            "name": "fetch",
            "description": "Fetches content from URLs.",
            "type": "stdio",
            # Assumes server installed and available in PATH or via python -m
            "command": [sys.executable, "-m", "mcp_server_fetch"],
            "enabled": True,
        }
    )
    next_steps.append(
        "- Ensure the Fetch MCP server is installed (e.g., `pip install mcp-server-fetch` or ensure the executable is in PATH)."
    )


    # 3. Git MCP Server (Docker)
    git_port = DEFAULT_GIT_PORT
    mcp_config["servers"].append(
        {
            "name": "git",
            "description": "Provides Git repository operations.",
            "type": "docker",
            "image": "roocode/mcp-server-git:latest", # Replace with actual image
            "container_name": "roocode-mcp-git",
            "ports": {f"{git_port}/tcp": git_port},
            "volumes": {
                os.getcwd(): {
                    "bind": DEFAULT_WORKSPACE_MOUNT,
                    "mode": "rw"
                }
            },
            "environment": {
                "WORKSPACE_DIR": DEFAULT_WORKSPACE_MOUNT
            },
            "enabled": True,
        }
    )
    next_steps.append(
        f"- Ensure Docker is running and the Git MCP server image ('roocode/mcp-server-git:latest' or equivalent) is available/pulled."
        f"\n  The server will attempt to run on port {git_port} and mount the current directory ({os.getcwd()}) to {DEFAULT_WORKSPACE_MOUNT} in the container."
    )


    # 4. Atlassian MCP Server (Docker)
    atlassian_port = DEFAULT_ATLASSIAN_PORT
    atlassian_creds = prompt_for_atlassian_credentials()
    mcp_config["servers"].append(
        {
            "name": "mcp-atlassian",
            "description": "Provides tools for interacting with JIRA and Confluence.",
            "type": "docker",
            "image": "roocode/mcp-server-atlassian:latest", # Replace with actual image
            "container_name": "roocode-mcp-atlassian",
            "ports": {f"{atlassian_port}/tcp": atlassian_port},
            "environment": atlassian_creds,
            "enabled": True,
        }
    )
    next_steps.append(
        f"- Ensure Docker is running and the Atlassian MCP server image ('roocode/mcp-server-atlassian:latest' or equivalent) is available/pulled."
        f"\n  The server will attempt to run on port {atlassian_port} using the credentials you provided."
        "\n  Make sure the API token has the necessary permissions for JIRA and Confluence."
    )

    # 5. Brave Search MCP Server (Docker)
    brave_port = DEFAULT_BRAVE_SEARCH_PORT
    brave_creds = prompt_for_brave_credentials()
    mcp_config["servers"].append(
        {
            "name": "brave-search",
            "description": "Provides web search capabilities via Brave Search API.",
            "type": "docker",
            "image": "roocode/mcp-server-brave-search:latest", # Replace with actual image
            "container_name": "roocode-mcp-brave-search",
            "ports": {f"{brave_port}/tcp": brave_port},
            "environment": brave_creds, # Pass API key as environment variable
            "enabled": True,
        }
    )
    next_steps.append(
        f"- Ensure Docker is running and the Brave Search MCP server image ('roocode/mcp-server-brave-search:latest' or equivalent) is available/pulled."
        f"\n  The server will attempt to run on port {brave_port} using the API key you provided."
    )


    print("\n--- Configuration Generation Complete ---")
    return mcp_config, next_steps


def save_mcp_config(config: Dict[str, Any], filename: str) -> None:
    """Saves the configuration to a JSON file."""
    filepath = os.path.join(os.getcwd(), filename)
    print(f"Saving configuration to: {filepath}")
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(config, f, indent=2)
        print("Configuration saved successfully.")
    except IOError as e:
        print(f"Error saving configuration file: {e}")
        sys.exit(1)


def main() -> None:
    """Main function to generate and save the MCP config."""
    # Check if mcp.json already exists
    if os.path.exists(MCP_JSON_FILENAME):
        overwrite = input(
            f"'{MCP_JSON_FILENAME}' already exists. Overwrite? (y/N): "
        ).lower()
        if overwrite != "y":
            print("Operation cancelled.")
            sys.exit(0)

    config, next_steps = generate_mcp_config()
    save_mcp_config(config, MCP_JSON_FILENAME)

    print("\n--- Next Steps ---")
    if next_steps:
        for i, step in enumerate(next_steps, 1):
            print(f"{i}. {step}")
    else:
        print("No specific next steps identified.")

    print(f"\nReview the generated '{MCP_JSON_FILENAME}' file.")
    print("You may need to adjust server image names, ports, commands, or environment variable names based on your specific MCP server implementations.")


if __name__ == "__main__":
    main()