# 🔒 Sécurité Cron Jobs - READ-ONLY

## 🎯 Décision Sécurité (11 octobre 2025)

Les **fonctionnalités de modification de cron jobs** ont été **supprimées du frontend** pour des raisons de sécurité.

---

## ⚠️ Risques Identifiés (AVANT)

| **Risque** | **Gravité** | **Impact Potentiel** |
|---|---|---|
| **SQL Injection** | 🔴 CRITIQUE | Création de jobs malicieux |
| **Privilege Escalation** | 🔴 CRITIQUE | Exécution avec droits `postgres` (superuser) |
| **Code Execution** | 🔴 CRITIQUE | Exécution de commandes SQL arbitraires |
| **Persistance** | 🟠 ÉLEVÉ | Backdoors permanents dans `cron.job` |
| **Déni de Service** | 🟠 ÉLEVÉ | Désactivation de jobs critiques |

---

## ✅ Solution Implémentée

### **Frontend (ArchiReg-Front/pages/admin.tsx)**

**Supprimé :**
- ❌ Bouton "Créer Job"
- ❌ Bouton "Désactiver/Activer"
- ❌ Bouton "Supprimer"
- ❌ Fonction `handleToggleJob()`
- ❌ Fonction `handleCreateCronJob()`

**Conservé :**
- ✅ Affichage liste des cron jobs
- ✅ Bouton "Voir les détails" (expand)
- ✅ Bouton "Rafraîchir" (reload list)
- ✅ Badge "🔒 Mode lecture seule"

---

### **Edge Function (cron-manager)**

**Avant :**
```typescript
// Supportait GET, POST, DELETE
if (method === 'POST') { /* toggle/create */ }
if (method === 'DELETE') { /* delete */ }
```

**Après :**
```typescript
// Supporte UNIQUEMENT GET (read-only)
if (method === 'GET') {
  return jobs; // Liste uniquement
}

return Response(405, { 
  error: 'Method not allowed - Read-only endpoint' 
});
```

---

### **Base de Données Supabase**

**Fonctions supprimées :**
```sql
DROP FUNCTION public.toggle_cron_job(bigint);
DROP FUNCTION public.create_cron_job(text, text, text);
DROP FUNCTION public.delete_cron_job(bigint);
```

**Fonction conservée :**
```sql
-- Lecture seule
CREATE FUNCTION public.get_cron_jobs_list() 
RETURNS json;
```

---

## 🛠️ Comment Modifier les Cron Jobs ?

### **Méthode Sécurisée (SQL Editor Supabase)**

**1. Accéder au SQL Editor :**
```
https://supabase.com/dashboard/project/joozqsjbcwrqyeqepnev/sql/new
```

**2. Activer/Désactiver un job :**
```sql
UPDATE cron.job 
SET active = false 
WHERE jobid = 22;
```

**3. Créer un nouveau job :**
```sql
SELECT cron.schedule(
  'mon-nouveau-job',        -- Nom
  '*/30 * * * *',           -- Schedule
  'SELECT ma_fonction();'   -- Commande
);
```

**4. Supprimer un job :**
```sql
SELECT cron.unschedule('mon-nouveau-job');
```

**5. Modifier la commande d'un job existant :**
```sql
SELECT cron.alter_job(
  3,  -- jobid
  command => '
    VACUUM ANALYZE files_queue;
    VACUUM ANALYZE documents;
    -- ... autres commandes
  '
);
```

---

## 📊 Impact Sécurité

| **Avant** | **Après** | **Amélioration** |
|---|---|---|
| Frontend peut créer des jobs SQL | ❌ Impossible | **+100% sécurité** ✅ |
| Frontend peut modifier des jobs | ❌ Impossible | **+100% sécurité** ✅ |
| Risque SQL injection via cron | ❌ Impossible | **0 risque** ✅ |
| Escalade de privilèges | ❌ Impossible | **0 risque** ✅ |

---

## 🎯 Avantages

1. **Sécurité maximale** : 0 risque d'injection SQL
2. **Simplicité** : Moins de code = moins de bugs
3. **Contrôle** : Modifications uniquement par admin avec accès SQL Editor
4. **Audit** : Toutes les modifications tracées dans Supabase

---

## 📝 Notes

- Les Edge Functions Supabase sont **déjà déployées** sur le cloud
- Le dossier local `supabase/` a été **supprimé** (c'était juste une copie temporaire)
- La **vraie source** des Edge Functions est sur Supabase Cloud
- Pour modifier une Edge Function : utiliser l'interface Supabase ou le CLI

---

**Version** : 1.0.0  
**Date** : 11 octobre 2025 16:00 UTC  
**Status** : ✅ Appliqué en production

