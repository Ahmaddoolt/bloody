-- Trust, safety, and donor verification support.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_forbidden BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS forbidden_reason TEXT,
  ADD COLUMN IF NOT EXISTS forbidden_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS forbidden_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'unverified',
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES profiles(id);

ALTER TABLE profiles
  DROP CONSTRAINT IF EXISTS profiles_verification_status_check;

ALTER TABLE profiles
  ADD CONSTRAINT profiles_verification_status_check
  CHECK (verification_status IN ('unverified', 'pending', 'verified', 'rejected'));

CREATE INDEX IF NOT EXISTS idx_profiles_not_forbidden
  ON profiles(user_type, is_forbidden);

CREATE INDEX IF NOT EXISTS idx_profiles_verification_status
  ON profiles(verification_status);

CREATE TABLE IF NOT EXISTS account_verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  donor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  identity_document_path TEXT NOT NULL,
  medical_document_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  admin_note TEXT,
  reviewed_by UUID REFERENCES profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT account_verification_status_check
    CHECK (status IN ('pending', 'approved', 'rejected'))
);

CREATE INDEX IF NOT EXISTS idx_account_verification_requests_donor
  ON account_verification_requests(donor_id);

CREATE INDEX IF NOT EXISTS idx_account_verification_requests_status
  ON account_verification_requests(status, created_at DESC);

CREATE OR REPLACE FUNCTION set_account_verification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_account_verification_updated_at
  ON account_verification_requests;

CREATE TRIGGER trg_account_verification_updated_at
BEFORE UPDATE ON account_verification_requests
FOR EACH ROW
EXECUTE FUNCTION set_account_verification_updated_at();

ALTER TABLE account_verification_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own verification requests"
ON account_verification_requests
FOR SELECT
USING (
  auth.uid() = donor_id
  OR EXISTS (
    SELECT 1 FROM profiles admin_profile
    WHERE admin_profile.id = auth.uid()
      AND admin_profile.user_type = 'admin'
  )
  OR auth.jwt() ->> 'email' = 'adminbloody2026@gmail.com'
);

CREATE POLICY "Users can create own verification requests"
ON account_verification_requests
FOR INSERT
WITH CHECK (auth.uid() = donor_id);

CREATE POLICY "Admins can review verification requests"
ON account_verification_requests
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles admin_profile
    WHERE admin_profile.id = auth.uid()
      AND admin_profile.user_type = 'admin'
  )
  OR auth.jwt() ->> 'email' = 'adminbloody2026@gmail.com'
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles admin_profile
    WHERE admin_profile.id = auth.uid()
      AND admin_profile.user_type = 'admin'
  )
  OR auth.jwt() ->> 'email' = 'adminbloody2026@gmail.com'
);

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'verification-documents',
  'verification-documents',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload own verification documents"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'verification-documents'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can read own verification documents"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'verification-documents'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM profiles admin_profile
      WHERE admin_profile.id = auth.uid()
        AND admin_profile.user_type = 'admin'
    )
    OR auth.jwt() ->> 'email' = 'adminbloody2026@gmail.com'
  )
);
