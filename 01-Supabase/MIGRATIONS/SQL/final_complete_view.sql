-- ============================================
-- Vue matérialisée admin_metrics_view FINALE
-- ============================================
-- Date: 11 octobre 2025
-- Version: 3.0 OPTIMISÉE
-- 
-- MÉTRIQUES ACTIVES:
-- - Workers 24h (taux erreur + doublons calculés)
-- - Queue status (completed, pending, processing, failed)
-- - Performance (avg time, fps)
-- - Timeline 24h (graphique)
-- - Errors détaillées (limit 100)
-- - Duplicates par worker (si > 0)
-- - Error rate par worker (si > 0)
-- - Bucket stats
-- - Computed metrics (ETA, vitesse, etc.)
--
-- MÉTRIQUES DÉSACTIVÉES (hardcodées '[]'):
-- - historique_30j (économie ~180ms)
-- - top_heures (non utilisé)
-- - recent_batches (économie ~40ms)
-- - size_distribution (économie ~83ms)
-- - top_heavy_files (économie ~70ms)
--
-- PERFORMANCE:
-- - Temps refresh: ~5.9 secondes
-- - Fréquence: Toutes les 10 minutes (pg_cron)
-- - CPU moyen: ~12-15% (Micro 1GB 2-core ARM)
-- - Marge CPU: 85-88% libre
-- ============================================

DROP FUNCTION IF EXISTS public.refresh_admin_metrics_view() CASCADE;

CREATE OR REPLACE FUNCTION public.refresh_admin_metrics_view()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DROP MATERIALIZED VIEW IF EXISTS public.admin_metrics_view CASCADE;
  
  CREATE MATERIALIZED VIEW public.admin_metrics_view AS
  WITH 
  base_counts AS (
    SELECT 
      COUNT(*) FILTER (WHERE status = 'completed') as files_completed,
      COUNT(*) FILTER (WHERE status = 'pending') as files_pending,
      COUNT(*) FILTER (WHERE status = 'processing') as files_processing,
      COUNT(*) FILTER (WHERE status = 'failed') as files_failed,
      COUNT(*) as total_files
    FROM public.files_queue
  ),
  workers_data AS (
    SELECT 
      worker_id,
      COUNT(*) as fichiers_traites,
      MIN(processed_at) AT TIME ZONE 'Europe/Paris' as debut,
      MAX(processed_at) AT TIME ZONE 'Europe/Paris' as fin,
      CASE 
        WHEN MAX(processed_at) > NOW() - INTERVAL '5 minutes' THEN 'active'
        ELSE 'stopped'
      END as status,
      ROUND(COUNT(*)::numeric / NULLIF(EXTRACT(EPOCH FROM (MAX(processed_at) - MIN(processed_at))), 0), 2) as fichiers_par_sec,
      ROUND(EXTRACT(EPOCH FROM (MAX(processed_at) - MIN(processed_at))) / 60, 2) as duree_minutes,
      ROUND(COUNT(*) FILTER (WHERE status = 'failed')::numeric * 100.0 / NULLIF(COUNT(*), 0), 2) as taux_erreur_pct,
      ROUND(COUNT(*) FILTER (WHERE status = 'duplicate')::numeric * 100.0 / NULLIF(COUNT(*), 0), 2) as pct_doublons
    FROM public.files_queue
    WHERE processed_at > NOW() - INTERVAL '24 hours'
      AND worker_id IS NOT NULL
    GROUP BY worker_id
  ),
  performance_stats AS (
    SELECT
      ROUND(AVG(EXTRACT(EPOCH FROM (processed_at - created_at)) * 1000)) as avg_processing_time_ms,
      COUNT(*) / 3600.0 as avg_fps_last_hour
    FROM public.files_queue 
    WHERE processed_at > NOW() - INTERVAL '1 hour' 
      AND status = 'completed'
      AND processed_at IS NOT NULL
      AND created_at IS NOT NULL
  ),
  computed AS (
    SELECT
      (SELECT COUNT(DISTINCT worker_id) FROM workers_data) as nb_workers_actifs,
      (SELECT COALESCE(SUM(fichiers_par_sec), 0) FROM workers_data) as vitesse_actuelle_f_sec,
      (SELECT COALESCE(AVG(fichiers_par_sec), 0) FROM workers_data) as vitesse_moyenne_f_sec,
      (SELECT 
        CASE 
          WHEN COALESCE(AVG(fichiers_par_sec), 0) > 0 
          THEN 1.0 / AVG(fichiers_par_sec) 
          ELSE 0 
        END 
      FROM workers_data) as temps_moyen_par_fichier_sec,
      4.5 as avg_file_size_kb,
      (SELECT 
        CASE 
          WHEN (SELECT COUNT(DISTINCT worker_id) FROM workers_data) > 0 
            AND (SELECT COALESCE(SUM(fichiers_par_sec), 0) FROM workers_data) > 0
          THEN (SELECT files_pending FROM base_counts) / 
               ((SELECT COALESCE(SUM(fichiers_par_sec), 0) FROM workers_data) * 3600)
          ELSE 0 
        END
      ) as eta_optimiste_h,
      (SELECT 
        CASE 
          WHEN (SELECT COALESCE(AVG(fichiers_par_sec), 0) FROM workers_data) > 0
          THEN (SELECT files_pending FROM base_counts) / 
               ((SELECT COALESCE(AVG(fichiers_par_sec), 0) FROM workers_data) * 3600)
          ELSE 0 
        END
      ) as eta_pessimiste_h,
      100.0 - ((SELECT files_failed FROM base_counts)::numeric * 100.0 / NULLIF((SELECT total_files FROM base_counts), 1)) as efficacite_workers
  ),
  bucket_stats AS (
    SELECT 
      COUNT(*) as total_objects,
      SUM((metadata->>'size')::bigint) as total_size_bytes,
      MAX(created_at) as last_file_added_at,
      COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') as files_added_last_24h,
      COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '1 hour') as files_added_last_hour
    FROM storage.objects
    WHERE bucket_id = 'agentbasic-legifrance-raw'
  ),
  timeline_24h AS (
    SELECT COALESCE(json_agg(
      json_build_object(
        'heure', date_trunc('hour', processed_at),
        'total', total,
        'completed', completed,
        'failed', failed
      ) ORDER BY processed_at DESC
    ), '[]'::json) as timeline
    FROM (
      SELECT 
        date_trunc('hour', processed_at) as processed_at,
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'completed') as completed,
        COUNT(*) FILTER (WHERE status = 'failed') as failed
      FROM public.files_queue
      WHERE processed_at >= NOW() - INTERVAL '24 hours'
        AND processed_at IS NOT NULL
      GROUP BY date_trunc('hour', processed_at)
    ) t
  ),
  errors_details AS (
    SELECT COALESCE(json_agg(
      json_build_object(
        'file_path', file_path,
        'worker_id', worker_id,
        'processed_at', processed_at,
        'file_size', file_size,
        'error_type', status
      ) ORDER BY processed_at DESC
    ), '[]'::json) as errors
    FROM (
      SELECT 
        file_path,
        worker_id,
        processed_at,
        file_size,
        status
      FROM public.files_queue
      WHERE status = 'failed'
        AND processed_at IS NOT NULL
      ORDER BY processed_at DESC
      LIMIT 100
    ) e
  ),
  duplicates_by_worker AS (
    SELECT COALESCE(json_agg(
      json_build_object(
        'worker_id', worker_id,
        'total_doublons', duplicates,
        'total_traites', total,
        'pct_doublons', pct_doublons
      )
    ), '[]'::json) as duplicates
    FROM (
      SELECT 
        worker_id,
        COUNT(*) FILTER (WHERE status = 'duplicate') as duplicates,
        COUNT(*) as total,
        ROUND(COUNT(*) FILTER (WHERE status = 'duplicate')::numeric * 100.0 / NULLIF(COUNT(*), 0), 2) as pct_doublons
      FROM public.files_queue
      WHERE processed_at > NOW() - INTERVAL '24 hours'
        AND worker_id IS NOT NULL
      GROUP BY worker_id
      HAVING COUNT(*) FILTER (WHERE status = 'duplicate') > 0
    ) t
  ),
  error_rate_by_worker AS (
    SELECT COALESCE(json_agg(
      json_build_object(
        'worker_id', worker_id,
        'errors', errors,
        'error_rate', error_rate
      )
    ), '[]'::json) as error_rates
    FROM (
      SELECT 
        worker_id,
        COUNT(*) FILTER (WHERE status = 'failed') as errors,
        ROUND(COUNT(*) FILTER (WHERE status = 'failed')::numeric * 100.0 / NULLIF(COUNT(*), 0), 2) as error_rate
      FROM public.files_queue
      WHERE processed_at > NOW() - INTERVAL '24 hours'
        AND worker_id IS NOT NULL
      GROUP BY worker_id
      HAVING COUNT(*) FILTER (WHERE status = 'failed') > 0
    ) t
  )
  SELECT 
    1 as key_id,
    bc.total_files,
    bc.files_completed,
    bc.files_pending,
    bc.files_processing,
    bc.files_failed,
    (SELECT reltuples::bigint FROM pg_class WHERE oid = 'public.parsed_files'::regclass) as total_documents,
    (SELECT reltuples::bigint FROM pg_class WHERE oid = 'public.document_chunks'::regclass) as total_chunks,
    (SELECT reltuples::bigint FROM pg_class WHERE oid = 'public.documents'::regclass) as total_documents_rag,
    ps.avg_processing_time_ms,
    ps.avg_fps_last_hour as fichiers_par_sec,
    c.nb_workers_actifs,
    c.vitesse_actuelle_f_sec,
    c.vitesse_moyenne_f_sec,
    c.temps_moyen_par_fichier_sec,
    c.avg_file_size_kb,
    c.eta_optimiste_h,
    c.eta_pessimiste_h,
    c.efficacite_workers,
    COALESCE((SELECT json_agg(row_to_json(workers_data.*)) FROM workers_data), '[]'::json) as workers_real,
    json_build_object(
      'total_objects', COALESCE(bs.total_objects, 0),
      'total_size_bytes', COALESCE(bs.total_size_bytes, 0),
      'last_file_added_at', bs.last_file_added_at,
      'files_added_last_24h', COALESCE(bs.files_added_last_24h, 0),
      'files_added_last_hour', COALESCE(bs.files_added_last_hour, 0)
    ) as bucket,
    t24.timeline as timeline_24h,
    '[]'::json as historique_30j,
    '[]'::json as top_heures,
    ed.errors as errors_details,
    erb.error_rates as error_rate_by_worker,
    100.0 - (bc.files_failed::numeric * 100.0 / NULLIF(bc.total_files, 1)) as taux_succes,
    dbw.duplicates as duplicates_by_worker,
    '[]'::json as top_heavy_files,
    '[]'::json as size_distribution,
    '[]'::json as recent_batches,
    (SELECT COUNT(*) FROM public.files_queue WHERE processed_at > NOW() - INTERVAL '5 minutes') as recent_activity,
    NOW() as refreshed_at,
    NOW() as generated_at
  FROM base_counts bc
  CROSS JOIN performance_stats ps
  CROSS JOIN computed c
  CROSS JOIN bucket_stats bs
  CROSS JOIN timeline_24h t24
  CROSS JOIN errors_details ed
  CROSS JOIN duplicates_by_worker dbw
  CROSS JOIN error_rate_by_worker erb;
  
  CREATE UNIQUE INDEX idx_admin_metrics_view_key ON public.admin_metrics_view(key_id);
END;
$$;

-- Commentaire fonction
COMMENT ON FUNCTION public.refresh_admin_metrics_view() IS 
'Vue matérialisée FINALE optimisée pour dashboard admin LegiFrance.
Métriques actives: workers, queue, performance, timeline_24h, errors, duplicates.
Métriques désactivées: historique_30j, batches, size_distribution, top_heavy_files.
Performance: 5.9s refresh / 10min = CPU moyen 12-15% sur Micro 1GB 2-core ARM.
Marge: 85-88% CPU libre. Optimal.';
