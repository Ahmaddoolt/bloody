-- Priority Notification Fix + Supabase pg_cron Reminder Setup
-- Run this script in the Supabase SQL Editor (Dashboard → SQL Editor → New Query)

-- ============================================================
-- 1. Enable pg_cron extension (already enabled on Supabase by default)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================
-- 2. Create the periodic reminder function
--    Inserts a notification row for every active donor/receiver
--    who hasn't received a reminder in the last 4 days.
-- ============================================================
CREATE OR REPLACE FUNCTION send_periodic_reminder()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO notifications (user_id, title, body, type, is_read)
  SELECT
    id,
    'تذكير: التبرع بالدم ينقذ الأرواح 🩸',
    'هل أنت مستعد للتبرع؟ تبرعك بالدم يمكن أن ينقذ حياة شخص يحتاجك الآن. انضم إلينا اليوم!',
    'reminder',
    false
  FROM profiles
  WHERE user_type IN ('donor', 'receiver')
    AND id NOT IN (
      -- Skip users who already received a reminder in the last 4 days
      SELECT DISTINCT user_id
      FROM notifications
      WHERE type = 'reminder'
        AND created_at > NOW() - INTERVAL '4 days'
    );
END;
$$;

-- ============================================================
-- 3. Schedule the job every 4 days at 10:00 AM UTC
--    Runs on days 1, 5, 9, 13, 17, 21, 25, 29 of each month.
--    The duplicate guard above prevents double-sending if the
--    schedule drifts slightly near month boundaries.
-- ============================================================

-- Remove existing job first (idempotent re-run)
SELECT cron.unschedule('blood-donation-reminder');

SELECT cron.schedule(
  'blood-donation-reminder',
  '0 10 1,5,9,13,17,21,25,29 * *',
  'SELECT send_periodic_reminder()'
);

-- ============================================================
-- Verification queries (run separately after setup):
-- ============================================================
-- Check the job is registered:
--   SELECT * FROM cron.job;
--
-- Test the function manually:
--   SELECT send_periodic_reminder();
--
-- Inspect inserted notifications:
--   SELECT * FROM notifications ORDER BY created_at DESC LIMIT 20;
-- ============================================================
