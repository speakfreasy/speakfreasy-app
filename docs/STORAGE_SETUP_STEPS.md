# Quick Storage Setup - Step by Step

## ✅ Simple 5-Minute Setup

### Step 1: Create Storage Bucket

1. **Open Supabase Dashboard**
2. **Go to:** Storage (left sidebar)
3. **Click:** "New bucket" button
4. **Enter details:**
   - **Name:** `hall-images`
   - **Public bucket:** ✅ **Check this box** (important!)
   - **File size limit:** 5 MB
   - **Allowed MIME types:** Leave default or add `image/*`
5. **Click:** "Create bucket"

✅ **Done!** Your bucket is ready.

---

### Step 2: Test the Bucket

1. **Click** on the `hall-images` bucket
2. **Create folders:**
   - Click "Create folder" → Name: `avatars` → Create
   - Click "Create folder" → Name: `banners` → Create
3. **Upload test image:**
   - Go to `avatars` folder
   - Click "Upload file"
   - Select any JPG/PNG image
   - Upload
4. **Get URL:**
   - Click on the uploaded image
   - Click "Copy URL"
   - Should look like: `https://xxxxx.supabase.co/storage/v1/object/public/hall-images/avatars/filename.jpg`
5. **Test URL:**
   - Paste URL in browser
   - Image should display ✅

---

### Step 3: Update Your Hall (Optional Test)

If you want to test with your existing hall:

```sql
-- Update The Jazz Lounge with test images
UPDATE halls
SET
  avatar_url = 'YOUR_COPIED_URL_HERE',
  bio = 'Welcome to The Jazz Lounge - smooth jazz and soulful vibes.',
  description = 'Premium jazz content'
WHERE slug = 'the-jazz-lounge';

-- Check it worked
SELECT name, avatar_url, bio FROM halls WHERE slug = 'the-jazz-lounge';
```

---

### Step 4: Run the App

1. **Restart your Flutter app**
2. **Go to:** `/halls`
3. **Click:** "The Jazz Lounge"
4. **Verify:**
   - Hall name shows "The Jazz Lounge" ✅
   - Avatar shows your test image ✅
   - Bio shows your description ✅

---

## 🎯 What's Next?

Once storage is working, I'll build the **Creator Controls** so creators can:
- ✏️ Edit hall name, bio, description
- 📸 Upload avatar & banner from the app
- 💰 Update pricing
- 📊 View stats

---

## ❓ Troubleshooting

**Problem:** "Bucket not found" error
**Solution:** Make sure you named it exactly `hall-images` (lowercase, with dash)

**Problem:** "Access denied" when uploading
**Solution:** Make sure "Public bucket" checkbox was checked during creation

**Problem:** Image URL doesn't work
**Solution:** Verify the bucket is set to "Public" in bucket settings

**Problem:** Can't see uploaded image in app
**Solution:**
1. Hard refresh the app (stop and restart)
2. Check the database has the correct `avatar_url` value
3. Verify URL works when pasted directly in browser

---

## 📝 Notes

- **Free tier:** 1 GB storage (plenty for development)
- **File naming:** App will use `{hall-id}.jpg` for consistency
- **Overwriting:** Uploading same filename replaces old image (by design)
- **CDN:** Supabase automatically caches images for fast loading
