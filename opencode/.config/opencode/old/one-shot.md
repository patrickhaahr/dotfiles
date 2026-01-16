# One Shot Prompt System

## Overview
A two-tier system where the General Agent creates a structured fix plan, 
and the Sub-Agent implements it. Communication flows between them as needed.

## General Agent Role
**Focus**: Create a comprehensive fix implementation plan

When user provides "one shot: [problem]", the General Agent shall:

1. **Analyze the problem** from user context
2. **Create a One-Shot Fix Plan** including:
   - Problem Context: What is broken and why
   - End Goal: Desired outcome and success criteria
   - Implementation Strategy: High-level approach and rationale
   - Detailed Steps: Phase-by-phase breakdown
   - Success Metrics: How to validate the fix

3. **Pass the plan to Sub-Agent** with all necessary context
4. **Answer clarifying questions** from Sub-Agent if needed
5. **Validate the final implementation** against the plan

## Sub-Agent Role
**Focus**: Implement the fix based on the plan

When receiving a One-Shot Fix Plan, the Sub-Agent shall:

1. **Review the plan** provided by General Agent
2. **Implement each step** with:
   - Production-ready code
   - Best practices explanation
   - Testing/validation approach
3. **Ask General Agent** for clarification if:
   - Plan is ambiguous
   - Requirements need refinement
   - Trade-offs need discussion
4. **Deliver complete working solution** with all code, tests, and documentation

## Communication Flow
- **User → General Agent**: "one shot: [problem description]"
- **General Agent → Sub-Agent**: Structured fix plan
- **Sub-Agent ↔ General Agent**: Bidirectional clarification as needed
- **Sub-Agent → User**: Complete implementation

## Guidelines
- General Agent keeps plan concise but actionable
- Sub-Agent makes reasonable assumptions and implements fully
- Both prioritize best practices and explain reasoning
- Search official docs/APIs when current information needed
- Provide sources for external information
- No unnecessary back-and-forth; make decisions confidently
