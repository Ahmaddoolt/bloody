-- Atomic receiver donation confirmation with a durable 24-hour cooldown.

CREATE OR REPLACE FUNCTION public.confirm_receiver_donation(p_donor_id UUID)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_receiver_id UUID := auth.uid();
  v_confirmed_at TIMESTAMPTZ := now();
  v_last_confirmation_at TIMESTAMPTZ;
BEGIN
  IF v_receiver_id IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT last_confirmation_at
  INTO v_last_confirmation_at
  FROM profiles
  WHERE id = v_receiver_id
    AND user_type = 'receiver'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'receiver_profile_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF v_last_confirmation_at IS NOT NULL
      AND v_last_confirmation_at > v_confirmed_at - INTERVAL '24 hours' THEN
    RAISE EXCEPTION 'confirmation_on_cooldown' USING ERRCODE = 'P0001';
  END IF;

  UPDATE profiles
  SET
    points = COALESCE(points, 0) + 10,
    last_donation_date = v_confirmed_at::date
  WHERE id = p_donor_id
    AND user_type = 'donor';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'donor_profile_not_found' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO donations (donor_id, status)
  VALUES (p_donor_id, 'completed');

  UPDATE profiles
  SET last_confirmation_at = v_confirmed_at
  WHERE id = v_receiver_id;

  RETURN v_confirmed_at;
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_receiver_donation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.confirm_receiver_donation(UUID)
  TO authenticated;
