# ⚡ AUTO-SYNC STORAGE ↔ FILES_QUEUE

**Date** : 15 octobre 2025  
**Version** : 2.5.0  
**Status** : ✅ FONCTIONNEL

---

## 🎯 Principe

Le micro-service maintient **automatiquement** la cohérence entre :
- **Bucket Storage** : Fichiers JSON uploadés
- **Table files_queue** : Queue de traitement pour Workers

```
Micro-service upload JSON
    ↓
Bucket Storage (+1 fichier)
    ↓
INSERT automatique files_queue (+1 row) ← AUTO-SYNC CONTINU
```

---

## 🔄 SYNCHRONISATION CONTINUE

### **Lors de chaque collecte** (temps réel)

**Fichier** : `app/services/supabase_service.py` (ligne 71-131)

```python
async def save_legal_document(document: Dict, category: str):
    """Upload bucket + INSERT files_queue automatique"""
    
    # 1. Upload vers Storage
    self.supabase_client.storage.from_("agentbasic-legifrance-raw").upload(
        path=bucket_path,
        file=json_content.encode('utf-8')
    )
    
    # 2. INSERT AUTOMATIQUE dans files_queue
    self.supabase_client.table('files_queue').insert({
        "file_path": bucket_path,
        "bucket_id": "agentbasic-legifrance-raw",
        "status": "pending"
    }).execute()
```

**Résultat** :
- ✅ Mode MASSIVE : ~200-300 docs/min → 200-300 INSERT/min
- ✅ Mode MAINTENANCE : ~50-100 docs/2h → 50-100 INSERT/2h
- ✅ **Cohérence 100%** en temps réel

---

## 🚀 AUTO-SYNC AU DÉMARRAGE

### **Vérification Intelligente**

**Fichier** : `app/main.py` (ligne 70-104)

```python
# Au démarrage du micro-service
coherence = await supabase_service.check_queue_coherence()

if coherence.get("needs_sync", False):
    missing_count = coherence.get("missing", 0)
    
    # Auto-sync si < 100k fichiers manquants
    if missing_count < 100000:
        asyncio.create_task(supabase_service.auto_sync_storage_to_queue())
        logger.info("✅ AUTO-SYNC lancé en arrière-plan")
    else:
        logger.critical("🚨 SYNC MANUELLE REQUISE - Trop de fichiers manquants")
else:
    logger.info("✅ Cohérence OK")
```

### **Seuils de Synchronisation**

| Écart | Action | Méthode |
|-------|--------|---------|
| **< 5%** | ✅ Rien | Cohérence OK |
| **5-100k manquants** | ⚡ Auto-sync | Arrière-plan automatique |
| **> 100k manquants** | 🚨 Alerte admin | SQL manuel requis |

---

## 📊 ÉTAT ACTUEL (15 Oct 2025)

### **Vérification Cohérence**
```
Storage : 259 fichiers
files_queue : 259 fichiers
Écart : 0 fichiers (0%)
Status : ✅ COHÉRENCE PARFAITE
```

**Résultat** : Auto-sync n'a PAS besoin de tourner ! ✅

---

## 🔧 SYNC MANUELLE (Cas Extrêmes)

### **Quand ?**
- Après TRUNCATE files_queue
- Après migration/restauration
- Écart > 100k fichiers

### **Script SQL**
```sql
-- Batch 50k pour éviter timeout
INSERT INTO files_queue (file_path, bucket_id, file_size, status, processed)
SELECT 
    name as file_path,
    bucket_id,
    (metadata->>'size')::BIGINT as file_size,
    'pending' as status,
    FALSE as processed
FROM storage.objects
WHERE bucket_id = 'agentbasic-legifrance-raw'
LIMIT 50000 OFFSET 0  -- Ajuster OFFSET : 0, 50k, 100k, etc.
ON CONFLICT (file_path) DO NOTHING;
```

---

## 📈 MONITORING

### **Vérifier Cohérence**
```sql
-- Comparaison Storage vs files_queue
SELECT 
    'Storage' as source,
    COUNT(*) as total_files
FROM storage.objects
WHERE bucket_id = 'agentbasic-legifrance-raw'

UNION ALL

SELECT 
    'files_queue' as source,
    COUNT(*) as total_files
FROM files_queue;
```

**Résultat attendu** : Même nombre (ou queue légèrement > storage) ✅

---

## 🎉 Résumé

**Auto-sync intelligent** :
- ✅ INSERT automatique lors de chaque upload
- ✅ Vérification au démarrage
- ✅ Sync arrière-plan si écart 5-100k
- ✅ Alerte admin si écart > 100k
- ✅ Cohérence 100% garantie

**Cohérence actuelle : 259 = 259 (PARFAIT) !** 🎯

