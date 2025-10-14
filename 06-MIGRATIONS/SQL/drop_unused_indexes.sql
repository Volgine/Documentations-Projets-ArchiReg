-- SUPPRESSION DES INDEX INUTILISÉS (37 index jamais utilisés)
-- Libère 500+ MB et accélère les écritures

-- FILES_QUEUE (8 index inutilisés)
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_pending;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_worker;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_worker_processed;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_status_time;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_status_all;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_file_size;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_unprocessed_by_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_created_processed;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_files_queue_status_created_at;

-- PARSED_FILES (4 index inutilisés)
DROP INDEX CONCURRENTLY IF EXISTS public.parsed_files_legifrance_id_idx;
DROP INDEX CONCURRENTLY IF EXISTS public.parsed_files_status_idx;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_parsed_files_file_path;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_parsed_files_file_path_status;

-- DOCUMENTS (4 index inutilisés)
DROP INDEX CONCURRENTLY IF EXISTS public.idx_documents_content_hash;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_documents_user_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_documents_status;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_documents_file_path;

-- DOCUMENT_CHUNKS (3 index inutilisés)
DROP INDEX CONCURRENTLY IF EXISTS public.idx_document_chunks_document_id;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_document_chunks_chunk_index;
DROP INDEX CONCURRENTLY IF EXISTS public.document_chunks_embedding_idx;

-- ADMIN_METRICS_SNAPSHOT (2 index inutilisés)
DROP INDEX CONCURRENTLY IF EXISTS public.idx_metrics_snapshot_valid;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_metrics_snapshot_created;

-- AUTRES TABLES (16 index inutilisés)
DROP INDEX CONCURRENTLY IF EXISTS public.idx_users_role;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_timeline_cache_hour;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_metrics_hourly_rollup_hour;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_weekly_reports_week;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_metrics_archive_created;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_metrics_archive_worker;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_realtime_metrics_updated;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_system_alerts_unresolved;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_sync_checkpoints_lookup;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_manual_purge_logs_created_at;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_manual_purge_logs_admin_level;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_manual_purge_logs_criteria_gin;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_manual_purge_logs_purge_uuid;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_retention_audit_log_operation_timestamp;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_retention_audit_log_created_at;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_backup_audit_log_created_at;
DROP INDEX CONCURRENTLY IF EXISTS public.idx_backup_audit_log_status_type;

