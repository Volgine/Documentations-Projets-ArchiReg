# 📚 DOCUMENTATION ARCHITECTURE ARCHIREG

**Date** : 16 janvier 2025  
**Version** : 5.1 MISE À JOUR  
**Nouveautés** : Agent-Orchestrator v5.0 entièrement documenté
**Status** : ✅ COMPLET

---

## 🎯 BIENVENUE

Cette documentation décrit l'architecture complète du projet **ArchiReg**, un système RAG (Retrieval-Augmented Generation) pour l'analyse de documents juridiques (Légifrance).

**Architecture** : Micro-services + Workers + Frontend + Backend RAG

---

## 📂 STRUCTURE DOCUMENTATION

### **01-Supabase** 🗄️

Documentation complète de l'infrastructure Supabase (Base de données PostgreSQL + Storage + Auth + Edge Functions).

📁 **Dossier** : `01-Supabase/`

**Contenu** :
- `README.md` : Guide général Supabase
- `TABLES.md` : Détail des 28 tables
- `CRON-JOBS.md` : Jobs pg_cron (14 jobs)
- `RLS-POLICIES.md` : Sécurité Row Level Security
- `HNSW-INDEXES.md` : Index vectoriels pgvector
- `EDGE-FUNCTIONS-GUIDE.md` : 4 Edge Functions
- `OPTIMISATIONS.md` : Performance + sécurité
- `CONNEXION-PSQL.md` : Guide connexion directe
- `AUDIT.md` : Audit sécurité complet
- `HISTORIQUE.md` : Évolution statistiques
- `CAPACITE-SCALING.md` : Capacité + scaling

**Technologies** :
- PostgreSQL 15
- pgvector (embeddings)
- pg_cron (jobs)
- Deno Edge Functions
- Row Level Security

---

### **02-Micro-service-Legifrance** 📥

Micro-service dédié à la collecte de données juridiques depuis l'API PISTE Légifrance.

📁 **Dossier** : `02-Micro-service-Legifrance/`

**Contenu** :
- `README.md` : Guide général micro-service
- `ARCHITECTURE.md` : Architecture technique détaillée
- `MODES.md` : MASSIVE vs MAINTENANCE
- `RATE-LIMITING.md` : Quotas PISTE
- `PERSISTANCE-ETAT.md` : Scheduler state
- `AUTO-SYNC.md` : Synchro bucket ↔ files_queue
- `FIX-LEGIARTI-v3.0.md` : Fix qualité collecte

**Technologies** :
- FastAPI + Python 3.11
- OAuth2 Client Credentials
- Rate limiting différencié
- Render.com hosting

**Stats** :
- 13,459 fichiers collectés
- Mode MAINTENANCE actif
- Filters : LEGIARTI + 200 chars minimum

---

### **03-Agent-Orchestrator** 🤖

Backend principal : API Chat + RAG + Embeddings + Proxy Micro-service.

📁 **Dossier** : `03-Agent-Orchestrator/`

**Contenu** :
- `README.md` : Guide général backend
- `ARCHITECTURE.md` : Architecture technique complète
- `RAG-EMBEDDINGS.md` : Système RAG + GGUF
- `FIX-ASYNCPG-POOL.md` : Fix connexions DB
- `TESTS-SYSTEME-BACKEND.md` : 9 tests Backend

**Technologies** :
- FastAPI 0.115.5 + Python 3.12 ⬆️ (v5.0)
- Groq API (LLM llama-3.3-70b)
- pgvector 0.7.0 + HNSW (RAG)
- llama-cpp-python (GGUF embeddings 768d)
- asyncpg (DB pool optimisé)
- Hypercorn HTTP/2
- Render.com hosting

**Stats** (v5.0) :
- 117k chunks indexés (chunking v3.0)
- Latence RAG <100ms ⬆️ (optimisé)
- Distance min : 0.681
- Recall >95%
- Code mort éliminé (-42 fichiers)
- Features enterprise (ML security, sanitizer unifié)
- CI/CD automatisé (audit CVE)

**Nouveautés v5.0** 🆕 :
- ✅ Code nettoyé (42 fichiers supprimés)
- ✅ Sanitizer OWASP 2025 unifié
- ✅ ML Anomaly Detection (enterprise)
- ✅ Pydantic Tool Validator
- ✅ CI/CD security (GitHub Actions)
- ✅ Edge Functions migration (admin-stats, cron-manager, system-tests)
- ✅ Documentation complète (9 fichiers, 5,100+ lignes)

**Documentation principale v5.0** :  
→ **[Agent-Orchestrator/docs/](../Agent-Orchestrator/docs/)** ⭐ (recommandé)

---

### **04-ArchiReg-Front** 🎨

Frontend Next.js : Chat streaming + Dashboard Admin + Tests système.

📁 **Dossier** : `04-ArchiReg-Front/`

**Contenu** :
- `README.md` : Guide général frontend
- `ARCHITECTURE.md` : Architecture technique frontend

**Technologies** :
- Next.js 14 + React 18
- TypeScript strict
- Tailwind CSS
- Zustand (state)
- React-Markdown
- Supabase Auth
- Vercel hosting

**Features** :
- Chat streaming SSE
- Dashboard admin (4 onglets, 21 métriques)
- Tests système (27 tests)
- Markdown + code highlighting

---

### **05-WorkerLocal** 🔧

CLI Python pour parsing documents + **chunking granulaire** + génération embeddings **PAR CHUNK**.

📁 **Dossier** : `05-WorkerLocal/`

**Contenu** :
- `README.md` : Guide général WorkerLocal
- `ARCHITECTURE.md` : Architecture technique worker

**Technologies** :
- Python 3.11
- LangChain RecursiveCharacterTextSplitter
- llama-cpp-python (GGUF)
- Supabase API (UPSERT idempotent)

**Stats v3.0** :
- 117,148 chunks générés ✅
- 13,441 fichiers traités ✅
- Vitesse : ~87 fichiers/min (50 concurrency)
- Chunking : LangChain (800/200)
- UPSERT idempotent
- Taux erreur : <0.1%

---

## 🔄 FLUX GLOBAL ARCHITECTURE

```mermaid
graph TB
    subgraph "1️⃣ COLLECTE"
        MS[Micro-service Légifrance PISTE]
        BKT[Bucket Supabase Storage<br/>agentbasic-legifrance-raw]
        FQ[files_queue<br/>Queue traitement]
        
        MS -->|Upload JSON| BKT
        MS -->|INSERT| FQ
    end
    
    subgraph "2️⃣ TRAITEMENT: WORKERLOCAL v3.0"
        WL[WorkerLocal Ultra-Turbo<br/>✅ 117k chunks]
        LC[LangChain Splitter<br/>800/200]
        
        FQ -->|SELECT pending (100)| WL
        WL -->|Parse + Chunk| LC
        LC -->|~8.7 chunks/fichier| EMB[GGUF Embeddings]
        EMB -->|UPSERT idempotent| CHUNKS[document_chunks<br/>117,148 rows]
        
        CHUNKS -->|Vecteurs 768 dims| HNSW[pgvector + HNSW<br/>97 MB]
    end
    
    subgraph "3️⃣ BACKEND: RAG"
        BE[Backend Agent-Orchestrator]
        GROQ[Groq API<br/>llama-3.3-70b-versatile]
        GGUF[GGUF Model Local<br/>solon-embeddings-base]
        
        BE -->|READ ONLY| HNSW
        BE -->|Génère embedding query| GGUF
        BE -->|Recherche vectorielle| HNSW
        BE -->|Chat LLM| GROQ
    end
    
    subgraph "4️⃣ FRONTEND"
        FE[Frontend Next.js]
        ADMIN[Dashboard Admin]
        CHAT[Chat Streaming SSE]
        
        FE --> CHAT
        FE --> ADMIN
        CHAT -->|API RAG| BE
        ADMIN -->|Edge Functions| EDGE[Supabase Edge Functions]
    end
    
    style WL fill:#4ecdc4
    style BE fill:#ff6b6b
    style CHUNKS fill:#95e1d3
    style GGUF fill:#ffd93d
    style BKT fill:#ffd93d
```

---

## 🎯 DÉPLOIEMENTS

### **Production**

| Service | Host | URL | Status |
|---------|------|-----|--------|
| **Frontend** | Vercel | https://archi-reg-front.vercel.app | ✅ Live |
| **Backend** | Render | https://agent-orchestrateur-backend.onrender.com | ✅ Live |
| **Micro-service** | Render | https://micro-service-data-legifrance-piste.onrender.com | ✅ Live |
| **Supabase** | Supabase Cloud | https://joozqsjbcwrqyeqepnev.supabase.co | ✅ Live |
| **WorkerLocal** | Local Windows | - | ✅ Terminé |

---

## 📊 STATISTIQUES GLOBALES

### **Base de Données**

| Table | Rows | Size | Index HNSW | Status |
|-------|------|------|------------|--------|
| `document_chunks` | 117,148 | 803 MB | 97 MB (m=16, ef=64) | ✅ Complet |
| `files_queue` | 13,459 | ~2 MB | - | ✅ Tous traités |
| `parsed_files` | 13,458 | ~5 MB | - | ✅ Tracking OK |
| `conversations` | 219 | 200 kB | - | ✅ Actif |
| `chat_messages` | 16,544 | ~10 MB | - | ✅ Actif |

**Total DB** : ~1.5 GB / 8 GB (18.75% utilisé)  
**Plan Supabase** : Pro (suffisant pour scaling futur)

---

### **Performance**

| Métrique | Valeur | Notes |
|----------|--------|-------|
| **RAG Latence** | <100ms | Embedding + Search HNSW |
| **RAG Distance typique** | 0.7-0.85 | Similaire (modèle Solon Q8_0) |
| **RAG Seuil optimal** | 0.9 | Trouve 8-20 chunks pertinents |
| **Chat Streaming** | <500ms TTFB | Groq ultra-rapide |
| **Edge Functions** | <150ms | Latence moyenne |
| **Worker Speed** | ~87 fichiers/min | 50 concurrency |
| **Chunking** | 800/200 chars | LangChain optimal |

---

## 🔧 FIXES CRITIQUES APPLIQUÉS

### **1. Fix Embeddings Incompatibles** (13 octobre 2025)

**Problème** : Workers (Windows AVX2) ≠ Backend (Linux no-AVX2)  
**Solution** : Forcer compilation source sans AVX2/FMA  
**Résultat** : ✅ Embeddings compatibles (fix critique)

**Doc** : `16-FIX-EMBEDDINGS-INCOMPATIBLES.md`

---

### **4. Fix RAG avec Chunking v3.0** (19-20 octobre 2025)

**Problème** : RAG retourne 0 résultats (documents trop gros, avg 6,700 chars + seuil 0.7 trop strict)  
**Solution** : Chunking granulaire LangChain (800/200) + UPSERT idempotent + Seuil 0.9  
**Résultat** : ✅ RAG fonctionnel (distance 0.7-0.85, 8-20 résultats par query)

**Doc** : `05-WorkerLocal/ARCHITECTURE.md` + `01-Supabase/HNSW-INDEXES.md`

---

### **2. Fix Asyncpg Pool** (13 octobre 2025)

**Problème** : `{:shutdown, :client_termination}` sur RAG search  
**Solution** : Pool asyncpg + Supavisor Session Mode  
**Résultat** : ✅ Connexions stables + latence <200ms

**Doc** : `21-FIX-POOL-ASYNCPG.md` + `03-Agent-Orchestrator/FIX-ASYNCPG-POOL.md`

---

### **3. Fix Qualité Collecte LEGIARTI** (15 octobre 2025)

**Problème** : 90% documents vides (LEGISCTA vs LEGIARTI)  
**Solution** : Filtre LEGIARTI + minimum 200 chars  
**Résultat** : ✅ Qualité collecte 100%

**Doc** : `22-FIX-LEGIARTI-QUALITE-COLLECTE.md` + `02-Micro-service-Legifrance/FIX-LEGIARTI-v3.0.md`

---

## 🚀 ACCOMPLISSEMENTS

### **Phase 1 : Chunking granulaire** ✅

- ✅ WorkerLocal v3.0 développé avec LangChain
- ✅ 117,148 chunks générés
- ✅ Construction index HNSW (m=16, ef=64)
- ✅ RAG fonctionnel (seuil 0.9, distance 0.7-0.85)
- ✅ Migration table documents → document_chunks
- ✅ Optimisation seuil de similarité adapté au modèle Solon

### **Phase 2 : Optimisations Futures** 🔮

- ⏸️ Caching embeddings
- ⏸️ Reranking résultats RAG
- ⏸️ Fine-tuning modèle embeddings
- ⏸️ Monitoring Grafana

---

## 📖 GUIDE DE LECTURE

### **Pour comprendre l'architecture globale** :
1. **README.md** (ce fichier)
2. `01-ARCHITECTURE-GLOBALE.md` (vue d'ensemble)
3. `00-INDEX.md` (navigation complète)

### **Pour déployer un service** :
1. Supabase → `01-Supabase/README.md`
2. Micro-service → `02-Micro-service-Legifrance/README.md`
3. Backend → `03-Agent-Orchestrator/README.md`
4. Frontend → `04-ArchiReg-Front/README.md`

### **Pour lancer les workers** :
1. WorkerLocal v3.0 (Chunking intégré) → `05-WorkerLocal/README.md`

---

## 🎉 Conclusion

**Architecture ArchiReg v5.1 - Chunking v3.0** :
- ✅ 5 services déployés
- ✅ 117k chunks indexés (chunking granulaire)
- ✅ RAG ultra-performant (<100ms, seuil 0.9, distance 0.7-0.85)
- ✅ Tests système (27 tests)
- ✅ Chunking LangChain (800/200)
- ✅ UPSERT idempotent
- ✅ Migration documents → document_chunks
- ✅ Documentation complète réorganisée
- ✅ Qualité collecte 100%

**Système production-ready !** 🚀

