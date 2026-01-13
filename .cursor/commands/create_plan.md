# Instruction: Create Robust, Executable Implementation Plans

You are to act as a thorough, methodical planner for implementation plans that will be stored in `.ai/plans`. Your goal is to create comprehensive, executable plans that are grounded in research, clearly structured, and free of ambiguities. Be rigorous, demand specificity, and ensure the plan can be executed systematically without guesswork.

The plan structure should support phased execution (handled by the `execute_plan` command), but you should create the complete plan document in one session, saving incrementally as you progress.

---

## 1. Research Validation and Analysis

**Autonomous Analysis Required:** You should analyze research independently and extract findings without asking for confirmation. Only ask if the research is unclear or contradictory.

### Research File Discovery
- Verify the research file exists in `.ai/research`.
- If no research file is specified, attempt intelligent matching by topic keywords.
- If auto-matching fails, use the most recent research file as fallback.
- If no research file exists at all, **stop immediately** and require the user to create research first.
- _Research is mandatory—plans without research context are incomplete and risky._

### Research Content Analysis
- Read the full research file into context.
- **Autonomously extract** key findings, technical decisions, constraints, and recommendations.
- **Autonomously identify** any contradictions or areas requiring clarification.
- **Autonomously note** dependencies, prerequisites, and technical requirements mentioned in research.
- **Only ask the user** if you find contradictions, ambiguities, or missing critical information that would prevent creating a valid plan.

### Topic and Type Validation
- Ensure the topic clearly describes what is being planned.
- Verify the type (feature/bugfix/refactor/infra) accurately categorizes the work.
- Check that the description aligns with both topic and type.
- If misalignment is found, ask the user for clarification.

---

## 2. Plan Creation Workflow

**Hybrid Approach:** Explore the codebase autonomously to find file paths, component names, and architectural patterns. Only ask the user when you're uncertain or when multiple valid approaches exist.

### Codebase Exploration
- **Autonomously explore** the codebase to identify:
  - Relevant file paths and locations
  - Existing component/function names and patterns
  - Architectural decisions and conventions
  - Dependencies and relationships
- Use codebase search, file reading, and pattern analysis to gather this information.
- **Only ask the user** when:
  - You cannot find relevant files/components after reasonable exploration
  - Multiple valid approaches exist and you need guidance on which aligns with their preferences
  - You encounter architectural decisions that aren't clear from the codebase
  - You need clarification on business logic or requirements not covered in research

### Implementation Decisions
- **Autonomously propose** implementation approaches based on research and codebase analysis.
- **Present options** when multiple valid approaches exist: "I see two possible approaches: [A] or [B]. Which aligns better with your codebase/requirements?"
- **Ask for confirmation** on major architectural decisions or when research suggests multiple valid paths.
- **Infer and proceed** when the path is clear from research and codebase patterns.

### Plan Structure Creation
- Create the plan following the Output Structure template (Section 4).
- Structure steps to support phased execution (each step should be independently executable with clear dependencies).
- Break complex work into discrete, actionable steps that can be checked off.
- Order steps logically—dependencies must come before dependent work.

---

## 3. File Management

### File Naming Convention
- Format: `YYYY-MM-DD_type_topic.md`
- Example: `2025-11-07_feature_user_authentication.md`
- Use lowercase with underscores for topic (sanitize spaces and special characters).

### File Path
- Save to: `.ai/plans/YYYY-MM-DD_type_topic.md`
- Use relative path from workspace root.

### Incremental Saving
- **Save the plan file incrementally** as you create each major section:
  - Save after completing the Objective section
  - Save after completing the Research Summary section
  - Save after completing each major group of Implementation Plan steps (e.g., after steps 1-3, then after steps 4-6, etc.)
  - Save after completing Risks/Caveats section
  - Save after completing References section
  - Final save after completing Review & Next Steps section
- This allows the user to see progress and provide feedback during creation.
- Update the file in place—don't create multiple versions.

---

## 4. Output Structure

The generated plan must follow this exact structure:

```markdown
# [Type Plan] Topic

**Date:** YYYY-MM-DD
**Type:** feature|bugfix|refactor|infra
**Topic:** Brief topic description
**Plan Author:** (fill in dev/command runner name if needed)
**Linked Research:** research_file_name.md

---

## 1. Objective

Clear, specific statement of the purpose of this plan. Include acceptance criteria or success conditions that make completion verifiable.

**Acceptance Criteria:**
- Measurable condition 1 that indicates this plan is complete
- Measurable condition 2
- Validation methods: tests, manual verification, etc.

---

## 2. Summary of Relevant Research

**Source:** `research_file_name.md`

> (Concise excerpt from the linked research for context, max 1200 chars. Highlight findings most relevant to implementation decisions.)

---

## 3. Implementation Plan

Each step must be specific, executable, and have clear acceptance criteria. Order steps to respect dependencies. Structure steps to support phased execution—each step should be independently executable with clear prerequisites.

- [ ] **(Step 1)**: Specific action to take
    - **Prerequisites:** List any dependencies or requirements
    - **Acceptance Criteria:** How to verify this step is complete
    - **Quality Gates:** Tests, linting, qa.sh, etc. to run after this step

- [ ] **(Step 2)**: Specific action to take
    - **Prerequisites:** List any dependencies or requirements
    - **Acceptance Criteria:** How to verify this step is complete
    - **Quality Gates:** Tests, linting, qa.sh, etc. to run after this step

- [ ] **(Step 3)**: Specific action to take
    - **Prerequisites:** List any dependencies or requirements
    - **Acceptance Criteria:** How to verify this step is complete
    - **Quality Gates:** Tests, linting, qa.sh, etc. to run after this step

(Add more steps as needed. Break complex steps into sub-steps if necessary.)

---

## 4. Risks / Caveats

Based on research and technical analysis, identify potential issues and mitigation strategies.

**Identified Risks:**
- Risk description - **Mitigation:** How to address or minimize this risk

**Assumptions:**
- List assumptions that, if incorrect, would impact the plan

**Potential Blockers:**
- List any dependencies or conditions that could prevent progress

**Uncertainties:**
- Areas where more research or clarification is needed

---

## 5. References & Links

- [Research: research_file_name.md](../research/research_file_name.md)
- (Add links to relevant code files, documentation, or external resources)

---

## 6. Review & Next Steps

- [ ] Review this plan with team/stakeholders
- [ ] Validate consistency with research findings
- [ ] Verify all steps are specific and executable
- [ ] Confirm acceptance criteria are measurable
- [ ] Update as needed after feedback
- [ ] Proceed to execution only after review approval

---

**Note:** This plan should be reviewed using the `criticize_plan` command before execution. Execute using the `execute_plan` command, which will validate consistency with research and ensure quality gates are met.
```

---

## 5. Content Requirements

### Objective Section
- State clearly what the plan aims to achieve.
- Include acceptance criteria or success conditions.
- Avoid vague statements—demand concrete, verifiable outcomes.
- Link the objective directly to the research findings.

### Research Summary
- Provide a concise excerpt (max 1200 chars) that gives essential context.
- Highlight findings most relevant to implementation decisions.
- Reference the full research file for complete details.
- Ensure the summary supports the implementation approach.

### Implementation Plan Steps
- Each step must be specific enough to execute without ambiguity.
- Include dependencies and prerequisites for each step.
- Specify acceptance criteria or validation methods for each step.
- Include quality gates (tests, linting, qa.sh) at appropriate checkpoints.
- For complex steps, break them into sub-steps.
- Specify file paths, function names, or specific components when relevant (discovered through codebase exploration).

### Risks and Caveats
- Identify technical risks based on research and codebase analysis.
- List assumptions that, if wrong, would derail the plan.
- Note areas of uncertainty or potential blockers.
- Include mitigation strategies for identified risks.
- Reference any paradoxes or contradictions found in research.

### References and Links
- Link to the full research file with correct relative path: `../research/research_file_name.md`
- Include links to relevant code files, documentation, or external resources.
- Ensure all referenced materials are accessible and current.

---

## 6. Quality Validation

Before finalizing, perform these checks:

### Consistency Check
- Verify the plan aligns with research findings—no contradictions.
- Ensure technical decisions in the plan match research recommendations.
- Check that dependencies are correctly identified and ordered.

### Completeness Check
- Verify all placeholder text has been replaced with specific content.
- Ensure each step has clear acceptance criteria.
- Confirm that risks are identified and addressed.
- Check that file paths and references are correct.

### Clarity Check
- Ensure steps are unambiguous and executable.
- Verify that someone else could follow the plan without additional context.
- Check that technical terms are defined or linked to documentation.
- Confirm that acceptance criteria are measurable.

---

## 7. Critical Rules

### Research and Analysis
- **Never create a plan without research**—research is mandatory for context and validation.
- **Autonomously analyze research**—extract findings, identify dependencies, note constraints without asking for confirmation.
- **Only ask about research** if you find contradictions, ambiguities, or missing critical information.

### Codebase Exploration
- **Autonomously explore the codebase** to find file paths, component names, and architectural patterns.
- **Only ask when uncertain**—if you cannot find relevant information after reasonable exploration, or if multiple valid approaches exist.
- **Infer from patterns**—use existing codebase conventions and patterns to make decisions.

### Plan Quality
- **Never use vague language**—demand specificity in objectives, steps, and acceptance criteria.
- **Never skip validation**—always check consistency, completeness, and clarity before finalizing.
- **Never ignore contradictions**—if research conflicts with the plan, surface it immediately.
- **Always link research**—every plan must reference a research file for traceability.
- **Always specify acceptance criteria**—each step must have a clear completion condition.
- **Always consider dependencies**—order steps correctly and note prerequisites.
- **Always include quality gates**—specify when tests, linting, or qa.sh should run.

### File Management
- **Always use correct naming format**: `YYYY-MM-DD_type_topic.md`
- **Save incrementally** as you complete each major section.
- **Update file in place**—don't create multiple versions.

### Decision Making
- **Present options** when multiple valid approaches exist—ask for developer preference.
- **Surface uncertainties immediately**—don't wait until the end to ask clarifying questions.
- **Proceed autonomously** when the path is clear from research and codebase analysis.
