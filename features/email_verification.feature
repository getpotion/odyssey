Feature: Email verification
  As a registered user
  I want to verify my email address
  So that my account becomes active and I can log in

  Scenario: Successful email verification with valid token
    Given I have registered with user_id "user-123" and email "user@example.com"
    And a verification email with token "abc123" has been sent and stored
    When I access the verification link "/v1/api/users/verify/abc123"
    Then the user with user_id "user-123" should be marked as verified in the database
    And I should be redirected to the login page at "/users/login"
    And a success message "Account verified!" should be displayed

  Scenario: Failed verification with invalid token
    Given I have registered with user_id "user-123"
    When I access the verification link "/v1/api/users/verify/invalid-token"
    Then the user with user_id "user-123" should remain unverified in the database
    And I should be redirected to the login page at "/users/login"
    And an error message "Invalid or expired token" should be displayed
