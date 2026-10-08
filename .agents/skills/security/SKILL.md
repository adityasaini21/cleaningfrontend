---
name: security
description: Perform a defensive security review and hardening of the NuKlean Flutter + Spring Boot application. Review authentication, authorization, APIs, database access, secrets, networking, privacy, COD order security, production configuration, dependencies, and secure coding practices. Identify security weaknesses through source-code and configuration review, then apply minimal defensive fixes without changing existing application functionality.
---

# NuKlean Defensive Security Review & Hardening

## Mission

Perform a comprehensive **defensive security review and hardening** of the NuKlean application before production launch.

The application consists of:

- Flutter mobile application
- Spring Boot backend
- REST APIs
- Relational database
- Authentication
- Authorization / RBAC
- User accounts
- Admin functionality
- Product management
- Category management
- Orders
- Cash on Delivery (COD)
- Location-based delivery charge calculation
- Production infrastructure

The objective is:

> **Improve the security of the existing NuKlean application without changing its existing functionality.**

The application must be treated as having an untrusted client architecture.

Security-sensitive rules must be enforced by the backend.

Do not claim that the application is "100% secure" or "unhackable".

Instead:

- Review the existing implementation.
- Identify security weaknesses.
- Apply appropriate defensive fixes.
- Verify the fixes.
- Preserve existing functionality.

---

# 1. CRITICAL FUNCTIONALITY PRESERVATION RULE

This is the highest-priority project constraint.

## DO NOT CHANGE EXISTING FUNCTIONALITY

The existing NuKlean application functionality must remain intact.

Do NOT:

- Add new features.
- Remove existing features.
- Redesign the UI.
- Change existing navigation.
- Change existing user flows.
- Change product functionality.
- Change category functionality.
- Change cart functionality.
- Change order functionality.
- Change COD functionality.
- Change delivery functionality.
- Change existing business rules unnecessarily.
- Change API contracts unnecessarily.
- Change database structure unnecessarily.
- Perform unrelated refactoring.
- Replace working implementations without a security reason.
- Upgrade dependencies unnecessarily.
- Modify unrelated code for style or preference.

Security changes must be:

- Minimal
- Targeted
- Defensive
- Necessary
- Tested
- Backward-compatible where possible

If a security improvement would require changing existing user-visible functionality, do not make the change silently.

Instead:

1. Explain why the security issue requires the change.
2. Explain what functionality would be affected.
3. Propose the smallest possible change.
4. Clearly identify it in the final report.

The primary objective is:

> **Secure the existing application without changing how the application works.**

---

# 2. REVIEW BEFORE MODIFYING

Do not immediately modify source code.

First inspect the project and understand the existing architecture.

Review:

- Flutter project structure
- Spring Boot project structure
- Authentication flow
- Authorization flow
- REST APIs
- Database configuration
- Entities
- DTOs
- Services
- Controllers
- Repositories
- Security configuration
- JWT implementation if present
- Admin functionality
- User functionality
- Product functionality
- Category functionality
- Cart functionality
- Order functionality
- COD flow
- Location handling
- Delivery charge calculation
- Configuration files
- Environment variables
- Logging
- Error handling
- Dependencies
- Android release configuration
- Production configuration

Do not assume the architecture.

Understand the existing implementation first.

---

# 3. DEFENSIVE SECURITY PRINCIPLE

The Flutter application is a client and must not be treated as the ultimate authority for security-sensitive information.

The backend must enforce security-sensitive rules.

Review whether the backend independently validates:

- User identity
- User ownership
- User role
- Product price
- Product availability
- Quantity
- Delivery charge
- Order total
- Payment method
- Payment status
- Order status
- Administrative permissions

Do not rely only on:

- Flutter UI restrictions
- Hidden buttons
- Client-side validation
- Client-side role checks
- Client-side price calculations

Client-side validation is useful for user experience but must not replace backend validation.

---

# 4. AUTHENTICATION REVIEW

Review the authentication implementation.

Check:

- Protected endpoints require authentication where appropriate.
- Authentication state is correctly validated.
- Invalid authentication credentials are rejected.
- Expired authentication credentials are handled correctly.
- JWT signatures are properly validated if JWT is used.
- JWT expiration is enforced.
- JWT secrets are protected.
- Passwords are never stored in plaintext.
- Passwords use a secure password hashing mechanism.
- Authentication errors do not expose sensitive information.
- Authentication tokens are not unnecessarily logged.
- Refresh-token handling is secure if refresh tokens are implemented.
- Logout/session behavior is appropriate for the existing architecture.
- Authentication-related secrets are not hardcoded.

Do not redesign the authentication system unless a serious security weakness requires it.

Preserve the existing login and registration functionality.

---

# 5. AUTHORIZATION REVIEW

Review server-side authorization carefully.

Verify that authorization is enforced for protected resources.

Check:

- Normal users can access only resources they are authorized to access.
- Users cannot access unrelated users' private data.
- Administrative functionality requires appropriate authorization.
- User roles are determined by trusted backend information.
- Client requests cannot arbitrarily change roles.
- Ownership checks are present where required.
- Administrative APIs are protected.

Pay particular attention to:

- Object ownership
- Resource access
- User IDs
- Order IDs
- Product IDs
- Administrative endpoints
- Role-based access

The backend must enforce authorization.

Do not rely on Flutter UI visibility to provide security.

---

# 6. API SECURITY REVIEW

Review all REST API controllers and endpoints.

For each endpoint determine:

- Authentication requirement
- Authorization requirement
- Accepted input
- Validation
- Returned data
- Ownership requirements
- Sensitive fields
- Error handling
- Rate-limiting considerations

Review:

- HTTP methods
- Request validation
- DTO usage
- Response DTOs
- Error responses
- Pagination
- Sensitive data exposure
- Public endpoints
- Administrative endpoints

Ensure APIs do not unnecessarily expose:

- Password hashes
- Authentication tokens
- Database credentials
- Internal identifiers
- Cost prices
- Internal administrative information
- Sensitive personal information
- Internal exception details

Do not change API behavior unless required for security.

---

# 7. INPUT VALIDATION

Review all externally supplied input.

Check:

- Request bodies
- Query parameters
- Path variables
- Headers
- User-provided text
- Quantities
- IDs
- Addresses
- Location values
- Order values

Use appropriate Spring validation mechanisms where applicable.

Prefer:

- Bean Validation
- Strongly typed DTOs
- Validation annotations
- Service-layer validation
- Repository parameterization

Avoid trusting raw client input.

Validation should not unnecessarily alter legitimate user behavior.

---

# 8. DATABASE SECURITY

Review database access.

Check:

- Database credentials
- Database connection configuration
- Repository queries
- Native SQL
- JPQL
- Entity relationships
- Ownership checks
- Sensitive fields
- Data exposure

Prefer:

- Spring Data repositories
- Parameterized queries
- JPA
- Strongly typed query parameters

Review whether user-controlled values can influence database queries unsafely.

Ensure production database credentials are not embedded in source code or Flutter.

Use least-privilege database access where practical.

Do not modify database schema unless a security issue genuinely requires it.

---

# 9. SECRETS AND CREDENTIALS REVIEW

Review the repository and configuration for accidentally exposed secrets.

Look for:

- Database passwords
- Database usernames
- JWT secrets
- API keys
- Firebase credentials
- Private keys
- Access tokens
- Cloud credentials
- SMTP credentials
- Third-party service credentials
- Hardcoded passwords
- Production secrets

Review:

- Source code
- Configuration files
- Environment configuration
- Android configuration
- Build configuration
- Flutter configuration
- Git-tracked files

Remember:

> A secret embedded inside a mobile application cannot be considered a server-side secret.

Never place backend secrets in Flutter.

If a production credential is found in source code:

1. Identify the exposure.
2. Do not print the secret in the report.
3. Recommend rotation/revocation.
4. Remove the exposure.
5. Update configuration to use secure secret management.

Do not expose secret values in terminal output or logs.

---

# 10. FLUTTER SECURITY REVIEW

Review the Flutter application for defensive security practices.

Check:

- Hardcoded credentials
- Hardcoded server secrets
- Sensitive logs
- Token storage
- Local sensitive data
- HTTP connections
- Production API configuration
- Debug functionality
- Unnecessary permissions
- Sensitive information displayed unnecessarily

Sensitive authentication credentials should use an appropriate secure storage mechanism.

Do not store backend secrets in Flutter.

Do not rely on Flutter for authorization.

Preserve the existing UI and user experience.

---

# 11. NETWORK SECURITY

Review production networking.

Production communication should use:

```text
HTTPS
```

Review for:

- HTTP production endpoints
- TLS configuration
- Disabled certificate validation
- Insecure network configuration
- Sensitive information transmitted without encryption

Do not disable TLS or certificate verification to solve development problems in production.

If development environments use HTTP, ensure production configuration remains secure without unnecessarily changing development functionality.

---

# 12. CORS REVIEW

Review Spring Boot CORS configuration.

Check:

- Allowed origins
- Allowed methods
- Allowed headers
- Credentials configuration

Avoid unnecessarily broad configurations.

Do not introduce overly restrictive CORS settings that break legitimate existing functionality.

The goal is:

> Secure the existing API while preserving legitimate application communication.

---

# 13. RATE LIMITING AND ABUSE RESISTANCE

Review whether sensitive endpoints need rate limiting.

Pay particular attention to:

- Login
- Registration
- OTP functionality if present
- Password reset
- Order creation
- Expensive API operations

Identify opportunities for appropriate defensive controls.

Do not perform credential attacks or load testing.

Do not perform denial-of-service testing.

If rate limiting is absent, document the recommendation unless implementation can be safely introduced without affecting legitimate application functionality.

---

# 14. CASH ON DELIVERY SECURITY

The current NuKlean application supports:

> **Cash on Delivery (COD) only.**

Do not add online payment functionality.

Do not introduce payment gateways.

Do not add payment SDKs.

Do not add online payment credentials.

For COD, verify that the backend remains authoritative for:

- Payment method
- Payment status
- Order status
- Product price
- Delivery charge
- Order total
- Order ownership

The client must not be treated as the authority for these security-sensitive values.

Review whether a normal user can improperly modify:

- Payment status
- Order status
- Product price
- Delivery charge
- Order total
- Order ownership
- User role

Use defensive code review and safe automated tests to verify these controls.

Do not perform destructive testing.

---

# 15. ORDER AND PRICING SECURITY

Review the order creation and order management flow.

The backend should obtain authoritative product information from the database.

Review whether the backend properly determines:

- Product existence
- Product availability
- Product price
- Quantity
- Delivery charge
- Order total
- Order ownership
- Payment method
- Payment status
- Order status

Do not blindly trust values supplied by Flutter.

The backend should calculate or independently validate security-sensitive order values.

Review whether a user can unintentionally or maliciously influence another user's order.

Do not change legitimate pricing or ordering functionality.

Only strengthen validation and authorization where required.

---

# 16. LOCATION AND PRIVACY REVIEW

Review location-related functionality.

Check:

- What location information is collected
- Why it is collected
- Where it is transmitted
- Where it is stored
- Whether it is logged
- Who can access it

Use the minimum information required for delivery functionality.

If location is used for delivery-charge calculation:

- Review client-side calculation.
- Ensure security-sensitive delivery charges are not blindly trusted.
- Preserve the existing delivery experience.

Do not expose one user's location to another user.

Do not unnecessarily store or log precise location information.

---

# 17. FILE UPLOAD REVIEW

If the application supports file uploads, review:

- File size limits
- File type validation
- MIME validation
- Filename handling
- Storage location
- Path handling
- Unsafe executable content
- Path traversal protections

Do not introduce upload functionality if it does not already exist.

Only review and secure existing upload functionality.

---

# 18. ERROR HANDLING

Review production error handling.

Production API responses should not unnecessarily expose:

- Stack traces
- Database errors
- SQL queries
- Internal file paths
- Framework internals
- Credentials
- Authentication internals

Use safe, user-appropriate error responses.

Preserve existing meaningful application errors where possible.

Do not hide legitimate business errors simply for security reasons.

---

# 19. LOGGING REVIEW

Review application logs.

Ensure logs do not unnecessarily contain:

- Passwords
- JWT tokens
- API keys
- Database credentials
- Authentication secrets
- Sensitive personal information
- Precise location information
- Internal credentials

Debug logging should not expose secrets in production.

Do not remove useful operational logging unless it creates a security or privacy problem.

---

# 20. DEPENDENCY REVIEW

Review Flutter/Dart and Java/Spring dependencies.

Check for:

- Known security issues
- Severely outdated packages
- Abandoned dependencies
- Unnecessary dependencies

Do not blindly upgrade all dependencies.

Do not perform large dependency migrations.

If a dependency has a serious security issue:

1. Identify it.
2. Determine whether a safe upgrade exists.
3. Check compatibility.
4. Upgrade only when necessary.
5. Verify that existing functionality remains intact.

---

# 21. ANDROID PRODUCTION SECURITY

Review Android release configuration.

Check:

- Release build configuration
- Debug mode
- Debug credentials
- Test endpoints
- Production HTTPS
- Unnecessary permissions
- Exported components
- Sensitive logs
- Signing configuration
- Embedded secrets

Do not change Android configuration unless necessary for security or production hardening.

Do not weaken security settings to make functionality work.

---

# 22. SPRING BOOT SECURITY REVIEW

Review:

- Spring Security configuration
- Authentication configuration
- Authorization configuration
- JWT filters
- Password encoding
- CORS
- CSRF applicability
- Exception handling
- Profiles
- Actuator configuration
- Public endpoints
- Protected endpoints

Pay particular attention to accidentally exposed:

- Administrative endpoints
- Debug endpoints
- Monitoring endpoints
- Actuator endpoints

Do not expose internal management functionality publicly unless explicitly required.

Preserve legitimate existing API behavior.

---

# 23. PRODUCTION CONFIGURATION REVIEW

Review production configuration for:

- Debug settings
- Logging levels
- Database credentials
- JWT secrets
- API keys
- CORS
- HTTPS
- Actuator
- Error responses
- External service credentials
- Development-only configuration

Ensure development configuration is not accidentally used in production.

Do not expose secret values while reporting findings.

---

# 24. OWASP-ORIENTED DEFENSIVE REVIEW

Perform a defensive review based on major OWASP security principles.

Review for:

- Broken Access Control
- Cryptographic Failures
- Injection
- Insecure Design
- Security Misconfiguration
- Vulnerable Components
- Authentication Failures
- Software/Data Integrity Failures
- Security Logging/Monitoring Failures
- SSRF where applicable

Also review mobile-specific concerns:

- Insecure local storage
- Insecure communication
- Excessive permissions
- Client-side trust
- Sensitive information leakage
- Reverse-engineering exposure

This is a **defensive source-code and configuration review**.

Do not perform destructive penetration testing.

---

# 25. SAFE SECURITY VERIFICATION

Verify defensive controls using:

- Source-code review
- Configuration review
- Unit tests
- Integration tests
- Existing application tests
- Safe local test requests
- Static analysis where available

Verify that:

- Authentication is enforced where required.
- Authorization is enforced server-side.
- Ownership checks exist.
- Sensitive fields cannot be modified through ordinary DTO binding.
- Product prices come from trusted backend data.
- Order totals are independently calculated or validated.
- Delivery charges are independently validated.
- Payment status is protected.
- Order status is protected.
- Roles are protected.
- Sensitive information is not exposed in responses.
- Secrets are not hardcoded.

Do not perform:

- Credential attacks
- Brute-force attacks
- Denial-of-service testing
- Destructive testing
- Production compromise attempts
- Data destruction
- External-system attacks

Use only safe testing appropriate for the application's own development environment.

---

# 26. SECURITY FINDING SEVERITY

Classify findings as:

## CRITICAL

Issues that could cause severe compromise such as:

- Complete authentication bypass
- Complete authorization bypass
- Major database exposure
- Remote code execution
- Major sensitive-data exposure
- Severe credential compromise

## HIGH

Serious weaknesses such as:

- Privilege escalation
- Significant authorization weakness
- Significant sensitive-data exposure
- Serious authentication weakness
- Significant API access-control problem

## MEDIUM

Security weaknesses requiring specific conditions or having limited impact.

## LOW

Minor security weaknesses or hardening opportunities.

## INFORMATIONAL

Best-practice recommendations without significant immediate security impact.

Prioritize CRITICAL and HIGH findings before production launch.

---

# 27. SECURITY FIXING PROCESS

For each confirmed security weakness:

1. Explain the root cause.
2. Identify the affected component/file.
3. Determine the smallest safe fix.
4. Apply the defensive fix.
5. Preserve existing functionality.
6. Add or update tests where practical.
7. Verify the fix.
8. Review related code for the same class of issue.

Do not perform unrelated refactoring.

Do not rewrite large sections of the application without a security reason.

Do not change working functionality merely because another implementation is preferred.

---

# 28. BEFORE MODIFYING ANY FILE

Before changing a file, ask:

1. Is this change actually required for security?
2. Is there a smaller fix?
3. Will this affect existing functionality?
4. Will this affect the Flutter UI?
5. Will this affect navigation?
6. Will this affect an existing API?
7. Will this affect the database?
8. Will this affect the order flow?
9. Will this affect COD behavior?
10. Can the change be verified safely?

Prefer the smallest safe change.

---

# 29. FUNCTIONALITY REGRESSION CHECK

After applying security fixes, verify that existing functionality still works.

Check relevant existing flows such as:

### Authentication

- Login
- Registration
- Logout
- Session/token handling

### User functionality

- Profile
- Product browsing
- Categories
- Product details
- Cart
- Order creation
- COD
- Order history

### Delivery

- Location handling
- Delivery charge calculation
- Address handling

### Admin functionality

- Product management
- Category management
- Order management
- User management where applicable

Do not redesign these flows.

The security review must not become a feature-development task.

---

# 30. NO ONLINE PAYMENT CHANGES

The application currently uses:

> Cash on Delivery only.

Do not add:

- Payment gateways
- Payment SDKs
- Online payment APIs
- Card handling
- UPI handling
- Payment credentials
- Fake payment-success logic

Online payment security will be reviewed separately when an online payment provider is actually integrated.

---

# 31. FUTURE ONLINE PAYMENT NOTE

When online payments are introduced in the future, perform a separate security review covering:

- Server-side payment verification
- Gateway signatures
- Webhooks
- Transaction IDs
- Payment amount verification
- Duplicate-payment prevention
- Idempotency
- Replay protection
- Payment-state transitions
- Refund handling
- Sensitive payment data

Do not implement these now.

---

# 32. FINAL SECURITY REPORT

After completing the defensive review and any approved fixes, provide a concise report.

## Critical Findings

List confirmed unresolved critical issues.

## High Findings

List confirmed unresolved high-severity issues.

## Medium Findings

List medium-severity findings.

## Low / Informational

List lower-risk hardening recommendations.

## Fixed

List security issues that were fixed.

For each fixed issue include:

- Root cause
- Fix
- File/component affected
- Verification performed

## Files Changed

List every file modified.

For each file explain briefly why it was changed.

## Tests Performed

List the safe security and regression tests performed.

## Functionality Verification

Confirm whether existing functionality remained unchanged.

If any functionality changed, explicitly state:

- What changed
- Why it was necessary
- Which component was affected

## Remaining Risks

List any security concerns that remain.

## Launch Recommendation

Use exactly one:

```text
READY FOR LAUNCH
```

or

```text
READY WITH LOW-RISK FINDINGS
```

or

```text
NOT READY FOR LAUNCH
```

Do not mark the application ready if a known exploitable CRITICAL or HIGH security issue remains.

---

# 33. FINAL RULES

Always follow these rules:

1. This is a defensive security review.
2. Review the application's own source code and configuration.
3. Do not perform destructive testing.
4. Do not attack external systems.
5. Do not perform credential attacks.
6. Do not perform denial-of-service testing.
7. Do not expose secrets.
8. Never trust client-controlled security-sensitive values.
9. Enforce security-sensitive rules on the backend.
10. Do not add online payments.
11. Preserve existing functionality.
12. Prefer minimal targeted fixes.
13. Do not perform unrelated refactoring.
14. Verify security fixes.
15. Verify existing functionality after changes.
16. Never claim the application is 100% secure or unhackable.

The ultimate objective is:

> **HARDEN THE EXISTING NUKLEAN APPLICATION FOR PRODUCTION WITHOUT CHANGING ITS EXISTING FUNCTIONALITY.**
