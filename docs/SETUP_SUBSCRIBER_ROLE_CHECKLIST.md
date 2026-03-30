# ✅ Setup Checklist: Default Subscriber Role

## What You Need to Do

### 1️⃣ Run the Database Trigger (REQUIRED)

**Where:** Supabase Dashboard → SQL Editor

**File:** [`setup_default_subscriber_role.sql`](setup_default_subscriber_role.sql)

**Action:**
1. Copy the entire contents of `setup_default_subscriber_role.sql`
2. Paste into Supabase SQL Editor
3. Click "Run"
4. Verify no errors

**What it does:**
- Automatically creates a profile row with `role = 'subscriber'` when users sign up
- Uses email prefix as default display name (e.g., `john` from `john@example.com`)

---

### 2️⃣ Test It Works

**Method 1: Sign up a new user**
1. Run the app
2. Sign up with a test email (e.g., `test-subscriber@example.com`)
3. Check the database:

```sql
SELECT p.id, u.email, p.role, p.display_name
FROM profiles p
JOIN auth.users u ON u.id = p.id
WHERE u.email = 'test-subscriber@example.com';
```

**Expected result:** `role = 'subscriber'`

**Method 2: Direct SQL test**
```sql
-- Check all recent signups
SELECT p.id, u.email, p.role, p.display_name, p.created_at
FROM profiles p
JOIN auth.users u ON u.id = p.id
ORDER BY p.created_at DESC
LIMIT 5;
```

---

### 3️⃣ Fix Existing Users (Optional)

If you have existing users with `null` or empty roles:

```sql
-- Update all users without a role to be subscribers
UPDATE profiles
SET role = 'subscriber'
WHERE role IS NULL OR role = '';

-- Verify
SELECT id, role, display_name FROM profiles;
```

---

## Code Changes Made

✅ Updated [`auth_repository.dart`](../lib/data/auth_repository.dart) to accept optional display name

**No other code changes needed** - the database trigger handles everything else automatically!

---

## How It Works

```
User signs up
    ↓
Supabase creates auth.users record
    ↓
Trigger fires: on_auth_user_created
    ↓
Function: handle_new_user() inserts into profiles
    ↓
Profile created with role = 'subscriber' ✅
```

---

## Verification Commands

```sql
-- Count users vs profiles (should match)
SELECT
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM profiles) as total_profiles;

-- Check role distribution
SELECT role, COUNT(*)
FROM profiles
GROUP BY role;

-- Find users without profiles (shouldn't exist after trigger setup)
SELECT u.id, u.email
FROM auth.users u
LEFT JOIN profiles p ON p.id = u.id
WHERE p.id IS NULL;
```

---

## Need Help?

See full documentation: [`setup_subscriber_role_guide.md`](setup_subscriber_role_guide.md)
