-- Migration: Fix NULL cities and add FCM token indexes
-- Date: 2024-01-15

-- Set default city for users with NULL city
UPDATE profiles 
SET city = 'Damascus' 
WHERE city IS NULL AND user_type IN ('donor', 'receiver');

-- Ensure fcm_token column exists
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT DEFAULT NULL;

-- Add index for city queries (used in notification filtering)
CREATE INDEX IF NOT EXISTS idx_profiles_city ON profiles(city);

-- Add index for FCM token queries (used in push notifications)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- Add index for user_type + availability (common query pattern)
CREATE INDEX IF NOT EXISTS idx_profiles_donor_available ON profiles(user_type, is_available) WHERE user_type = 'donor' AND is_available = true;

-- Add constraint to prevent NULL cities for donors and receivers
ALTER TABLE profiles 
ADD CONSTRAINT check_city_not_null 
CHECK (city IS NOT NULL OR user_type = 'admin');