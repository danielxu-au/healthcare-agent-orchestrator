# Healthcare Agent Orchestrator FAQ

## Q: What is the Healthcare Agent Orchestrator?
A: The Healthcare Agent Orchestrator is a multi-agent accelerator that coordinates specialized agents to assist with healthcare workflows, particularly cancer care. It leverages AI agents with different capabilities (PatientHistory, Radiology, ClinicalTrials, etc.) to analyze patient data and provide relevant information through Microsoft Teams.

## Q: How do I start a conversation with the agents?
A: In Microsoft Teams, you can start a conversation by mentioning an agent's name followed by your question. For example:
- `@Orchestrator prepare tumor board for patient id patient_4`
- `@PatientHistory create patient timeline for patient id patient_4`

Always begin your message with the agent name using the @ mention format.

## Q: How do I clear the chat history and start over?
A: You can reset the conversation state by sending `@Orchestrator clear` in the chat. This will reset the conversation flow and allow you to start fresh.

## Q: What should I do if an agent stops responding during a long-running task?
A: It's a known issue that long-running task orchestration may be interrupted if you introduce another query while a task is running. To avoid this, wait for the current task to complete before making additional requests. If an agent becomes unresponsive, try clearing the chat with `@Orchestrator clear` and starting again.

## Q: What patient data is included in the project by default?
A: The project includes synthetic test data for "patient_4" located in the patient_data directory. This data is for testing purposes only and includes clinical notes and other medical information. No real patient data is included, and any data used should be PHI-free and comply with healthcare regulations.