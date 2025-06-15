Feature: 2FA recovery
  As a user who has lost access to my authenticator app
  I want to recover access to my account
  So that I can regain control without relying on SMS

  Scenario: Successful recovery using a recovery code
    Given I have a verified account with 2FA enabled for user_id "user-123"
    And I have recovery codes ["ABCD-1234", "EFGH-5678"] stored in the database
    When I send a POST request to "/v1/api/users/2fa/recovery" with JSON body {"recovery_code": "ABCD-1234"}
    Then the response status code should be 200
    And the response should include a JSON object with a "token" field containing a valid JWT
    And the recovery code "ABCD-1234" should be marked as used in the database
    And I should be able to use the token to access protected resources

  Scenario: Failed recovery with invalid recovery code
    Given I have a verified account with 2FA enabled for user_id "user-123"
    When I send a POST request to "/v1/api/users/2fa/recovery" with JSON body {"recovery_code": "INVALID-5678"}
    Then the response status code should be 400
    And the response should include a JSON object with "error": "Invalid or used recovery code"
    And the account should remain inaccessible without a valid code

  Scenario: Successful recovery via email request
    Given I have a verified account with user_id "user-123" and 3 failed 2FA attempts
    When I send a POST request to "/v1/api/users/2fa/recovery/email" with JSON body {"email": "user@example.com"}
    Then the response status code should be 200
    And the response should include a JSON object with "message": "Recovery email sent."
    And a recovery email should be sent to "user@example.com" with a unique link or code
    When I follow the recovery link or enter the code
    Then I should be able to log in and reset my 2FA setup
