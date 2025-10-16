# 📑 INDEX - BACKEND AGENT-ORCHESTRATOR

**Date** : 16 janvier 2025  
**Version** : 5.0.0  
**Status** : ✅ EN PRODUCTION

⚠️ **ATTENTION** : Documentation v5.0 complète disponible dans :
→ **[Agent-Orchestrator/docs/](../../../Agent-Orchestrator/docs/)** (recommandé ⭐)

Cette documentation (DOCS-ARCHITECTURE/03-Agent-Orchestrator) est conservée pour référence historique.

---

## 🎯 DÉMARRAGE RAPIDE

**Nouveau ?** Commence par :
1. **[README.md](./README.md)** - Vue d'ensemble backend
2. **[01-ARCHITECTURE.md](./01-ARCHITECTURE.md)** - Architecture technique
3. **[02-POURQUOI-RAG.md](./02-POURQUOI-RAG.md)** - Comprendre le RAG

---

## 📚 DOCUMENTATION COMPLÈTE

### **🏗️ ARCHITECTURE** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) | **Architecture backend** complète (services, API, déploiement) | 465 lignes | ⭐⭐⭐ |

**Contenu** :
- Responsabilités backend (Chat, RAG, Embeddings, Proxy, Tests)
- Services principaux (ChatService, RAGService, GGUFEmbeddingService, etc.)
- Flux RAG complet
- Structure fichiers
- Variables d'environnement
- Déploiement Render (Hypercorn HTTP/2)

---

### **🧠 RAG & EMBEDDINGS** (2 fichiers)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [02-POURQUOI-RAG.md](./02-POURQUOI-RAG.md) | **Guide éducatif** : Pourquoi RAG ? Limitations LLM, workflow | 569 lignes | ⭐⭐⭐ |
| [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md) | **Implémentation RAG** : GGUF, pgvector, HNSW, performance | 373 lignes | ⭐⭐⭐ |

**Quick Links** :
- Comprendre RAG → [02-POURQUOI-RAG.md](./02-POURQUOI-RAG.md)
- Implémentation technique → [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md)

**Contenu 02-POURQUOI-RAG.md** :
- Limitations LLM (context window, hallucinations)
- Principe RAG (Retrieval-Augmented Generation)
- Workflow complet
- Avantages vs alternatives

**Contenu 03-RAG-EMBEDDINGS.md** :
- Modèle GGUF (Solon-embeddings-large-0.1.Q8_0.gguf)
- GGUFEmbeddingService (lazy loading)
- RAGService (recherche vectorielle)
- Index HNSW (performance <200ms)
- Fixes critiques appliqués

---

### **🔧 FIXES CRITIQUES** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [04-FIX-ASYNCPG-POOL.md](./04-FIX-ASYNCPG-POOL.md) | **Fix connexions DB** : asyncpg pool + Supavisor Session Mode | 349 lignes | ⭐⭐⭐ |

**Problème** :
- `{:shutdown, :client_termination}` sur RAG search
- Connexions individuelles → timeout

**Solution** :
- Pool asyncpg (min=2, max=10)
- Supavisor Session Mode (port 5432)
- IPv4 compatible

**Résultat** :
- ✅ RAG 100% fonctionnel (0 → 312k docs)
- ✅ Latence <250ms
- ✅ Connexions stables

---

### **🧪 TESTS** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [05-TESTS-SYSTEME-BACKEND.md](./05-TESTS-SYSTEME-BACKEND.md) | **9 tests Backend** (DB, Admin API, RAG, Groq, etc.) | 420 lignes | ⭐⭐ |

**Tests disponibles** :
1. `test-supabase` : Connexion DB + pool
2. `test-admin-api` : Edge Function admin-stats
3. `test-health-check` : Health endpoint
4. `test-pgvector` : Extension vector + HNSW
5. `test-materialized-view` : Vue admin_metrics_view
6. `test-cron-jobs` : pg_cron actif
7. `test-groq-llm` : API Groq
8. `test-simple` : Configuration backend
9. `run-unit-tests` : Tests unitaires Python

**Architecture hybride** : 9 Backend + 18 Edge Functions = 27 tests

---

## 🎯 GUIDES PAR NIVEAU

### **🚀 DÉBUTANT : Comprendre le backend**
1. [README.md](./README.md) - Vue d'ensemble
2. [02-POURQUOI-RAG.md](./02-POURQUOI-RAG.md) - Principe RAG
3. [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) - Architecture

### **🔧 DÉVELOPPEUR : Implémenter RAG**
1. [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) - Services principaux
2. [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md) - RAG technique
3. [04-FIX-ASYNCPG-POOL.md](./04-FIX-ASYNCPG-POOL.md) - Pool DB

### **⚙️ DEVOPS : Déployer et maintenir**
1. [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) - Déploiement Render
2. [05-TESTS-SYSTEME-BACKEND.md](./05-TESTS-SYSTEME-BACKEND.md) - Tests
3. [04-FIX-ASYNCPG-POOL.md](./04-FIX-ASYNCPG-POOL.md) - Fixes critiques

### **🔬 EXPERT : Optimiser RAG**
1. [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md) - Performance RAG
2. [04-FIX-ASYNCPG-POOL.md](./04-FIX-ASYNCPG-POOL.md) - Optimisations DB
3. [02-POURQUOI-RAG.md](./02-POURQUOI-RAG.md) - Stratégies avancées

---

## 🔍 RECHERCHE PAR SUJET

### **Architecture & Services**
- Architecture complète → [01-ARCHITECTURE.md](./01-ARCHITECTURE.md)
- Services Python → [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) (section Services)

### **RAG & Embeddings**
- Concept RAG → [02-POURQUOI-RAG.md](./02-POURQUOI-RAG.md)
- Implémentation → [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md)
- Modèle GGUF → [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md) (section GGUF)

### **Base de données**
- Pool asyncpg → [04-FIX-ASYNCPG-POOL.md](./04-FIX-ASYNCPG-POOL.md)
- Index HNSW → [03-RAG-EMBEDDINGS.md](./03-RAG-EMBEDDINGS.md) (section HNSW)

### **Tests**
- Tests Backend → [05-TESTS-SYSTEME-BACKEND.md](./05-TESTS-SYSTEME-BACKEND.md)
- Tests hybrides → [05-TESTS-SYSTEME-BACKEND.md](./05-TESTS-SYSTEME-BACKEND.md) (section Architecture)

---

## 📊 STATISTIQUES DOCUMENTATION

### **Fichiers**
- **Total fichiers** : 7 (5 numérotés + README + INDEX)
- **Total lignes** : ~2,200 lignes

### **Par Catégorie**
- Architecture : 1 fichier
- RAG & Embeddings : 2 fichiers
- Fixes : 1 fichier
- Tests : 1 fichier

---

## ✅ ÉTAT ACTUEL PRODUCTION

⚠️ **Documentation v5.0** : Voir [Agent-Orchestrator/docs/](../../../Agent-Orchestrator/docs/) pour version à jour complète.

### **Statistiques Réelles** (16 Jan 2025)

| Métrique | Valeur | Status |
|----------|--------|--------|
| **Documents indexés** | 312,000 | ✅ |
| **Embeddings générés** | 312,000 (768 dims) | ✅ |
| **Index HNSW** | 383 MB (m=16) | ✅ |
| **Latence RAG** | <250ms | ✅ |
| **Recall HNSW** | >95% | ✅ |
| **Pool asyncpg** | min=2, max=10 | ✅ |
| **Connexions stables** | 100% success | ✅ |

### **Services Actifs** (Backend)
- ✅ **ModernAgentService** : Business logic chat
- ✅ **SupabaseSearchService** : RAG search pgvector
- ✅ **GGUFEmbeddingService** : Embeddings locaux 768d
- ✅ **ProjectService** : CRUD projets ArchiReg
- ✅ **StorageService** : Upload Supabase
- ✅ **LLMService** : Groq integration
- ✅ **SimpleMCPService** : MCP protocol

### **Services migrés** 🌐 (Edge Functions)
- 🌐 **admin-stats** : Métriques dashboard
- 🌐 **cron-manager** : Liste 14 cron jobs
- 🌐 **system-tests** : 18 tests système

### **Modèle GGUF**
- **Nom** : solon-embeddings-large-0.1-Q8_0.gguf
- **Dimensions** : 768
- **Quantization** : Q8_0 (8-bit)
- **Taille** : ~500 MB
- **Source** : Bucket Supabase `ai-models`

---

## 🔗 LIENS UTILES

### **Déploiement**
- **URL Production** : https://agent-orchestrateur-backend.onrender.com
- **Host** : Render.com (Starter Plan)
- **Runtime** : Hypercorn HTTP/2
- **Health Check** : `/health`

### **Endpoints API**
- `POST /api/v3/chat/streaming` - Chat streaming SSE
- `POST /api/v3/chat/completions` - Chat batch
- `GET /api/v3/conversations` - Historique
- `POST /api/v3/legifrance/*` - Proxy micro-service
- `GET /api/v3/system-tests/{test}` - Tests Backend

### **Documentation Connexe**
- Supabase → [../../01-Supabase/](../../01-Supabase/)
- Workers → [../../05-WorkerLocal/](../../05-WorkerLocal/)
- Frontend → [../../04-ArchiReg-Front/](../../04-ArchiReg-Front/)

---

## 🎉 RÉSUMÉ

**Backend Agent-Orchestrator v4.7** :
- ✅ 7 fichiers organisés (01-05 + README + INDEX)
- ✅ Architecture FastAPI + Hypercorn HTTP/2
- ✅ RAG performant (<250ms, recall >95%)
- ✅ Pool asyncpg stable
- ✅ 312k documents indexés
- ✅ Tests système (9 Backend + 18 Edge)
- ✅ En production stable

**Backend optimisé et documenté !** 🚀

