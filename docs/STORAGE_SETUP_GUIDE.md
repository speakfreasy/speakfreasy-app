# Supabase Storage Setup Guide

## Overview

Speakfreasy uses **Supabase Storage** for hosting images (hall avatars, banners, user avatars).

### Benefits:
- ✅ Built-in CDN for fast delivery
- ✅ Automatic image optimization
- ✅ Public URLs for easy access
- ✅ Row Level Security (RLS) for access control
- ✅ Direct upload from Flutter app

---

## Setup Steps

### 1. Create Storage Buckets (Supabase Dashboard)

**Go to:** Supabase Dashboard → Storage → Create Bucket

#### Bucket 1: `hall-images`
- **Name:** `hall-images`
- **Public:** ✅ Yes (images need to be publicly accessible)
- **File size limit:** 5 MB (recommended)
- **Allowed MIME types:** `image/jpeg`, `image/png`, `image/webp`, `image/gif`

**Folder Structure:**
```
hall-images/
  ├── avatars/
  │   └── {hall-id}.jpg
  └── banners/
      └── {hall-id}.jpg
```

#### Bucket 2: `profile-images` (Optional)
- **Name:** `profile-images`
- **Public:** ✅ Yes
- **For:** User profile avatars (future use)

---

### 2. Set Up RLS Policies (SQL)

**Go to:** Supabase Dashboard → SQL Editor

**Run:** [setup_supabase_storage.sql](setup_supabase_storage.sql)

This creates policies for:
- ✅ Public read access (anyone can view)
- ✅ Authenticated upload (logged-in users can upload)
- ✅ Owner update/delete (users can manage their own uploads)

---

### 3. Get Storage URL

Your storage URL format will be:
```
https://{project-ref}.supabase.co/storage/v1/object/public/hall-images/{path}
```

Example:
```
https://abc123.supabase.co/storage/v1/object/public/hall-images/avatars/hall-uuid.jpg
```

---

## File Naming Convention

### Hall Avatars:
- **Path:** `hall-images/avatars/{hall-id}.jpg`
- **Example:** `hall-images/avatars/43daf2f1-4cab-43e6-befe-6f026ec7cdb4.jpg`

### Hall Banners:
- **Path:** `hall-images/banners/{hall-id}.jpg`
- **Example:** `hall-images/banners/43daf2f1-4cab-43e6-befe-6f026ec7cdb4.jpg`

**Benefits of this approach:**
- ✅ Unique filenames (using hall UUID)
- ✅ Easy to find images by hall ID
- ✅ Overwriting old images when updating (same filename)

---

## File Upload Flow

```
Creator selects image
    ↓
App validates file (size, type)
    ↓
Upload to Supabase Storage
    ↓
Get public URL
    ↓
Save URL to halls.avatar_url or halls.banner_url
    ↓
Display image in UI
```

---

## Testing

### Upload Test Image:
1. Go to Supabase Dashboard → Storage → `hall-images`
2. Create folder: `avatars`
3. Upload test image: `test.jpg`
4. Copy public URL
5. Verify you can access it in browser

### In SQL:
```sql
-- Update hall with test image URL
UPDATE halls
SET avatar_url = 'https://your-project.supabase.co/storage/v1/object/public/hall-images/avatars/test.jpg'
WHERE slug = 'the-jazz-lounge';

-- Verify
SELECT name, avatar_url FROM halls WHERE slug = 'the-jazz-lounge';
```

---

## Next: Build Upload UI

Once buckets are created, we'll build:
1. `StorageRepository` - Handles uploads to Supabase Storage
2. `ImagePickerWidget` - UI for selecting/uploading images
3. `HallSettingsScreen` - Creator controls for managing hall

---

## Cost Notes

**Supabase Free Tier:**
- ✅ 1 GB storage
- ✅ 2 GB bandwidth/month
- ✅ 50 MB file size limit

**Upgrade when:**
- Storage exceeds 1 GB
- Bandwidth exceeds 2 GB/month
- Need larger file uploads

For early development, free tier is more than enough!

---

## Troubleshooting

### "Infinite recursion detected in policy for relation halls" (avatar/update fails)

When uploading a hall avatar or updating hall details, Supabase may return:

`PostgrestException(message: infinite recursion detected in policy for relation "halls", code: 42P17)`

This is caused by the **RLS (Row Level Security) policy** on the `halls` table referencing `halls` again (e.g. via a JOIN or subquery), so Postgres re-evaluates the same policy and hits a loop.

**Fix:** Run the SQL in [docs/fix_halls_rls_recursion.sql](fix_halls_rls_recursion.sql) in the Supabase Dashboard → SQL Editor. It drops the recursive UPDATE policy and adds a safe policy that checks ownership only via the `creators` table (no read from `halls`), so recursion is removed.
