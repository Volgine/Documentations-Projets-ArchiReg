# 🔴 AGENT-ORCHESTRATOR BACKEND

**Date** : 16 janvier 2025  
**Version** : 5.0.0  
**Framework** : FastAPI 0.115.5 + Python 3.12  
**Status** : ✅ EN PRODUCTION  
**URL** : https://agent-orchestrateur-backend.onrender.com  
**Service ID** : srv-d246a42li9vc73ccv6q0

---

## 🎯 Vue d'ensemble

**Backend RAG intelligent** qui transforme 312k documents Légifrance en recherche sémantique + chat expert.

```
Documents juridiques (312k)
    ↓ Embeddings GGUF (768d)
pgvector + HNSW (383 MB)
    ↓ RAG Search (<200ms)
Backend Agent-Orchestrator
    ↓ Groq LLM Streaming
Chat ArchiReg (Frontend)
```

---

## ✨ Responsabilités

### **CE QU'IL FAIT** ✅ (Backend)

1. **Chat LLM Streaming** : Groq llama-3.3-70b + SSE
2. **RAG Search** : Recherche vectorielle 312k documents
3. **GGUF Embeddings** : Génération locale 768d
4. **Projects CRUD** : Gestion projets ArchiReg
5. **Storage Upload** : Fichiers Supabase
6. **Proxy Micro-service** : Contrôle Légifrance
7. **User Stats** : Analytics utilisateur
8. **Tests Backend** : 9 tests système

### **MIGRÉ VERS EDGE FUNCTIONS** 🌐

- ❌ Admin stats dashboard → `admin-stats` (latence -99.7%)
- ❌ Cron jobs manager → `cron-manager` (read-only sécurisé)
- ❌ System tests (18) → `system-tests` (latence -59%)

### **CE QU'IL NE FAIT PAS** ❌

- Collecte Légifrance → Micro-service dédié
- Parsing/chunking → Workers locaux
- Stockage fichiers → Supabase Storage direct
- Auth → Supabase Auth
- Admin dashboard → Edge Functions

---

## 📊 État production

### **Statistiques réelles**

| Métrique | Valeur | Status |
|----------|--------|--------|
| **Documents indexés** | 312,000 | ✅ |
| **Index HNSW** | 383 MB | ✅ |
| **Latence RAG** | <200ms | ✅ |
| **Recall** | >95% | ✅ |
| **Uptime** | 99.9% | ✅ |
| **Pool asyncpg** | min=2, max=10 | ✅ |

### **Services actifs**

- ✅ Chat streaming (Groq llama-3.3-70b)
- ✅ RAG search (pgvector + HNSW)
- ✅ GGUF embeddings (Solon-large Q8_0)
- ✅ Projects CRUD
- ✅ Storage upload
- ✅ User stats

### **Stack technique**

```
FastAPI 0.115.5
Python 3.12
Hypercorn HTTP/2
Groq API (llama-3.3-70b-versatile)
PostgreSQL 15.8 + pgvector 0.7.0
Redis Cloud (Upstash)
GGUF local (768 dimensions)
```

---

## 📚 Documentation complète

### **Dans ce dossier** (DOCS-ARCHITECTURE/03-Agent-Orchestrator)

| Fichier | Description | Lignes |
|---------|-------------|--------|
| **[00-INDEX.md](00-INDEX.md)** | Navigation | 230 |
| **[01-ARCHITECTURE.md](01-ARCHITECTURE.md)** | Architecture détaillée | 470 |
| **[02-POURQUOI-RAG.md](02-POURQUOI-RAG.md)** | Guide RAG éducatif | 570 |
| **[03-RAG-EMBEDDINGS.md](03-RAG-EMBEDDINGS.md)** | Implémentation RAG | 370 |
| **[04-FIX-ASYNCPG-POOL.md](04-FIX-ASYNCPG-POOL.md)** | Fix connexions DB | 350 |
| **[05-TESTS-SYSTEME-BACKEND.md](05-TESTS-SYSTEME-BACKEND.md)** | Tests système | 420 |

### **Dans Agent-Orchestrator/docs/** (Nouvelle doc v5.0)

| Fichier | Description | Lignes |
|---------|-------------|--------|
| **[README.md](../../../Agent-Orchestrator/README.md)** | Vue d'ensemble v5.0 | 650 |
| **[docs/00-INDEX.md](../../../Agent-Orchestrator/docs/00-INDEX.md)** | Index navigation | 210 |
| **[docs/01-ARCHITECTURE.md](../../../Agent-Orchestrator/docs/01-ARCHITECTURE.md)** | Architecture v5.0 | 810 |
| **[docs/02-API-REFERENCE.md](../../../Agent-Orchestrator/docs/02-API-REFERENCE.md)** | Référence API | 610 |
| **[docs/03-SERVICES.md](../../../Agent-Orchestrator/docs/03-SERVICES.md)** | Services détaillés | 400 |
| **[docs/04-DEPLOYMENT.md](../../../Agent-Orchestrator/docs/04-DEPLOYMENT.md)** | Déploiement | 300 |
| **[docs/05-SECURITY.md](../../../Agent-Orchestrator/docs/05-SECURITY.md)** | Sécurité OWASP 2025 | 400 |
| **[docs/06-DEVELOPMENT.md](../../../Agent-Orchestrator/docs/06-DEVELOPMENT.md)** | Guide dev | 300 |
| **[docs/07-EDGE-FUNCTIONS.md](../../../Agent-Orchestrator/docs/07-EDGE-FUNCTIONS.md)** | Edge Functions | 300 |

**Recommandation** : Utiliser la **nouvelle documentation v5.0** dans `Agent-Orchestrator/docs/` (plus complète et à jour).

---

## 🔗 Liens utiles

| Ressource | URL |
|-----------|-----|
| **API Production** | https://agent-orchestrateur-backend.onrender.com |
| **Health Check** | https://agent-orchestrateur-backend.onrender.com/health |
| **Metrics** | https://agent-orchestrateur-backend.onrender.com/metrics |
| **OpenAPI Docs** | https://agent-orchestrateur-backend.onrender.com/docs |
| **Edge Functions** | https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/* |

---

## 🎉 Résumé

**Backend v5.0** :
- ✅ 112 fichiers actifs (code mort éliminé)
- ✅ RAG <200ms (312k documents)
- ✅ Features enterprise (ML security, sanitizer unifié)
- ✅ CI/CD automatisé (audit CVE)
- ✅ Architecture hybride (Backend + Edge Functions)
- ✅ Documentation complète (5,100+ lignes)

**Backend production-ready et entièrement documenté** ! 🚀

---

**Documentation principale** : [Agent-Orchestrator/docs/](../../../Agent-Orchestrator/docs/)
