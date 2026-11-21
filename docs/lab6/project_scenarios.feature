Feature: Close rule and overdue flag (US-16)
  As a dispatcher
  I want reports to be closable only when Fixed, and unassigned Urgent reports flagged Overdue
  So that faults are not forgotten

  Scenario: Close a report that the technician marked Fixed
    Given a report with status "Fixed"
    When the dispatcher closes the report
    Then the report status is "Closed"

  Scenario: Refuse to close a report that is not Fixed
    Given a report with status "In Progress"
    When the dispatcher closes the report
    Then the closing is refused with "only a Fixed report can be closed"
    And the report status is still "In Progress"

  Scenario Outline: Overdue flag for unassigned Urgent reports
    Given an "<priority>" report created at 09:00 with status "New"
    When the time is <time>
    Then the report is <overdue>

    Examples:
      | priority | time  | overdue         |
      | Urgent   | 10:59 | not overdue     |
      | Urgent   | 11:01 | flagged Overdue |
      | Normal   | 11:01 | not overdue     |
