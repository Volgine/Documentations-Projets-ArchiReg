# 📑 INDEX GÉNÉRAL - DOCUMENTATION ARCHIREG

**Date** : 15 octobre 2025  
**Version** : 5.0 RÉORGANISÉE  
**Navigation** : Guide complet de la documentation

---

## 🎯 INTRODUCTION

Ce fichier INDEX sert de **table des matières** pour naviguer dans toute la documentation ArchiReg.

**Structure** : 6 dossiers principaux (01-Supabase → 06-WorkerLocal-Chunk)

---

## 📂 01-SUPABASE 🗄️

**Dossier** : `01-Supabase/`

📑 **[INDEX COMPLET → 01-Supabase/00-INDEX.md](./01-Supabase/00-INDEX.md)** ⭐

### **Documentation disponible**

- **16 fichiers numérotés** (01-TABLES → 15-TABLES-GUIDE)
- **README** : Vue d'ensemble Supabase
- **00-INDEX** : Navigation complète avec guides par niveau

### **Fichiers principaux**

| Fichier | Description | Importance |
|---------|-------------|-----------|
| [01-TABLES.md](./01-Supabase/01-TABLES.md) | État actuel 28 tables | ⭐⭐⭐ |
| [03-CRON-JOBS.md](./01-Supabase/03-CRON-JOBS.md) | 14 jobs pg_cron | ⭐⭐⭐ |
| [04-RLS-POLICIES.md](./01-Supabase/04-RLS-POLICIES.md) | Sécurité RLS | ⭐⭐⭐ |
| [05-HNSW-INDEXES.md](./01-Supabase/05-HNSW-INDEXES.md) | Index vectoriels | ⭐⭐⭐ |
| [06-EDGE-FUNCTIONS-GUIDE.md](./01-Supabase/06-EDGE-FUNCTIONS-GUIDE.md) | 3 Edge Functions | ⭐⭐⭐ |
| [09-OPTIMISATIONS.md](./01-Supabase/09-OPTIMISATIONS.md) | Perfs +50-60% | ⭐⭐⭐ |

### **Sous-dossiers**

- `EDGE-FUNCTIONS/` : Code TypeScript (admin-stats, cron-manager, system-tests)
- `MIGRATIONS/SQL/` : 6 scripts SQL (tous ✅ en production)

---

## 📂 02-MICRO-SERVICE-LEGIFRANCE 📥

**Dossier** : `02-Micro-service-Legifrance/`

📑 **[INDEX COMPLET → 02-Micro-service-Legifrance/00-INDEX.md](./02-Micro-service-Legifrance/00-INDEX.md)** ⭐

### **Documentation disponible**

- **8 fichiers** : 6 numérotés (01-ARCHITECTURE → 06-FIX-LEGIARTI) + README + INDEX
- **Version** : 3.0 UNIFICATION + FIX LEGIARTI
- **Status** : ✅ EN PRODUCTION (Mode MAINTENANCE)

### **Fichiers principaux**

| Fichier | Description | Importance |
|---------|-------------|-----------|
| [01-ARCHITECTURE.md](./02-Micro-service-Legifrance/01-ARCHITECTURE.md) | Architecture technique complète | ⭐⭐⭐ |
| [02-MODES.md](./02-Micro-service-Legifrance/02-MODES.md) | MASSIVE vs MAINTENANCE | ⭐⭐⭐ |
| [03-RATE-LIMITING.md](./02-Micro-service-Legifrance/03-RATE-LIMITING.md) | Quotas PISTE (1.28M/jour) | ⭐⭐⭐ |
| [06-FIX-LEGIARTI-v3.0.md](./02-Micro-service-Legifrance/06-FIX-LEGIARTI-v3.0.md) | Fix qualité 100% | ⭐⭐⭐ |

---

## 📂 03-AGENT-ORCHESTRATOR 🤖

**Dossier** : `03-Agent-Orchestrator/`

📑 **[INDEX COMPLET → 03-Agent-Orchestrator/00-INDEX.md](./03-Agent-Orchestrator/00-INDEX.md)** ⭐

⚠️ **Documentation v5.0 complète** : [Agent-Orchestrator/docs/](../Agent-Orchestrator/docs/) (recommandé)

### **Documentation disponible**

- **7 fichiers** : 5 numérotés (01-ARCHITECTURE → 05-TESTS) + README + INDEX
- **Version** : 5.0.0 (mise à jour 16/01/2025)
- **Status** : ✅ EN PRODUCTION (312k docs, RAG <200ms)
- **Nouveautés** : Code nettoyé, Edge Functions, CI/CD security

### **Fichiers principaux**

| Fichier | Description | Importance |
|---------|-------------|-----------|
| [01-ARCHITECTURE.md](./03-Agent-Orchestrator/01-ARCHITECTURE.md) | Architecture backend FastAPI | ⭐⭐⭐ |
| [02-POURQUOI-RAG.md](./03-Agent-Orchestrator/02-POURQUOI-RAG.md) | Guide éducatif RAG | ⭐⭐⭐ |
| [03-RAG-EMBEDDINGS.md](./03-Agent-Orchestrator/03-RAG-EMBEDDINGS.md) | Implémentation RAG + GGUF | ⭐⭐⭐ |
| [04-FIX-ASYNCPG-POOL.md](./03-Agent-Orchestrator/04-FIX-ASYNCPG-POOL.md) | Fix connexions DB | ⭐⭐⭐ |
| [05-TESTS-SYSTEME-BACKEND.md](./03-Agent-Orchestrator/05-TESTS-SYSTEME-BACKEND.md) | 9 tests Backend | ⭐⭐ |

---

## 📂 04-ARCHIREG-FRONT 🎨

**Dossier** : `04-ArchiReg-Front/`

⚠️ **Pas d'INDEX encore** - 2 fichiers seulement (README + ARCHITECTURE)

### **Documentation disponible**

| Fichier | Description | Importance |
|---------|-------------|-----------|
| [README.md](./04-ArchiReg-Front/README.md) | Guide général frontend | ⭐⭐ |
| [ARCHITECTURE.md](./04-ArchiReg-Front/ARCHITECTURE.md) | Next.js 14 + React 18 + TypeScript | ⭐⭐⭐ |

### **Contenu**

- Chat streaming SSE + Markdown renderer
- Dashboard admin (4 onglets, 21 métriques)
- Tests système (27 tests)
- Supabase Auth + Realtime

---

## 📂 05-WORKERLOCAL 🔧

**Dossier** : `05-WorkerLocal/`

⚠️ **Pas d'INDEX encore** - 3 fichiers (README + ARCHITECTURE + FIX)

### **Documentation disponible**

| Fichier | Description | Importance |
|---------|-------------|-----------|
| [README.md](./05-WorkerLocal/README.md) | Guide général WorkerLocal | ⭐⭐ |
| [ARCHITECTURE.md](./05-WorkerLocal/ARCHITECTURE.md) | CLI Python + GGUF embeddings GLOBAUX | ⭐⭐⭐ |
| [FIX-EMBEDDINGS-INCOMPATIBLES.md](./05-WorkerLocal/FIX-EMBEDDINGS-INCOMPATIBLES.md) | Fix critique AVX2/FMA | ⭐⭐⭐ |

### **Stats**

- ✅ 312k documents traités
- ✅ 37.5 fichiers/s (3 workers)
- ✅ Taux erreur <0.03%

---

## 📂 06-WORKERLOCAL-CHUNK 🧩

**Dossier** : `06-WorkerLocal-Chunk/`

⚠️ **Pas d'INDEX encore** - 2 fichiers seulement (README + ARCHITECTURE)

### **Documentation disponible**

| Fichier | Description | Importance |
|---------|-------------|-----------|
| [README.md](./06-WorkerLocal-Chunk/README.md) | Guide général Worker Chunk | ⭐⭐ |
| [ARCHITECTURE.md](./06-WorkerLocal-Chunk/ARCHITECTURE.md) | CLI Python + Chunking + GGUF embeddings GRANULAIRES | ⭐⭐⭐ |

### **Estimations**

- ⏸️ Prêt (pas encore lancé)
- ~6M chunks estimés (ratio 1:20)
- Chunk size : 500-1000 tokens
- Overlap : 10%

---

## 🗂️ FICHIERS RACINE

### **Documentation globale**

| Fichier | Description | Statut |
|---------|-------------|--------|
| `README.md` | Guide principal + overview | ⭐ START HERE |
| `00-INDEX.md` | Ce fichier (navigation) | Navigation |
| `01-ARCHITECTURE-GLOBALE.md` | Vue d'ensemble architecture | ⭐ Important |
| `02-WEBSOCKETS-VS-REALTIME.md` | Migration Realtime | Historique |
| `03-INFRASTRUCTURE.md` | URLs + services | Référence |

### **Fichiers hérités (legacy)**

| Fichier | Description | Action |
|---------|-------------|--------|
| `08-TESTS-SYSTEME.md` | Tests hybrides | ✅ À garder |
| `09-RAG-EMBEDDINGS.md` | RAG v1 | ⏸️ Legacy (voir 03-Agent-Orchestrator) |
| `10-CHUNKING-GRANULAIRE.md` | Chunking v1 | ⏸️ Legacy (voir 06-WorkerLocal-Chunk) |
| `11-BONNES-PRATIQUES.md` | Best practices | ✅ À garder |
| `12-MICRO-SERVICE-LEGIFRANCE.md` | Micro-service v1 | ⏸️ Legacy (voir 02-Micro-service-Legifrance) |
| `13-POURQUOI-RAG-EMBEDDINGS.md` | Explications RAG | ✅ À garder (éducatif) |
| `16-FIX-EMBEDDINGS-INCOMPATIBLES.md` | Fix critique | ✅ À garder |
| `17-FILES-QUEUE-SYNC.md` | Auto-sync | ⏸️ Legacy (voir 02-Micro-service-Legifrance/AUTO-SYNC.md) |

---

## 🎯 GUIDES DE LECTURE RECOMMANDÉS

### **🚀 DÉBUTANT : Comprendre le système**

1. **`README.md`** : Vue d'ensemble
2. **`01-ARCHITECTURE-GLOBALE.md`** : Architecture générale
3. **`13-POURQUOI-RAG-EMBEDDINGS.md`** : Pourquoi RAG ?
4. **`01-Supabase/README.md`** : Infrastructure DB
5. **`03-Agent-Orchestrator/ARCHITECTURE.md`** : Backend RAG

### **🔧 DÉVELOPPEUR : Déployer les services**

1. **`01-Supabase/TABLES.md`** : Comprendre DB
2. **`02-Micro-service-Legifrance/ARCHITECTURE.md`** : Collecte données
3. **`03-Agent-Orchestrator/ARCHITECTURE.md`** : Backend RAG
4. **`04-ArchiReg-Front/ARCHITECTURE.md`** : Frontend
5. **`05-WorkerLocal/ARCHITECTURE.md`** : Workers parsing

### **⚙️ DEVOPS : Maintenance et monitoring**

1. **`01-Supabase/CRON-JOBS.md`** : Jobs automatiques
2. **`01-Supabase/RLS-POLICIES.md`** : Sécurité
3. **`01-Supabase/OPTIMISATIONS.md`** : Performance
4. **`02-Micro-service-Legifrance/RATE-LIMITING.md`** : Quotas API
5. **`03-Agent-Orchestrator/TESTS-SYSTEME-BACKEND.md`** : Tests

### **🔬 EXPERT : Optimisation et scaling**

1. **`01-Supabase/HNSW-INDEXES.md`** : Index vectoriels
2. **`01-Supabase/CAPACITE-SCALING.md`** : Scaling DB
3. **`03-Agent-Orchestrator/RAG-EMBEDDINGS.md`** : RAG avancé
4. **`06-WorkerLocal-Chunk/ARCHITECTURE.md`** : Chunking granulaire
5. **`16-FIX-EMBEDDINGS-INCOMPATIBLES.md`** : Fix critique

---

## 🔍 RECHERCHE PAR SUJET

### **RAG + Embeddings**
- `03-Agent-Orchestrator/RAG-EMBEDDINGS.md` ⭐
- `13-POURQUOI-RAG-EMBEDDINGS.md` 📖
- `16-FIX-EMBEDDINGS-INCOMPATIBLES.md` 🔧

### **Base de données**
- `01-Supabase/TABLES.md` ⭐
- `01-Supabase/HNSW-INDEXES.md` ⭐
- `01-Supabase/CONNEXION-PSQL.md` 🔧

### **Collecte données**
- `02-Micro-service-Legifrance/ARCHITECTURE.md` ⭐
- `02-Micro-service-Legifrance/MODES.md` ⚙️
- `02-Micro-service-Legifrance/FIX-LEGIARTI-v3.0.md` 🔧

### **Workers**
- `05-WorkerLocal/ARCHITECTURE.md` ⭐
- `06-WorkerLocal-Chunk/ARCHITECTURE.md` ⭐

### **Frontend**
- `04-ArchiReg-Front/ARCHITECTURE.md` ⭐

### **Tests**
- `03-Agent-Orchestrator/TESTS-SYSTEME-BACKEND.md` ⭐
- `01-Supabase/EDGE-FUNCTIONS-GUIDE.md` (tests Edge)
- `08-TESTS-SYSTEME.md` (vue hybride)

### **Sécurité**
- `01-Supabase/RLS-POLICIES.md` ⭐
- `01-Supabase/AUDIT.md` 🔒
- `02-Micro-service-Legifrance/RATE-LIMITING.md` ⏱️

### **Performance**
- `01-Supabase/OPTIMISATIONS.md` ⭐
- `01-Supabase/HNSW-INDEXES.md` 🔍
- `03-Agent-Orchestrator/FIX-ASYNCPG-POOL.md` 🔧

---

## 📊 STATISTIQUES DOCUMENTATION

### **Dossiers**

| Dossier | Fichiers | INDEX | Status |
|---------|----------|-------|--------|
| 01-Supabase | 16 + README + INDEX | ✅ | ✅ Complet |
| 02-Micro-service-Legifrance | 6 + README + INDEX | ✅ | ✅ Complet |
| 03-Agent-Orchestrator | 5 + README + INDEX | ✅ | ✅ Complet |
| 04-ArchiReg-Front | 1 + README | ❌ | ⏸️ À compléter |
| 05-WorkerLocal | 2 + README | ❌ | ⏸️ À compléter |
| 06-WorkerLocal-Chunk | 1 + README | ❌ | ⏸️ À compléter |
| **Racine** | 5 fichiers | ✅ (ce fichier) | ✅ Complet |

**Total** : ~50 fichiers Markdown

---

## 🎉 CONCLUSION

**Documentation ArchiReg v5.0** :
- ✅ 6 dossiers organisés par service
- ✅ 48 fichiers documentation
- ✅ 15,100 lignes de doc
- ✅ Architecture complète documentée
- ✅ Guides de lecture par niveau
- ✅ Index de recherche par sujet

**Documentation complète et bien organisée !** 📚
