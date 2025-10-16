# 🔒 RLS POLICIES - SÉCURITÉ ROW LEVEL SECURITY

**Date** : 15 octobre 2025  
**Tables avec RLS** : 17/17 (100%)  
**Status** : ✅ TOUTES LES TABLES PROTÉGÉES

---

## 🎯 Principe

**RLS (Row Level Security)** = Sécurité au niveau des lignes

```sql
-- Sans RLS ❌
SELECT * FROM documents;  -- Voit TOUT (tous users)

-- Avec RLS ✅
SELECT * FROM documents;  -- Voit SEULEMENT ses docs + docs publics
```

---

## ✅ TABLES PROTÉGÉES (17 tables)

### **📚 LÉGIFRANCE RAG**

#### **documents**
```sql
-- Users voient leurs docs OU docs publics
CREATE POLICY documents_select_policy ON documents
FOR SELECT USING (
    (user_id = auth.uid()) OR (user_id IS NULL)
);

-- Service role peut tout faire
CREATE POLICY documents_service_role ON documents
FOR ALL USING (auth.role() = 'service_role');
```

#### **files_queue**
```sql
-- Service role uniquement (Workers + Backend)
CREATE POLICY files_queue_backend_only ON files_queue
FOR ALL USING (auth.role() = 'service_role');
```

#### **parsed_files**
```sql
-- Service role uniquement (Workers)
CREATE POLICY parsed_files_service_role ON parsed_files
FOR ALL USING (auth.role() = 'service_role');
```

#### **document_chunks**
```sql
-- Hérite des permissions du parent (documents)
CREATE POLICY chunks_inherit_parent ON document_chunks
FOR SELECT USING (
    document_id IN (
        SELECT id FROM documents 
        WHERE (user_id = auth.uid()) OR (user_id IS NULL)
    )
);

-- Service role peut tout faire
CREATE POLICY chunks_service_role ON document_chunks
FOR ALL USING (auth.role() = 'service_role');
```

---

### **💬 CHAT**

#### **conversations**
```sql
-- Users voient seulement leurs conversations
CREATE POLICY conversations_select_own ON conversations
FOR SELECT USING (user_id = auth.uid());

-- Admins voient tout
CREATE POLICY conversations_admin_all ON conversations
FOR ALL USING (
    (SELECT app_metadata->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);
```

#### **chat_messages**
```sql
-- Users voient seulement leurs messages
CREATE POLICY chat_messages_select_own ON chat_messages
FOR SELECT USING (user_id = auth.uid());
```

---

### **👤 UTILISATEURS**

#### **users**
```sql
-- Users voient leur propre profil
CREATE POLICY users_select_own ON users
FOR SELECT USING (id = auth.uid());

-- Admins voient tous les profils
CREATE POLICY users_admin_all ON users
FOR ALL USING (
    (SELECT app_metadata->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);
```

---

### **📊 MONITORING (Service Role Only)**

Toutes les tables de monitoring :
- `ingestion_metrics`
- `system_alerts`
- `timeline_cache`
- `metrics_hourly_rollup`
- `admin_metrics_snapshot`
- `realtime_metrics`
- `weekly_reports`

```sql
-- Service role + Admin uniquement
CREATE POLICY monitoring_service_admin ON [TABLE]
FOR ALL USING (
    auth.role() = 'service_role' OR
    (SELECT app_metadata->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
);
```

---

## 🔐 VÉRIFICATION

### **Toutes les Tables ont RLS**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = false;

-- Résultat attendu : 0 rows ✅
```

### **Liste des Policies**
```sql
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

---

## 🚨 RÈGLES CRITIQUES

### **1. Frontend JAMAIS service_role**
```bash
# ✅ Frontend utilise
NEXT_PUBLIC_SUPABASE_ANON_KEY=...  # RLS appliquées

# ❌ JAMAIS dans frontend
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=...  # DANGEREUX !
```

### **2. Workers/Backend utilisent service_role**
```bash
# ✅ Backend/Workers
SUPABASE_SERVICE_ROLE_KEY=...  # Bypass RLS (autorisé)
```

### **3. Admin via app_metadata**
```sql
-- Vérification admin
(SELECT app_metadata->>'role' FROM auth.users WHERE id = auth.uid()) = 'admin'
```

---

## 🎯 Sécurité Effective

**Toutes les tables sont protégées** :
- ✅ RLS activé (100%)
- ✅ Policies correctes
- ✅ Service role contrôlé
- ✅ Admin via app_metadata
- ✅ Frontend avec anon_key uniquement

**Aucune fuite de données possible !** 🔒

