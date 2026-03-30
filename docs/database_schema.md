# Database Schema (Supabase Source of Truth)

Updated: 2026-02-21 (auto-generated from live DB)
Supabase/PostgreSQL

---

## Core Tables

### **profiles**
User accounts linked to Supabase Auth (`auth.users`)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, FK → auth.users | User's auth ID |
| `role` | text | NOT NULL, default: 'subscriber' | subscriber, creator, admin |
| `display_name` | text | nullable | Public display name |
| `avatar_url` | text | nullable | Profile picture URL |
| `bio` | text | nullable | User bio |
| `stripe_customer_id` | text | nullable | Stripe customer reference |
| `created_at` | timestamptz | default: now() | |
| `updated_at` | timestamptz | default: now() | |

**Note:** Email is stored in `auth.users`, NOT in profiles table.

---

### **creators**
Creator profiles with approval workflow

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Creator record ID |
| `profile_id` | uuid | FK → profiles, UNIQUE, nullable | One creator per user |
| `hall_id` | uuid | FK → halls, nullable | Creator's hall |
| `slug` | text | UNIQUE, nullable | URL-friendly identifier |
| `approved` | boolean | default: false | Admin approval status |
| `created_at` | timestamptz | default: now() | |
| `updated_at` | timestamptz | default: now() | |

**Relationship:** 1 profile → 1 creator → 1 hall

---

### **halls**
Content channels/spaces owned by creators

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Hall ID |
| `creator_id` | uuid | FK → profiles, UNIQUE, NOT NULL | Hall owner (profile ID) |
| `name` | text | NOT NULL | Display name |
| `slug` | text | UNIQUE, NOT NULL | URL slug |
| `description` | text | nullable | Short description |
| `bio` | text | nullable | Detailed bio |
| `avatar_url` | text | nullable | Hall avatar image |
| `banner_url` | text | nullable | Header image |
| `links_json` | jsonb | nullable | Social links etc. |
| `price_cents` | integer | default: 300 | Subscription price (USD cents) |
| `payout_cents` | integer | default: 60 | Creator payout per sub |
| `subscriber_count` | integer | NOT NULL, default: 0 | Cached count (maintained by trigger) |
| `is_recommended` | boolean | default: false | Featured hall |
| `approved` | boolean | default: false | Admin approval |
| `created_at` | timestamptz | default: now() | |
| `updated_at` | timestamptz | default: now() | |

**Note:** `creator_id` FK points to `profiles.id`, not `creators.id`.

---

## Access & Subscriptions

### **subscriptions**
User subscriptions to halls (Stripe-powered)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Subscription ID |
| `user_id` | uuid | FK → profiles, NOT NULL | Subscriber |
| `hall_id` | uuid | FK → halls, NOT NULL | Subscribed hall |
| `stripe_sub_id` | text | UNIQUE, nullable | Stripe subscription ID |
| `stripe_price_id` | text | nullable | Price used |
| `status` | text | NOT NULL, default: 'inactive' | active, inactive, cancelled |
| `current_period_end` | timestamptz | nullable | Subscription end date |
| `cancel_at_period_end` | boolean | default: false | Will cancel at period end |
| `canceled_at` | timestamptz | nullable | Cancellation timestamp |
| `started_at` | timestamptz | nullable | First activation |
| `created_at` | timestamptz | default: now() | |

**Note:** Subscriptions are created/updated server-side only (RLS blocks all client writes).

---

### **user_access**
Global subscription access cache

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `user_id` | uuid | PK, FK → auth.users | User |
| `has_any_active_sub` | boolean | default: false | Global active flag |
| `hall_id` | uuid | FK → halls, nullable | Associated hall (if any) |
| `updated_at` | timestamptz | default: now() | Last sync |

**Purpose:** Fast global check for any active subscription. Use `subscriptions` for per-hall access.

---

### **price_to_hall**
Stripe pricing configuration

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `stripe_price_id` | text | PK | Stripe price ID |
| `hall_id` | uuid | FK → halls, NOT NULL | Associated hall |
| `currency` | text | default: 'usd' | Currency code |
| `unit_amount` | integer | nullable | Price in cents |
| `active` | boolean | default: true | Is price active |
| `created_at` | timestamptz | default: now() | |

**Note:** RLS blocks all client access — server-side only.

---

## Content Tables

### **posts**
Text posts with optional media

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Post ID |
| `scope` | text | NOT NULL | 'hall' or 'freasy' (global feed) |
| `hall_id` | uuid | FK → halls, nullable | Parent hall (required if scope='hall') |
| `author_id` | uuid | FK → profiles, NOT NULL | Post author |
| `body` | text | nullable | Post content |
| `pinned` | boolean | default: false | Sticky post |
| `hidden` | boolean | default: false | Moderation flag |
| `is_premium` | boolean | default: true | Requires subscription to view |
| `like_count` | integer | NOT NULL, default: 0 | Cached count (maintained by `toggle_post_like`) |
| `comment_count` | integer | NOT NULL, default: 0 | Cached count (maintained by trigger) |
| `created_at` | timestamptz | default: now() | |
| `updated_at` | timestamptz | default: now() | |

---

### **post_likes**
Like records for posts

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | |
| `post_id` | uuid | FK → posts, NOT NULL | Liked post |
| `user_id` | uuid | FK → profiles, NOT NULL | User who liked |
| `created_at` | timestamptz | default: now() | |

**Note:** Use `toggle_post_like(post_id)` RPC — do not insert/delete directly. Updates `posts.like_count` atomically.

---

### **post_media**
Media attachments for posts

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Media ID |
| `post_id` | uuid | FK → posts, NOT NULL | Parent post |
| `type` | text | NOT NULL | 'image' or 'video' |
| `url` | text | NOT NULL | CDN/storage URL |
| `position` | integer | default: 0 | Display order |
| `metadata` | jsonb | nullable | Dimensions, duration, etc. |
| `created_at` | timestamptz | default: now() | |

---

### **videos**
Video content via Bunny CDN

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Video ID |
| `hall_id` | uuid | FK → halls, NOT NULL | Parent hall |
| `bunny_video_id` | text | nullable | Bunny.net video ID |
| `bunny_library_id` | text | nullable | Bunny.net library ID |
| `title` | text | NOT NULL | Video title |
| `description` | text | nullable | Description |
| `status` | text | NOT NULL, default: 'uploading' | uploading, published, hidden |
| `thumbnail_url` | text | nullable | Thumbnail image |
| `duration_seconds` | integer | nullable | Video length |
| `is_preview` | boolean | default: false | Free preview (no sub required) |
| `view_count` | integer | NOT NULL, default: 0 | Cached view count |
| `created_at` | timestamptz | default: now() | |
| `updated_at` | timestamptz | default: now() | |
| `published_at` | timestamptz | nullable | Public release time |

**Note:** No direct author column — ownership inferred via `hall_id → halls.creator_id`.

---

### **comments**
Comments on posts or videos

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | uuid | PK, default: gen_random_uuid() | Comment ID |
| `post_id` | uuid | FK → posts, nullable | Parent post |
| `video_id` | uuid | FK → videos, nullable | Parent video |
| `author_id` | uuid | FK → profiles, NOT NULL | Comment author |
| `body` | text | NOT NULL | Comment text |
| `hidden` | boolean | default: false | Moderation flag |
| `created_at` | timestamptz | default: now() | |

**Note:** Set exactly one of `post_id` or `video_id`. No `parent_type`/`parent_id` columns.

---

## Admin/System Tables

### **stripe_events**
Webhook event log

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `event_id` | text | PK | Stripe event ID (idempotency key) |
| `event_type` | text | nullable | e.g. checkout.session.completed |
| `stripe_created` | timestamptz | nullable | Event timestamp from Stripe |
| `payload` | jsonb | nullable | Full event JSON |
| `processed_at` | timestamptz | default: now() | When we processed it |

**Note:** RLS blocks all client access — server-side only.

---

## Key Relationships

```
auth.users
  └─→ profiles (1:1, auto-created by handle_new_user trigger)
        ├─→ creators (1:1, optional — requires admin approval)
        │     └─→ halls (1:1, via creators.hall_id)
        │           ├─→ posts (1:many, scope='hall')
        │           │     ├─→ post_media (1:many)
        │           │     ├─→ post_likes (1:many)
        │           │     └─→ comments (1:many)
        │           ├─→ videos (1:many)
        │           │     └─→ comments (1:many)
        │           └─→ subscriptions (1:many)
        ├─→ subscriptions (1:many, as subscriber)
        ├─→ posts (1:many, scope='freasy', as author)
        ├─→ post_likes (1:many)
        └─→ comments (1:many, as author)
```

---

## Functions & Triggers

### Access Helper Functions (used in RLS policies)

| Function | Returns | Description |
|----------|---------|-------------|
| `has_any_active_sub()` | boolean | True if current user has any active subscription, OR is creator/admin |
| `has_hall_access(target_hall_id uuid)` | boolean | True if active sub to hall, OR is the hall's creator, OR is admin |
| `is_hall_creator_for(creator_id uuid)` | boolean | True if current user IS the given creator_id or owns that creator record |
| `user_owns_hall(hall_id uuid)` | boolean | True if current user is an approved creator who owns the hall |

### Callable RPCs

| Function | Returns | Description |
|----------|---------|-------------|
| `toggle_post_like(p_post_id uuid)` | boolean | Toggles like on/off, atomically updates `posts.like_count`. Returns `true` if now liked. |

### Trigger Functions

| Function | Fires On | Description |
|----------|----------|-------------|
| `handle_new_user()` | `auth.users` INSERT | Creates a `profiles` row with role='subscriber' |
| `update_updated_at()` | BEFORE UPDATE on various tables | Sets `updated_at = NOW()` |
| `update_hall_subscriber_count()` | `subscriptions` INSERT/UPDATE/DELETE | Maintains `halls.subscriber_count` |
| `update_post_comment_count()` | `comments` INSERT/DELETE | Maintains `posts.comment_count` |

---

## RLS Policy Summary

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| `profiles` | Anyone (authenticated) | — | Own row (role locked) / Admin full | — |
| `creators` | Approved + self + admin | Admin only | Admin only | Admin only |
| `halls` | Approved + own + admin | Approved creators | Own hall | Admin only |
| `posts` | Access-gated by scope/premium + creator/admin bypass | Author (creator/admin for freasy) | Own (pinned/hidden locked) / hall creator (moderation) / admin | Author / hall creator / admin |
| `post_likes` | Public | Authenticated (own user_id) | — | Own like |
| `post_media` | Access-gated via parent post | Post author | — | Post author / admin |
| `comments` | Access-gated via parent post/video + creator/admin bypass | Authenticated (with access to parent) | Own (hidden locked) / hall creator (hidden only) / admin | Own / hall creator / admin |
| `videos` | Published + preview/access gated + creator/admin bypass | Hall creator | Hall creator / admin | Hall creator / admin |
| `subscriptions` | Own or admin | **Blocked** (server-side only) | **Blocked** | **Blocked** |
| `user_access` | Own or admin | — | Own or admin | — |
| `price_to_hall` | **Blocked** | **Blocked** | **Blocked** | **Blocked** |
| `stripe_events` | **Blocked** | **Blocked** | **Blocked** | **Blocked** |

---

## Important Notes

1. **Email storage:** User emails are in `auth.users`, NOT in `profiles`
2. **halls.creator_id** FK points to `profiles.id` (not `creators.id`)
3. **Creator → Hall:** 1:1 via `creators.hall_id` and `halls.creator_id`
4. **Likes:** Always use `toggle_post_like()` RPC, never direct INSERT/DELETE on `post_likes`
5. **Cached counts:** `posts.like_count`, `posts.comment_count`, `halls.subscriber_count` are maintained by triggers — do not update manually
6. **Subscriptions:** Created/updated server-side only (Stripe webhook → edge function)
7. **Comments:** Use `post_id` OR `video_id` (never both, never neither)
8. **Videos:** status enum is `uploading`, `published`, `hidden`

---

## Test Account

- **Email:** dev@speakfreasy.ca (in `auth.users`)
- **Role:** admin (in `profiles.role`)
- `profiles.role` is a string — normalize with `.trim().toLowerCase()` before comparisons
