# Hall UI Audit - Current State

## Database Fields Available

### From `halls` table:
- `id` - Hall UUID
- `name` - Hall name (e.g., "The Jazz Lounge")
- `slug` - URL slug (e.g., "the-jazz-lounge")
- `description` - Short description
- `bio` - Detailed bio
- `banner_url` - Header/banner image URL
- `price_cents` - Subscription price
- `subscriber_count` - Number of subscribers
- `approved` - Admin approval status

### From `creators` table (via join):
- `profile_id` - Creator's user ID
- `approved` - Creator approval status

### From `profiles` table (creator's profile, via join):
- `display_name` - Creator's name (e.g., "creator")
- `avatar_url` - Creator's avatar image
- `bio` - Creator's personal bio (NOT hall bio)

---

## Screen 1: Halls List (`/halls`)

**File:** [halls_screen.dart](../lib/ui/screens/halls_screen.dart)

### What's Displayed:

| UI Element | Current Source | Line | Should Be |
|------------|---------------|------|-----------|
| Hall card avatar | `profile.avatar_url` (creator's avatar) | 71 | Could be hall-specific or creator's |
| Hall card title | `hall.name` ✅ | 82 | ✅ Correct |
| Hall card subtitle | `profile.display_name` (creator name) ✅ | 87 | ✅ Correct |
| Subscriber count | `hall.subscriber_count` ✅ | 100 | ✅ Correct |
| Price | `hall.price_cents` ✅ | 105 | ✅ Correct |

**Status:** ✅ Halls list is displaying correctly!

---

## Screen 2: Hall Interior (`/hall/:slug`)

**File:** [hall_interior_screen.dart](../lib/ui/screens/hall_interior_screen.dart)

### What's Displayed:

| UI Element | Current Source | Line | Should Be | Issue |
|------------|---------------|------|-----------|-------|
| **Banner** | Gradient placeholder | 72-86 | `hall.banner_url` | ❌ Not using hall banner |
| **Avatar** | `profile.avatar_url` (creator) | 94 | `profile.avatar_url` OR hall avatar | ⚠️ Could add hall avatar |
| **Display Name** | `profile.display_name` (creator) | 108 | `hall.name` | ❌ Shows "creator" instead of "The Jazz Lounge" |
| **Handle/Slug** | `@{slug}` ✅ | 126 | ✅ Correct | |
| **Subscriber count** | `hall.subscriber_count` ✅ | 126 | ✅ Correct | |
| **Bio** | `profile.bio` (creator's bio) | 131 | `hall.bio` OR `hall.description` | ❌ Shows creator bio, not hall bio |
| **Subscribe button** | Shows if not subscribed ✅ | 137 | ✅ Correct | |
| **Tabs** | Posts, Videos, Chat ✅ | 164-184 | ✅ Correct | |

---

## Issues Summary

### ❌ Critical Issues (Hall Interior Screen):

1. **Line 108:** Display name shows **creator's name** instead of **hall name**
   - Currently: `profile.display_name` ("creator")
   - Should be: `hall.name` ("The Jazz Lounge")

2. **Line 131:** Bio shows **creator's bio** instead of **hall bio**
   - Currently: `profile.bio` (null → "No bio available")
   - Should be: `hall.bio` or `hall.description`

3. **Lines 72-86:** Banner is **placeholder gradient** instead of hall banner
   - Currently: Hardcoded gradient
   - Should be: `hall.banner_url` with fallback to gradient

### ⚠️ Potential Enhancements:

4. **Avatar:** Currently shows creator's avatar
   - Could add a dedicated `hall.avatar_url` field in future
   - For now, creator's avatar is probably fine

---

## Data Flow

```
Database (halls table)
  ↓
hallRepository.getHallBySlug(slug)
  ↓
Returns: {
  id, name, slug, description, bio, banner_url, price_cents, subscriber_count,
  creators: [{
    profile_id, approved,
    profiles: { display_name, avatar_url, bio }
  }]
}
  ↓
hall_interior_screen.dart
  ↓
Extracts: creator → profiles
  ↓
❌ Uses profile.display_name instead of hall.name
❌ Uses profile.bio instead of hall.bio
❌ Ignores hall.banner_url
```

---

## Database Check - Hall Data

Run this to see what data exists for "The Jazz Lounge":

```sql
SELECT
  h.name,
  h.slug,
  h.description,
  h.bio,
  h.banner_url,
  h.price_cents,
  h.subscriber_count,
  p.display_name as creator_name,
  p.bio as creator_bio
FROM halls h
JOIN creators c ON c.hall_id = h.id
JOIN profiles p ON p.id = c.profile_id
WHERE h.slug = 'the-jazz-lounge';
```

---

## Next Steps

1. ✅ Audit complete
2. 🔧 Fix hall interior screen to use correct data fields
3. 🎨 Add hall banner image support
4. 🛠️ Build creator controls (separate task)
