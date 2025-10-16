# 🗄️ TABLES SUPABASE - GUIDE COMPLET

**Date** : 15 octobre 2025  
**Database** : PostgreSQL 17.6  
**Total Tables** : 28 tables  
**Status** : ✅ EN PRODUCTION

---

## 📊 ÉTAT ACTUEL (15 Oct 2025)

### Tables Actives (Données Réelles)

| Table | Rows | Taille | Status |
|-------|------|--------|--------|
| **files_queue** | 259 | 296 kB | ✅ Actif (231 pending) |
| **documents** | 28 | 312 kB | ✅ Actif (base reconstruite) |
| **parsed_files** | 28 | 372 MB | ✅ Actif |
| **document_chunks** | 0 | 3.6 MB | ⏸️ Prêt (6M chunks futurs) |
| **chat_messages** | ~1k | 5.4 MB | ✅ Actif |
| **conversations** | 205 | 104 kB | ✅ Actif |

---

## 📚 CATÉGORIES DES 28 TABLES

### **1️⃣ LÉGIFRANCE RAG (4 tables)** 🏛️

#### **files_queue** 📋
- **Rows** : 259
- **Size** : 296 kB
- **Rôle** : Queue traitement fichiers JSON depuis bucket
- **Utilisé par** : Micro-service (INSERT), Workers (SELECT pending)
- **Colonnes clés** :
  - `file_path` : Chemin bucket (UNIQUE)
  - `status` : pending/completed/failed
  - `worker_id` : Worker qui traite
- **RLS** : Service role only

#### **documents** 📄
- **Rows** : 28 (base reconstruite après fix LEGIARTI)
- **Size** : 312 kB
- **Rôle** : Documents avec embeddings contexte global
- **Utilisé par** : Workers (INSERT), Backend RAG (SELECT)
- **Colonnes clés** :
  - `content` : Texte complet
  - `embedding` : Vector 768 dims
  - `file_path` : Lien bucket (UNIQUE)
- **Index** : HNSW (à recréer après 100k docs)
- **RLS** : Users voient leurs docs OU docs publics (user_id IS NULL)

#### **parsed_files** 🔐
- **Rows** : 28
- **Size** : 372 MB
- **Rôle** : Anti-duplication (évite reparse)
- **Utilisé par** : Workers (vérification doublon)
- **Colonnes clés** :
  - `file_path` : UNIQUE
  - `content_hash` : SHA256
  - `document_id` : UUID document créé
- **RLS** : Service role only

#### **document_chunks** 🧩
- **Rows** : 0 (prêt pour 6-9M chunks)
- **Size** : 3.6 MB (pré-alloué)
- **Rôle** : Chunks granulaires (articles, sections)
- **Utilisé par** : WorkerLocal Chunk (INSERT futur), Backend RAG (SELECT futur)
- **Colonnes clés** :
  - `document_id` : UUID parent (NULLABLE)
  - `chunk_index` : Ordre
  - `content` : Texte chunk
  - `embedding` : Vector 768 dims
- **Index** : HNSW prêt
- **RLS** : Hérite parent

---

### **2️⃣ CHAT UTILISATEUR (2 tables)** 💬

#### **conversations** 🗨️
- **Rows** : 205
- **Size** : 104 kB
- **Rôle** : Sessions chat
- **Lien** : → chat_messages, ← auth.users, → projects
- **RLS** : Users voient leurs conversations

#### **chat_messages** 💬
- **Rows** : ~1,000
- **Size** : 5.4 MB
- **Rôle** : Messages chat (questions/réponses)
- **Lien** : ← conversations, ← auth.users
- **Colonnes clés** :
  - `message` : Contenu
  - `role` : user/assistant/system
  - `model_used` : Modèle Groq
  - `tokens_used` : Consommation
- **RLS** : Users voient leurs messages

---

### **3️⃣ AUTHENTIFICATION (1 table)** 👤

#### **users** 👥
- **Rows** : 0 (sync auto depuis auth.users)
- **Size** : 64 kB
- **Rôle** : Profils custom (complète auth.users)
- **Lien** : ← auth.users (sync auto)
- **Colonnes clés** :
  - `id` : UUID (même que auth.users.id)
  - `role` : admin/developer/user
  - `subscription_tier` : free/pro/enterprise
- **RLS** : Users voient leur profil
- **⚠️ NE PAS SUPPRIMER** : Utilisée par backend

---

### **4️⃣ MONITORING & ADMIN (7 tables)** 📊

- **ingestion_metrics** : Métriques parsing workers
- **system_alerts** : Alertes système
- **timeline_cache** : Timeline 24h pré-calculée
- **metrics_hourly_rollup** : Agrégation horaire
- **admin_metrics_snapshot** : Legacy (obsolète)
- **realtime_metrics** : Compteurs incrémentaux (futur)
- **weekly_reports** : Rapports hebdo (prêt)

---

### **5️⃣ ARCHIVAGE & PURGE (4 tables)** 📦

- **ingestion_metrics_archive** : Archive > 30j
- **retention_audit_log** : Audit purges
- **backup_audit_log** : Audit backups
- **manual_purge_logs** : Audit purges manuelles

---

### **6️⃣ FEATURES FUTURES (6 tables)** 🎨

- **projects** : Projets utilisateurs (vide)
- **templates** : Templates documents (vide)
- **project_exports** : Exports PDF/ZIP (vide)
- **map_views** : Vues cartographiques (vide)
- **mcp_servers** : Config MCP (vide)
- **sync_jobs_status** : Monitoring jobs (vide)

---

### **7️⃣ OPTIMISATION & DEBUG (4 tables)** 🔧

- **sync_checkpoints** : Checkpoints reprise (vide)
- **anomaly_detection_stats** : ML détection anomalies (vide)
- **index_usage_stats** : Monitoring index (vide)
- **intelligent_archive_config** : Config archivage (vide)

---

## ⚠️ TABLES SUPPRIMÉES (Oct 2025)

- ~~**plu_documents**~~ : ✅ Supprimée (21 index inutiles)
- ~~**public.messages**~~ : ✅ Supprimée (doublon chat_messages)

**Total libéré** : ~300 kB + 24 index

---

## 🎯 TABLES À NE JAMAIS SUPPRIMER

1. **files_queue** : Coordination workers
2. **documents** : RAG principal
3. **parsed_files** : Anti-duplication
4. **document_chunks** : Prêt chunking futur
5. **users** : Sync auth + rôles
6. **conversations** : Historique chat
7. **chat_messages** : Messages
8. **ingestion_metrics** : Métriques workers

---

**28 tables organisées, documentées, sécurisées** ✅

