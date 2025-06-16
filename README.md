# Odyssey

Odyssey is an Identity and Access Management (IAM) service designed for Potion, providing secure user authentication, authorization, and account management capabilities.

## Features

- User registration and email verification
- Secure password-based authentication
- Two-factor authentication (2FA) using TOTP
- JWT-based session management
- Recovery codes for 2FA backup
- API-first design with comprehensive documentation

## Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- PostgreSQL 15+
- SMTP server for email delivery

## Installation

1. Clone the repository:
```bash
git clone https://github.com/getpotion/odyssey.git
cd odyssey
```

2. Install dependencies:
```bash
mix deps.get
```

3. Set up the database:
```bash
mix ecto.create
mix ecto.migrate
```

4. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. Start the server:
```bash
mix phx.server
```

## Configuration

Key environment variables:

```env
# Database
DATABASE_URL=postgres://user:pass@localhost/odyssey_dev

# JWT
JWT_SECRET=your-secret-key
JWT_ISSUER=odyssey

# Email
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=user
SMTP_PASSWORD=pass
SMTP_FROM=noreply@example.com

# Application
HOST=localhost
PORT=4000
```

## API Endpoints

### Authentication

#### Register User
```http
POST /v1/api/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}
```

Response:
```json
{
  "message": "Registration successful. Please check your email to verify your account."
}
```

#### Verify Email
```http
GET /v1/api/verify-email/:token
```

Response:
```json
{
  "message": "Email verified successfully"
}
```

#### Login Init
```http
POST /v1/api/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password"
}
```

Response (2FA disabled):
```json
{
  "token_id": "abc123",
  "requires_2fa": false
}
```

Response (2FA enabled):
```json
{
  "token_id": "abc123",
  "requires_2fa": true
}
```

#### Login Poll
```http
GET /v1/api/login/poll/:token_id
```

Response (when ready):
```json
{
  "token": "jwt_token_here"
}
```

Response (when pending):
```json
{
  "errors": {
    "detail": "Token not ready"
  }
}
```

#### Verify 2FA
```http
POST /v1/api/login/verify-2fa
Content-Type: application/json

{
  "token_id": "abc123",
  "code": "123456"
}
```

Response:
```json
{
  "token": "jwt_token_here"
}
```

### 2FA Management

#### Setup 2FA
```http
GET /v1/api/2fa/setup
```

Response:
```json
{
  "secret": "JBSWY3DPEHPK3PXP",
  "qr_code": "otpauth://totp/..."
}
```

#### Verify 2FA Setup
```http
POST /v1/api/2fa/setup/verify
Content-Type: application/json

{
  "code": "123456"
}
```

Response:
```json
{
  "message": "2FA enabled successfully",
  "recovery_codes": ["CODE1", "CODE2"]
}
```

#### Disable 2FA
```http
POST /v1/api/2fa/disable
Content-Type: application/json

{
  "code": "123456"
}
```

Response:
```json
{
  "message": "2FA disabled successfully"
}
```

#### Recover 2FA with Recovery Code
```http
POST /v1/api/users/2fa/recovery
Content-Type: application/json

{
  "token_id": "abc123",
  "recovery_code": "ABCD-1234"
}
```

Response:
```json
{
  "token": "jwt_token_here"
}
```

#### Request 2FA Recovery via Email
```http
POST /v1/api/users/2fa/recovery/email
Content-Type: application/json

{
  "email": "user@example.com"
}
```

Response:
```json
{
  "message": "Recovery email sent."
}
```

#### Complete 2FA Recovery
```http
POST /v1/api/users/2fa/recovery/:token
```

Response:
```json
{
  "token": "jwt_token_here",
  "message": "2FA has been disabled. Please set up 2FA again for security."
}
```

## User Flows

### Registration Flow
1. User submits registration with email and password
2. System creates unverified user account
3. System sends verification email
4. User clicks verification link
5. Account is verified and ready for login

### Login Flow (2FA Disabled)
1. User submits email and password
2. System validates credentials
3. System generates JWT token
4. User receives token for API access

### Login Flow (2FA Enabled)
1. User submits email and password
2. System validates credentials
3. System generates pending token
4. User submits 2FA code
5. System validates 2FA code
6. System generates JWT token
7. User receives token for API access

### 2FA Setup Flow
1. User initiates 2FA setup
2. System generates TOTP secret and QR code
3. User scans QR code with authenticator app
4. User submits verification code
5. System validates code and enables 2FA
6. System provides recovery codes
7. User stores recovery codes securely

## Security Considerations

- Passwords are hashed using bcrypt
- JWT tokens are signed with a secure secret
- 2FA uses TOTP (Time-based One-Time Password)
- Recovery codes are provided for 2FA backup
- Email verification required for account activation
- Rate limiting on authentication endpoints
- Secure session management

## Development

### Running Tests
```bash
mix test
```

### Code Quality
```bash
mix credo --strict
```

### Documentation
```bash
mix docs
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
