# Scenarios

Acumen supports implementing different scenarios side-by-side as a way to quickly create new flows and experiences.
The default scenario we support is a cancer care scenario, where a group of agents is tasked with answering questions about patient care that could come up during a tumor board review.
We encourage you to create brand new scenarios that you can install. Simply create a new folder under scenarios. Specify at the minimum a `config/agents.yaml` file and a `requirements.txt` file.
At least one agent in your YAML file should be marked as the facilitator (`facilitator: true`).
Optionally, you can create tools under a tools directory. Those would be made available to your group chat.

To select your scenario, run

```
azd env set SCENARIO <scenario>
```

Then run `azd up` to configure and deploy your scenario.

> [!NOTE]
> Only one scenario is available currently: `default`. Follow the below instructions to add additional scenarios.

## Scenario Folder Structure

A scenario in the healthcare multi-agent system is organized with the following structure:

Scenario folder: `src/scenarios/<scenario>/`
- Required components:
    - `config/agents.yaml`: Defines all agents, their roles, and configurations
        - Must include at least one agent marked as the facilitator (`facilitator: true`)
    - `requirements.txt`: Lists all Python dependencies for your scenario

- Optional components:
    - `tools/`: Directory for custom tools available to your agents
        - Single file tools: `my_new_tool_plugin.py` with `create_plugin()` function
        - Package tools: `my_new_tool_plugin/` directory with `__init__.py` containing `create_plugin()`
    - `README.md`: Documentation specific to your scenario
    - Other custom folders: You can include additional directories for scenario-specific resources, data, configuration files, or utilities as needed

Then add your scenario to the Bicep file `infra/main.bicep`. Make sure the scenario name matches the folder name.

```bicep
var agentConfigs = {
  default: loadYamlContent('../src/scenarios/default/config/agents.yaml')
  <scenario>: loadYamlContent('../src/scenarios/<scenario>/config/agents.yaml')
}
```

You can now select and deploy your scenario using:
```bash
azd env set SCENARIO radflow
azd up
```

## Tips for Defining an Orchestrator Agent

When creating an orchestrator for your multi-agent scenario, consider these best practices:

### 1. Define Clear Facilitation Responsibilities

- Mark as facilitator: Include `facilitator: true` in your orchestrator's configuration
- Limit domain expertise: The orchestrator should coordinate, not provide specialized knowledge
- Focus on process over content: Emphasize conversation management rather than answers

### 2. Design Effective Turn Management

- Specify explicit handoff protocols: Require agents to return control (e.g., "back to you: *Orchestrator*")
- Use direct addressing: When calling on agents, use their name with formatting (e.g., "*AgentName*, please...")
- Include agent reference list: Use placeholder variables like `{{aiAgents}}` to list available participants

### 3. Include Planning and Transparency Elements

- Require plan formulation: Have the orchestrator create and explain the conversation flow
- Request user confirmation: Include steps to verify plans with users before proceeding
- Document participant order: Explain which agents will participate and why

### 4. Set Clear Role Boundaries

- Explicitly state limitations: Define what the orchestrator should NOT do (e.g., "DON'T: Provide clinical recommendations")
- Establish delegation patterns: Create rules for when to defer to specialist agents
- Define conversation closure criteria: Specify when a conversation thread is complete

### 5. Incorporate Progress Tracking

- Prevent premature conclusion: Include logic to check if all necessary agents have contributed
- Request missing information: Define protocols for identifying and requesting missing data
- Support follow-up questions: Create frameworks for handling additional user inquiries

### 6. Maintain Conversational Context

- Summarize responses: Have the orchestrator consolidate information periodically
- Track conversation state: Include methods to remember what has been discussed
- Manage conversation transitions: Create smooth handoffs between discussion topics

The orchestrator is the heart of your multi-agent chat, so investing time in its design will significantly improve the overall user experience.
