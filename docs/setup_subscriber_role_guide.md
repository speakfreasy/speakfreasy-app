# Setting Up Default Subscriber Role

This guide explains how to ensure all new users are automatically assigned the `subscriber` role when they sign up.

## Current Status

✅ **Database schema** already has `role` column with default: `'subscriber'` (see [database_schema.md](database_schema.md))

## Required Setup

### Option 1: Database Trigger (Recommended)

This is the **cleanest approach** - automatically creates a profile with `subscriber` role when a user signs up.

**Steps:**
1. Open your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Run the SQL script in [`setup_default_subscriber_role.sql`](setup_default_subscriber_role.sql)
4. Test by signing up a new user

**What it does:**
- Creates a PostgreSQL function `handle_new_user()` that inserts a profile row
- Sets up a trigger on `auth.users` that fires after each new signup
- Automatically sets `role = 'subscriber'` and creates a default display name

**Verification:**
```sql
-- Check recent signups
SELECT p.id, u.email, p.role, p.display_name, p.created_at
FROM profiles p
JOIN auth.users u ON u.id = p.id
ORDER BY p.created_at DESC
LIMIT 10;
```

---

### Option 2: Application-Level Fallback

If you can't set up the database trigger, you can handle profile creation in the Flutter app (but this is less reliable).

**Pros:** No database changes needed
**Cons:** If trigger fails or user closes app before profile creation, they'll have no profile

This would require modifying [`auth_repository.dart`](../lib/data/auth_repository.dart) to:
1. Call `signUp()`
2. Immediately insert into `profiles` table with `role = 'subscriber'`

---

## Testing

After setting up the trigger:

1. **Sign up a new test user** in the app
2. **Run this SQL query** in Supabase Dashboard:
   ```sql
   SELECT p.id, u.email, p.role, p.display_name
   FROM profiles p
   JOIN auth.users u ON u.id = p.id
   WHERE u.email = 'your-test-email@example.com';
   ```
3. **Verify** that `role` is `'subscriber'`
4. **Log in** with the test user and confirm they have subscriber access

---

## Role Hierarchy

| Role | Default | Description |
|------|---------|-------------|
| `subscriber` | ✅ | Default role for all new users |
| `creator` | ❌ | Requires admin approval (`creators.approved = true`) |
| `admin` | ❌ | Must be manually set by admin |

---

## Troubleshooting

**Problem:** New users have `null` role
**Solution:** The database trigger is not set up. Run [`setup_default_subscriber_role.sql`](setup_default_subscriber_role.sql)

**Problem:** Trigger exists but role is still `null`
**Solution:** Check if the profile row is being created at all:
```sql
SELECT COUNT(*) FROM profiles;
SELECT COUNT(*) FROM auth.users;
```
If counts don't match, the trigger isn't firing - check trigger permissions.

**Problem:** Old users have `null` role
**Solution:** Manually update existing users:
```sql
UPDATE profiles
SET role = 'subscriber'
WHERE role IS NULL OR role = '';
```
