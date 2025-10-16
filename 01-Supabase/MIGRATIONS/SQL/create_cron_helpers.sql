-- Create helper functions for pg_cron management and test them

-- 1) List cron jobs
CREATE OR REPLACE FUNCTION public.get_cron_jobs_list()
RETURNS TABLE (
  jobid bigint,
  schedule text,
  command text,
  nodename text,
  nodeport int,
  "database" text,
  username text,
  active bool,
  jobname text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    j.jobid,
    j.schedule,
    j.command,
    j.nodename,
    j.nodeport,
    j.database,
    j.username,
    j.active,
    j.jobname
  FROM cron.job j
  ORDER BY j.jobname;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_cron_jobs_list() TO service_role;

-- 2) Toggle a cron job
CREATE OR REPLACE FUNCTION public.toggle_cron_job(job_id bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_status boolean;
  new_status boolean;
  job_name text;
BEGIN
  SELECT active, jobname INTO current_status, job_name 
  FROM cron.job 
  WHERE jobid = job_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Job not found',
      'job_id', job_id
    );
  END IF;
  
  new_status := NOT current_status;
  
  UPDATE cron.job 
  SET active = new_status 
  WHERE jobid = job_id;
  
  RETURN json_build_object(
    'success', true,
    'job_id', job_id,
    'job_name', job_name,
    'previous_status', current_status,
    'new_status', new_status,
    'message', CASE WHEN new_status THEN 'Job activé' ELSE 'Job désactivé' END
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_cron_job(bigint) TO service_role;

-- 3) Delete a cron job
CREATE OR REPLACE FUNCTION public.delete_cron_job(job_id bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  job_name text;
BEGIN
  SELECT jobname INTO job_name 
  FROM cron.job 
  WHERE jobid = job_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Job not found',
      'job_id', job_id
    );
  END IF;
  
  PERFORM cron.unschedule(job_id);
  
  RETURN json_build_object(
    'success', true,
    'job_id', job_id,
    'job_name', job_name,
    'message', 'Job supprimé avec succès'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_cron_job(bigint) TO service_role;

-- Test list function
SELECT * FROM public.get_cron_jobs_list();
