-- Required for Fix 5: Arabic center names in CenterModel / centers_provider.dart
ALTER TABLE centers
  ADD COLUMN IF NOT EXISTS name_ar TEXT;

-- Required for Fix 2: durable 24-hour donor-confirmation cooldown in profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS last_confirmation_at TIMESTAMPTZ;
