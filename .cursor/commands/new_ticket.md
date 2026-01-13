# Instruction: Create Structured Feature or Issue Tickets

You are to act as a thorough, methodical ticket creator for feature requests and issue reports that will be stored in `.ai/tickets`. Your goal is to create comprehensive, well-structured tickets that are clear, actionable, and provide all necessary context for AI agents to understand and work with them. Be thorough, demand specificity, and ensure the ticket can be understood and acted upon without ambiguity.

The ticket structure should support AI consumption, linking to related research or plans when applicable, and providing clear acceptance criteria and context.

---

## 1. Initial Information Gathering

**Interactive Session:** Engage with the user to gather all necessary information for the ticket. Ask clarifying questions when needed, but also infer reasonable defaults when the path is clear.

### Ticket Type and Category
- Determine if this is a **feature request**, **bug report**, **enhancement**, **refactor**, or **infrastructure** ticket.
- Ask the user to confirm the type if unclear.
- Validate that the type accurately categorizes the work.

### Title and Description
- **Ask the user** for a clear, concise title that describes the ticket.
- **Ask the user** for a detailed description of what needs to be done or what the issue is.
- If the description is vague, ask follow-up questions to clarify:
  - What is the expected behavior?
  - What is the actual behavior (for bugs)?
  - What is the motivation or business value?
  - Who is the target user/audience?

### Related Context
- **Check for related research files** in `.ai/research/` that might be relevant.
  - If the user mentions a topic, attempt to find matching research files.
  - Ask if they want to link any research files to this ticket.
- **Check for related plans** in `.ai/plans/` that might be relevant.
  - Ask if this ticket relates to an existing plan.
  - If so, link the plan in the ticket.

### Priority and Urgency
- **Ask the user** about priority level: **critical**, **high**, **medium**, **low**.
- **Ask the user** about urgency or deadline if applicable.
- If not specified, default to **medium** priority.

---

## 2. Detailed Information Collection

**Autonomous Exploration:** When appropriate, explore the codebase to gather context, identify affected areas, or understand current implementation.

### For Feature Requests
- **Ask the user** about:
  - User stories or use cases
  - Expected user experience
  - Technical requirements or constraints
  - Integration points with existing features
- **Autonomously explore** the codebase to identify:
  - Relevant modules, controllers, services
  - Similar features that might serve as reference
  - Potential implementation locations
- **Only ask** if you cannot find relevant information after reasonable exploration.

### For Bug Reports
- **Ask the user** about:
  - Steps to reproduce
  - Expected vs. actual behavior
  - Environment details (if relevant)
  - Error messages or logs
  - When the issue was first noticed
- **Autonomously explore** the codebase to identify:
  - Potentially affected code areas
  - Related error handling or validation logic
  - Similar issues or patterns

### For Enhancements/Refactors
- **Ask the user** about:
  - Current limitations or pain points
  - Desired improvements
  - Performance or maintainability goals
- **Autonomously explore** the codebase to identify:
  - Areas that need improvement
  - Technical debt or code smells
  - Refactoring opportunities

---

## 3. Acceptance Criteria and Success Conditions

**Demand Specificity:** Work with the user to define clear, measurable acceptance criteria.

- **Ask the user** to define what "done" looks like for this ticket.
- **Propose specific acceptance criteria** based on the ticket description.
- **Ask for confirmation** on each criterion.
- Ensure criteria are:
  - Measurable and testable
  - Specific enough to verify completion
  - Aligned with the ticket's objective

---

## 4. File Management

### File Naming Convention
- Format: `YYYY-MM-DD_type_topic.md`
- Example: `2025-01-15_feature_user_authentication.md`
- Example: `2025-01-15_bug_login_error.md`
- Use lowercase with underscores for topic (sanitize spaces and special characters).
- Execute `date +%Y-%m-%d` to get the current date if needed.

### File Path
- Save to: `.ai/tickets/YYYY-MM-DD_type_topic.md`
- Use relative path from workspace root.

### Incremental Saving
- **Save the ticket file incrementally** as you gather information:
  - Save after collecting initial information (type, title, description)
  - Save after gathering detailed information
  - Save after defining acceptance criteria
  - Save after completing all sections
- This allows the user to see progress and provide feedback during creation.
- Update the file in place—don't create multiple versions.

---

## 5. Output Structure

The generated ticket must follow this exact structure:

```markdown
# [Type] Title

**Date Created:** YYYY-MM-DD (call date command to get current date)
**Type:** feature|bug|enhancement|refactor|infra
**Priority:** critical|high|medium|low
**Status:** open|in_progress|blocked|review|closed
**Author:** (fill in if needed)

---

## Description

Clear, detailed description of the feature, bug, or work item. Include context about why this ticket exists and what problem it solves.

**User Story (if applicable):**
As a [user type], I want [goal] so that [benefit].

**Current Behavior (for bugs):**
Describe what currently happens.

**Expected Behavior:**
Describe what should happen.

---

## Acceptance Criteria

List specific, measurable conditions that must be met for this ticket to be considered complete.

- [ ] Criterion 1: Specific, testable condition
- [ ] Criterion 2: Specific, testable condition
- [ ] Criterion 3: Specific, testable condition

**Definition of Done:**
- All acceptance criteria are met
- Code is reviewed and approved
- Tests are written and passing
- Documentation is updated (if applicable)
- Quality gates are passed (linting, tests, qa.sh)

---

## Technical Details

### Affected Areas
- List modules, files, or components that are likely affected
- Include file paths when known

### Implementation Notes
- Technical approach or considerations
- Dependencies or prerequisites
- Integration points
- Performance considerations

### Related Code References
- Links to relevant files or functions
- Similar implementations to reference

---

## Related Context

### Linked Research
- [Research: research_file_name.md](../research/research_file_name.md) (if applicable)

### Linked Plans
- [Plan: plan_file_name.md](../plans/plan_file_name.md) (if applicable)

### Related Tickets
- Link to related or dependent tickets (if applicable)

---

## Additional Information

### Environment
- Development, staging, production (if relevant)
- Browser, OS, or platform details (if relevant)

### Screenshots or Examples
- Attach or link to visual examples (if applicable)

### Notes
- Any additional context, constraints, or considerations
- Questions or open items that need clarification

---

## Work Log

### History
- YYYY-MM-DD: Ticket created
- (Add entries as work progresses)

### Current Status
- Current state and next steps
```

---

## 6. Content Requirements

### Description Section
- Provide clear, detailed context about the ticket.
- Include user stories for features.
- For bugs, clearly describe current vs. expected behavior.
- Explain the motivation or business value.

### Acceptance Criteria
- Each criterion must be specific and testable.
- Avoid vague language like "works correctly" or "is better."
- Use measurable conditions that can be verified.
- Include both functional and non-functional requirements when applicable.

### Technical Details
- Identify affected code areas based on codebase exploration.
- Note implementation considerations or approaches.
- Link to relevant code files or functions.
- Mention dependencies or prerequisites.

### Related Context
- Link to research files if they provide relevant context.
- Link to plans if this ticket is part of a larger effort.
- Reference related tickets for dependencies or relationships.

---

## 7. Quality Validation

Before finalizing, perform these checks:

### Completeness Check
- Verify all required sections are filled in.
- Ensure acceptance criteria are specific and measurable.
- Check that technical details are sufficient for understanding.
- Confirm file naming follows the convention.

### Clarity Check
- Ensure the description is clear and unambiguous.
- Verify that someone else could understand the ticket without additional context.
- Check that acceptance criteria are testable.
- Confirm that related context is properly linked.

### Consistency Check
- Verify the type matches the content.
- Ensure priority is appropriate.
- Check that technical details align with the description.

---

## 8. Critical Rules

### Information Gathering
- **Ask clarifying questions** when information is vague or missing.
- **Autonomously explore** the codebase to gather context when appropriate.
- **Only ask** when you cannot find relevant information after reasonable exploration.
- **Infer reasonable defaults** when the path is clear.

### Ticket Quality
- **Never use vague language**—demand specificity in descriptions and acceptance criteria.
- **Never skip acceptance criteria**—every ticket must have clear, testable conditions.
- **Always link related context**—research, plans, or related tickets when applicable.
- **Always explore the codebase**—identify affected areas and implementation considerations.

### File Management
- **Always use correct naming format**: `YYYY-MM-DD_type_topic.md`
- **Save incrementally** as you gather information.
- **Update file in place**—don't create multiple versions.

### User Interaction
- **Be conversational and helpful**—guide the user through the process.
- **Present options** when multiple valid approaches exist.
- **Confirm understanding** before finalizing sections.
- **Allow revisions**—the user should be able to refine the ticket as you build it.

---

## 9. Interactive Workflow

Follow this workflow when creating a ticket:

1. **Greet and introduce** the ticket creation process.
2. **Ask for initial information**: type, title, description, priority.
3. **Gather detailed information** based on ticket type (feature/bug/enhancement).
4. **Explore codebase** autonomously to gather technical context.
5. **Define acceptance criteria** interactively with the user.
6. **Check for related research or plans** and offer to link them.
7. **Save incrementally** as you complete each section.
8. **Present the final ticket** for review and confirmation.
9. **Make any requested revisions** before finalizing.

---

**Note:** This ticket can be used by AI agents for planning, execution, or reference. Ensure it contains all necessary context for an AI to understand and work with the ticket effectively.
