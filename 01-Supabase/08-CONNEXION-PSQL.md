# 🔌 CONNEXION PSQL DIRECTE - GUIDE

**Date** : 15 octobre 2025  
**Status** : ✅ ACTIF  
**Utilisations** : CREATE INDEX HNSW, migrations lourdes, SQL manuel

---

## 🎯 Quand utiliser PSQL direct ?

### ✅ **Recommandé pour**
- Construction index HNSW (durée longue)
- Migrations volumineuses
- Optimisations `work_mem`
- Requêtes analytiques complexes

### ❌ **Déconseillé pour**
- Requêtes READ standard → Passer par Backend/Edge Functions
- INSERT/UPDATE app → Passer par Supabase Client
- Modifications structurelles → SQL Editor Supabase (traçabilité)

---

## 🔑 CONFIGURATION CONNEXION

### **Parameters optimisés**

```sql
-- Connexion optimisée pour construction INDEX
psql "postgresql://postgres.joozqsjbcwrqyeqepnev:***@aws-0-eu-central-1.pooler.supabase.com:5432/postgres?sslmode=require&options=-c work_mem%3D256MB"
```

**Paramètres clés** :
- `work_mem=256MB` : Alloue mémoire pour opérations de tri
- `sslmode=require` : Force SSL
- `pooler.supabase.com:5432` : Mode Session Supavisor

---

## 🏗️ CRÉATION INDEX HNSW

### **Problème : Timeout Statement**

```sql
CREATE INDEX CONCURRENTLY idx_documents_embedding_hnsw 
ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Erreur après 15-30 min :
-- statement timeout
```

**Cause** : Paramètres Supabase par défaut :
- `statement_timeout = 900000` (15 min)
- `work_mem = 4MB` (trop faible)

---

### **Solution : Désactiver Timeout + Boost Memory**

```sql
-- 1. Augmenter work_mem pour cette session
SET work_mem = '256MB';

-- 2. Désactiver timeout (0 = infini)
SET statement_timeout = 0;

-- 3. Lancer construction index (CONCURRENTLY pour production)
CREATE INDEX CONCURRENTLY idx_documents_embedding_hnsw 
ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Durée : ~45-60 min pour 312k vecteurs
```

**Résultat** :
- ✅ Index construit sans interruption
- ✅ Taille : 383 MB
- ✅ Performance : <200ms pour recherches

---

## 📊 COMMANDES UTILES

### **Vérifier indexes actifs**
```sql
SELECT 
    schemaname, 
    tablename, 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename IN ('documents', 'document_chunks');
```

### **Taille tables/indexes**
```sql
SELECT 
    schemaname, 
    tablename, 
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### **Progression construction index**
```sql
SELECT 
    now()::text AS current_time,
    query,
    state,
    wait_event_type,
    wait_event
FROM pg_stat_activity
WHERE query LIKE '%CREATE INDEX%'
AND state != 'idle';
```

### **Statistiques pgvector**
```sql
SELECT 
    COUNT(*) AS total_vectors,
    pg_size_pretty(SUM(pg_column_size(embedding))) AS embedding_size
FROM documents
WHERE embedding IS NOT NULL;
```

---

## 🔒 SÉCURITÉ

### **Pooler Mode** : Session vs Transaction

```bash
# ✅ SESSION MODE (pour CREATE INDEX, SET variables)
pooler.supabase.com:5432

# ❌ TRANSACTION MODE (incompatible CREATE INDEX)
pooler.supabase.com:6543
```

**Pourquoi Session Mode ?**
- CREATE INDEX CONCURRENTLY interdit en mode Transaction
- SET work_mem persiste pendant toute la session
- Compatibilité `asyncpg` (Backend)

---

### **Credentials**

```bash
Host     : aws-0-eu-central-1.pooler.supabase.com
Port     : 5432 (Session Mode)
Database : postgres
User     : postgres.joozqsjbcwrqyeqepnev
Password : [voir .env SUPABASE_DB_PASSWORD]
```

**⚠️ ATTENTION** : Ne JAMAIS commit credentials dans Git !

---

## 🎯 WORKFLOW CRÉATION INDEX HNSW

### **Étape par étape**

```bash
# 1. Se connecter en PSQL
psql "postgresql://postgres.joozqsjbcwrqyeqepnev:***@aws-0-eu-central-1.pooler.supabase.com:5432/postgres?sslmode=require"

# 2. Dans psql shell :
SET work_mem = '256MB';
SET statement_timeout = 0;

# 3. Lancer création
\timing on  -- Active mesure temps

CREATE INDEX CONCURRENTLY idx_documents_embedding_hnsw 
ON documents USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Attend 45-60 min...

# 4. Vérifier création
\d documents

# 5. Tester recherche
EXPLAIN ANALYZE
SELECT id, title, <embedding> <=> '[0,0,...]' AS distance
FROM documents
ORDER BY embedding <=> '[0,0,...]'
LIMIT 10;
```

---

## 📊 PARAMÈTRES HNSW OPTIMAUX

### **Documents (312k vecteurs)**
```sql
m = 16               # Connexions par nœud (standard)
ef_construction = 64 # Qualité construction (balance vitesse/précision)
```

**Résultat** :
- Index size : 383 MB
- Latence : <200ms
- Recall : >95%

### **Document Chunks (6M vecteurs estimés)**
```sql
m = 24               # Plus de connexions (volume élevé)
ef_construction = 96 # Meilleure qualité
```

**Estimation** :
- Index size : ~2.5 GB
- Latence : <300ms
- Recall : >97%

---

## 🎉 Résumé

**Connexion PSQL optimisée** :
- ✅ Session Mode (5432)
- ✅ work_mem=256MB
- ✅ statement_timeout=0
- ✅ CREATE INDEX CONCURRENTLY
- ✅ Paramètres HNSW optimaux

**INDEX HNSW construit sans timeout !** 🚀

