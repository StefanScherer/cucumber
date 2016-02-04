@cucumber-selftest @ignore
Feature: Piping correctly escapes

  Background:

    Given there is a shell

  Scenario: Alphanumeric

    When I run the command `echo -n "TEST23"`
    And I pipe the output of the command to `cat`
    Then the command should succeed
    And the output of the command should be "TEST23"

  Scenario: Double quote

    When I run the command `echo -n '"'`
    And I pipe the output of the command to `cat`
    Then the command should succeed
    And the output of the command should be '"'

  Scenario: Newline

    When I run the command `echo -e "Line 1\nLine 2"`
    And I pipe the output of the command to `cat`
    Then the command should succeed
    And the output of the command should match the regex '\ALine 1\nLine 2\n\Z'

  Scenario: Escaped value

    When I run the command `echo -n '\"'`
    And I pipe the output of the command to `cat`
    Then the command should succeed
    And the output of the command should be '\"'

  Scenario: Environment variable

    When I run the command `echo -n '$test'`
    And I pipe the output of the command to `cat`
    Then the command should succeed
    And the output of the command should be "$test"
