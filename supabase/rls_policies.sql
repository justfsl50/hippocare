-- ============================================================
-- Supabase RLS Policies for Hippocare Hospital
-- ============================================================
-- Run AFTER migration.sql has been applied.
--
-- Uses SECURITY DEFINER helper functions to avoid infinite
-- recursion when policies on other tables query `profiles`.
-- ============================================================


-- ────────────────────────────────────────────────
-- HELPER FUNCTIONS (SECURITY DEFINER — bypass RLS)
-- ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.user_role()
RETURNS text LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_staff()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'staff')
  );
$$;

CREATE OR REPLACE FUNCTION public.is_doctor()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'doctor'
  );
$$;


-- ────────────────────────────────────────────────
-- 1. PROFILES
-- ────────────────────────────────────────────────
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_select_admin"
  ON profiles FOR SELECT
  USING (public.is_admin());

CREATE POLICY "profiles_insert_own"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);


-- ────────────────────────────────────────────────
-- 2. DOCTORS
-- ────────────────────────────────────────────────
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "doctors_select_public"
  ON doctors FOR SELECT
  USING (true);

CREATE POLICY "doctors_insert_admin"
  ON doctors FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "doctors_update_admin"
  ON doctors FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "doctors_delete_admin"
  ON doctors FOR DELETE
  USING (public.is_admin());


-- ────────────────────────────────────────────────
-- 3. PATIENTS
-- ────────────────────────────────────────────────
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patients_select_own"
  ON patients FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "patients_select_admin_staff"
  ON patients FOR SELECT
  USING (public.is_admin_or_staff());

CREATE POLICY "patients_select_doctor"
  ON patients FOR SELECT
  USING (
    public.is_doctor()
    AND id IN (SELECT patient_id FROM appointments WHERE doctor_id = auth.uid())
  );

CREATE POLICY "patients_insert_admin_staff"
  ON patients FOR INSERT
  WITH CHECK (public.is_admin_or_staff());

CREATE POLICY "patients_update_admin_staff"
  ON patients FOR UPDATE
  USING (public.is_admin_or_staff());

CREATE POLICY "patients_delete_admin"
  ON patients FOR DELETE
  USING (public.is_admin());


-- ────────────────────────────────────────────────
-- 4. APPOINTMENTS
-- ────────────────────────────────────────────────
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "appointments_select_patient"
  ON appointments FOR SELECT
  USING (patient_id = auth.uid());

CREATE POLICY "appointments_select_doctor"
  ON appointments FOR SELECT
  USING (doctor_id = auth.uid());

CREATE POLICY "appointments_select_admin_staff"
  ON appointments FOR SELECT
  USING (public.is_admin_or_staff());

CREATE POLICY "appointments_insert_patient"
  ON appointments FOR INSERT
  WITH CHECK (patient_id = auth.uid());

CREATE POLICY "appointments_insert_admin_staff"
  ON appointments FOR INSERT
  WITH CHECK (public.is_admin_or_staff());

CREATE POLICY "appointments_update_doctor"
  ON appointments FOR UPDATE
  USING (doctor_id = auth.uid());

CREATE POLICY "appointments_update_admin_staff"
  ON appointments FOR UPDATE
  USING (public.is_admin_or_staff());

CREATE POLICY "appointments_delete_admin_staff"
  ON appointments FOR DELETE
  USING (public.is_admin_or_staff());


-- ────────────────────────────────────────────────
-- 5. PRESCRIPTIONS
-- ────────────────────────────────────────────────
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "prescriptions_insert_doctor"
  ON prescriptions FOR INSERT
  WITH CHECK (public.is_doctor());

CREATE POLICY "prescriptions_select_doctor"
  ON prescriptions FOR SELECT
  USING (doctor_id = auth.uid());

CREATE POLICY "prescriptions_select_patient"
  ON prescriptions FOR SELECT
  USING (patient_id = auth.uid());

CREATE POLICY "prescriptions_select_admin"
  ON prescriptions FOR SELECT
  USING (public.is_admin());


-- ────────────────────────────────────────────────
-- 6. PAYMENTS
-- ────────────────────────────────────────────────
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payments_select_own"
  ON payments FOR SELECT
  USING (patient_id = auth.uid());

CREATE POLICY "payments_select_admin"
  ON payments FOR SELECT
  USING (public.is_admin());

CREATE POLICY "payments_insert_admin"
  ON payments FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "payments_update_own"
  ON payments FOR UPDATE
  USING (patient_id = auth.uid());

CREATE POLICY "payments_update_admin"
  ON payments FOR UPDATE
  USING (public.is_admin());


-- ────────────────────────────────────────────────
-- 7. STAFF
-- ────────────────────────────────────────────────
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "staff_select_own"
  ON staff FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "staff_select_admin"
  ON staff FOR SELECT
  USING (public.is_admin());

CREATE POLICY "staff_insert_admin"
  ON staff FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "staff_update_admin"
  ON staff FOR UPDATE
  USING (public.is_admin());

CREATE POLICY "staff_delete_admin"
  ON staff FOR DELETE
  USING (public.is_admin());


-- ────────────────────────────────────────────────
-- 8. PATIENT_LOG
-- ────────────────────────────────────────────────
ALTER TABLE patient_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_log_select_admin_staff"
  ON patient_log FOR SELECT
  USING (public.is_admin_or_staff());

CREATE POLICY "patient_log_insert_admin_staff"
  ON patient_log FOR INSERT
  WITH CHECK (public.is_admin_or_staff());
