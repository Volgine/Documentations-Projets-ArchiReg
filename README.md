# 📚 DOCUMENTATION ARCHIREG - GUIDE COMPLET

## 🎯 À PROPOS

Cette documentation explique **l'architecture complète** du projet ArchiReg après les **optimisations Supabase** (octobre 2025).

**Version** : 5.8.0 OPTIMISATIONS SUPABASE APPLIQUÉES  
**Status** : ✅ EN PRODUCTION  
**Dernière mise à jour** : 14 octobre 2025 23:00 UTC  

---

## 🚀 INFRASTRUCTURE (14 oct 2025)

### **💾 Database Supabase Pro (25€/mois)**
- **PostgreSQL** : 17.6 (patches sécurité ✅)
- **Timezone** : Europe/Paris 🇫🇷
- **Database** : 6.7 GB / 100 GB (7% usage)
- **Storage** : 5 GB / 100 GB (5% usage)
- **Compute** : Micro 1GB 2-core ARM (suffisant)
- **Connexions** : 25/60 (42% usage)
- **Marge** : Capacité 10-15x sans surcoût

### **⚡ Optimisations Appliquées**
1. ✅ Cron refresh : 5 min → 15 min (-66% appels)
2. ✅ work_mem : 3.5 MB → 8 MB (+134% RAM)
3. ✅ Index partiels : files_queue optimisé
4. ✅ Tables supprimées : plu_documents, public.messages (24 index)
5. ✅ admin_metrics_view : Sécurisée (service_role only)

**Gain total** : **+50-60% performance globale** 🎉

---

## 🧠 RAG & EMBEDDINGS

### **📦 WorkerLocal (Documents Globaux)**
- **Rôle** : Parse documents → embeddings contexte global
- **Table cible** : `documents` (312,205 docs, 3 GB)
- **Index HNSW** : 383 MB (recherche vectorielle rapide)
- **Status** : ✅ Terminé (312k docs générés)
- **Config** : llama-cpp-python FROM SOURCE (--no-binary)
- **Compatibilité** : ✅ Aligné avec Backend (fix 13 oct 2025)

### **🔬 WorkerLocal Chunk (Chunks Granulaires)**
- **Rôle** : Parse + découpage articles/sections → embeddings granulaires
- **Table cible** : `document_chunks` (0 rows, prêt pour 6M chunks)
- **Découpage** : 4 stratégies intelligentes (articles/sections/paragraphes/fallback)
- **Status** : ✅ Prêt à lancer (14-16h pour 6M chunks avec 3 workers)
- **Config** : llama-cpp-python FROM SOURCE (--no-binary)
- **Compatibilité** : ✅ Aligné avec Backend

### **🔍 Recherche RAG**
- **Modèle** : GGUF Solon-embeddings-base (768 dims, n_ctx=512)
- **Performance** : Distance min 0.66, threshold 0.70, 1611 résultats pertinents
- **Latence** : <500ms (recherche dans 312k docs)
- **Architecture** : pgvector + HNSW (6,200x moins de calculs)

---

## 🏛️ MICRO-SERVICE LÉGIFRANCE

### **Version 3.0 - Unification + Filtre LEGIARTI**
- **Stratégie unifiée** : MAINTENANCE = MASSIVE (même collecte de qualité)
- **Filtre LEGIARTI** : Ignore sections vides (LEGISCTA), garde vrais articles
- **Filtre qualité** : Texte > 200 chars après nettoyage HTML
- **Résultat** : 60% docs > 3K chars (vs 10% avant fix)
- **Code clean** : -645 lignes de code mort (1613 → 968 lignes)
- **Auto-sync** : Vérifie cohérence Storage ↔ files_queue au démarrage
- **Persistance** : État scheduler sauvegardé (résilience crash)

---

## 📖 DOCUMENTATION (20 FICHIERS)

### **🎯 ESSENTIELS (À LIRE EN PRIORITÉ)**

| # | Fichier | Description |
|---|---------|-------------|
| ⭐ | [RESUME-ARCHITECTURE-V4.7.md](./RESUME-ARCHITECTURE-V4.7.md) | Résumé ultra-simple (COMMENCER ICI) |
| **0** | [00-INDEX.md](./00-INDEX.md) | Index général, guide de lecture |
| **1** | [01-ARCHITECTURE-GLOBALE.md](./01-ARCHITECTURE-GLOBALE.md) | Schémas Mermaid, 4 services |
| **9** | [09-RAG-EMBEDDINGS.md](./09-RAG-EMBEDDINGS.md) | RAG complet, Workers, Backend |
| **16** | [16-FIX-EMBEDDINGS-INCOMPATIBLES.md](./16-FIX-EMBEDDINGS-INCOMPATIBLES.md) | Fix critique AVX2 vs SSE4 |
| **19** | [19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md](./19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md) | Audit + optimisations |
| **20** | [20-TABLES-EXPLICATIVES.md](./20-TABLES-EXPLICATIVES.md) | Guide des 28 tables |

### **🔧 TECHNIQUE**

| # | Fichier | Description |
|---|---------|-------------|
| **2** | [02-WEBSOCKETS-VS-REALTIME.md](./02-WEBSOCKETS-VS-REALTIME.md) | Migration WebSockets → Realtime |
| **3** | [03-INFRASTRUCTURE.md](./03-INFRASTRUCTURE.md) | Services, URLs, configs |
| **10** | [10-CHUNKING-GRANULAIRE.md](./10-CHUNKING-GRANULAIRE.md) | Architecture hybride 2 niveaux |
| **12** | [12-MICRO-SERVICE-LEGIFRANCE.md](./12-MICRO-SERVICE-LEGIFRANCE.md) | Upload direct + Auto-sync |
| **17** | [17-FILES-QUEUE-SYNC.md](./17-FILES-QUEUE-SYNC.md) | Sync automatique files_queue |
| **18** | [18-CONNEXION-PSQL-DIRECTE.md](./18-CONNEXION-PSQL-DIRECTE.md) | psql direct, CREATE INDEX |

### **📚 RÉFÉRENCE**

| # | Fichier | Description |
|---|---------|-------------|
| **4** | [04-HISTORIQUE-TABLES.md](./04-HISTORIQUE-TABLES.md) | Stats tables, évolution |
| **7** | [07-SECURITE-CRON-JOBS.md](./07-SECURITE-CRON-JOBS.md) | Sécurité pg_cron |
| **8** | [08-TESTS-SYSTEME.md](./08-TESTS-SYSTEME.md) | 27 tests système |
| **11** | [11-BONNES-PRATIQUES.md](./11-BONNES-PRATIQUES.md) | Guide bonnes pratiques |
| **13** | [13-POURQUOI-RAG-EMBEDDINGS.md](./13-POURQUOI-RAG-EMBEDDINGS.md) | Pourquoi RAG ? Flux complet |
| **14** | [14-STRUCTURE-TABLES.md](./14-STRUCTURE-TABLES.md) | Structure 17 tables |
| **15** | [15-CAPACITE-SCALING.md](./15-CAPACITE-SCALING.md) | Capacité & scaling (obsolète) |

### **📁 DOSSIERS**

- **05-EDGE-FUNCTIONS/** : 3 Edge Functions (admin-stats, cron-manager, system-tests)
- **06-MIGRATIONS/SQL/** : 6 scripts SQL production

---

## 🎯 QUESTIONS FRÉQUENTES

### **Q : Différence entre WorkerLocal et WorkerLocal Chunk ?**
**R** :
- **WorkerLocal** : 1 document = 1 embedding (contexte global) → Table `documents`
- **WorkerLocal Chunk** : 1 document = N embeddings (chunks granulaires) → Table `document_chunks`
- Les deux utilisent le même modèle GGUF (768 dims, n_ctx=512)
- Les deux sont alignés avec le Backend (llama-cpp-python FROM SOURCE)

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
- **Auto** : pg_cron toutes les 15 minutes (optimisé)
- **Manuel** : Cliquer "Actualiser" dans le frontend
- **SQL** : `SELECT refresh_admin_metrics_view();`

### **Q : Pourquoi CPU Supabase est passé de 90% à 12% ?**
**R** : 
1. Suppression cache warmer backend (12 queries SQL/4min)
2. Migration vers Edge Functions (0ms latence)
3. Vue matérialisée optimisée (reltuples, index, HAVING)
4. Refresh moins fréquent (15min au lieu de 5min)
5. work_mem augmenté (8 MB), index partiels créés

### **Q : Les embeddings sont-ils compatibles entre Workers et Backend ?**
**R** : ✅ **OUI** (depuis le 13 oct 2025) !
- Fix appliqué : `--no-binary=llama-cpp-python` dans requirements.txt
- Force compilation FROM SOURCE (même flags pour Windows et Linux)
- Validation : distance min 0.66, 1611 résultats trouvés
- Documentation : [16-FIX-EMBEDDINGS-INCOMPATIBLES.md](./16-FIX-EMBEDDINGS-INCOMPATIBLES.md)

---

## 🚀 DÉMARRAGE RAPIDE

### **1. Lire la doc dans l'ordre** 📖
1. **RESUME-ARCHITECTURE-V4.7.md** - Vue d'ensemble ultra-simple
2. **00-INDEX.md** - Carte complète des 20 documents
3. **01-ARCHITECTURE-GLOBALE.md** - Comprendre les 4 services
4. **09-RAG-EMBEDDINGS.md** - Comprendre le RAG
5. **16-FIX-EMBEDDINGS-INCOMPATIBLES.md** - Fix critique
6. **19-AUDIT-SECURITE-PERFORMANCE-SUPABASE.md** - Optimisations
7. **20-TABLES-EXPLICATIVES.md** - Référence des 28 tables

### **2. Vérifier le système** 🔍
- Frontend : https://archireg-front.vercel.app/admin
- Backend : https://agent-orchestrateur-backend.onrender.com/health
- Supabase : Dashboard Pro (6.7 GB / 100 GB)

### **3. Monitoring** 📊
- **Database** : 6.7 GB / 100 GB (7% usage)
- **Connexions** : 25/60 (42% usage)
- **Refresh admin** : Toutes les 15 min (optimisé)
- **Workers** : 3 actifs (si lancés)

---

## 🎉 RÉSUMÉ

### **✅ INFRASTRUCTURE**
- Supabase Pro Plan : 25€/mois stable
- Database 6.7 GB / 100 GB (7% usage)
- PostgreSQL 17.6 + timezone Europe/Paris
- Optimisations : +50-60% performance

### **✅ RAG & WORKERS**
- WorkerLocal : 312k documents (embeddings globaux) ✅ Terminé
- WorkerLocal Chunk : Prêt pour 6M chunks (granulaires) ⏸️
- Embeddings compatibles : Windows ↔ Linux ✅
- Recherche RAG fonctionnelle : 1611 résultats ✅

### **✅ SERVICES**
- Frontend : Vercel (Next.js)
- Backend : Render (FastAPI, RAG)
- Micro-service : Render (Légifrance, auto-sync)
- Edge Functions : 3 fonctions (admin-stats, cron-manager, system-tests)

### **✅ SÉCURITÉ**
- RLS activé sur toutes les tables
- admin_metrics_view : service_role only
- Postgres patches appliqués
- Timezone France configurée

### **✅ DOCUMENTATION**
- 20 documents markdown (13,278+ lignes)
- 7 catégories de tables expliquées
- 3 repos GitHub publiés
- Guide complet et à jour

---

## 📚 STRUCTURE COMPLÈTE

```
DOCS-ARCHITECTURE/
│
├── 🎯 ESSENTIELS
│   ├── RESUME-ARCHITECTURE-V4.7.md        ⭐ Commencer ici
│   ├── 00-INDEX.md                        📋 Index général
│   ├── 01-ARCHITECTURE-GLOBALE.md         🏗️ Schémas Mermaid
│   ├── 09-RAG-EMBEDDINGS.md               🧠 RAG complet
│   ├── 16-FIX-EMBEDDINGS-INCOMPATIBLES.md 🔧 Fix critique
│   ├── 19-AUDIT-SECURITE-PERFORMANCE.md   🔍 Optimisations
│   └── 20-TABLES-EXPLICATIVES.md          📊 Guide tables
│
├── 🔧 TECHNIQUE
│   ├── 02-WEBSOCKETS-VS-REALTIME.md       🔌 WebSockets
│   ├── 03-INFRASTRUCTURE.md               💻 Services
│   ├── 10-CHUNKING-GRANULAIRE.md          🔬 Architecture hybride
│   ├── 12-MICRO-SERVICE-LEGIFRANCE.md     🏛️ Micro-service
│   ├── 17-FILES-QUEUE-SYNC.md             ⚡ Auto-sync
│   └── 18-CONNEXION-PSQL-DIRECTE.md       🔗 Maintenance
│
├── 📚 RÉFÉRENCE
│   ├── 04-HISTORIQUE-TABLES.md            📊 Stats
│   ├── 07-SECURITE-CRON-JOBS.md           🔒 Sécurité
│   ├── 08-TESTS-SYSTEME.md                🧪 27 tests
│   ├── 11-BONNES-PRATIQUES.md             📖 Best practices
│   ├── 13-POURQUOI-RAG-EMBEDDINGS.md      💡 Pourquoi RAG
│   ├── 14-STRUCTURE-TABLES.md             🗄️ Structure tables
│   └── 15-CAPACITE-SCALING.md             📈 Scaling (obsolète)
│
├── 📁 DOSSIERS
│   ├── 05-EDGE-FUNCTIONS/                 🌐 3 Edge Functions
│   │   ├── admin-stats/
│   │   ├── cron-manager/
│   │   └── system-tests/
│   └── 06-MIGRATIONS/SQL/                 🗄️ Scripts SQL
│       ├── final_complete_view.sql
│       ├── create_cron_helpers.sql
│       ├── create_indexes.sql
│       └── drop_unused_indexes.sql
│
└── 📋 PLANS & HISTORIQUE
    ├── CREATE_HNSW_INDEXES.sql
    ├── PLAN-ARCHITECTURE-RAG-COMPLETE.md
    ├── PLAN-FIX-GGUF-EMBEDDINGS.md
    └── DEPLOIEMENT-SYSTEM-TESTS.md
```

---

## 🔗 REPOS GITHUB

### **1. Documentations-Projets-ArchiReg**
📍 https://github.com/Volgine/Documentations-Projets-ArchiReg.git
- 36 fichiers, 13,278+ lignes
- Documentation complète architecture

### **2. WorkerLocal-Legifrance**
📍 https://github.com/UrbArchi-AI/WorkerLocal-Legifrance.git
- 38 fichiers, 3,879 lignes
- Parser documents (embeddings globaux)

### **3. WorkerLocal-ChunkGranulat-Legifrance**
📍 https://github.com/UrbArchi-AI/WorkerLocal-ChunkGranulat-Legifrance.git
- 38 fichiers, 3,524 lignes
- Parser + découpage granulaire

---

**📅 Date** : 14 octobre 2025 23:00 UTC  
**👨‍💻 Projet** : ArchiReg v5.8.0 OPTIMISATIONS SUPABASE  
**🎯 Status** : ✅ Production, optimisé, documenté

