# 📁 SQL MIGRATIONS - ADMIN METRICS VIEW

## **📋 FICHIERS FINAUX (EN PRODUCTION) :**

| Fichier | Statut | Description |
|---------|--------|-------------|
| **`final_complete_view.sql`** | ✅ **EN PRODUCTION** | Vue matérialisée optimisée avec métriques essentielles |
| **`create_cron_helpers.sql`** | ✅ **EN PRODUCTION** | Fonctions helpers pour pg_cron (get, toggle, delete, create) |
| **`create_indexes.sql`** | ✅ **APPLIQUÉ** | Index partiels sur files_queue (via psql) |
| **`drop_unused_indexes.sql`** | ✅ **APPLIQUÉ** | Suppression 37 index inutilisés (via psql) |

---

## **🎯 VUE `admin_metrics_view` - MÉTRIQUES ACTIVES :**

### **📊 FILES QUEUE (6 métriques) :**
- `total_files` (COUNT FILTER)
- `files_completed` (COUNT FILTER avec index)
- `files_pending` (COUNT FILTER avec index)
- `files_processing` (COUNT FILTER avec index)
- `files_failed` (COUNT FILTER avec index)
- `recent_activity` (dernières 5 min)

### **📚 DOCUMENTS (3 métriques) :**
- `total_documents` (parsed_files, **reltuples**)
- `total_chunks` (document_chunks, **reltuples**)
- `total_documents_rag` (documents, **reltuples**)

### **⚡ PERFORMANCE (2 métriques) :**
- `avg_processing_time_ms` (dernière heure)
- `fichiers_par_sec` (dernière heure)

### **👷 WORKERS (1 métrique JSON) :**
- `workers_real` (array JSON, dernières 24h)
  - worker_id, fichiers_traites, debut, fin, status
  - fichiers_par_sec, duree_minutes
  - **taux_erreur_pct, pct_doublons** (calculés)

### **📦 BUCKET (5 métriques dans JSON) :**
- `total_objects`
- `total_size_bytes`
- `last_file_added_at`
- `files_added_last_24h`
- `files_added_last_hour`

### **📈 COMPUTED METRICS (8 métriques) :**
- `nb_workers_actifs`
- `vitesse_actuelle_f_sec`
- `vitesse_moyenne_f_sec`
- `temps_moyen_par_fichier_sec`
- `avg_file_size_kb`
- `eta_optimiste_h`
- `eta_pessimiste_h`
- `efficacite_workers`

### **📊 TIMELINE (1 métrique JSON) :**
- `timeline_24h` (horaire, dernières 24h)

### **🐛 ERREURS & QUALITÉ (3 métriques JSON) :**
- `errors_details` (dernières 100 erreurs, limit)
- `error_rate_by_worker` (si erreurs > 0, avec HAVING)
- `duplicates_by_worker` (si doublons > 0, avec HAVING)

### **✅ SANTÉ (1 métrique) :**
- `taux_succes` (% de fichiers réussis)

### **🕒 TIMESTAMPS (2 métriques) :**
- `refreshed_at`
- `generated_at`

---

## **❌ MÉTRIQUES DÉSACTIVÉES (OPTIMISATION) :**

| Métrique | Raison | Gain |
|----------|--------|------|
| `historique_30j` | Scan 30 jours trop lourd | **~180ms** |
| `top_heures` | Non utilisé dans frontend | **0ms** |
| `recent_batches` | Redondant avec workers | **~40ms** |
| `size_distribution` | Redondant avec avg_file_size_kb | **~83ms** |
| `top_heavy_files` | Non critique | **~70ms** |

**TOTAL ÉCONOMISÉ : ~373ms par refresh**

---

## **⚙️ REFRESH AUTOMATIQUE :**

**Cron Job :** `refresh-admin-metrics-view`  
**Schedule :** **Toutes les 10 minutes** (`*/10 * * * *`)  
**Commande :** `SELECT public.refresh_admin_metrics_view();`

**Changement vs avant :** 2 min → 10 min = **-80% fréquence**

---

## **🔄 VACUUM ANALYZE AUTOMATIQUE :**

**Cron Job :** `weekly-vacuum` (#3)  
**Schedule :** **Dimanche 3h du matin** (`0 3 * * 0`)  
**Commande :**
```sql
VACUUM ANALYZE files_queue;
VACUUM ANALYZE ingestion_metrics;
VACUUM ANALYZE system_alerts;
VACUUM ANALYZE documents;        -- ✅ AJOUTÉ (13 oct 2025)
VACUUM ANALYZE parsed_files;     -- ✅ AJOUTÉ (13 oct 2025)
VACUUM ANALYZE document_chunks;  -- ✅ AJOUTÉ (13 oct 2025)
```

**Raison :** Maintenir `reltuples` à jour pour les 3 grandes tables utilisées dans la vue `admin_metrics_view` (lignes 219-221).

**Impact :**
- ✅ Stats à jour toute la semaine (au lieu de semaines de retard)
- ✅ Frontend affiche les vrais chiffres (`total_documents_rag`, `total_documents`, `total_chunks`)
- ⚠️ +2-3 min de traitement (Dimanche 3h, aucun client actif)
- ⚠️ +10-15% CPU pendant 2-3 min (nuit, zéro impact utilisateurs)

---

## **🎯 OPTIMISATIONS APPLIQUÉES :**

### **1. Performance SQL :**
- ✅ **reltuples** au lieu de COUNT(*) pour grandes tables (parsed_files, documents, document_chunks)
- ✅ **COUNT(*) FILTER** avec index pour files_queue
- ✅ **Fenêtres temporelles réduites** (1h, 24h au lieu de 30j)
- ✅ **LIMITS** sur tous les aggregats (100 erreurs, 20 batches)
- ✅ **HAVING** pour filtrer les résultats vides (erreurs, doublons)

### **2. Index Stratégiques :**
- ✅ `idx_files_queue_pending_recent` (status, processed_at)
- ✅ `idx_files_queue_unprocessed_by_id` (processed, id)
- ✅ `idx_files_queue_processed_at_recent` (processed_at DESC)
- ✅ `idx_files_queue_worker_processing` (worker_id, status, processed_at)

### **3. Suppression Index Inutilisés :**
- ✅ 37 index supprimés
- ✅ Économie : **~432 MB** d'espace disque
- ✅ Amélioration : Writes plus rapides

---

## **📊 PERFORMANCE FINALE :**

| Métrique | Avant (Free tier) | Après (Micro 1GB 2-core) | Amélioration |
|----------|-------------------|--------------------------|--------------|
| **Temps refresh** | Timeout (>60s) | **5.9 secondes** | **-90%** ✅ |
| **Fréquence refresh** | 2 min (30x/h) | **10 min (6x/h)** | **-80%** ✅ |
| **CPU moyen** | 90% (saturé) | **12-15%** | **-83%** ✅ |
| **CPU pendant refresh** | 100% | 25-30% (6s) | **-70%** ✅ |
| **Auth timeout** | 30-40s | <100ms | **-99.7%** ✅ |
| **Marge CPU** | 0% | **85-88%** | ✅ |

---

## **🚀 DÉPLOIEMENT :**

### **1. Créer la vue :**
```sql
-- Via Supabase SQL Editor ou MCP
\i final_complete_view.sql
```

### **2. Créer les helpers cron :**
```sql
\i create_cron_helpers.sql
```

### **3. Créer les index (via psql interactif) :**
```bash
psql "postgresql://postgres.joozqsjbcwrqyeqepnev:PASSWORD@aws-0-eu-west-3.pooler.supabase.com:6543/postgres"
\i create_indexes.sql
```

### **4. Supprimer index inutilisés (via psql interactif) :**
```bash
\i drop_unused_indexes.sql
```

### **5. Créer le cron job :**
```sql
SELECT cron.schedule(
  'refresh-admin-metrics-view',
  '*/10 * * * *',
  'SELECT refresh_admin_metrics_view();'
);
```

---

## **🔐 SÉCURITÉ :**

- ✅ RLS activé sur toutes les tables
- ✅ Vue accessible uniquement via Edge Function (service_role)
- ✅ Pas d'accès direct depuis frontend (anon key)
- ✅ Fonction `SECURITY DEFINER` avec `search_path = public`

---

## **📚 RÉFÉRENCES :**

- [Edge Function admin-stats](../../05-EDGE-FUNCTIONS/admin-stats/index.ts)
- [Edge Function cron-manager](../../05-EDGE-FUNCTIONS/cron-manager/index.ts)
- [Architecture Globale](../../01-ARCHITECTURE-GLOBALE.md)
- [WebSockets vs Realtime](../../02-WEBSOCKETS-VS-REALTIME.md)

---

**📅 Dernière mise à jour :** 11 octobre 2025  
**Version :** 3.0 FINALE  
**Status :** ✅ En production
