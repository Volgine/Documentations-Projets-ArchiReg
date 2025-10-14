# 📚 RÉSUMÉ ARCHITECTURE v4.7.0 - CHUNKING GRANULAIRE COMPLET

**Date** : 13 octobre 2025 08:30 UTC  
**Version** : 5.2.0 FIX RAG VERSION LLAMA-CPP  
**Status** : ✅ **RAG FONCTIONNEL** (llama-cpp==0.3.16, threshold 0.70, 3 docs trouvés) + Microservice v2.5 + Dashboard 100%

---

## 🎯 Vue d'Ensemble Ultra-Simplifiée

### **4 Services + 2 Types de Workers**

```
┌──────────────┐
│   FRONTEND   │  Vercel (Next.js)
└──────┬───────┘
       │
   ┌───┴────┬────────┬─────────┐
   │        │        │         │
   ▼        ▼        ▼         ▼
┌──────┐ ┌──────┐ ┌────────┐ ┌─────────┐
│ EDGE │ │BACKEND│ │ MICRO  │ │ WORKERS │
│FUNCS │ │RENDER │ │SERVICE │ │ LOCAL   │
└───┬──┘ └───┬──┘ └────┬───┘ └────┬────┘
    │        │         │           │
    └────────┴─────────┴───────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   SUPABASE DB   │
         │  • documents    │ ← WorkerLocal (930k docs, 1 doc = 1 embedding)
         │  • doc_chunks   │ ← WorkerLocal Chunk (0 rows, prêt pour 6M chunks)
         │  • pgvector     │
         └─────────────────┘
```

---

## 🏭 LES 2 WORKERS (ARCHITECTURE DUALE)

### **WorkerLocal (v1.0)** ✅ **930k DOCUMENTS GÉNÉRÉS**

**Rôle** : Génère embeddings de **contexte global**

```
Bucket Légifrance (1M fichiers JSON)
           ↓
    WorkerLocal x3 (PC Windows)
           ↓
  Parse JSON → Texte complet
           ↓
  1 document = 1 embedding GGUF
           ↓
Table `documents` (930,364 rows)
  - content: Texte complet du document
  - embedding: Vector 768 dims (contexte global)
  - file_path: Lien vers bucket
```

**Commande** :
```bash
cd WorkerLocal
python cli.py run
```

**Métriques** :
- ✅ **930,364 documents** avec embeddings
- ✅ **99.999% succès** (10 échecs sur 930k)
- ✅ **n_ctx=512** (qualité 100%)
- ✅ **worker_id** : `"workerlocal-ultra-turbo"`
- ✅ **DÉJÀ TERMINÉ** (pas besoin de relancer)

---

### **WorkerLocal Chunk (v2.0)** ✅ **PRÊT À GÉNÉRER 6M CHUNKS**

**Rôle** : Génère embeddings **granulaires** (articles, sections, paragraphes)

```
Bucket Légifrance (même source)
           ↓
  WorkerLocal Chunk x3 (PC Windows)
           ↓
  Parse JSON → Texte complet
           ↓
  Lookup document_id parent (via file_path)
           ↓
  Découpage intelligent :
    - Stratégie 1: Articles (Article L123-1)
    - Stratégie 2: Sections (Section IV)
    - Stratégie 3: Paragraphes (si >2000 chars)
    - Stratégie 4: Fallback (texte complet)
           ↓
  1 document = N chunks = N embeddings GGUF
           ↓
Table `document_chunks` (0 rows → 6M rows)
  - content: Texte du chunk (article/section)
  - embedding: Vector 768 dims (contexte granulaire)
  - document_id: Lien vers parent (ou NULL)
  - chunk_index: Ordre dans le document
```

**Commande** :
```bash
cd "WorkerLocal Chunk"
python cli.py run --batch-size 100

# Ou 3 workers parallèles (recommandé)
# Terminal 1, 2, 3: même commande
```

**Métriques prévues** :
- ⏸️ **930,394 fichiers** à traiter
- ⏸️ **~7-9M chunks** à générer (8-10 chunks/doc)
- ⏸️ **14-16 heures** (3 workers)
- ✅ **n_ctx=512** (qualité 100%)
- ✅ **worker_id** : `"workerlocal-chunks-v2"`
- ✅ **PRÊT À LANCER** maintenant

---

## 🔄 WORKFLOW MODE CONTINU

### **Comment ça marche** :

```python
while True:  # ✅ Boucle infinie
    # 1. Récupère 100 fichiers depuis files_queue (status=pending)
    files = get_unprocessed_files(limit=100)
    
    # 2. Traite les 100 en parallèle (concurrence=50)
    for file in files:
        - Télécharge JSON
        - Parse texte
        - Découpe en chunks (articles/sections)
        - Génère embedding par chunk
        - Insert dans document_chunks
    
    # 3. Si 0 fichiers traités → compte batch vide
    if processed == 0:
        empty_batches += 1
        
        # Arrêt après 3 batchs vides consécutifs
        if empty_batches >= 3:
            break  # ✅ Arrêt propre
    
    # 4. Pause 0.5s puis recommence
    sleep(0.5)
```

**Résultat** :
- ✅ **Mode aspirateur** : Traite TOUT jusqu'à épuisement
- ✅ **100 fichiers** par batch
- ✅ **Pause 0.5s** entre batchs (évite surcharge)
- ✅ **Arrêt automatique** : 3 batchs vides = fini

---

## 📊 ARCHITECTURE HYBRIDE (2 NIVEAUX)

### **Niveau 1 : Documents Globaux** (ACTUEL) ✅

**Table** : `documents` (930k rows)

**Usage** :
- 🎯 Recherche large : "urbanisme", "PLU", "règlements"
- 🎯 Contexte général
- 🎯 Filtre initial : 930k → 100 docs pertinents

**Latence** : ~50ms

---

### **Niveau 2 : Chunks Granulaires** (PRÊT) ✅

**Table** : `document_chunks` (0 rows → 6M rows après lancement)

**Usage** :
- 🎯 Recherche précise : "Article L123-1", "Section IV"
- 🎯 Citation exacte
- 🎯 Affinage : 100 docs → 10 chunks ultra-précis

**Latence** : ~30ms (recherche dans 100 docs)

---

### **Recherche Hybride** (FUTUR Backend)

```
User Query: "Article L123-1 hauteur"
           ↓
Backend RAG → Recherche Niveau 1 (documents)
           ↓
Top 100 documents pertinents (~50ms)
           ↓
Backend RAG → Recherche Niveau 2 (chunks dans ces 100 docs)
           ↓
Top 10 chunks ultra-précis (~30ms)
           ↓
Total: ~80ms (au lieu de 500ms si recherche dans 6M chunks)
```

**À implémenter après génération chunks** :
- Endpoint `/api/v3/rag/search-hybrid`
- Frontend toggle recherche globale/hybride

---

## 🔐 SÉCURITÉ

### **Tables avec RLS** ✅

| Table | RLS | SELECT | INSERT | Status |
|-------|-----|--------|--------|--------|
| **documents** | ✅ ON | user_id OU NULL | user_id | ✅ Sécurisé |
| **document_chunks** | ✅ ON | service_role OU parent | service_role | ✅ Aligné |
| **parsed_files** | ✅ ON | service_role | service_role | ✅ Sécurisé |
| **files_queue** | ✅ ON | service_role | service_role | ✅ Sécurisé |

**Workers** : Utilisent `service_role_key` → Accès complet ✅

---

## 📊 MÉTRIQUES ACTUELLES (11 OCT 2025)

| Métrique | Valeur | Source |
|----------|--------|--------|
| **Fichiers bucket** | 1,077,264 | Bucket Légifrance |
| **Files_queue** | 931,743 | Table queue |
| **Parsed_files** | 930,937 | Table anti-duplication |
| **Documents** | 930,364 | Table documents (embeddings globaux) |
| **Document_chunks** | 0 | Table chunks (prêt à générer) |
| **Status completed** | 930,846 | files_queue |
| **Status processing** | 887 | files_queue |
| **Status failed** | 10 | files_queue (0.001%) |

---

## 🎯 DIFFÉRENCES CLÉS

| Aspect | WorkerLocal | WorkerLocal Chunk |
|--------|-------------|-------------------|
| **worker_id** | `workerlocal-ultra-turbo` | `workerlocal-chunks-v2` |
| **Classe Python** | `BatchWorker` | `ChunkBatchWorker` |
| **Fichier** | `worker/batch.py` | `worker/chunk_batch.py` |
| **Table cible** | `documents` | `document_chunks` |
| **Découpage** | Aucun (texte complet) | 4 stratégies intelligentes |
| **Output** | 1 doc = 1 embedding | 1 doc = N chunks = N embeddings |
| **Lien parent** | N/A | Automatique via file_path |
| **Status** | ✅ Terminé (930k docs) | ✅ Prêt à lancer (0 chunks) |

---

## 🚀 PROCHAINES ÉTAPES

### **MAINTENANT** 🔥
1. ✅ Rebuild Render backend (sans cache) → Fix n_ctx=512 + warm-up
2. ✅ Tester RAG après rebuild → Vérifier latence <500ms

### **QUAND TU VEUX** ⏸️
1. Lancer WorkerLocal Chunk (3 workers × 14-16h)
2. Monitoring génération chunks (6M chunks estimés)
3. Implémenter `/api/v3/rag/search-hybrid` dans backend
4. Ajouter toggle recherche hybride dans frontend

---

## 🎉 RÉSUMÉ ULTRA-SIMPLE

**WorkerLocal** :
- ✅ Génère embeddings **contexte global** (1 doc = 1 embedding)
- ✅ Table `documents` (930k rows)
- ✅ DÉJÀ TERMINÉ ✅

**WorkerLocal Chunk** :
- ✅ Génère embeddings **granulaires** (1 doc = N embeddings)
- ✅ Table `document_chunks` (0 rows, prêt)
- ✅ PRÊT À LANCER ✅

**Backend RAG** :
- ✅ Recherche dans `documents` (opérationnel)
- ⏸️ Recherche hybride (à faire après génération chunks)

---

**📅 Date** : 12 octobre 2025 13:00 UTC  
**✅ Status** : ARCHITECTURE DUALE 100% + MICROSERVICE V2.4 PERSISTANCE ✅

