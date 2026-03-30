-- Check current data for "The Jazz Lounge"
SELECT
  h.id,
  h.name,
  h.slug,
  h.description,
  h.bio,
  h.banner_url,
  h.price_cents,
  h.subscriber_count,
  p.display_name as creator_name,
  p.avatar_url as creator_avatar,
  p.bio as creator_bio
FROM halls h
JOIN creators c ON c.hall_id = h.id
JOIN profiles p ON p.id = c.profile_id
WHERE h.slug = 'the-jazz-lounge';
