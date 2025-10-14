# 📋 FILES_QUEUE : SYNCHRONISATION AUTOMATIQUE

**Date** : 13 Octobre 2025  
**Version** : v1.0  
**Auteur** : Documentation Technique

---

## 🎯 Vue d'Ensemble

La table `files_queue` est maintenue **automatiquement à jour** par le micro-service Légifrance lors de la collecte de nouveaux documents depuis l'API PISTE.

---

## ⚡ Fonctionnement Automatique

### 1️⃣ **Mode MASSIVE (Collecte Continue)**

```python
# Micro-service Légifrance (app/services/supabase_service.py)
async def save_legal_document(document: Dict, category: str):
    # 1. Upload vers Storage bucket
    bucket_path = f"legifrance/{category}/{doc_id}.json"
    self.supabase_client.storage.from_('agentbasic-legifrance-raw').upload(
        bucket_path, json_content
    )
    
    # 2. INSERT AUTOMATIQUE dans files_queue ← CRITIQUE !
    self.supabase_client.table('files_queue').insert({
        "file_path": bucket_path,
        "bucket_id": "agentbasic-legifrance-raw",
        "status": "pending"
    }).execute()
```

**Résultat** :
- ✅ ~200-300 documents collectés par minute (en mode MASSIVE)
- ✅ Chaque document → Upload Storage + INSERT files_queue
- ✅ Les Workers peuvent traiter immédiatement
- ✅ Pas de synchronisation manuelle nécessaire

---

### 2️⃣ **Mode MAINTENANCE (Collecte CRON)**

```python
# Scheduler : Toutes les 2h (configurable)
# CRON: "0 */2 * * *"
async def _run_collection_job():
    # Collecte batch (50-100 docs)
    documents = await legifrance_service.search_urbanisme_documents(page_size=50)
    
    # Sauvegarde → Auto-insert files_queue
    for doc in documents:
        await supabase_service.save_legal_document(doc, "urbanisme")
```

**Résultat** :
- ✅ 50-100 documents toutes les 2h
- ✅ INSERT automatique dans files_queue
- ✅ Pas d'intervention manuelle

---

## 🔄 Synchronisation Manuelle (Cas Spéciaux)

### ⚠️ Quand Faire une Sync Manuelle ?

**SEULEMENT dans ces cas** :

1. **Après un TRUNCATE de files_queue**
   - Vidage complet de la queue (erreur humaine)
   - Besoin de repeupler depuis Storage existant

2. **Après une migration/réinitialisation**
   - Nouvelle installation du système
   - Restauration depuis backup Storage

3. **Détection d'incohérence**
   - Storage a 1.3M fichiers mais files_queue a seulement 10k
   - Perte de synchronisation (très rare)

---

## 📊 Script de Synchronisation Manuelle

### **SQL : Repeupler files_queue depuis Storage**

```sql
-- ========================================
-- REPEUPLER files_queue depuis Storage
-- Utiliser ON CONFLICT pour éviter doublons
-- ========================================

-- OPTION A : Batch par batch (recommandé pour >500k fichiers)
INSERT INTO files_queue (file_path, bucket_id, file_size, status, processed)
SELECT 
    name as file_path,
    bucket_id,
    (metadata->>'size')::BIGINT as file_size,
    'pending' as status,
    FALSE as processed
FROM storage.objects
WHERE bucket_id = 'agentbasic-legifrance-raw'
LIMIT 100000 OFFSET 0  -- Ajuster OFFSET : 0, 100000, 200000, etc.
ON CONFLICT (file_path) DO NOTHING;

-- OPTION B : Tout d'un coup (seulement si <100k fichiers)
INSERT INTO files_queue (file_path, bucket_id, file_size, status, processed)
SELECT 
    name,
    bucket_id,
    (metadata->>'size')::BIGINT,
    'pending',
    FALSE
FROM storage.objects
WHERE bucket_id = 'agentbasic-legifrance-raw'
ON CONFLICT (file_path) DO NOTHING;
```

---

## 📈 Monitoring de la Synchronisation

### **Vérifier la Cohérence Storage ↔ files_queue**

```sql
-- Stats comparatifs
SELECT 
    'Storage' as source,
    COUNT(*) as total_files,
    pg_size_pretty(SUM((metadata->>'size')::BIGINT)) as total_size
FROM storage.objects
WHERE bucket_id = 'agentbasic-legifrance-raw'

UNION ALL

SELECT 
    'files_queue' as source,
    COUNT(*) as total_files,
    pg_size_pretty(SUM(file_size)) as total_size
FROM files_queue;
```

**Résultat attendu** :
```
source       | total_files | total_size
-------------|-------------|------------
Storage      | 1,383,227   | 145 GB
files_queue  | 1,385,500   | 146 GB
```

> **Note** : files_queue peut avoir légèrement PLUS de fichiers que Storage car le micro-service insère dans files_queue AVANT l'upload (puis upload fail = fichier en queue mais pas en Storage).

---

## 🚨 Alertes & Diagnostics

### **Détecter une Désynchronisation**

```sql
-- Fichiers dans Storage MAIS PAS dans files_queue
SELECT COUNT(*) as missing_in_queue
FROM storage.objects s
LEFT JOIN files_queue fq ON s.name = fq.file_path
WHERE s.bucket_id = 'agentbasic-legifrance-raw'
  AND fq.file_path IS NULL;
```

**Si `missing_in_queue > 1000`** → Lancer synchronisation manuelle ⚠️

---

### **Vérifier le Taux d'Insertion Temps Réel**

```sql
-- Fichiers ajoutés dans les dernières 10 minutes
SELECT 
    date_trunc('minute', created_at) as minute,
    COUNT(*) as files_inserted,
    STRING_AGG(DISTINCT bucket_id, ', ') as buckets
FROM files_queue
WHERE created_at > NOW() - INTERVAL '10 minutes'
GROUP BY date_trunc('minute', created_at)
ORDER BY minute DESC;
```

**Résultat attendu (mode MASSIVE)** :
```
minute              | files_inserted | buckets
--------------------|----------------|-----------------------------
2025-10-13 20:05:00 | 297           | agentbasic-legifrance-raw
2025-10-13 20:04:00 | 312           | agentbasic-legifrance-raw
2025-10-13 20:03:00 | 288           | agentbasic-legifrance-raw
```

> **~200-300 fichiers/min** = Micro-service en collecte MASSIVE active ✅

---

## 💡 Bonnes Pratiques

### ✅ À FAIRE

1. **Laisser le micro-service gérer files_queue automatiquement**
   - Ne PAS créer de cron de synchronisation Storage → files_queue
   - Le micro-service le fait déjà en temps réel

2. **Monitorer la cohérence périodiquement**
   - Dashboard admin affiche Storage vs files_queue
   - Alertes si écart > 10%

3. **Après TRUNCATE : Sync manuelle obligatoire**
   - Utiliser le script SQL par batch 100k
   - Vérifier la cohérence après

### ❌ À ÉVITER

1. **Ne PAS créer un cron de sync automatique**
   - Doublon avec le micro-service
   - Peut causer des conflits

2. **Ne PAS faire TRUNCATE sans raison valide**
   - files_queue = source de vérité pour les Workers
   - TRUNCATE = régénération complète nécessaire

3. **Ne PAS synchroniser manuellement si tout fonctionne**
   - Le micro-service maintient la queue automatiquement
   - Intervention manuelle = risque d'erreur

---

## 📚 Résumé

| Scénario | Action | Automatique ? |
|----------|--------|---------------|
| **Nouveau document collecté** | INSERT files_queue | ✅ Automatique (micro-service) |
| **Mode MASSIVE actif** | ~200-300 docs/min → files_queue | ✅ Automatique |
| **Mode MAINTENANCE** | ~50-100 docs/2h → files_queue | ✅ Automatique |
| **Après TRUNCATE** | Repeupler depuis Storage | ❌ Manuel (SQL batch) |
| **Incohérence détectée** | Synchronisation Storage → queue | ❌ Manuel (SQL) |
| **Fonctionnement normal** | Rien à faire | ✅ Automatique |

**Conclusion** : Dans 99% des cas, **files_queue se maintient tout seul** grâce au micro-service Légifrance ! 🎉

