-- ═══════════════════════════════════════════════════════════════════
-- FIX : Permissions pour toggle_cron_job
-- ═══════════════════════════════════════════════════════════════════
-- La fonction toggle_cron_job() doit avoir SECURITY DEFINER pour
-- pouvoir modifier cron.job (qui appartient à l'extension pg_cron)
-- ═══════════════════════════════════════════════════════════════════

-- Drop et recréer avec SECURITY DEFINER
DROP FUNCTION IF EXISTS public.toggle_cron_job(bigint);

CREATE OR REPLACE FUNCTION public.toggle_cron_job(job_id bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER  -- ← Important : Exécute avec les droits du créateur (postgres)
SET search_path = public
AS $$
DECLARE
  current_status boolean;
  new_status boolean;
  job_name text;
BEGIN
  -- Récupérer le statut actuel
  SELECT active, jobname INTO current_status, job_name
  FROM cron.job
  WHERE jobid = job_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cron job % not found', job_id;
  END IF;

  -- Inverser le statut
  new_status := NOT current_status;

  -- Mettre à jour
  UPDATE cron.job 
  SET active = new_status 
  WHERE jobid = job_id;

  -- Retourner le résultat
  RETURN json_build_object(
    'jobid', job_id,
    'jobname', job_name,
    'old_status', current_status,
    'new_status', new_status,
    'success', true
  );
END;
$$;

-- Grant EXECUTE à authenticated et service_role
GRANT EXECUTE ON FUNCTION public.toggle_cron_job(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_cron_job(bigint) TO service_role;

-- Vérification
SELECT 
  proname as function_name,
  prosecdef as is_security_definer,
  proowner::regrole as owner
FROM pg_proc 
WHERE proname = 'toggle_cron_job';

