Feature: User login
  As a user
  I want to log in via a web interface
  So that I can obtain an API token for accessing the Potion PaaS

  Scenario: Successful login without 2FA
    Given I have a verified account with user_id "user-123" and email "user@example.com"
    When I navigate to the login page at "/users/login"
    And I submit the form with email "user@example.com", password "securepass", and a generated token_id "token-456"
    Then I should be redirected to the home page at "/"
    And a JWT should be available by polling "/v1/api/users/login/poll/token-456" with a 200 status code and a "token" field

  Scenario: Successful login with 2FA
    Given I have a verified account with 2FA enabled for user_id "user-123"
    When I navigate to the login page at "/users/login"
    And I submit the form with email "user@example.com", password "securepass", and a generated token_id "token-789"
    Then I should be redirected to the 2FA verification page at "/users/2fa"
    When I submit a valid 2FA code "123456" on the verification page
    Then a JWT should be available by polling "/v1/api/users/login/poll/token-789" with a 200 status code and a "token" field

  Scenario: Failed login with invalid credentials
    Given I have a verified account with user_id "user-123"
    When I navigate to the login page at "/users/login"
    And I submit the form with email "user@example.com", password "wrongpass", and a generated token_id "token-abc"
    Then I should remain on the login page
    And an error message "Invalid credentials" should be displayed
    And no JWT should be available by polling "/v1/api/users/login/poll/token-abc" which returns a 404 status code with "error": "Token not ready"
