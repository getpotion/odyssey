Feature: 2FA setup
  As a user
  I want to enable two-factor authentication
  So that my account is more secure

  Scenario: Successful 2FA setup
    Given I am logged in with user_id "user-123"
    When I navigate to the 2FA setup page at "/users/2fa/setup"
    And I scan the provided QR code with an authenticator app
    And I submit a valid TOTP code "123456"
    Then the user with user_id "user-123" should have two_factor_enabled set to true in the database
    And a set of recovery codes should be generated and stored
    And I should be redirected to the home page at "/"
    And a success message "2FA enabled successfully" should be displayed

  Scenario: Failed 2FA setup with invalid code
    Given I am logged in with user_id "user-123"
    When I navigate to the 2FA setup page at "/users/2fa/setup"
    And I submit an invalid TOTP code "000000"
    Then the user with user_id "user-123" should remain with two_factor_enabled set to false in the database
    And I should remain on the 2FA setup page
    And an error message "Invalid 2FA code" should be displayed
