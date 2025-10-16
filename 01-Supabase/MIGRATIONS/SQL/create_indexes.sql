-- SCRIPT POUR CRÉER LES INDEX CONCURRENTLY
-- À EXÉCUTER DANS UNE SESSION psql INTERACTIVE

SET statement_timeout = '1h';

-- Index 1: Pending récents
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_queue_pending_recent 
ON public.files_queue (created_at DESC) 
WHERE status = 'pending';

-- Index 2: Non processés par ID
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_queue_unprocessed_by_id 
ON public.files_queue (id) 
WHERE processed = false;

-- Index 3: Processés récents
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_queue_processed_at_recent 
ON public.files_queue (processed_at DESC) 
WHERE processed_at IS NOT NULL;

-- Index 4: Worker en traitement
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_queue_worker_processing 
ON public.files_queue (worker_id, created_at DESC) 
WHERE status = 'processing';

