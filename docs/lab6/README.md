# Lab 6 — TDD, BDD & Refactoring

**Team 14 — Group 2 — Campus Maintenance Reporter** · Agile Software Engineering · SET 312

Code is in `lab6/`. Run everything from inside `lab6/`:

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate    macOS/Linux: source .venv/bin/activate
python -m pip install pytest pytest-cov behave ruff
python -m pytest -q                                   # 10 passed
python -m pytest --cov=registration --cov-report=term-missing   # 100%
python -m behave                                      # 7 scenarios passed
```

## Part A — TDD (Red → Green → Refactor)
`git log` shows the cycles: for every rule a `test:` commit (RED, the test fails), a `feat:` commit (GREEN) and, where useful, a `refactor:` commit. See `git_log.txt`.

### Task A1 — coverage
Before: `registration.py  20  1  95%  Missing: 26` (the "drop a course that is not registered" error).
Added `test_cannot_drop_course_that_is_not_registered`, which also checks the error message. After: **100%**.
Screenshot: `coverage_100.png` (text: `coverage_report.txt`).

**Does 100% coverage prove the code is correct?**
No — coverage only shows which lines the tests executed, not that the tests check the right behaviour (a test with no assertion can give 100% too).

## Part B — BDD
`lab6/features/registration.feature` has the 3 scenarios, the Scenario Outline (3 rows) and the new **Drop a registered course** scenario (Task B1). The new `@when('the student drops "{code}"')` step was written in `features/steps/registration_steps.py`.
Result (`behave_output.txt`, `behave_output.png`): **1 feature passed, 7 scenarios passed, 28 steps passed**.

## Part C — Refactoring with SOLID

### Task C1 — Smells found in `legacy_invoice.py`
| Smell | Where | Principle it breaks |
|---|---|---|
| Long `if/elif` chain on `kind` | inside the loop and again after the loop | **OCP** — a new student type means editing this function (in two places) |
| One function does 4 jobs: calculates, formats text, writes a file, prints | whole `make_invoice` | **SRP** — many reasons to change |
| Magic numbers `1200`, `0.5`, `2000`, `5000` | fee lines | Readability / hidden business rules |
| Hard-wired file I/O (`open(...)` inside the function) and `print` | last lines | **DIP** — depends on the disk and console, cannot be tested without writing files |
| File opened without `with` (`f.close()` skipped if `write` fails) | `f = open(...)` | Resource-safety smell |
| Fee computed per course although only total hours matter; string built with `+` | loop, `text = ...` | Needless complexity / readability |

### Characterization tests
`tests/test_invoice_characterization.py` was written and run **against the unchanged legacy code first** — all passed (`characterization_before_refactor.txt`), then the refactoring was done in small moves (steps 2–5), running the tests after each one (see commits).

### Task C2 — SiblingPolicy (test-first)
Commit `test: C2 ...` (RED, `KeyError: 'sibling'`) then `feat: C2 ...` (GREEN). The diff of that commit touches only `SiblingPolicy` and one `POLICIES` entry — **`make_invoice` was not changed**.

| Measure | Before | After |
|---|---|---|
| Cyclomatic complexity of `make_invoice` (Ruff C901) | 6 | 1 |
| Tests passing | 3 (characterization) | 10 total |
| Add a new student type | edit two if/elif chains | add one class + one dict entry |
| Test without writing files | not possible | yes, with `FakeWriter` |

## Part D — Gherkin scenarios for our team story
**Story: US-16** — *As a dispatcher, I want reports to be closable only when Fixed, and Urgent reports not assigned within 2 hours flagged Overdue, so that faults are not forgotten.* (see `project_scenarios.feature`)

```gherkin
Feature: Close rule and overdue flag (US-16)
  As a dispatcher
  I want reports to be closable only when Fixed, and unassigned Urgent reports flagged Overdue
  So that faults are not forgotten

  Scenario: Close a report that the technician marked Fixed          # happy path
    Given a report with status "Fixed"
    When the dispatcher closes the report
    Then the report status is "Closed"

  Scenario: Refuse to close a report that is not Fixed               # refused / error
    Given a report with status "In Progress"
    When the dispatcher closes the report
    Then the closing is refused with "only a Fixed report can be closed"
    And the report status is still "In Progress"

  Scenario Outline: Overdue flag for unassigned Urgent reports       # edge / outline
    Given an "<priority>" report created at 09:00 with status "New"
    When the time is <time>
    Then the report is <overdue>

    Examples:
      | priority | time  | overdue         |
      | Urgent   | 10:59 | not overdue     |
      | Urgent   | 11:01 | flagged Overdue |
      | Normal   | 11:01 | not overdue     |
```
