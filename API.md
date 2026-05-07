# FamilyHub API Documentation

## Supabase Endpoints

### Authentication
All auth flows go through Supabase Auth (`supabase_flutter`).

| Flow | Method | Notes |
|------|--------|-------|
| Email/Password | `supabase.auth.signInWithPassword` | Standard |
| Google Sign-In | `supabase.auth.signInWithIdToken` | ID token from `google_sign_in` |
| Sign Up | `supabase.auth.signUp` | Creates auth user + profile row |
| Sign Out | `AuthService.signOut()` | Clears Supabase, Google, and local cache |

### Database Tables

#### profiles
- Canonical user data (display_name, email, avatar_url, fcm_token, etc.)
- RLS: Users can read/update their own row.

#### families
- Family group container.
- RLS: Members can read their family.

#### family_members
- Links users to families with roles (admin/member/child).
- RLS: Users can read their family's members.

#### household_tasks
- System table with 300+ predefined tasks.
- RLS: All authenticated users can read (read-only system data).

#### task_schedules
- Family-specific task assignments.
- RLS: Users can CRUD only their family's schedules.

#### support_sessions
- Live support chat sessions.
- RLS: Users can only view/insert their own sessions.

#### messages (Chat)
- Realtime chat messages.
- RLS: Users can read messages in their family.

## RLS Policies Summary
- Every new table automatically gets RLS enabled via `rls_auto_enable` event trigger.
- All user-facing tables enforce `auth.uid()` checks.
- System tables (e.g., `household_tasks`) allow read access to all authenticated users.
