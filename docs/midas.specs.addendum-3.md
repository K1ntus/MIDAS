
## Specification Set 1: Code-Based Components (Libraries/Services)

These components represent potentially complex logic that should be implemented in code (e.g., Python libraries callable within the RooCode environment) rather than relying solely on LLM instructions for reliability and maintainability.

**Component 1: `ContextOptimizer` Service**

*   **Purpose:** To intelligently reduce the size of context provided to LLMs, ensuring essential information fits within token limits while minimizing the loss of critical details.
*   **Core Logic/Responsibilities:**
    1.  **Input Aggregation:** Receive the core task prompt and various related context items (e.g., issue descriptions, recent comments, relevant file contents/snippets, documentation excerpts).
    2.  **Strategy Selection (Configurable):** Based on configuration and input context characteristics (size, type), select one or more optimization strategies:
        *   **Summarization:** If context items exceed individual size thresholds, invoke an LLM (potentially a cheaper/faster model) to generate concise summaries.
        *   **Selective Inclusion (RAG-like):** If a large corpus (e.g., codebase, documentation) is referenceable, use embedding-based retrieval (vector search) or keyword search to find and include only the most relevant snippets based on the core task prompt.
        *   **Pruning/Filtering:** Apply rule-based pruning (e.g., remove boilerplate comments, filter out older/less relevant comments based on heuristics).
        *   **Direct Passthrough:** If context is already small enough, pass it through directly.
    3.  **Context Assembly:** Combine the optimized context pieces with the original core task prompt, ensuring the total size is below the specified `max_tokens` limit. Prioritize the core prompt and most relevant/recent information if truncation is still necessary after optimization.
    4.  **Output Formatting:** Return the final, optimized prompt string ready to be sent to the primary task-solving LLM.
*   **Key Inputs:**
    *   `current_task_prompt` (str): The specific instruction for the LLM.
    *   `related_context` (Dict[str, Union[str, List[str]]]): A dictionary containing various context elements (e.g., `{"issue_body": "...", "comments": ["...", "..."], "code_snippets": ["..."]}`).
    *   `max_tokens` (int): The target maximum token limit for the final context.
    *   `optimization_strategy_config` (Optional[Dict]): Configuration overriding default strategy selection.
*   **Key Outputs:**
    *   `optimized_prompt` (str): The processed prompt string ready for the LLM.
*   **Conceptual Interface:**
    ```python
    class ContextOptimizer:
        async def optimize_context(self, current_task_prompt: str, related_context: Dict, max_tokens: int) -> str:
            # ... implementation details ...
            pass
    ```
*   **Dependencies:**
    *   LLM client (for summarization).
    *   Vector Database / Search Index client (for RAG).
    *   Tokenizer (to estimate token counts accurately).
    *   Configuration management service.
*   **Key Considerations:**
    *   Latency overhead introduced by optimization steps (especially summarization LLM calls).
    *   Cost of optimization vs. potential savings on primary LLM calls.
    *   Accuracy of relevance determination in RAG.
    *   Configurability of strategies per agent or task type.

**Component 2: `RobustnessChecker` Service**

*   **Purpose:** To provide standardized checks for common agent failure modes like infinite loops, output inconsistencies (hallucinations), and determining appropriate error handling (retries).
*   **Core Logic/Responsibilities:**
    1.  **Loop Detection:**
        *   Analyze a provided history of agent actions/states for the current task instance.
        *   Implement heuristics like checking for repeated sequences of actions, identical state parameters across multiple steps, or exceeding a maximum interaction count.
        *   Return a boolean indicating if a loop pattern is detected based on configured thresholds.
    2.  **Output Consistency Verification:**
        *   Compare LLM-generated output (e.g., factual statements, code snippets) against provided `grounding_sources` (e.g., requirement documents, existing code, API specs).
        *   Implement checks ranging from simple keyword contradiction detection to more advanced semantic consistency analysis (potentially using embeddings or a dedicated verification LLM).
        *   Identify known patterns associated with hallucinations (e.g., making up APIs, citing non-existent sources) based on configuration/rules.
        *   Return a boolean indicating if the output appears consistent with sources and free of detected hallucination patterns.
    3.  **Retry Decision Logic:**
        *   Analyze error messages from failed tool calls (e.g., GitHub MCP, file system access).
        *   Match error messages against configurable patterns representing transient (retryable) vs. permanent (non-retryable) errors.
        *   Consider the current `attempt_count` against a configured maximum retry limit.
        *   Return a boolean indicating whether a retry is recommended.
*   **Key Inputs:**
    *   `agent_history` (List[Dict]): History of actions/states for loop detection.
    *   `llm_output` (str): The generated text to verify.
    *   `grounding_sources` (List[str]): Texts to check consistency against.
    *   `error_message` (str): Error from a failed tool call.
    *   `attempt_count` (int): Current retry attempt number.
    *   `robustness_config` (Optional[Dict]): Configuration for thresholds, patterns, etc.
*   **Key Outputs:**
    *   `is_loop_detected` (bool)
    *   `is_consistent` (bool)
    *   `should_retry` (bool)
*   **Conceptual Interface:**
    ```python
    class RobustnessChecker:
        def check_for_loop(self, agent_history: List[Dict]) -> bool:
            # ... implementation ...
            pass

        async def verify_output_consistency(self, llm_output: str, grounding_sources: List[str]) -> bool:
            # ... implementation ...
            pass

        def should_retry_tool(self, error_message: str, attempt_count: int) -> bool:
            # ... implementation ...
            pass
    ```
*   **Dependencies:**
    *   Configuration management service.
    *   Potentially LLM client or embedding models for advanced consistency checks.
*   **Key Considerations:**
    *   Balancing sensitivity of checks (avoiding false positives/negatives).
    *   Performance impact, especially for complex consistency checks.
    *   Maintainability of error patterns and hallucination indicators.

**Component 3: `TokenTracker` Service**

*   **Purpose:** To centrally log and monitor LLM token usage for cost analysis and budgeting. (Likely integrated directly into RooCode's LLM call infrastructure).
*   **Core Logic/Responsibilities:**
    1.  **Integration Point:** Intercepts or receives data about every LLM API call made via RooCode.
    2.  **Data Extraction:** Extracts relevant metadata: timestamp, agent triggering the call, task identifier, model used, prompt details (optional, consider privacy), input token count, output token count, estimated cost (if pricing known).
    3.  **Logging/Storage:** Sends this structured data to a designated logging system, database, or monitoring platform (e.g., LangSmith, Datadog, Prometheus, custom database).
*   **Key Inputs:**
    *   LLM API call request & response details (including token counts provided by the API).
    *   Agent/Task context information provided by RooCode.
*   **Key Outputs/Side Effects:**
    *   Log entries created in the target monitoring system.
*   **Conceptual Interface (Internal/Callback):**
    ```python
    # Likely called internally by RooCode's LLM handler
    class TokenTracker:
        def log_usage(self, usage_data: Dict):
            # usage_data contains agent_id, task_id, model, input_tokens, etc.
            # ... implementation logs data ...
            pass
    ```
*   **Dependencies:**
    *   RooCode's internal LLM interaction mechanism.
    *   Target Logging/Monitoring System API/Client.
*   **Key Considerations:**
    *   Performance overhead of logging every call.
    *   Schema design for logged data to support analysis.
    *   Integration with the chosen monitoring platform.
    *   Security/Privacy implications if logging full prompts.
