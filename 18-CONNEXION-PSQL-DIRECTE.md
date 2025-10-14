# 🔗 Connexion psql Directe à Supabase

## 🎯 Format de Connexion Directe (sans pooler)

### ✅ Format Correct
```bash
postgresql://postgres:PASSWORD@db.PROJECT_ID.supabase.co:5432/postgres?sslmode=require
```

### 📋 Exemple avec notre projet
```bash
postgresql://postgres:F6jdur5RDzXfMkBP@db.joozqsjbcwrqyeqepnev.supabase.co:5432/postgres?sslmode=require
```

## ⚠️ Points Importants

### ❌ À ÉVITER
- **Pooler** : `aws-0-eu-west-3.pooler.supabase.com` → Timeout sur SET + CREATE INDEX
- **User complet** : `postgres.PROJECT_ID` → Authentication failed

### ✅ À UTILISER
- **Direct** : `db.PROJECT_ID.supabase.co` → Pas de timeout
- **User simple** : `postgres` → Authentication OK

## 🚀 Commandes SQL avec SET (nécessitent connexion directe)

```sql
SET maintenance_work_mem = '512MB';
SET max_parallel_maintenance_workers = 4;
SET statement_timeout = '1800000';
SET work_mem = '64MB';
CREATE INDEX CONCURRENTLY idx_name ON table USING hnsw (column vector_cosine_ops);
```

## 📊 Cas d'Usage

### ✅ Connexion Directe (recommandée pour)
- Création d'index HNSW avec SET
- Commandes maintenance lourdes
- Opérations DDL complexes

### ✅ Pooler (pour applications)
- Connexions application
- Requêtes SELECT/INSERT/UPDATE simples
- Haute disponibilité

## 🔧 Résolution de Problèmes

### Erreur : "password authentication failed"
- Vérifier le nom d'utilisateur : utiliser `postgres` (pas `postgres.PROJECT_ID`)
- Vérifier le mot de passe dans le dashboard Supabase

### Erreur : "timeout" sur CREATE INDEX
- Utiliser la connexion directe (pas pooler)
- Appliquer les paramètres SET avant CREATE INDEX

### Erreur : "cannot run inside a transaction block"
- Utiliser `CREATE INDEX CONCURRENTLY` (pas `CREATE INDEX`)
- Ou exécuter via psql direct (pas via migration)

### Erreur : "could not resize shared memory segment" / "No space left on device"
- **Cause** : `maintenance_work_mem` trop élevé pour Supabase Micro
- **Solution** : Réduire à 128MB au lieu de 512MB
- **Commandes corrigées** :
```sql
SET maintenance_work_mem = '128MB';  -- Au lieu de 512MB
SET max_parallel_maintenance_workers = 4;
SET statement_timeout = '1800000';
SET work_mem = '64MB';
DROP INDEX IF EXISTS idx_name;
CREATE INDEX CONCURRENTLY idx_name ON table USING hnsw (column vector_cosine_ops) WITH (m = 16, ef_construction = 64);
```

### Erreur : "relation already exists" sur CREATE INDEX
- **Cause** : Index existe déjà (peut-être corrompu)
- **Solution** : DROP puis RECREATE
```sql
DROP INDEX IF EXISTS idx_name;
CREATE INDEX CONCURRENTLY idx_name ON table USING hnsw (column vector_cosine_ops) WITH (m = 16, ef_construction = 64);
```

---

**Format validé et testé le 13 octobre 2025** ✅
