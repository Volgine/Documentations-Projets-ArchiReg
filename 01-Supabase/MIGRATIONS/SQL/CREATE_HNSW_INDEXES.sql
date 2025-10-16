-- ============================================
-- CRÉATION INDEX HNSW POUR OPTIMISATION RAG
-- ============================================
-- Date: 13 octobre 2025
-- Auteur: Agent-Orchestrator
-- Objectif: Accélérer recherche vectorielle (930k docs)
-- Gain attendu: 100x à 1000x plus rapide
-- Durée création: 5-15 minutes selon charge serveur
-- ============================================

-- ⚠️ IMPORTANT: Exécuter dans le SQL Editor de Supabase Dashboard
-- URL: https://supabase.com/dashboard/project/joozqsjbcwrqyeqepnev/sql/new

-- ============================================
-- 1. INDEX HNSW SUR documents.embedding
-- ============================================

-- Créer l'index HNSW (asynchrone, ne bloque pas la base)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_documents_embedding_hnsw 
ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,              -- Nombre de connexions par nœud (balance précision/vitesse)
    ef_construction = 64 -- Taille de la file pendant construction (qualité index)
);

-- ============================================
-- 2. INDEX HNSW SUR document_chunks.embedding
-- ============================================

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_document_chunks_embedding_hnsw 
ON document_chunks 
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,
    ef_construction = 64
);

-- ============================================
-- 3. OPTIMISER LES STATISTIQUES
-- ============================================

-- Mettre à jour les statistiques pour le query planner
ANALYZE documents;
ANALYZE document_chunks;

-- ============================================
-- 4. VÉRIFIER LES INDEX CRÉÉS
-- ============================================

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE indexname LIKE '%hnsw%'
ORDER BY tablename, indexname;

-- ============================================
-- 5. VÉRIFIER LES PERFORMANCES (OPTIONNEL)
-- ============================================

-- Test avant/après: recherche vectorielle
-- Avant index: 30+ secondes (timeout)
-- Après index: <1 seconde

-- Exemple de requête test:
-- EXPLAIN ANALYZE
-- SELECT id, content, embedding <=> '[0.1,0.2,...]'::vector as distance
-- FROM documents
-- WHERE embedding <=> '[0.1,0.2,...]'::vector < 0.7
-- ORDER BY distance
-- LIMIT 8;

-- ============================================
-- 📊 RÉSULTATS ATTENDUS
-- ============================================

-- Index HNSW créés:
-- ✅ idx_documents_embedding_hnsw (~500 MB pour 930k docs)
-- ✅ idx_document_chunks_embedding_hnsw (~300 MB pour ~7M chunks)

-- Performances RAG:
-- ✅ Recherche < 1s au lieu de timeout
-- ✅ Chatbot répond instantanément avec contexte
-- ✅ Frontend ne timeout plus

-- ============================================
-- ⚠️ NOTES IMPORTANTES
-- ============================================

-- 1. CONCURRENTLY permet création sans bloquer la base
-- 2. Durée: 5-15 minutes selon charge serveur
-- 3. Espace disque: ~800 MB supplémentaires
-- 4. Pas de downtime pendant création
-- 5. Si erreur, réessayer sans CONCURRENTLY (mais bloquera la base)

-- ============================================
-- 🔗 DOCUMENTATION
-- ============================================

-- pgvector HNSW: https://github.com/pgvector/pgvector#hnsw
-- Supabase pgvector: https://supabase.com/docs/guides/ai/vector-indexes
-- HNSW params: https://github.com/pgvector/pgvector#index-options

