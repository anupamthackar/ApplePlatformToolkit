# Prompt Flow Guide

This document defines the sequential flow of prompts to systematically build the Context Stack files for a project using an AI Assistant. Follow this step-by-step prompt chain to ensure alignment and minimize architectural drift.

---

## Stage 1: Product Definition & Alignment

### Prompt 1: Create PRD
```markdown
Act as a Senior Product Manager.
Analyze the following features for my project:
[INSERT FEATURES DESCRIPTION]

Generate a production-ready Product Requirements Document (PRD) at `AI Agent/PRD.mdc`.
Use the following markdown template:
# Product Requirements Document
## Product Vision
## Problem Statement
## Solution Overview
## Target Audience
## User Personas
## User Stories
## User Flow
## Functional Requirements
## Non Functional Requirements
## API Requirements
## Database Requirements
## Security Requirements
## Edge Cases
## Risks
## Assumptions
## Limitations
## KPIs
## Future Enhancements
```

### Prompt 2: Create KPIs
```markdown
Analyze the PRD at `AI Agent/PRD.mdc`.
Generate a detailed KPI document at `AI Agent/KPI.mdc`.
Rules:
- Every KPI must be measurable.
- Include target values.
- Include explicit pass/fail conditions.
Use the following template:
# KPI
## Functional KPIs
## Technical KPIs
## Performance KPIs
## Reliability KPIs
## Security KPIs
## User Experience KPIs
## Acceptance Criteria
```

---

## Stage 2: Structural Architecture & Guidelines

### Prompt 3: Create Architecture
```markdown
Act as Principal Software Architect.
Analyze the PRD (`AI Agent/PRD.mdc`) and KPIs (`AI Agent/KPI.mdc`).
Generate a comprehensive system architecture document at `AI Agent/architecture.mdc`.
Ensure the design maps to standard project conventions (such as Swift 6 concurrency, 4-layer modular separations).
Use the following template:
# Architecture
## System Overview
## Component Diagram
## Data Flow
## Frontend Architecture
## Backend Architecture
## Database Architecture
## API Design
## Security Design
## Caching Strategy
## Queue Strategy
## Deployment Strategy
## Monitoring Strategy
## Disaster Recovery
```

### Prompt 4: Create Coding Style Guide
```markdown
Generate a Coding Style Guide at `AI Agent/style-guide.mdc` based on project constraints (e.g. Swift Package Manager, strict concurrency, Swift 6, custom namespaces).
Use the following template:
# Style Guide
## Naming Convention
## Folder Convention
## API Convention
## Database Convention
## Error Handling Convention
## Logging Convention
## Documentation Convention
```

### Prompt 5: Create AI Agent Constraints
```markdown
Generate an AI interaction configuration document at `AI Agent/context_build.mdc`.
Outline the boundaries of what code modification can be done, command line execution permissions, and token optimization rules (Vibe Coding Protocol).
Include:
- Project Boundaries
- Token Optimization
```

---

## Stage 3: Quality Assurance & Operations

### Prompt 6: Create Testing Strategy
```markdown
Generate a Testing Strategy at `AI Agent/testing.mdc` targeting the features defined in the PRD.
Map out unit tests, integration tests, E2E flows, security tests, and performance benchmarks.
Use the following template:
# Testing Strategy
## Unit Testing
## Integration Testing
## E2E Testing
## Security Testing
## Performance Testing
## Edge Cases
## Acceptance Validation
```

### Prompt 7: Create Security Requirements
```markdown
Generate a Security Requirements document at `AI Agent/security.mdc`.
Include specific constraints on token storage, biometrics access rules, cryptographic protocols (AES-GCM), and logging PII redaction rules.
Use the following template:
# Security Requirements
## Authentication
## Authorization
## Validation
## Encryption
## Rate Limiting
## Audit Logging
## Security Checklist
```

### Prompt 8: Create Deployment Guide
```markdown
Generate a Deployment Guide at `AI Agent/deployment.mdc` focusing on target runtime builds, compiler parameters (like strict concurrency flags), CI workflows, and rollback strategies.
Use the following template:
# Deployment
## Environments
## Build Process
## CI/CD
## Rollback Strategy
## Release Strategy
```

### Prompt 9: Create Observability Plan
```markdown
Generate an Observability Plan at `AI Agent/observability.mdc` detailing OS logging protocols, signpost instrumentation intervals for latency tracking, and threshold warning triggers.
Use the following template:
# Observability
## Logs
## Metrics
## Tracing
## Alerts
## Dashboards
```

### Prompt 10: Create Decision Log
```markdown
Generate a Decision Log at `AI Agent/decision-log.mdc` detailing core architectural choices, rationales, rejected alternatives, and consequences for key system components.
Use the following template:
# Decision Log
## Decision
## Reason
## Alternatives
## Consequences
## Date
```

---

## Stage 4: Personas Specification

### Prompt 11: Create Developer Personas
```markdown
Generate the three developer persona files under `AI Agent/personas/`:
1. `frontend_persona.mdc`: Focusing on Haptic, UI, ThemeManager, and accessibility benchmarks.
2. `backend_persona.mdc`: Focusing on concurrency, networking interceptors, and security logic.
3. `database_persona.mdc`: Focusing on CoreData/SwiftData schema, log entries, and performance.
Use the standard Focus/Constraints/Output templates for each.
```

---

## Stage 5: Specific Features Details

### Prompt 12: Create Feature Subfolders
```markdown
For the feature [INSERT FEATURE NAME], create its feature folder under `AI Agent/features/[feature_name]/` containing:
1. `feature_prd.mdc`: Goals, requirements, and user stories.
2. `feature_architecture.mdc`: Data flows, dependency maps, and class details.
3. `feature_test_cases.mdc`: Step-by-step test setups.
4. `implementation_notes.mdc`: API declarations and code interface examples.
```
