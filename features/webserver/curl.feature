@cucumber-selftest @ignore
Feature: Accessing the web server with curl

  Background:

    Given there is a shell

  Scenario: curl homepage

    When I run the command `curl http://web`
    And I pipe the output of the command to `cat`
    Then the command should succeed
    And the output of the command should contain "Your nginx container is running!"
