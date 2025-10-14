# 📚 Documentation Architecture ArchiReg - INDEX

## 🎯 Vue d'Ensemble

Ce dossier contient la **documentation complète et finale** de l'architecture ArchiReg après la migration vers Edge Functions Supabase.

**Date de création** : 10 octobre 2025  
**Dernière mise à jour** : 14 octobre 2025 23:00 UTC  
**Version** : 5.8.0 OPTIMISATIONS SUPABASE APPLIQUÉES  
**Status** : ✅ **EN PRODUCTION** - RAG actif HNSW optimisé (<1s, 312k docs, 1.4GB) + 17 tables + Optimisations Supabase +30-40% perf ✅

🔥 **NOUVEAU** : 
- [19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md](./19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md) - Audit complet + optimisations appliquées
- [20-TABLES-EXPLICATIVES.md](./20-TABLES-EXPLICATIVES.md) - Guide complet des 28 tables : rôle, liens, catégories

---

## 📖 GUIDE DE LECTURE (ORDRE RECOMMANDÉ)

### **1️⃣ Commencer ici** 👇

**[RESUME-ARCHITECTURE-V4.7.md](./RESUME-ARCHITECTURE-V4.7.md)** ⭐ **NOUVEAU - COMMENCER ICI**
- Résumé ultra-simple de toute l'architecture
- 2 Workers expliqués (WorkerLocal vs WorkerLocal Chunk)
- Flux complets et métriques
- Prochaines étapes claires

**[00-INDEX.md](./00-INDEX.md)** (ce fichier)
- Index général
- Guide de lecture
- État du système

### **2️⃣ Comprendre l'architecture** 🏗️
**[01-ARCHITECTURE-GLOBALE.md](./01-ARCHITECTURE-GLOBALE.md)**
- Schémas Mermaid complets
- Flux de données
- Services et responsabilités
- Métriques avant/après migration

### **3️⃣ Comprendre les WebSockets** 🔌
**[02-WEBSOCKETS-VS-REALTIME.md](./02-WEBSOCKETS-VS-REALTIME.md)**
- ⭐ **IMPORTANT** : Explique clairement la différence
- Ancien système WebSockets backend (supprimé)
- Nouveau système Supabase Realtime (en production)
- Code exemples et comparaisons

### **4️⃣ Infrastructure détaillée** 💻
**[03-INFRASTRUCTURE.md](./03-INFRASTRUCTURE.md)**
- Tous les services (Frontend, Backend, Micro-service, Workers)
- URLs et configurations
- Déploiements

### **5️⃣ Historique des données** 📊
**[04-HISTORIQUE-TABLES.md](./04-HISTORIQUE-TABLES.md)**
- Statistiques tables Supabase
- Évolution des données
- Tailles et row counts

### **6️⃣ Edge Functions** 🌐
**[05-EDGE-FUNCTIONS/](./05-EDGE-FUNCTIONS/)**
- `admin-stats` : Métriques dashboard
- `cron-manager` : Gestion cron jobs (READ-ONLY)
- `system-tests` : 18 tests système (Backend, Supabase, RAG, Realtime) ⭐
- README complet avec code et déploiement

### **7️⃣ Migrations SQL** 🗄️
**[06-MIGRATIONS/SQL/](./06-MIGRATIONS/SQL/)**
- Vue matérialisée finale
- Fonctions pg_cron
- Index et optimisations

### **8️⃣ Tests Système** 🧪
**[08-TESTS-SYSTEME.md](./08-TESTS-SYSTEME.md)**
- Architecture hybride (Backend + Edge Functions)
- 26 tests complets détaillés
- Modales enrichies avec explications

### **9️⃣ RAG & Embeddings** 🧠 ⭐
**[09-RAG-EMBEDDINGS.md](./09-RAG-EMBEDDINGS.md)**
- Architecture complète RAG
- Workers Locaux (génération embeddings)
- Backend (recherche sémantique)
- Modèle GGUF Solon-embeddings-base (n_ctx=512)
- Flux de données détaillé
- Métriques et performance
- Fix n_ctx + Warm-up

### **🔟 Chunking Granulaire** 🔬 ⭐ **IMPLÉMENTÉ**
**[10-CHUNKING-GRANULAIRE.md](./10-CHUNKING-GRANULAIRE.md)**
- Architecture hybride (v2.0)
- Niveau 1: Documents globaux (930k docs)
- Niveau 2: Chunks granulaires (prêt à générer)
- WorkerLocal Chunk 100% opérationnel
- 4 stratégies découpage (articles/sections/paragraphes/fallback)
- Lien parent-enfant automatique (via file_path)
- Durée: 14-16h pour 6M chunks (3 workers)

### **1️⃣1️⃣ Bonnes Pratiques** 📖 ⭐
**[11-BONNES-PRATIQUES.md](./11-BONNES-PRATIQUES.md)**
- Points critiques à ne jamais oublier
- Bonnes pratiques workers (batch, concurrence, monitoring)
- Bonnes pratiques sécurité (RLS, secrets, service_role)
- Bonnes pratiques performance (index, timeout, n_ctx)
- Pièges à éviter (worker_id, RLS, warnings)
- Checklist avant modifications majeures
- Commandes utiles

### **1️⃣2️⃣ Micro-Service Légifrance** 🏛️ ⭐ **v2.4 PERSISTANCE**
**[12-MICRO-SERVICE-LEGIFRANCE.md](./12-MICRO-SERVICE-LEGIFRANCE.md)**
- Upload DIRECT vers bucket (v2.0)
- Persistance état scheduler (v2.4) - Se rappelle running/stopped après crash

### **1️⃣3️⃣ Pourquoi RAG & Embeddings** 💡 ⭐ **FONDAMENTAUX**
**[13-POURQUOI-RAG-EMBEDDINGS.md](./13-POURQUOI-RAG-EMBEDDINGS.md)**
- Pourquoi le LLM ne peut pas lire directement les embeddings
- Rôle de chaque composant (Bucket, GGUF, pgvector, LLM)
- Parsing avec/sans chunks expliqué
- Flux complet de données

### **1️⃣4️⃣ Structure des Tables** 🗄️ ⭐ **NOUVEAU**
**[14-STRUCTURE-TABLES.md](./14-STRUCTURE-TABLES.md)**
- Vue complète des 17 tables Supabase
- 5 tables principales détaillées (documents, files_queue, parsed_files, chunks, chat)
- Colonnes, types, exemples concrets
- Flux de données avec diagramme Mermaid
- Index HNSW : état construction + gains attendus (6,200x moins de calculs)
- Statistiques : 930k docs, 9.5 GB, progression 83.2%
- Workflow complet (Microservice → Queue → Workers → Documents → RAG)
- Commandes SQL utiles pour surveillance

### **1️⃣5️⃣ Capacité Client & Scaling** 📈 ⭐ **MIS À JOUR**
**[15-CAPACITE-SCALING.md](./15-CAPACITE-SCALING.md)**
- ⚠️ **OBSOLÈTE (doc historique)** : Database 9.5 GB > 8 GB (avant nettoyage)
- ✅ **ACTUEL (14 oct 2025)** : Database 6.7 GB / 100 GB (7% usage) après optimisations
- Infrastructure optimisée : 25 EUR/mois stable (Pro Plan)
- Capacité actuelle : 50-100 users simultanés, 10-20 requêtes/sec
- Marge restante : Croissance 10-15x sans surcoût
- Auto-scaling activé : Disk 202 GB provisionné (facturé sur usage réel)

### **1️⃣6️⃣ Fix Embeddings Incompatibles** 🔧 ⭐ **CRITIQUE**
**[16-FIX-EMBEDDINGS-INCOMPATIBLES.md](./16-FIX-EMBEDDINGS-INCOMPATIBLES.md)**
- Problème : Embeddings incompatibles Windows (AVX2) vs Linux (SSE4)
- Solution : Forcer compilation llama-cpp-python FROM SOURCE (--no-binary)
- Validation : Recherche RAG fonctionnelle (distance min 0.66, 1611 résultats)
- Database nettoyée : 11 GB libérés (documents, index HNSW, parsed_files)
- WorkerLocal + WorkerLocal Chunk alignés avec Backend

### **1️⃣7️⃣ Synchronisation Automatique files_queue** ⚡ **AUTO-SYNC**
**[17-FILES-QUEUE-SYNC.md](./17-FILES-QUEUE-SYNC.md)**
- Auto-sync intelligent au démarrage micro-service (vérification cohérence)
- Auto-sync < 100k fichiers manquants (arrière-plan automatique)
- Alert admin si > 100k manquants (sync SQL manuelle)
- Maintien continu : ~200-300 docs/min en mode MASSIVE
- Scripts SQL batch 50k pour cas extrêmes

### **1️⃣8️⃣ Connexion psql Directe Supabase** 🔗 ⭐ **MAINTENANCE**
**[18-CONNEXION-PSQL-DIRECTE.md](./18-CONNEXION-PSQL-DIRECTE.md)**
- Format connexion directe port 5432 (user postgres, sans pooler)
- Paramètres optimisés CREATE INDEX HNSW (maintenance_work_mem 128MB)
- Résolution erreurs : authentication, timeout, shared memory
- Cas d'usage : maintenance lourde vs applications

### **1️⃣9️⃣ Audit Sécurité & Performance Supabase** 🔍 ⭐ **NOUVEAU (14 oct 2025)**
**[19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md](./19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md)**
- Audit complet : RLS, index, requêtes, connexions, extensions
- Problèmes critiques identifiés : refresh 9.6s, 47 index inutiles, work_mem faible
- Optimisations appliquées : Cron 15min, tables supprimées, index partiels, work_mem 8MB
- Gain total : +50-60% performance admin metrics
- Infrastructure Pro Plan : 6.7 GB / 100 GB (7% usage), marge 10-15x

### **2️⃣0️⃣ Tables Explicatives** 📊 ⭐ **NOUVEAU (14 oct 2025)**
**[20-TABLES-EXPLICATIVES.md](./20-TABLES-EXPLICATIVES.md)**
- Guide complet des 28 tables : rôle, liens, catégories
- 7 catégories : Légifrance RAG, Chat, Auth, Monitoring, Archivage, Futures, Debug
- Diagramme Mermaid des liens entre tables
- Tables actives vs futures vs legacy
- Avertissements : tables à ne jamais supprimer

---

## 🏗️ Architecture Simplifiée

```
┌─────────────────────────────────────────────────────┐
│            FRONTEND (ArchiReg-Front)                 │
│                  Vercel Deploy                       │
│  • Chat (via Backend Render)                         │
│  • Admin Dashboard (via Edge Functions Supabase)     │
└────────────────┬────────────────────────────────────┘
                 │
        ┌────────┼────────┬──────────────┐
        │        │        │              │
        ▼        ▼        ▼              ▼
   ┌────────┐ ┌────┐ ┌─────────┐  ┌──────────┐
   │  EDGE  │ │BACK│ │  MICRO  │  │  WORKER  │
   │FUNCTION│ │END │ │ SERVICE │  │  LOCAL   │
   │Supabase│ │Rend│ │ Render  │  │  (x3)    │
   └────┬───┘ └─┬──┘ └────┬────┘  └────┬─────┘
        │       │         │             │
        └───────┴─────────┴─────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  SUPABASE DB    │
              │ • PostgreSQL    │
              │ • pgvector      │
              │ • Storage       │
              │ • pg_cron       │
              └─────────────────┘
```

---

## ✅ Migration Terminée (10 octobre 2025)

### **Ce Qui a Changé**

| Composant | Avant | Après |
|-----------|-------|-------|
| **Admin Métriques** | Backend Render | Edge Function `admin-stats` ✅ |
| **Cron Jobs** | Backend Render (CRUD) | Edge Function `cron-manager` (READ-ONLY) 🔒 |
| **WebSockets** | Backend Render (3 WS) | Supabase Realtime (2 channels) ✅ |
| **Cache Warmer** | APScheduler 4min | Vue matérialisée 10min ✅ |

### **Résultats Mesurés**

| Métrique | Avant | Après | Amélioration |
|----------|-------|-------|--------------|
| **CPU Supabase** | 90% | 12-15% | **-83%** ✅ |
| **Auth timeout** | 30-40s | <100ms | **-99.7%** ✅ |
| **Requêtes SQL admin** | 180/h | 0 | **-100%** ✅ |
| **Refresh view** | Timeout | 5.9s | ✅ |
| **WebSockets backend** | 3 actifs | 0 | **Migration complète** ✅ |

---

## 📊 État Actuel du Système (14 octobre 2025)

### **Frontend Dashboard**

| Section | Status | Dernière validation |
|---------|--------|---------------------|
| **Vue d'ensemble** | ✅ Validé | 14 oct 2025 |
| **Workers** | ✅ Validé | 14 oct 2025 |
| **Cron Jobs** | ✅ Optimisé (15min) | 14 oct 2025 ⭐ |
| **Timeline 24h** | ✅ Optimisé (refresh 15min) | 14 oct 2025 ⭐ |
| **Qualité & Erreurs** | ✅ Validé | 14 oct 2025 |
| **Système > Actions** | ✅ 27 tests disponibles | 14 oct 2025 |

**Améliorations récentes** :
- ✅ Messages d'erreur clairs (❌ Échec traitement, ⏱️ Timeout, etc.)
- ✅ KPIs workers fusionnés dans header du tableau
- ✅ Timeline 24h + Qualité & Erreurs côte à côte
- ✅ Badges colorés intelligents pour types d'erreurs
- 🔒 **Cron Jobs en lecture seule** (sécurité renforcée - pas de SQL injection possible)
- ⭐ **27 tests système** : 9 via Backend + 18 via Edge Function (architecture hybride optimale)
- 🎨 **Modales enrichies** : 18 tests avec descriptions détaillées, répercussions, durées
- 🧠 **Test Groq LLM** : Validation API + modèle gpt-oss-120b + mesure latence/tokens

### **Supabase Database**

| Table | Rows | Utilisation |
|-------|------|-------------|
| `files_queue` | 1,034,780 | Queue traitement workers |
| `parsed_files` | 930,937 | Fichiers parsés |
| `documents` | 930,394 | Documents RAG (Légifrance + futurs) |
| `document_chunks` | 0 | Chunks embeddings (futur) |

### **Bucket Storage**

| Bucket | Fichiers | Taille |
|--------|----------|--------|
| `agentbasic-legifrance-raw` | 1,077,264 | 4.6 GB |

### **Services Actifs**

| Service | Plateforme | Status | URL |
|---------|-----------|--------|-----|
| Frontend | Vercel | ✅ Live | https://archireg-front.vercel.app |
| Backend Orchestrator | Render | ✅ Live | https://agent-orchestrateur-backend.onrender.com |
| Micro-service Légifrance | Render | ✅ Live | https://micro-service-data-legifrance-piste.onrender.com |
| Worker Local x3 | PC Windows | ✅ Active | localhost |
| Edge Functions (x3) | Supabase | ✅ Live | https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/ |

**Edge Functions déployées** :
- ✅ `admin-stats` : Métriques dashboard admin
- ✅ `cron-manager` : Liste cron jobs (READ-ONLY)
- ✅ `system-tests` v3 : **18 tests système** (Backend, Supabase, Security, RAG, Realtime, Meta-test)

### **Performance Supabase**

| Ressource | Usage | Marge |
|-----------|-------|-------|
| **CPU** | 12-15% | **85-88% libre** ✅ |
| **Memory** | ~60-100 MB | ~900 MB libre ✅ |
| **Disk I/O** | Faible | Large marge ✅ |
| **Plan** | Micro 1GB 2-core ARM | Optimal ✅ |

---

## 🚀 Déploiements

### **Frontend (Vercel)**
```bash
cd ArchiReg-Front
npx vercel --prod --yes
```

### **Backend (Render)**
```bash
git push origin main
# Auto-deploy via webhook GitHub
```

### **Edge Functions (Supabase)**
```bash
supabase functions deploy admin-stats
supabase functions deploy cron-manager
supabase functions deploy system-tests
```

**Ou via MCP Supabase** :
```typescript
mcp_supabase_deploy_edge_function({
  name: "system-tests",
  files: [{name: "index.ts", content: "..."}]
})
```

---

## 🔐 Sécurité

- ✅ RLS activé sur toutes les tables
- ✅ Edge Functions avec auth JWT
- ✅ Vue matérialisée : service_role only
- ✅ Policies optimisées avec `(select auth.role())`
- ✅ Pas de WebSockets backend (0 code manuel)
- 🔒 **Cron Jobs READ-ONLY** (pas de SQL injection possible via frontend)
- 🗑️ Fonctions SQL dangereuses supprimées (`toggle_cron_job`, `create_cron_job`, `delete_cron_job`)

---

## 📞 Support

- **Projet** : ArchiReg - Assistant IA pour architectes
- **Stack** : Next.js, FastAPI, Supabase, Render, Vercel
- **Version** : 4.0.0 FINALE

---

**📅 Dernière mise à jour** : 12 octobre 2025 13:00 UTC  
**✅ Status** : EN PRODUCTION - 27 tests + RAG (n_ctx=512) + Workers + Micro-service v2.4 (Persistance État) ✅
