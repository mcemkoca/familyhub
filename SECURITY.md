# 🔒 Security Policy

## Supported Versions

The following versions of FamilyHub are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Features

FamilyHub implements multiple layers of security to protect user data:

### 🔐 Data Protection
- **Compile-time Obfuscation**: All API keys and secrets are obfuscated using [`envied`](https://pub.dev/packages/envied) with XOR encryption
- **Secure Storage**: Sensitive tokens stored via [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) (Android Keystore / iOS Keychain)
- **Local Database Encryption**: Hive local cache encrypted with AES-256 cipher
- **Biometric Authentication**: Fingerprint / Face ID supported via `local_auth`

### 🛡️ Network Security
- **HTTPS-only**: All API communications enforce TLS 1.2+
- **SSL Pinning**: Certificate pinning implemented for critical endpoints
- **Supabase RLS**: Row Level Security policies protect database access
- **No HTTP Fallback**: Plain HTTP requests are explicitly blocked

### 🔑 Authentication & Authorization
- **JWT-based Auth**: Supabase JWT tokens with automatic refresh
- **PIN Protection**: Child accounts secured with SHA-256 hashed PINs
- **Admin Gates**: Server-side RPC verification for admin/premium features
- **Session Timeout**: Automatic logout after configurable inactivity period

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### 📧 Contact
- **Email**: `security@mcemkoca.dev` (preferred for sensitive issues)
- **GitHub**: Create a [Security Advisory](https://github.com/mcemkoca/familyhub/security/advisories/new) (for non-critical issues)

### 📝 What to Include
1. **Description**: Clear explanation of the vulnerability
2. **Impact**: Who is affected and what data is at risk
3. **Reproduction**: Step-by-step instructions to reproduce
4. **Proof of Concept**: Minimal code/screenshots if applicable
5. **Suggested Fix**: If you have one, we'd love to see it

### ⏱️ Response Timeline

| Phase | Timeline |
|-------|----------|
| Acknowledgment | Within 48 hours |
| Initial Assessment | Within 5 business days |
| Fix & Verification | Within 30 days (critical: 7 days) |
| Public Disclosure | Coordinated with reporter |

### 🙏 Disclosure Policy
- **Responsible Disclosure**: We follow coordinated disclosure. Please do not publicly disclose vulnerabilities until a fix is released.
- **No Legal Action**: We will not take legal action against researchers who act in good faith.
- **Hall of Fame**: With your permission, we will acknowledge your contribution in our release notes.

## Security Checklist for Contributors

Before submitting code, please verify:

- [ ] No hardcoded secrets or API keys in source files
- [ ] All database queries use parameterized APIs (no raw SQL)
- [ ] User input is validated before processing
- [ ] RLS policies are reviewed for new tables
- [ ] No `print()` statements with sensitive data
- [ ] Error messages don't leak internal paths or stack traces
- [ ] File uploads validate MIME types and paths

## Security Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)

---

*Last updated: 2026-05-08*
