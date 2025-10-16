# 🗄️ SUPABASE - DOCUMENTATION COMPLÈTE

**Date** : 15 octobre 2025  
**Version Database** : PostgreSQL 17.6  
**Plan** : Pro (25€/mois)  
**Status** : ✅ EN PRODUCTION

---

## 🎯 Vue d'Ensemble

Supabase est le **cœur de l'infrastructure ArchiReg** :
- **Database** : 28 tables PostgreSQL + pgvector
- **Storage** : Bucket Légifrance (259 fichiers, 17 MB)
- **Edge Functions** : 3 fonctions (admin-stats, cron-manager, system-tests)
- **Auth** : Authentification utilisateurs
- **Realtime** : Channels temps réel (admin-metrics, admin-alerts)

---

## 📊 ÉTAT ACTUEL (15 Oct 2025)

### Infrastructure
- **Database** : 6.7 GB / 100 GB (7% usage) ✅
- **Storage** : 5 GB / 100 GB (5% usage) ✅
- **Connexions** : 25 / 60 max (42% usage) ✅
- **Compute** : Micro 1GB 2-core ARM (suffisant)
- **Timezone** : Europe/Paris 🇫🇷

### Bucket Storage
- **agentbasic-legifrance-raw** : 259 fichiers, 17 MB
- **ai-models** : Modèle GGUF (public)
- **urbanisme-documents** : Documents PLU (futur)

### Tables Principales
- **files_queue** : 259 fichiers (231 pending, 28 completed)
- **documents** : 28 docs RAG avec embeddings
- **parsed_files** : 28 fichiers parsés
- **document_chunks** : 0 (prêt pour 6M chunks)

---

## 📚 DOCUMENTATION PAR THÈME

### **🗄️ Base de Données**
- [**TABLES.md**](./TABLES.md) - Les 28 tables expliquées (rôles, liens, catégories)
- [**HNSW-INDEXES.md**](./HNSW-INDEXES.md) - Index vectoriels pgvector + performance
- [**MIGRATIONS/**](./MIGRATIONS/) - Scripts SQL production

### **🔐 Sécurité**
- [**RLS-POLICIES.md**](./RLS-POLICIES.md) - Row Level Security sur toutes les tables
- [**CRON-JOBS.md**](./CRON-JOBS.md) - Jobs pg_cron + sécurité

### **🌐 Edge Functions**
- [**EDGE-FUNCTIONS.md**](./EDGE-FUNCTIONS.md) - admin-stats, cron-manager, system-tests

### **⚡ Performance**
- [**OPTIMISATIONS.md**](./OPTIMISATIONS.md) - Audit + optimisations appliquées (+50-60% perf)
- [**CONNEXION-PSQL.md**](./CONNEXION-PSQL.md) - Connexion directe port 5432

---

## 🚀 Prochaines Étapes

1. ✅ Laisser Workers finir traitement (231 fichiers pending)
2. ⏸️ Activer mode MASSIVE si besoin (20 codes → 10-50K articles)
3. ⏸️ Lancer WorkerLocal Chunk (6M chunks granulaires)
4. ⏸️ Recréer index HNSW après 100k documents

---

**Infrastructure stable, optimisée, documentée** ✅

