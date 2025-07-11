#!/bin/bash
cd /Users/austinrathe/Documents/Developer/BarkPark

# Add all changes
git add -A

# Create detailed commit message
git commit -m "feat: Complete password reset implementation with email service

Backend Implementation:
- Add database migration (008) for reset_token and reset_token_expires columns
- Create EmailService using nodemailer with Ethereal (dev) and SMTP (prod) support
- Implement password reset endpoints:
  - POST /api/auth/forgot-password - Request reset with email validation
  - POST /api/auth/reset-password - Reset with token and new password
  - GET /api/auth/verify-reset-token - Validate token before reset
- Add User model methods for secure token generation (64-char hex)
- Implement 1-hour token expiration with automatic cleanup
- Add comprehensive test suite with 12 tests covering all scenarios
- Support rate limiting structure (simplified for MVP)

iOS Implementation:
- Create PasswordResetViewModel with validation logic
- Build ForgotPasswordView with email input and validation
- Build ResetPasswordView with token entry and password fields
- Add password visibility toggle and requirements display
- Integrate \"Forgot Password?\" link in LoginView
- Add API methods for all reset endpoints with proper error handling
- Support automatic login after successful password reset

Technical Fixes:
- Fix nodemailer import (createTransport vs createTransporter)
- Downgrade nodemailer from v7 to v6.10.1 for compatibility
- Update iOS onChange to new iOS 17 syntax
- Add migration to unified-migrate.js runner
- Apply migration to test database for test suite

Configuration:
- Development uses Ethereal Email automatically (preview URLs in console)
- Production requires SMTP env vars in Railway dashboard
- Updated .env.example with SMTP configuration template
- Added SMTP variables to CLAUDE.md production requirements

Security:
- Email enumeration protection (always returns success)
- Secure random token generation using crypto.randomBytes
- Tokens cleared after successful use
- Password minimum 6 characters with confirmation

The password reset flow is now fully functional end-to-end, with proper
error handling, user feedback, and security considerations.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push origin main