Feature: User registration
  As a new user
  I want to register an account
  So that I can access the Potion PaaS

  Scenario: Successful registration with valid details
    Given I am on the registration interface
    When I submit a registration request with user_id "user-123", email "user@example.com", and password "securepass"
    Then the system should respond with a 201 status code
    And the response should include the message "User registered. Please verify your email."
    And a verification email should be sent to "user@example.com" containing a unique verification token

  Scenario: Registration with existing user_id
    Given a user with user_id "user-123" already exists in the database
    When I submit a registration request with user_id "user-123", email "newuser@example.com", and password "newpass"
    Then the system should respond with a 400 status code
    And the response should include an error message "User ID already exists"

  Scenario: Registration with existing email
    Given a user with email "user@example.com" already exists in the database
    When I submit a registration request with user_id "user-456", email "user@example.com", and password "newpass"
    Then the system should respond with a 400 status code
    And the response should include an error message "Email already exists"
