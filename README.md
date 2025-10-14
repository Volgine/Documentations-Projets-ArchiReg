# 📚 DOCUMENTATION ARCHIREG - GUIDE COMPLET

## 🎯 À PROPOS

Cette documentation explique **l'architecture complète** du projet ArchiReg après la **migration vers Edge Functions Supabase** (octobre 2025).

**Version** : 5.3.0 FIX RAG VERSION LLAMA-CPP + THRESHOLD 0.70  
**Status** : ✅ EN PRODUCTION  
**Dernière mise à jour** : 13 octobre 2025 08:30 UTC  
**CPU Supabase** : 12-15% (optimal)  
**Dashboard LégiFrance** : ✅ 100% validé (11 oct 2025)  
**Tests Système** : ✅ 27 tests (9 Backend + 18 Edge Function) - RAG: 3 docs trouvés ⭐  
**RAG & Embeddings** : ✅ **FONCTIONNEL** - llama-cpp==0.3.16 - threshold 0.70 - 930k docs indexés 🧠  
**Groq LLM** : ✅ Test API + gpt-oss-120b + latence/tokens 🚀  
**Chunking Granulaire** : ✅ WorkerLocal Chunk 100% opérationnel (14-16h pour 6M chunks) 🔬  
**Micro-service Légifrance** : ✅ v2.5 Upload direct Supabase + Contrôle frontend total 🎯

---

## 📖 FICHIERS PRINCIPAUX (LIRE DANS CET ORDRE)

| # | Fichier | Description | Priorité |
|---|---------|-------------|----------|
| **📌** | [RESUME-ARCHITECTURE-V4.7.md](./RESUME-ARCHITECTURE-V4.7.md) | ⭐ Résumé ultra-simple (COMMENCER ICI) | ⭐⭐⭐ |
| **0** | [00-INDEX.md](./00-INDEX.md) | Index général, état système | ⭐⭐⭐ |
| **1** | [01-ARCHITECTURE-GLOBALE.md](./01-ARCHITECTURE-GLOBALE.md) | Schémas Mermaid, flux de données | ⭐⭐⭐ |
| **2** | [02-WEBSOCKETS-VS-REALTIME.md](./02-WEBSOCKETS-VS-REALTIME.md) | WebSockets backend vs Supabase Realtime | ⭐⭐⭐ |
| **3** | [03-INFRASTRUCTURE.md](./03-INFRASTRUCTURE.md) | Tous les services, URLs, configs | ⭐⭐ |
| **4** | [04-HISTORIQUE-TABLES.md](./04-HISTORIQUE-TABLES.md) | Stats tables, évolution données | ⭐ |
| **8** | [08-TESTS-SYSTEME.md](./08-TESTS-SYSTEME.md) | Architecture hybride tests (27 tests) | ⭐⭐ |
| **9** | [09-RAG-EMBEDDINGS.md](./09-RAG-EMBEDDINGS.md) | RAG complet, Workers, Backend, n_ctx=512 | ⭐⭐⭐ |
| **10** | [10-CHUNKING-GRANULAIRE.md](./10-CHUNKING-GRANULAIRE.md) | Architecture hybride v2.0 (IMPLÉMENTÉ) | ⭐⭐⭐ |
| **11** | [11-BONNES-PRATIQUES.md](./11-BONNES-PRATIQUES.md) | Guide bonnes pratiques + pièges à éviter | ⭐⭐⭐ |
| **12** | [12-MICRO-SERVICE-LEGIFRANCE.md](./12-MICRO-SERVICE-LEGIFRANCE.md) | Upload direct + Architecture unifiée (v2.3) | ⭐⭐⭐ |
| **13** | [13-POURQUOI-RAG-EMBEDDINGS.md](./13-POURQUOI-RAG-EMBEDDINGS.md) | ⭐ Pourquoi embeddings ? Flux RAG complet | ⭐⭐⭐ |

---

## 📁 DOSSIERS

### **05-EDGE-FUNCTIONS/** 🌐
Documentation des Edge Functions Supabase (Deno/TypeScript)

**Contenu** :
- `admin-stats/index.ts` : Métriques dashboard
- `cron-manager/index.ts` : Gestion pg_cron (READ-ONLY)
- `system-tests/index.ts` : 15 tests système ⭐ **NOUVEAU**
- `README.md` : Doc complète avec code et déploiement

**À lire si** : Tu veux comprendre comment fonctionnent les Edge Functions

---

### **06-MIGRATIONS/SQL/** 🗄️
Scripts SQL de production

**Contenu** :
- `final_complete_view.sql` : Vue matérialisée optimisée (5.9s refresh)
- `create_cron_helpers.sql` : Fonctions helpers pg_cron
- `create_indexes.sql` : Index stratégiques
- `drop_unused_indexes.sql` : Nettoyage 37 index
- `README.md` : Doc migrations complète

**À lire si** : Tu veux comprendre la base de données et les optimisations SQL

---

## 🎯 QUESTIONS FRÉQUENTES

### **Q : On utilise encore des WebSockets ?**
**R** : Oui, mais **gérés par Supabase automatiquement** ! Plus de code WebSocket manuel.  
👉 Lire [02-WEBSOCKETS-VS-REALTIME.md](./02-WEBSOCKETS-VS-REALTIME.md)

### **Q : Où est le code admin dashboard ?**
**R** : 
- **Frontend** : `ArchiReg-Front/pages/admin.tsx`
- **Backend** : Edge Functions Supabase (`admin-stats`, `cron-manager`)
- **Base de données** : Vue matérialisée `admin_metrics_view`

### **Q : Comment déployer le frontend ?**
**R** :
```bash
cd ArchiReg-Front
npx vercel --prod --yes
```

### **Q : Comment refresh les métriques admin ?**
**R** : 
- **Auto** : pg_cron toutes les 10 minutes
- **Manuel** : Cliquer "Actualiser" dans le frontend
- **SQL** : `SELECT refresh_admin_metrics_view();`

### **Q : Pourquoi CPU Supabase est passé de 90% à 12% ?**
**R** : 
1. Suppression cache warmer backend (12 queries SQL/4min)
2. Migration vers Edge Functions (0ms latence)
3. Vue matérialisée optimisée (reltuples, index, HAVING)
4. Refresh moins fréquent (10min au lieu de 2min)

### **Q : Quelles métriques sont désactivées ?**
**R** : 
- `historique_30j` (trop lourd, ~180ms)
- `recent_batches` (redondant)
- `size_distribution` (redondant)
- `top_heavy_files` (non critique)

**Gain** : ~373ms par refresh

---

## 🚀 DÉMARRAGE RAPIDE

### **1. Lire la doc dans l'ordre** 📖
1. [00-INDEX.md](./00-INDEX.md) - Commencer ici
2. [01-ARCHITECTURE-GLOBALE.md](./01-ARCHITECTURE-GLOBALE.md) - Comprendre l'archi
3. [02-WEBSOCKETS-VS-REALTIME.md](./02-WEBSOCKETS-VS-REALTIME.md) - WebSockets expliqués

### **2. Vérifier le système** 🔍
- Frontend : https://archireg-front.vercel.app/admin
- Backend : https://agent-orchestrateur-backend.onrender.com/health
- Supabase : https://supabase.com/dashboard/project/joozqsjbcwrqyeqepnev

### **3. Monitoring** 📊
- **CPU Supabase** : Doit être ~12-15%
- **Refresh view** : Toutes les 10 min
- **Workers actifs** : 3 (si lancés)

---

## 📚 STRUCTURE COMPLÈTE

```
DOCS-ARCHITECTURE/
│
├── 00-INDEX.md                    ⭐ Index général
├── 01-ARCHITECTURE-GLOBALE.md     ⭐ Schémas Mermaid
├── 02-WEBSOCKETS-VS-REALTIME.md   ⭐ WebSockets expliqués
├── 03-INFRASTRUCTURE.md           📋 Tous les services
├── 04-HISTORIQUE-TABLES.md        📊 Stats tables
│
├── 05-EDGE-FUNCTIONS/             🌐 Edge Functions
│   ├── README.md
│   ├── admin-stats/
│   │   └── index.ts
│   ├── cron-manager/
│   │   └── index.ts
│   └── system-tests/              ⭐ NOUVEAU
│       ├── index.ts
│       └── README.md
│
└── 06-MIGRATIONS/                 🗄️ Migrations SQL
    └── SQL/
        ├── README.md
        ├── final_complete_view.sql
        ├── create_cron_helpers.sql
        ├── create_indexes.sql
        └── drop_unused_indexes.sql
```

---

## 🎉 RÉSUMÉ

✅ **Architecture optimisée** : CPU 12-15% (vs 90%)  
✅ **WebSockets migrés** : Supabase Realtime (0 code manuel)  
✅ **Edge Functions** : admin-stats + cron-manager (READ-ONLY) + system-tests v3 ⭐  
✅ **Vue matérialisée** : 5.9s refresh / 10 min  
✅ **Documentation complète** : 14 fichiers (Résumé + Bonnes pratiques + RAG + Chunking + Micro-service)  
✅ **Code 100% clean** : Aucun code mort  
✅ **Dashboard LégiFrance** : 100% validé (Vue d'ensemble, Workers, Cron Jobs, Timeline, Qualité & Erreurs)  
🔒 **Sécurité renforcée** : Cron Jobs READ-ONLY (0 risque SQL injection)  
🧪 **Tests Système** : **27 tests** (9 Backend + 18 Edge Function) - Architecture hybride optimale  
🎨 **Modales enrichies** : 18 tests avec descriptions détaillées, répercussions, badges colorés  
🧠 **RAG & Embeddings** : 930k documents indexés, GGUF Solon-base (768 dims, n_ctx=512), Workers + Backend pgvector  
🚀 **Groq LLM** : Test API complet + modèle gpt-oss-120b (120B params) + mesure latence/tokens  
🔬 **Chunking Granulaire** : ✅ WorkerLocal Chunk 100% opérationnel (4 stratégies, lien parent auto, 14-16h pour 6M chunks)  
🏛️ **Micro-Service Légifrance** : ✅ v2.4 Persistance état (résilience crash, restauration automatique, contrôle total) 🎯

---

**📅 Date** : 12 octobre 2025 13:00 UTC  
**👨‍💻 Projet** : ArchiReg v5.1.0 PERSISTANCE ÉTAT

