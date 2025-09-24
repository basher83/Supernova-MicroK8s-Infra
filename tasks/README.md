# Generic Task Management System Template

## Overview

This is a reusable task management system template designed for any software project. It provides structured tracking for work items, dependencies, and progress across development phases. The system is technology-agnostic and can be adapted to any tech stack or project type.

## Purpose

The task system addresses several critical needs:

- **Visibility**: Clear understanding of what needs to be done and current progress
- **Dependencies**: Explicit tracking of task relationships and blockers
- **Prioritization**: P0/P1/P2 classification for resource allocation
- **Validation**: Success criteria and validation steps for each task
- **Documentation**: Detailed implementation guidance for complex tasks
- **Adaptability**: Customizable categories and validation patterns for any project type

## How to Use This Template

### 1. Copy to Your Project

```bash
# Copy the template directory to your project
cp -r ./ tasks/

# Navigate to your tasks directory
cd tasks/
```

### 2. Customize Categories

Edit `INDEX.md` to define your project-specific task categories:

```text
# Example Categories:
├── development/               # DEV tasks (setup, tooling, dependencies)
├── features/                  # FEAT tasks (new features, functionality)
├── bugs/                      # BUG tasks (bug fixes, issue resolution)
├── documentation/             # DOCS tasks (guides, documentation)
├── testing/                   # TEST tasks (tests, validation)
├── performance/               # PERF tasks (optimizations)
├── security/                  # SEC tasks (security improvements)
└── refactoring/               # REFACTOR tasks (code improvements)
```

### 3. Define Task ID Prefixes

Choose 3-4 letter prefixes for your task categories:

- **DEV** - Development setup, tooling, dependencies
- **FEAT** - New features and functionality
- **BUG** - Bug fixes and issue resolution
- **DOCS** - Documentation and guides
- **TEST** - Testing implementation and coverage
- **PERF** - Performance optimizations
- **SEC** - Security improvements
- **REFACTOR** - Code refactoring and improvements

### 4. Customize Validation Commands

Edit `template.md` to include project-specific validation commands:

```bash
# Example validation patterns (customize for your tech stack)
# For web apps: npm run build, npm run test, npm run lint
# For databases: dbt build, sqlfluff lint
# For IaC: terraform validate, packer validate
# For containers: docker build, docker-compose up
```

## Directory Structure

```text
tasks/
├── README.md                   # Project-specific documentation (adapt this template)
├── INDEX.md                    # Active task tracker and progress dashboard
├── template.md                 # Task file template (customize for your tech stack)
├── [category-1]/               # Your first task category directory
│   └── [PREFIX]-XXX-*.md       # Task files using your prefixes
├── [category-2]/               # Your second task category directory
│   └── [PREFIX]-XXX-*.md       # Task files using your prefixes
└── [category-n]/               # Additional task categories as needed
    └── [PREFIX]-XXX-*.md       # Task files using your prefixes
```

## How to Use This System

### 1. Check Current Status

Review `INDEX.md` for:

- Overall project progress percentage
- Current phase and priorities
- Task dependencies and blockers
- Critical path for completion

### 2. Select a Task

Choose tasks marked as 🔄 Ready that match your expertise and project needs:

- **DEV** tasks: Development setup, tooling, dependencies
- **FEAT** tasks: New features and functionality
- **BUG** tasks: Bug fixes and issue resolution
- **DOCS** tasks: Documentation and guides
- **TEST** tasks: Testing implementation and coverage
- **PERF** tasks: Performance optimizations
- **SEC** tasks: Security improvements
- **REFACTOR** tasks: Code refactoring and improvements

### 3. Follow Task Structure

Each task file contains:

- Clear objective and success criteria
- Step-by-step implementation guide
- Validation commands specific to your tech stack
- Dependencies and prerequisites

## Task File Format

All task files follow the structure defined in [`template.md`](template.md).

See the template file for the exact format and all required sections. The template includes placeholders for project-specific validation commands.

## Status Indicators

- 🔄 **Ready**: Task can be started immediately
- ⏸️ **Blocked**: Waiting on dependencies to complete
- 🚧 **In Progress**: Currently being worked on
- ✅ **Complete**: Task finished and validated
- ❌ **Failed**: Task encountered issues, needs revision

## Priority Levels

- **P0 (Critical)**: Must complete for core functionality to work
- **P1 (Important)**: Significant functionality or improvement
- **P2 (Nice to Have)**: Optimization or enhancement

## Generic Task Categories

### Development (DEV)

Tasks related to project setup and tooling:

- Environment configuration
- Dependency management
- Build system setup
- Development tools configuration

### Features (FEAT)

Tasks for implementing new functionality:

- User-facing features
- API endpoints
- Database schema changes
- Integration with external services

### Bug Fixes (BUG)

Tasks for resolving issues:

- Critical bug fixes
- Performance issues
- Security vulnerabilities
- User experience improvements

### Documentation (DOCS)

Tasks for creating and updating documentation:

- API documentation
- User guides
- Architecture decisions
- Implementation guides

### Testing (TEST)

Tasks for testing infrastructure:

- Unit test implementation
- Integration test setup
- Test coverage improvement
- Testing automation

### Performance (PERF)

Tasks for optimization:

- Load time improvements
- Memory usage optimization
- Database query optimization
- Bundle size reduction

### Security (SEC)

Tasks for security improvements:

- Authentication enhancements
- Authorization implementation
- Data validation improvements
- Security audit fixes

### Refactoring (REFACTOR)

Tasks for code quality improvements:

- Code organization
- Architecture improvements
- Technical debt reduction
- Legacy code modernization

## Creating New Tasks

### 1. Determine Task Category

Choose the most appropriate category:

- **DEV**: Project setup, tooling, dependencies
- **FEAT**: New features, functionality
- **BUG**: Bug fixes, issue resolution
- **DOCS**: Documentation, guides
- **TEST**: Testing, validation
- **PERF**: Performance optimizations
- **SEC**: Security improvements
- **REFACTOR**: Code improvements

### 2. Assign Task ID

Use sequential numbering with your chosen prefix:

- DEV-001, DEV-002, etc.
- FEAT-001, FEAT-002, etc.
- BUG-001, BUG-002, etc.

### 3. Use the Template

Copy `template.md` and fill in all sections:

- Keep descriptions concise and actionable
- Include specific commands and file paths for your tech stack
- Define clear success criteria
- **IMPORTANT**: Run `date +"%Y-%m-%d"` to get current date for Created/Updated fields
- Update the "Updated" field whenever status changes
- Customize validation commands for your specific tools and frameworks

### 4. Update INDEX.md

Add your task to the appropriate phase table and update:

- Task counts and time estimates
- Dependency graph if needed
- Overall completion percentage
- Project-specific phases and timelines

## Best Practices

### Task Sizing

- **Small** (1-2 hours): Single file changes, simple configurations
- **Medium** (3-4 hours): Multi-file changes, new features
- **Large** (5+ hours): Consider breaking into subtasks

### Dependencies

- List explicit task IDs that must complete first
- Use "None" for tasks that can start immediately
- Update blocked tasks when dependencies complete

### Validation

- Include specific commands to verify success for your tech stack
- Reference test files or build scripts
- Document expected output
- Customize validation for your specific tools (npm, yarn, docker, terraform, etc.)

### Documentation

- Link to relevant project documentation
- Reference external resources specific to your tech stack
- Include troubleshooting tips for your tools

## Workflow Example 1: Find and Execute Existing Task

```bash
# 1. Check current status
cat tasks/INDEX.md | rg "Ready"

# 2. Select a task
cat tasks/features/FEAT-001-*.md

# 3. Complete the work (customize commands for your tech stack)
npm install new-package
npm run build
npm test

# 4. Validate completion
npm run lint
npm run test:coverage

# 5. Update task status in INDEX.md
# Change status from 🔄 Ready to ✅ Complete
```

## Workflow Example 2: Create New Task

```bash
# 1. Check current task count and next available ID
cat tasks/INDEX.md | grep "Total Tasks"

# 2. Determine appropriate category and prefix (DEV, FEAT, BUG, etc.)
# Example: Creating a new feature task
mkdir -p tasks/features

# 3. Copy template and create new task file
cp template.md tasks/features/FEAT-010-new-feature.md

# 4. Edit the new task file with specific details
# - Update Task ID: FEAT-010
# - Add description and objective
# - Fill in implementation steps
# - Add validation commands for your tech stack
# - Set dependencies (if any)
# - Run: date +"%Y-%m-%d" for Created/Updated dates

# 5. Update INDEX.md to include the new task
# - Add to appropriate phase table
# - Update task count and completion percentage
# - Update dependency graph if needed
# - Update time estimates
```

## Integration Points

This task system integrates with your project structure:

- **Project-specific documentation**: Link to your ADRs, guides, and planning docs
- **Tech stack documentation**: Reference your framework and tool documentation
- **Deployment guides**: Include your specific deployment procedures
- **Code repositories**: Reference your source code organization

## Maintenance

- Review task status weekly
- Archive completed phases to `completed/` subdirectory
- Update time estimates based on actual completion
- Add lessons learned to task notes
- Customize categories as your project evolves

## Customization Examples

### For Web Applications (Next.js/React)

```bash
# Validation commands in template.md
npm run build
npm run lint
npm run test:coverage

# Categories: DEV, FEAT, BUG, DOCS, TEST, PERF, SEC, REFACTOR
```

### For Infrastructure Projects (Terraform/Ansible)

```bash
# Validation commands in template.md
terraform validate
terraform plan
ansible-lint playbooks/*.yml

# Categories: DEV, FEAT, BUG, DOCS, TEST, PERF, SEC, REFACTOR
```

### For Data Projects (Python/Airflow)

```bash
# Validation commands in template.md
python -m pytest tests/
black src/
isort src/

# Categories: DEV, FEAT, BUG, DOCS, TEST, PERF, SEC, REFACTOR
```

---

_For current task status and active work items, see [INDEX.md](INDEX.md)_

## Example Implementation

See [`tasks/`](tasks/) for a complete working example of the task management system in action. This includes:

- **6 example tasks** across 3 categories (DEV, FEAT, TEST)
- **Real implementation steps** with actual commands
- **Dependency management** showing how tasks block each other
- **Complete workflow** from setup to testing

### Quick Start with Example

```bash
# 1. Explore the example tasks
cat tasks/INDEX.md | head -20
cat tasks/development/DEV-001-*.md

# 2. See the dependency graph
cat tasks/INDEX.md | grep -A 10 "Task Dependencies"

# 3. Try validation commands from the tasks
cd tasks
npm run build    # Example command from DEV-003
npm test         # Example command from TEST-001
```

The example demonstrates a complete project workflow from development setup through feature implementation to testing.

---
