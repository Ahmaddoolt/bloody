-- Add blood_request_reason column for receiver priority requests
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS blood_request_reason TEXT;

-- Add fcm_token column if not already present (may have been added manually)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add language column used for localized push notifications
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'ar';
