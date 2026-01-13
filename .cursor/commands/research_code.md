# Interactive Research Code Command (for Cursor)

## Instructions for Conducting Codebase Research

Follow these stages sequentially. Maintain explicit dialogue with the developer at decision points. Avoid hasty conclusions. Iterate on hypotheses until reaching solid, evidence-based conclusions.

---

## Stage 1: General Index & Initial Exploration

1. Identify the target path for research (codebase, directory, or documentation set).
2. Scan and index the codebase or documentation at the target path.
3. If the developer specifies priority areas, files, or subfolders, focus indexing there. Otherwise, perform a broad index of all accessible content.
4. Gather a map of:
   - Main files and their purposes
   - Folder structures and organization
   - High-level themes relevant to the research topic
5. Present the index to the developer and confirm the scope is appropriate.

---

## Stage 2: Hypothesis Formulation

1. Review the index and any prior research documents in `.ai/research/`.
2. If the developer provides specific hypotheses, use those. Otherwise, auto-generate high-value, testable hypotheses based on the index and research topic.
3. List all hypotheses clearly for exploration.
4. Present the hypotheses to the developer and confirm they are appropriate for investigation.

---

## Stage 3: Iterative Hypothesis Exploration

For each hypothesis:

1. Propose the optimal research approach:
   - Which code areas to explore
   - What specific questions to answer
   - What tools or methods to use (codebase_search, grep, file reading, etc.)
2. **PAUSE** and wait for developer feedback:
   - Developer can accept the proposed approach
   - Developer can customize or modify the approach
   - Developer can skip this hypothesis
3. Once approved, conduct the focused research probe:
   - Execute the research approach
   - Gather observations and evidence
   - Raise questions and surface uncertainties
   - Do not leap to conclusions prematurely
4. Present findings to the developer:
   - Show evidence gathered
   - Highlight uncertainties or open questions
   - Developer can choose to:
     - Finalize findings for this hypothesis
     - Request additional research with refined approach
     - Leave comments or notes
5. Repeat steps 1-4 for each hypothesis until all are explored.

---

## Stage 4: Consolidation of Findings

1. Summarize:
   - The codebase/documentation index
   - All hypotheses explored
   - Research steps taken
   - Finalized findings for each hypothesis
2. Collect:
   - All finalized conclusions
   - Developer comments and notes
   - Relevant observations and evidence
3. Determine the status of each hypothesis:
   - Proven (with evidence)
   - Disproven (with evidence)
   - Inconclusive (with explanation)
4. Present the consolidated findings to the developer for review before report generation.

---

## Stage 5: Structured Report Generation

1. Execute `date +%Y-%m-%d` to get the current date.
2. Create a filename using the format: `YYYY-mm-dd_research_topic_here.md`
   - Replace `YYYY-mm-dd` with the date from step 1
   - Replace `research_topic_here` with a sanitized version of the research topic
3. Create the file at: `.ai/research/YYYY-mm-dd_research_topic_here.md`
4. Generate the research report using the following markdown template:

```markdown
# Research Report

**Date:** <!-- YYYY-MM-DD -->
**Topic:** <!-- Main research topic -->
**Target Path:** <!-- Main codebase/directory/repo -->

---

## Summary

_Short summary of the research process, key findings, and overall conclusions._

---

## Codebase/Documentation Index

```
<Insert hierarchical map or outline of the explored codebase or documentation here>
```

---

## Hypotheses and Findings

| Hypothesis | Status (Proven/Disproven/Inconclusive) | Key Findings |
|------------|----------------------------------------|--------------|
| <!-- Hypothesis 1 --> | <!-- Status --> | <!-- Main findings and evidence --> |
| <!-- Hypothesis 2 --> | <!-- Status --> | <!-- ... --> |

---

## Detailed Findings

<!-- Write here your detailed research findings including code examples, key functions, file references, conclusions and assumptions -->

---

## Prior Research Considered

- <!-- Title, author, and link (if available) for each prior research document reviewed -->

---

## Recommendations & Next Steps

- <!-- Explicit actionable recommendations -->
- <!-- Important next steps -->
- <!-- Open questions and areas meriting further investigation -->
- <!-- Risks or caveats -->
```

5. Fill in all sections of the template with the consolidated findings from Stage 4.
6. Save the report file.
7. Present the completed report to the developer.

---

## Interaction Guidelines

- At each decision point (marked with **PAUSE**), stop and wait for developer input before proceeding.
- Communicate progress clearly at each stage.
- Adapt the research approach based on developer feedback.
- Maintain an evidence-based approach—support all conclusions with code examples, file references, or documentation citations.
- If uncertainties arise, surface them explicitly rather than making assumptions.
