Feature: OIDC auth
  As a client application
  I want to authenticate users via OpenID Connect
  So that users can securely access my application

  Scenario: Successful OIDC authorization code flow
    Given I am a client application with client_id "client-123" and redirect_uri "https://app.example.com/callback"
    When I send a GET request to "/v1/api/oauth2/authorize?client_id=client-123&redirect_uri=https://app.example.com/callback&state=state-456&response_type=code"
    And the user logs in with email "user@example.com" and password "securepass" on the consent page
    Then I should be redirected to "https://app.example.com/callback?code=code-789&state=state-456"
    When I send a POST request to "/v1/api/oauth2/token" with JSON body {"grant_type": "authorization_code", "code": "code-789", "client_id": "client-123", "client_secret": "secret-abc", "redirect_uri": "https://app.example.com/callback"}
    Then the response status code should be 200
    And the response should include a JSON object with "access_token", "token_type": "Bearer", "expires_in": 86400, and "id_token"
    When I send a GET request to "/v1/api/oauth2/userinfo" with header "Authorization: Bearer <access_token>"
    Then the response status code should be 200
    And the response should include a JSON object with "sub": "user-123", "email": "user@example.com", "role": "user_admin"

  Scenario: Failed token exchange with invalid client_secret
    Given I am a client application with client_id "client-123"
    When I send a POST request to "/v1/api/oauth2/token" with JSON body {"grant_type": "authorization_code", "code": "code-789", "client_id": "client-123", "client_secret": "wrong-secret", "redirect_uri": "https://app.example.com/callback"}
    Then the response status code should be 400
    And the response should include a JSON object with "error": "invalid_grant"
