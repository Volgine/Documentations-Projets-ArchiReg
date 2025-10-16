# 🚀 INDEX HNSW - RECHERCHE VECTORIELLE PGVECTOR

**Date** : 15 octobre 2025  
**Extension** : pgvector  
**Status** : ⚠️ INDEX SUPPRIMÉS (base reconstruite)

---

## 🎯 État Actuel

### **Index HNSW Documents**
```
Nom    : idx_documents_embedding_hnsw
Table  : documents
Status : ❌ SUPPRIMÉ (base vidée le 13 oct 2025)
Raison : Reconstruction propre après fix LEGIARTI
```

### **Index HNSW Chunks**
```
Nom    : idx_document_chunks_embedding_hnsw  
Table  : document_chunks
Status : ❌ SUPPRIMÉ
Raison : Base vidée pour reconstruction
```

---

## 📊 HISTORIQUE

### **Ancienne Base (Avant 13 Oct 2025)**
```
documents :
├─ Rows : 312,205 documents
├─ Index HNSW : 383 MB (valid, ready)
├─ Performance : <1s recherche sur 312k docs
└─ Problème : Embeddings incompatibles (AVX2 vs SSE4)

→ Base vidée → Index supprimé
```

### **Nouvelle Base (Après 15 Oct 2025)**
```
documents :
├─ Rows : 28 documents (base reconstruite)
├─ Index HNSW : ❌ Pas encore créé
├─ Raison : Attendre ~100k docs avant création
└─ Fix : Embeddings compatibles (--no-binary)
```

---

## 🚀 CRÉATION INDEX (À FAIRE APRÈS 100K DOCS)

### **Quand Créer ?**
- ⏳ **Maintenant** : 28 docs → Trop petit
- ✅ **Optimal** : 100k+ docs → Créer index
- 🎯 **Idéal** : 500k+ docs → Performance max

### **Commande SQL**
```sql
-- Documents (contexte global)
CREATE INDEX CONCURRENTLY idx_documents_embedding_hnsw 
ON documents 
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,              -- Connexions par nœud
    ef_construction = 64 -- Qualité construction
);

-- Chunks (granulaire, futur)
CREATE INDEX CONCURRENTLY idx_document_chunks_embedding_hnsw 
ON document_chunks 
USING hnsw (embedding vector_cosine_ops)
WITH (
    m = 16,
    ef_construction = 64
);
```

### **Durée Construction**
- **100k docs** : ~10-15 min
- **500k docs** : ~30-45 min
- **1M docs** : ~60-90 min

---

## 📈 GAINS ATTENDUS

| Métrique | Sans Index | Avec HNSW | Gain |
|----------|-----------|-----------|------|
| **Temps recherche** | 30s+ (timeout) | <1s | **100x-1000x** |
| **Comparaisons** | 930,000 | ~150 | **6,200x** |
| **Complexité** | O(n) linéaire | O(log n) | Logarithmique |
| **Coverage** | 21% (timeout) | 100% | **479%** |

---

## 🔧 MAINTENANCE INDEX

### **Auto-Update**
✅ **Oui** ! L'index se met à jour automatiquement lors des INSERT :
```sql
INSERT INTO documents (..., embedding)
VALUES (..., '[0.123, -0.456, ...]');
-- → Index HNSW mis à jour automatiquement ✅
```

### **REINDEX Mensuel**
Job pg_cron configuré (jobid 23) :
```sql
-- 1er du mois à 3h
REINDEX INDEX CONCURRENTLY idx_documents_embedding_hnsw;
REINDEX INDEX CONCURRENTLY idx_document_chunks_embedding_hnsw;
ANALYZE documents;
ANALYZE document_chunks;
```

**Pourquoi ?**
- Après +100k insertions → Graphe fragmenté
- REINDEX reconstruit optimalement
- Performance restaurée <1s

---

## 🎯 PARAMÈTRES OPTIMAUX

### **m = 16**
- Connexions par nœud dans le graphe HNSW
- Plus élevé = meilleure précision, index plus gros
- 16 = optimal pour 100k-1M docs

### **ef_construction = 64**
- Qualité construction graphe
- Plus élevé = meilleure qualité, construction plus lente
- 64 = bon équilibre

### **ef_search = 100**
```sql
-- Configuré dans backend au runtime
SET hnsw.ef_search = 100;
```
- Précision recherche
- 100 = recommandé Supabase pour 768 dims

---

## 📚 SURVEILLANCE

### **Vérifier État Index**
```sql
SELECT 
    i.relname as index_name,
    pg_size_pretty(pg_relation_size(i.oid)) as size,
    idx.indisvalid as is_valid,
    idx.indisready as is_ready
FROM pg_class i
JOIN pg_index idx ON i.oid = idx.indexrelid
WHERE i.relname LIKE '%hnsw%';
```

### **Performance Recherche**
```sql
EXPLAIN ANALYZE
SELECT id, embedding <=> '[...]'::vector as distance
FROM documents
WHERE embedding <=> '[...]'::vector < 0.3
ORDER BY distance
LIMIT 8;
```

**Cible** : 
- ✅ < 500ms : Index optimal
- ⚠️ 500ms-2s : Index OK
- ❌ > 2s : REINDEX recommandé

---

## 🎉 Résumé

**Index HNSW actuellement** :
- ❌ Supprimés (base reconstruite)
- ⏳ À créer après 100k docs
- ✅ Cron job REINDEX mensuel configuré
- ✅ Auto-update lors des INSERT

**Prochaine étape** : Laisser Workers générer 100k+ docs, puis recréer index ! 🚀

