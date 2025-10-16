# ⏰ CRON JOBS SUPABASE (pg_cron)

**Date** : 15 octobre 2025  
**Total Jobs** : 14 jobs actifs  
**Status** : ✅ TOUS ACTIFS

---

## 📊 JOBS ACTIFS (État Réel)

### **🧹 NETTOYAGE & MAINTENANCE**

#### **Job 1 : cleanup-old-logs**
```sql
Schedule : 0 2 * * *  (Tous les jours à 2h)
Commande : DELETE FROM system_alerts 
           WHERE created_at < NOW() - INTERVAL '30 days' 
             AND resolved = TRUE
Status   : ✅ Actif
```

#### **Job 2 : cleanup-old-metrics**
```sql
Schedule : 15 2 * * *  (Tous les jours à 2h15)
Commande : DELETE FROM ingestion_metrics 
           WHERE created_at < NOW() - INTERVAL '30 days'
Status   : ✅ Actif
```

#### **Job 3 : weekly-vacuum**
```sql
Schedule : 0 3 * * 0  (Dimanche à 3h)
Commande : VACUUM ANALYZE files_queue;
           VACUUM ANALYZE ingestion_metrics;
           VACUUM ANALYZE system_alerts;
           VACUUM ANALYZE documents;
           VACUUM ANALYZE parsed_files;
           VACUUM ANALYZE document_chunks
Status   : ✅ Actif
Durée    : ~5-15 min
```

#### **Job 4 : weekly-reindex**
```sql
Schedule : 0 4 * * 0  (Dimanche à 4h)
Commande : REINDEX INDEX CONCURRENTLY idx_files_queue_status_all;
           REINDEX INDEX CONCURRENTLY idx_files_queue_processed_at
Status   : ✅ Actif
Durée    : ~2-5 min
```

---

### **📊 MÉTRIQUES & MONITORING**

#### **Job 5 : update-timeline-cache**
```sql
Schedule : */5 * * * *  (Toutes les 5 minutes)
Commande : INSERT INTO timeline_cache (hour, total, completed, failed)
           SELECT date_trunc('hour', processed_at), COUNT(*), ...
           FROM files_queue WHERE processed_at >= NOW() - INTERVAL '24 hours'
           ON CONFLICT (hour) DO UPDATE ...
Status   : ✅ Actif
```

#### **Job 9 : hourly-rollup**
```sql
Schedule : 0 * * * *  (Toutes les heures)
Commande : INSERT INTO metrics_hourly_rollup
           SELECT date_trunc('hour'), COUNT(*), AVG(...) 
           FROM files_queue
           ON CONFLICT (hour) DO UPDATE ...
Status   : ✅ Actif
```

#### **Job 8 : weekly-report**
```sql
Schedule : 0 6 * * 1  (Lundi à 6h)
Commande : INSERT INTO weekly_reports
           SELECT week_start, week_end, total_processed, ...
           FROM files_queue WHERE processed_at > NOW() - INTERVAL '7 days'
Status   : ✅ Actif
```

---

### **🚨 ALERTES AUTOMATIQUES**

#### **Job 6 : detect-inactive-workers**
```sql
Schedule : */10 * * * *  (Toutes les 10 minutes)
Commande : INSERT INTO system_alerts WHERE MAX(processed_at) < NOW() - INTERVAL '30 min'
Status   : ✅ Actif
Seuil    : Worker inactif > 30 min
```

#### **Job 7 : detect-high-error-rate**
```sql
Schedule : */15 * * * *  (Toutes les 15 minutes)
Commande : INSERT INTO system_alerts WHERE error_rate > 10%
Status   : ✅ Actif
Seuil    : Taux erreur > 10%
Severity : > 20% = critical, > 10% = warning
```

#### **Job 11 : detect-stagnant-queue**
```sql
Schedule : */30 * * * *  (Toutes les 30 minutes)
Commande : INSERT INTO system_alerts WHERE pending > 100 AND age > 2h
Status   : ✅ Actif
Seuil    : Queue stagnante > 100 fichiers > 2h
```

---

### **📈 ADMIN METRICS (OPTIMISÉ)**

#### **Job 21 : refresh-admin-metrics-main**
```sql
Schedule : */15 * * * *  (Toutes les 15 minutes) ← OPTIMISÉ (était 5 min)
Commande : SELECT public.refresh_admin_metrics_view();
Status   : ✅ Actif
Gain     : -66% CPU (5min → 15min)
```

#### **Job 22 : refresh-admin-metrics-view**
```sql
Schedule : */15 * * * *  (Toutes les 15 minutes) ← OPTIMISÉ (était 5 min)
Commande : SELECT refresh_admin_metrics_view();
Status   : ✅ Actif
Note     : Doublon du job 21 (à nettoyer ?)
```

---

### **🔄 MAINTENANCE INDEX HNSW**

#### **Job 23 : monthly-reindex-hnsw**
```sql
Schedule : 0 3 1 * *  (1er du mois à 3h)
Commande : REINDEX INDEX CONCURRENTLY idx_documents_embedding_hnsw;
           REINDEX INDEX CONCURRENTLY idx_document_chunks_embedding_hnsw;
           ANALYZE documents;
           ANALYZE document_chunks;
Status   : ✅ Actif
Durée    : ~10-20 min (selon taille base)
```

---

### **🗄️ ARCHIVAGE**

#### **Job 10 : archive-old-metrics**
```sql
Schedule : 0 3 * * *  (Tous les jours à 3h)
Commande : DELETE FROM ingestion_metrics WHERE created_at < NOW() - '30 days'
           INSERT INTO ingestion_metrics_archive ...
Status   : ✅ Actif
```

---

## 📊 RÉSUMÉ PAR FRÉQUENCE

| Fréquence | Jobs | Rôle |
|-----------|------|------|
| **Toutes les 5 min** | 1 job | Timeline cache (métriques 24h) |
| **Toutes les 10 min** | 1 job | Workers inactifs |
| **Toutes les 15 min** | 3 jobs | Admin metrics (×2) + Error rate |
| **Toutes les 30 min** | 1 job | Queue stagnante |
| **Toutes les heures** | 1 job | Hourly rollup |
| **Tous les jours 2h-3h** | 3 jobs | Cleanup logs + metrics + archive |
| **Dimanche matin** | 2 jobs | VACUUM + REINDEX |
| **Lundi matin** | 1 job | Weekly report |
| **1er du mois** | 1 job | REINDEX HNSW |

**Total** : **14 jobs actifs** ✅

---

## 🔒 SÉCURITÉ

**IMPORTANT** : Les cron jobs **NE PEUVENT PAS être modifiés depuis le frontend** (mode READ-ONLY) !

Pour modifier un job :
```sql
-- Via SQL Editor Supabase uniquement
UPDATE cron.job SET schedule = '*/30 * * * *' WHERE jobid = 5;
```

**Fonctions SQL dangereuses supprimées** :
- ~~`toggle_cron_job()`~~ ❌
- ~~`create_cron_job()`~~ ❌
- ~~`delete_cron_job()`~~ ❌

---

## 🎯 JOBS CRITIQUES (NE PAS DÉSACTIVER)

1. **refresh-admin-metrics** (21, 22) : Dashboard admin
2. **update-timeline-cache** (5) : Graphique timeline
3. **weekly-vacuum** (3) : Performance DB
4. **monthly-reindex-hnsw** (23) : Recherche vectorielle

---

**14 jobs actifs, optimisés, sécurisés** ✅

