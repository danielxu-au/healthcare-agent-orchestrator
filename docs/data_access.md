# Data Access

This document covers the design of the data access layer used to load and format patient data in a persistent storage.

## Overview

The Data Access Layer (DAL) serves as an abstraction layer that encapsulates the data access logic used by agent tools. It provides a unified interface for interacting with various data sources, ensuring consistency, maintainability, and scalability across the system.

### Key Responsibilities

- **Data Retrieval**: Fetch data from databases, APIs, or other external sources.
- **Data Transformation**: Convert raw data into structured formats suitable for processing by agent tools.
- **Data Validation**: Ensure the integrity and validity of the data being accessed.
- **Error Handling**: Manage exceptions and errors that may occur during data access operations.

### Benefits

- **Abstraction**: Decouples the data access logic from the business logic, promoting modularity.
- **Reusability**: Centralizes data access logic, making it reusable across multiple agent tools.
- **Maintainability**: Simplifies updates and changes to data access mechanisms without impacting the tools that rely on them.

### Components

1. **Data Models**: Define the structure and schema of the data being accessed.
2. **Data Accessors**: Implement the logic for interacting with specific data sources.

By leveraging the Data Access Layer, developers can focus on building robust agent tools without worrying about the complexities of data access and management.


## Data Models

This table describes the available data models that are persisted in storage.
| Data Model Name | Type |  Description |
|-|-|-|
| Chat Artifact | ChatArtifact | Stores generated data from Agents, such as patient timeline, patient data answers and relevant research paper search results. |
| Chat Context | ChatContext | Contains contextual information related to a chat session, such as chat history and loaded patient data used throughout a chat session. |
| Clinical Note | dict | Represents clinical notes or medical documentation for patient records. |
| Image | binary | Stores medical images such as CT scans, X-rays or MRIs for diagnostic purposes. |

## Data Accessors

This table describes the available data accessors to access persistent storage.
| Data Accessor Name | Description |
|-|-|
| Chat Artifact Accessor | Handles read/write/archive operations for ChatArtifact. |
| Chat Context Accessor | Handles read/write/archive operations for ChatContext. |
| Clinical Note Accessor | Handles read operation for clinical notes. |
| Image Accessor | Handles read operation for patient images. |

## Usage of DataAccess in Agents

Agents manage chat history and session data using `ChatContext`. Upon receiving a message, the agent will load `ChatContext` using `DataAccess` for an existing chat or create a new one. After responding to a message, the agent will save `ChatContext` using `DataAccess`.

When an agent receives a "clear" message, the `ChatContext` associated with the chat session will be archived.

## Usage of DataAccess in Plugins

Plugins are created with `PluginConfiguration`. Tools in the plugin can access data models via `PluginConfiguration.data_access`.

```py
class SamplePlugin:

    def __init__(self, config: PluginConfiguration):
        self.config = config

    @kernel_function()
    async def tool1(self, patient_id: str) -> str:
        clinical_notes = await self.config.data_access.clinical_note_accessor.read_all(patient_id)

        # Do something with clinical notes
        ...
```