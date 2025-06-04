# How to Use MCP in the Healthcare Agent Orchestrator  

## Overview of MCP

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) is an open and standardized protocol designed to enable seamless integration between agents and tools. In this project, each agent is exposed as a custom tool via an MCP server, ensuring that other clients can interact with our agents through a unified and consistent protocol.

### Implementation
The MCP implementation resides in `./src/mcp_app.py`. A route is exposed under `/mcp/orchestrator`, where each agent is treated as an individual tool. Each MCP session creates a new group chat with shared history and context. The implementation leverages the [Streamable HTTP](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http) protocol to maintain a stateless server with effective session management.

## Copilot Integration  

Copilot Studio supports MCP through its connector interface. This guide explains how to create a custom connector and connect it to an agent in Copilot Studio, enabling full integration with the M365 ecosystem. By using the connector interface, enterprises can implement security and governance controls such as [Virtual Networks](https://learn.microsoft.com/en-us/power-platform/admin/vnet-support-overview) and [Data Loss Prevention](https://learn.microsoft.com/en-us/power-platform/admin/wp-data-loss-prevention).

## Creating a Custom MCP Connector  

To create a custom connector, follow the documentation here:  
[Create a Custom MCP Connector](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agent-extend-action-mcp)

Use the following Swagger definition, replacing `REPLACE_ME` with the hostname of the web app deployed using `azd up`:

```sh
azd env get-value BACKEND_APP_HOSTNAME
```

```yaml
swagger: '2.0'
info:
  title: MCP server Healthcare Agent Orchestrator
  description: >-
    Can answer any patient or healthcare related questions. To be used liberally
    and return results as is
  version: 1.0.0
host: REPLACE_ME  # Replace with your deployed web app hostname
basePath: /mcp
schemes:
  - https
consumes: []
produces: []
paths:
  /orchestrator/:
    post:
      summary: MCP server Healthcare Agent Orchestrator
      parameters:
        - in: body
          name: queryRequest
          schema:
            $ref: '#/definitions/QueryRequest'
        - in: header
          name: Mcp-Session-Id
          type: string
          required: false
      produces:
        - application/json
      responses:
        '200':
          description: Immediate Response
          schema:
            $ref: '#/definitions/QueryResponse'
        '201':
          description: Created and will follow callback
      operationId: InvokeMCP
      tags:
        - Agentic
        - McpStreamable
definitions:
  QueryRequest:
    type: object
    properties:
      jsonrpc:
        type: string
      id:
        type: string
      method:
        type: string
      params:
        type: object
      result:
        type: object
      error:
        type: object
  QueryResponse:
    type: object
    properties:
      jsonrpc:
        type: string
      id:
        type: string
      method:
        type: string
      params:
        type: object
      result:
        type: object
      error:
        type: object
parameters: {}
responses: {}
securityDefinitions: {}
security: []
tags: []
```

Follow the steps outlined in the [documentation](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agent-extend-action-mcp#create-a-custom-mcp-connector) to create the custom connector.

## Creating an Agent in Copilot That Consumes MCP  

After creating the custom connector, you can create an agent that consumes the MCP server. Follow the steps here:  
[Add an Existing MCP Action to an Agent](https://learn.microsoft.com/en-us/microsoft-copilot-studio/agent-extend-action-mcp#add-an-existing-mcp-action-to-an-agent)

Use the following instructions for your Copilot agent:

> You are overseeing a group chat between several AI agents and a human user. Each AI agent can be invoked through the use of a tool.  
> For any action, question, or statement by the user, always start by invoking the orchestrator agent. The orchestrator agent will create a general plan. You can then execute the plan by invoking each agent in sequence.  
> Reason deeply about the plan and how to best execute it. Return the results of each action without modifications, ensuring links are preserved. Return results as soon as they are available, if possible.  
> Continue executing actions in sequence until the user query is resolved.

Enable [Generative Orchestration](https://learn.microsoft.com/en-us/microsoft-copilot-studio/advanced-generative-actions) to allow your Copilot to use tools from the MCP server as they are discovered. Consider disabling other knowledge sources to ensure the Copilot relies solely on the healthcare orchestrator, or add reputable sources to complement it.

Under "Tools," select "Add Tool" and choose the MCP connector created earlier. It will appear as `MCP Server Healthcare Agent Orchestrator` (from the Swagger title).

Test your changes and publish your agent.

## Conclusion  

By following these steps, you can quickly publish a Copilot agent and enable it to leverage the full capabilities of the M365 ecosystem.
