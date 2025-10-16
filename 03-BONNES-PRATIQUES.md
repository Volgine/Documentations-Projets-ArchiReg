# 📖 BONNES PRATIQUES & POINTS CRITIQUES

**Date** : 11 octobre 2025  
**Version** : 1.0  
**Status** : ✅ **GUIDE COMPLET**

---

## 🎯 Introduction

Ce document regroupe les **bonnes pratiques**, **pièges à éviter**, et **points critiques** pour maintenir et faire évoluer ArchiReg.

---

## 🚨 POINTS CRITIQUES À NE JAMAIS OUBLIER

### **1. n_ctx DOIT ÊTRE ALIGNÉ AVEC LE MODÈLE** ⚠️

**RÈGLE D'OR** :
```python
# ✅ CORRECT
n_ctx = 512  # Aligné avec bert.context_length du modèle Solon-base

# ❌ INCORRECT
n_ctx = 4096  # → Warning "exceeds trained context length" → Qualité dégradée
```

**Où vérifier** :
- `WorkerLocal/embedding/llama_service.py` (ligne 63)
- `WorkerLocal Chunk/embedding/llama_service.py` (ligne 63)
- `Agent-Orchestrator/backend/llama_server.py` (ligne 44)

**Validation** :
```bash
# Logs backend - PAS de warning si correct
# ❌ BAD: "WARNING llama_context exceeds trained context length"
# ✅ GOOD: Pas de warning
```

---

### **2. NE JAMAIS MODIFIER LES 2 WORKERS EN MÊME TEMPS** ⚠️

**RÈGLE** : Un seul worker à la fois en production

**Raison** :
- WorkerLocal et WorkerLocal Chunk utilisent la **même source** (bucket Légifrance)
- Si les 2 lancés en même temps : **doublons de traitement**

**Bonne pratique** :
```bash
# ✅ CORRECT: Séquentiel
1. Lancer WorkerLocal (terminé → 930k docs)
2. Attendre fin complète
3. Lancer WorkerLocal Chunk (6M chunks)

# ❌ INCORRECT: Parallèle sur même source
Terminal 1: WorkerLocal run
Terminal 2: WorkerLocal Chunk run  # ❌ Doublon traitement !
```

**Exception** : Lancement parallèle OK si worker_id différents (déjà le cas ✅)

---

### **3. TOUJOURS UTILISER SERVICE_ROLE_KEY POUR LES WORKERS** 🔐

**RÈGLE** : Workers = `service_role`, pas `anon_key`

**Raison** :
- RLS sur `documents` et `document_chunks` : `service_role` uniquement pour INSERT
- `anon_key` → 403 Forbidden

**Configuration** :
```python
# ✅ CORRECT
supabase_service_role_key: str = Field("eyJhbGciOiJIUzI1NiIs...")  # Service role

# ❌ INCORRECT
supabase_anon_key: str = Field("eyJhbGciOiJIUzI1NiIs...")  # Anon → RLS refuse INSERT
```

**Vérification** :
```bash
# Logs worker - Si erreur 403:
# ❌ "403 Forbidden" → Tu utilises anon_key au lieu de service_role
```

---

### **4. INDEX PGVECTOR OBLIGATOIRE POUR PERFORMANCE** ⚡

**RÈGLE** : Toujours créer index pgvector sur colonnes `embedding`

**Pourquoi** :
- Sans index : Recherche O(n) → **500ms** pour 6M chunks
- Avec index IVFFlat : Recherche O(log n) → **10-30ms**

**Commandes** :
```sql
-- ✅ Documents (déjà fait)
CREATE INDEX idx_documents_embedding 
ON documents 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 100);

-- ✅ Chunks (déjà fait)
CREATE INDEX idx_chunks_embedding 
ON document_chunks 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists = 300);
```

**Validation** :
```sql
-- Vérifier les index
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('documents', 'document_chunks');
```

---

### **5. NE PAS REPARSER LES DOCUMENTS DÉJÀ TRAITÉS** ⚠️

**RÈGLE** : Vérifier `parsed_files` AVANT de retraiter

**Raison** :
- 930k documents déjà parsés avec qualité 100%
- Reparser = **14-16h de travail inutile**

**Vérification** :
```sql
-- Vérifier si déjà parsé
SELECT COUNT(*) FROM parsed_files WHERE status = 'completed';
-- Résultat: 930,937 (déjà fait ✅)
```

**Exception** : Si changement de modèle GGUF (dimensions différentes)

---

### **6. WARM-UP OBLIGATOIRE POUR LE BACKEND** 🔥

**RÈGLE** : Toujours faire un warm-up du subprocess llama.cpp au démarrage

**Pourquoi** :
- Première requête : 4.45s (subprocess lazy loading)
- Avec warm-up : 500ms

**Implémentation** :
```python
# backend/core/startup.py (ligne 47)
await embedding_service.get_embedding("test warm-up")
```

**Validation** :
```bash
# Logs backend au démarrage - Doit afficher:
# ✅ "🔥 Warm-up embedding service..."
# ✅ "✅ Embedding service warm et prêt (cache initialisé)"
```

---

### **7. RENDER CPU : DÉSACTIVER AVX2/FMA** 🖥️

**RÈGLE** : Compilation llama-cpp-python SANS optimisations AVX/AVX2/FMA

**Raison** :
- CPU Render : AMD EPYC (supporte SSE4, mais pas toutes les instructions AVX2/FMA)
- Avec AVX2/FMA : **SIGILL (rc=-4)** → Crash subprocess

**Configuration** :
```dockerfile
# backend/Dockerfile (ligne 70)
ENV CMAKE_ARGS="-DGGML_NATIVE=OFF -DGGML_AVX=OFF -DGGML_AVX2=OFF -DGGML_FMA=OFF"
ENV FORCE_CMAKE=1
```

**Validation** :
```bash
# Logs backend - Si SIGILL:
# ❌ "SIGILL DÉTECTÉ (rc=-4): Instruction CPU non supportée"
# ✅ "✅ Subprocess llama.cpp démarré (PID: ...)"
```

---

### **8. WORKER_MODE = READ_ONLY POUR LE BACKEND** 📖

**RÈGLE** : Backend ne doit JAMAIS écrire dans `documents` ou `document_chunks`

**Raison** :
- Backend : READ ONLY (génère embeddings queries, recherche pgvector)
- Workers : WRITE ONLY (génèrent embeddings documents/chunks)
- Séparation des responsabilités

**Configuration** :
```python
# backend/core/config.py (ligne 89)
worker_mode: str = os.getenv("WORKER_MODE", "read_only")  # ✅ READ_ONLY
```

**Validation** :
```bash
# Logs backend - Si tentative d'écriture:
# ❌ "Worker mode READ_ONLY: écriture interdite"
```

---

## 🎯 BONNES PRATIQUES WORKERS

### **1. Lancement avec --batch-size adapté**

**Recommandations** :
```bash
# ✅ Production: Batch 100 (optimal)
python cli.py run --batch-size 100

# ✅ Test: Batch 10 (rapide)
python cli.py run --batch-size 10 --max-batches 1

# ❌ Éviter: Batch 1000 (trop lourd)
python cli.py run --batch-size 1000  # RAM saturée
```

---

### **2. Monitoring en temps réel**

**Commande** :
```bash
# Terminal 1: Worker
cd WorkerLocal
python cli.py run

# Terminal 2: Stats temps réel
python cli.py stats  # Affiche progression
```

**Logs à surveiller** :
```bash
# ✅ Normal
"✅ Batch terminé: 100 traités, 0 erreurs, 5 doublons (2.1s)"

# ⚠️ Attention
"⚠️ Fichier non trouvé (404): legifrance/..."  # Normal si fichier supprimé

# ❌ Problème
"❌ Erreur DB: ..."  # Vérifier connexion Supabase
"⏱️ Timeout chunk ..."  # Réduire batch_size ou max_concurrency
```

---

### **3. Gestion des crashes**

**Si crash Worker** :
```bash
# 1. Vérifier derniers logs
tail -100 worker.log

# 2. Vérifier état queue
python -c "
from db.supabase_client import get_supabase_client
import asyncio
async def check():
    client = await get_supabase_client()
    stats = await client.get_stats()
    print(stats)
asyncio.run(check())
"

# 3. Relancer (anti-duplication gère la reprise)
python cli.py run
```

**Le worker reprend automatiquement** où il s'est arrêté (via `files_queue`)

---

### **4. Nettoyage périodique**

**Supprimer logs anciens** :
```bash
# WorkerLocal
rm ultra_turbo.log.* worker.log.*

# WorkerLocal Chunk
rm ultra_turbo.log.* worker.log.*
```

**Vider cache llama.cpp** (si changement modèle) :
```bash
rm -rf cache/shared/*.gguf
```

---

## 🔐 BONNES PRATIQUES SÉCURITÉ

### **1. Ne JAMAIS commit les secrets**

**Fichiers sensibles** :
- `.env` (service_role_key, API keys)
- `venv/` (environnement Python)
- `cache/` (modèles GGUF)
- `*.log` (logs avec données)

**Vérification** :
```bash
# ✅ .gitignore doit contenir:
.env
venv/
cache/
*.log
```

---

### **2. RLS toujours activées**

**Vérification** :
```sql
-- Toutes les tables doivent avoir RLS ON
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false;

-- Résultat attendu: 0 rows (toutes ont RLS)
```

---

### **3. Service role uniquement pour workers et backend**

**RÈGLE** : Frontend n'a JAMAIS accès au `service_role_key`

**Vérification** :
```bash
# ✅ Frontend utilise:
NEXT_PUBLIC_SUPABASE_ANON_KEY=...  # Anon key (RLS appliquées)

# ✅ Backend utilise:
SUPABASE_SERVICE_ROLE_KEY=...  # Service role (bypass RLS)

# ❌ JAMAIS dans frontend:
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=...  # ❌ DANGEREUX !
```

---

## ⚡ BONNES PRATIQUES PERFORMANCE

### **1. Batch size optimal : 100**

**Pourquoi** :
- Trop petit (10) : Trop d'appels API (latence réseau)
- Trop grand (1000) : Saturation RAM + timeout
- **100** : Sweet spot (testé et validé)

---

### **2. Concurrence max : 50**

**Configuration** :
```python
# config/settings.py
max_concurrency: int = Field(50, ...)  # ✅ Optimal
```

**Raison** :
- 50 threads parallèles : Utilise CPU à 100%
- Plus de 50 : Overhead asyncio (diminishing returns)

---

### **3. Index pgvector : 100-300 listes**

**Règle de calcul** :
```python
# Nombre de listes IVFFlat
lists = sqrt(nombre_de_rows)

# Documents (930k)
lists = sqrt(930000) ≈ 100  # ✅

# Chunks (6M)
lists = sqrt(6000000) ≈ 300  # ✅
```

**Trade-off** :
- Moins de listes : Recherche plus rapide, moins précise
- Plus de listes : Recherche plus lente, plus précise

---

### **4. Timeout adapté à la charge**

**Valeurs recommandées** :
```python
download_timeout: int = 30  # ✅ 30s pour bucket Supabase
processing_timeout: int = 30  # ✅ 30s pour embedding GGUF
```

**Ajustement si problème** :
```python
# Si timeouts fréquents:
download_timeout: int = 60  # Augmenter
max_concurrency: int = 30   # Réduire concurrence
```

---

## 🗄️ BONNES PRATIQUES BASE DE DONNÉES

### **1. Ne JAMAIS supprimer manuellement dans `parsed_files`**

**Raison** :
- `parsed_files` = Anti-duplication
- Suppression → Worker va retraiter → Doublon dans `documents`

**Exception** : Si vraiment besoin, supprimer aussi dans `documents` :
```sql
-- ✅ Supprimer des 2 tables
DELETE FROM documents WHERE file_path = 'xxx';
DELETE FROM parsed_files WHERE file_path = 'xxx';
```

---

### **2. Vérifier plan Supabase avant lancement massif**

**Stockage prévu** :

| Table | Rows | Taille | Plan |
|-------|------|--------|------|
| `documents` | 930k | ~2 GB | ✅ Free OK |
| `document_chunks` | 6M | ~20 GB | ⚠️ Pro requis |
| **Total** | 6.9M | ~22 GB | ⚠️ Pro 25 GB |

**Vérification** :
```bash
# Dashboard Supabase → Settings → Usage
# Vérifier: Database size < limite plan
```

---

### **3. Refresh vue matérialisée toutes les 10 min (pas plus)**

**Configuration** :
```sql
-- pg_cron job (déjà configuré)
SELECT cron.schedule(
    'refresh_admin_metrics',
    '*/10 * * * *',  -- ✅ Toutes les 10 min
    'SELECT refresh_admin_metrics_view();'
);
```

**Raison** :
- Moins de 10 min : CPU élevé
- Plus de 10 min : Métriques trop vieilles

---

## 🔧 BONNES PRATIQUES DÉPLOIEMENT

### **1. Backend : Rebuild sans cache si changement llama-cpp**

**Quand** :
- Changement `CMAKE_ARGS`
- Changement `n_ctx`
- Changement modèle GGUF

**Commande Render** :
```bash
# Dashboard Render → Manual Deploy
# ✅ Cocher "Clear build cache"
```

---

### **2. Frontend : npx vercel --prod après changement**

**Commande** :
```bash
cd ArchiReg-Front
npx vercel --prod --yes
```

**⚠️ Pas `vercel --prod`** (erreur "command not found")

---

### **3. Edge Functions : Déployer les 3 ensemble**

**Commande** :
```bash
supabase functions deploy admin-stats
supabase functions deploy cron-manager
supabase functions deploy system-tests
```

**Raison** : Dépendances croisées (system-tests appelle admin-stats)

---

## 📊 BONNES PRATIQUES MONITORING

### **1. Vérifier CPU Supabase toutes les semaines**

**Dashboard** : https://supabase.com/dashboard/project/joozqsjbcwrqyeqepnev/reports

**Cibles** :
- ✅ CPU : 12-15% (optimal)
- ⚠️ CPU : 20-30% (surveiller)
- ❌ CPU : >50% (optimiser queries)

---

### **2. Surveiller taux d'échec workers**

**Commande** :
```sql
SELECT 
    status,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM files_queue), 2) as percentage
FROM files_queue
GROUP BY status;
```

**Cibles** :
- ✅ Failed : <0.1%
- ⚠️ Failed : 0.1-1%
- ❌ Failed : >1% (problème à investiguer)

---

### **3. Tester RAG régulièrement**

**Dashboard Admin** → Actions → Test RAG

**Vérifications** :
- ✅ Status 200
- ✅ Résultats >0 (si embeddings chargés)
- ✅ Latence <500ms (après warm-up)

---

## 🔄 BONNES PRATIQUES ÉVOLUTION

### **1. Changement de modèle GGUF**

**Procédure** :
```bash
# 1. Télécharger nouveau modèle
wget https://url-du-modele.gguf -O WorkerLocal/models/nouveau-modele.gguf

# 2. Modifier config
# WorkerLocal/config/settings.py
model_filename: str = Field("nouveau-modele.gguf", ...)
vector_dim: int = Field(1024, ...)  # Si dimensions différentes

# 3. ⚠️ Si dimensions changent: REPARSER TOUT
# Vider tables + relancer workers
```

**⚠️ Important** : Modèle différent = embeddings incompatibles

---

### **2. Ajout nouveau type de chunk**

**Exemple** : Ajouter "alinéa" comme type de chunk

**Modification** :
```python
# WorkerLocal Chunk/worker/chunk_batch.py
def _split_into_chunks(self, text: str, file_path: str):
    # STRATÉGIE 5: Alinéas
    alinea_pattern = r"(Alinéa [0-9]+)"
    # ... code découpage ...
```

**Test** :
```bash
python cli.py run --batch-size 10 --max-batches 1
# Vérifier logs pour "chunking_version": "2.0-alineas"
```

---

### **3. Migration vers modèle plus grand (768 → 1024 dims)**

**Procédure complète** :
```bash
# 1. Créer nouvelles tables
CREATE TABLE documents_1024 (..., embedding VECTOR(1024));
CREATE TABLE document_chunks_1024 (..., embedding VECTOR(1024));

# 2. Modifier workers (vector_dim = 1024)

# 3. Lancer workers sur nouvelles tables

# 4. Une fois terminé: Renommer tables
# documents_1024 → documents
# document_chunks_1024 → document_chunks

# 5. Mettre à jour backend
```

**Durée** : ~14-16h (re-génération complète)

---

## 🚨 PIÈGES À ÉVITER

### **1. ❌ Ne PAS lancer 2 workers avec même worker_id**

**Problème** :
- Métriques mélangées dans `ingestion_metrics`
- Impossible de tracer quel worker a fait quoi

**Solution** :
```python
# Toujours avoir worker_id UNIQUE par instance
worker_id: str = Field("workerlocal-ultra-turbo", ...)  # Worker 1
worker_id: str = Field("workerlocal-chunks-v2", ...)     # Worker 2
```

---

### **2. ❌ Ne PAS modifier RLS sur tables workers sans tester**

**Problème** :
- RLS trop restrictives : Workers ne peuvent plus INSERT
- RLS trop permissives : Fuite de données

**Test après modification RLS** :
```bash
# Lancer worker en mode test
python cli.py run --batch-size 1 --max-batches 1

# Vérifier logs:
# ✅ "✅ Document inséré: uuid-..."
# ❌ "403 Forbidden" → RLS trop restrictive
```

---

### **3. ❌ Ne PAS oublier les index après création table**

**Checklist nouvelle table avec embeddings** :
```sql
-- 1. Créer table
CREATE TABLE ma_table (embedding VECTOR(768));

-- 2. ✅ OBLIGATOIRE: Créer index pgvector
CREATE INDEX idx_ma_table_embedding 
ON ma_table 
USING ivfflat (embedding vector_cosine_ops);

-- 3. ✅ OBLIGATOIRE: Activer RLS
ALTER TABLE ma_table ENABLE ROW LEVEL SECURITY;

-- 4. ✅ OBLIGATOIRE: Créer policies
CREATE POLICY ma_table_select_policy ...
CREATE POLICY ma_table_insert_policy ...
```

---

### **4. ❌ Ne PAS ignorer les warnings llama.cpp**

**Warnings critiques** :
```bash
# ❌ CRITIQUE
"WARNING llama_context exceeds trained context length"
→ n_ctx trop élevé → Qualité dégradée → CORRIGER

# ⚠️ INFO
"ggml_backend_cuda_init: no CUDA devices found"
→ Normal si CPU only → Ignorer

# ❌ CRITIQUE
"SIGILL (rc=-4)"
→ Instructions CPU non supportées → Recompiler sans AVX2
```

---

## 📖 COMMANDES UTILES

### **Vérifier état système complet**

```sql
-- Métriques globales
SELECT 
    'files_queue' as table_name, COUNT(*) as rows FROM files_queue
UNION ALL
SELECT 'parsed_files', COUNT(*) FROM parsed_files
UNION ALL
SELECT 'documents', COUNT(*) FROM documents
UNION ALL
SELECT 'document_chunks', COUNT(*) FROM document_chunks;
```

### **Vérifier index pgvector**

```sql
SELECT 
    schemaname, 
    tablename, 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE indexdef LIKE '%ivfflat%';
```

### **Vérifier RLS**

```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;
```

---

## 🎯 CHECKLIST AVANT MODIFICATION MAJEURE

### **Avant de modifier Workers** :

- [ ] Backup table `documents` et `document_chunks`
- [ ] Tester sur 10 fichiers (`--batch-size 10 --max-batches 1`)
- [ ] Vérifier logs (zéro erreur)
- [ ] Vérifier anti-duplication (doublons = succès)
- [ ] Surveiller RAM/CPU pendant 5 min

### **Avant de modifier Backend** :

- [ ] Tester en local (`hypercorn backend.main:app`)
- [ ] Vérifier n_ctx aligné avec modèle
- [ ] Vérifier warm-up implémenté
- [ ] Tester endpoint RAG (`/api/v3/rag/search-legifrance?query=test`)
- [ ] Push sur branche `dev` d'abord (pas `main`)

### **Avant de modifier Tables Supabase** :

- [ ] Backup via SQL export
- [ ] Tester migration sur branche dev Supabase
- [ ] Vérifier RLS après migration
- [ ] Vérifier index pgvector créés
- [ ] Tester workers après migration

---

## 🎉 RÉSUMÉ

**Points critiques** :
1. ✅ n_ctx=512 (aligné modèle)
2. ✅ Workers séquentiels (pas parallèles sur même source)
3. ✅ Service_role pour workers
4. ✅ Index pgvector obligatoires
5. ✅ Pas de reparse inutile
6. ✅ Warm-up backend
7. ✅ AVX2/FMA désactivés (Render)
8. ✅ Worker_mode READ_ONLY (backend)

**Bonnes pratiques** :
- ✅ Batch 100, concurrence 50
- ✅ Monitoring temps réel
- ✅ Tests avant prod
- ✅ RLS toujours activées
- ✅ Secrets jamais committés

**Pièges évités** :
- ❌ Pas 2 workers même worker_id
- ❌ Pas modifier RLS sans test
- ❌ Pas oublier index pgvector
- ❌ Pas ignorer warnings llama.cpp

---

**📅 Dernière mise à jour** : 11 octobre 2025 22:55 UTC  
**✅ Status** : GUIDE COMPLET - 100% VALIDÉ ✅

