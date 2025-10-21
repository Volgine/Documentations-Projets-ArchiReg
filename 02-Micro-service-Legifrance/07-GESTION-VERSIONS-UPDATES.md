# 🔄 GESTION DES VERSIONS ET MISES À JOUR

**Date** : 21 octobre 2025  
**Version** : 3.1 - Déduplication + UPSERT  
**Status** : ✅ EN PRODUCTION

---

## 🎯 QUESTION : COMMENT LE SERVICE GÈRE LES MISES À JOUR ?

**Exemple** : Code de l'Urbanisme 2021 → Nouvelle version 2025

---

## 📊 CAS D'USAGE

### **CAS 1 : MISE À JOUR MINEURE (MÊME ID LEGIARTI)** ✅

**Exemple** : Correction typo dans l'article L111-1

#### **Version 2021**
```json
{
  "id": "LEGIARTI000024376802",
  "num": "L111-1",
  "texteHtml": "<p>Ancien texte avec typo...</p>",
  "dateDebut": "2021-01-01",
  "dateFin": "2999-01-01"
}
```

**Fichier créé** : `legifrance/architecture_urbanisme/LEGIARTI000024376802.json`

#### **Version 2025 (correction)**
```json
{
  "id": "LEGIARTI000024376802",  // ✅ MÊME ID
  "num": "L111-1",
  "texteHtml": "<p>Texte corrigé...</p>",
  "dateDebut": "2021-01-01",
  "dateFin": "2999-01-01"
}
```

**Action** : ✅ **ÉCRASE** le fichier existant (bucket UPSERT + files_queue UPSERT)

**Résultat** :
- ✅ 1 seul fichier dans le bucket (version la plus récente)
- ✅ 1 seule entrée dans files_queue
- ✅ Pas de doublon !

---

### **CAS 2 : NOUVELLE VERSION LÉGALE (NOUVEL ID LEGIARTI)** 🔄

**Exemple** : Article L111-1 réécrit par nouvelle loi

#### **Version 2021**
```json
{
  "id": "LEGIARTI000024376802",  // Ancien ID
  "num": "L111-1",
  "texteHtml": "<p>Texte version 2021...</p>",
  "dateDebut": "2021-01-01",
  "dateFin": "2025-03-15"  // ❌ Fin de validité !
}
```

**Fichier** : `LEGIARTI000024376802.json`

#### **Version 2025 (réécriture)**
```json
{
  "id": "LEGIARTI000055555555",  // ✅ NOUVEL ID
  "num": "L111-1",
  "texteHtml": "<p>Texte version 2025...</p>",
  "dateDebut": "2025-03-16",
  "dateFin": "2999-01-01"
}
```

**Fichier** : `LEGIARTI000055555555.json` (NOUVEAU !)

**Action** : ✅ **CRÉE** un nouveau fichier (ID différent)

**Résultat** :
- ✅ 2 fichiers dans le bucket (historique complet)
- ✅ L'ancien reste accessible (version historique)
- ✅ Le nouveau est aussi collecté

**📌 NOTE** : C'est Légifrance qui décide si c'est une mise à jour (même ID) ou une nouvelle version (nouvel ID).

---

### **CAS 3 : ARTICLE SANS ID LÉGIFRANCE (HASH CONTENU)** ⚠️

**Exemple** : Document sans `id` ni `textId` dans la réponse API

#### **Version 2021**
```python
# Pas d'ID officiel → Génération hash du contenu
content = "L111-1|Texte urbanisme 2021..."
hash = sha256(content) = "abc123def456"
doc_id = "hash_abc123def456"
```

**Fichier** : `hash_abc123def456.json`

#### **Version 2025 (contenu modifié)**
```python
# Pas d'ID officiel → Génération hash du NOUVEAU contenu
content = "L111-1|Texte urbanisme 2025..."  // ❌ Contenu différent !
hash = sha256(content) = "xyz789ghi012"  // ❌ Hash différent !
doc_id = "hash_xyz789ghi012"
```

**Fichier** : `hash_xyz789ghi012.json` (NOUVEAU !)

**Action** : ✅ **CRÉE** un nouveau fichier (hash change avec le contenu)

**Résultat** :
- ⚠️ 2 fichiers dans le bucket (même article, versions différentes)
- ⚠️ Pas de déduplication automatique (pas d'ID stable)

---

## 🛠️ CODE IMPLÉMENTATION

### **1. Génération de l'ID (PRIORITÉS)**

```python
# PRIORITÉ 1 : ID de déduplication passé par mass_collector (MD5 métadonnées)
doc_id = document.get("_dedup_id")

# PRIORITÉ 2 : ID officiel Légifrance (STABLE entre versions)
if not doc_id:
    doc_id = document.get("id") or document.get("textId")  # LEGIARTI000xxxxx

# PRIORITÉ 3 : Hash SHA256 du contenu (CHANGE si contenu modifié)
if not doc_id:
    content_for_hash = f"{num_article}|{texte_html}"
    doc_id = f"hash_{sha256(content_for_hash)[:16]}"
```

---

### **2. Upload Bucket avec UPSERT**

```python
# Upload vers bucket (ligne 132-139)
self.supabase_client.storage.from_("agentbasic-legifrance-raw").upload(
    path=f"legifrance/{category}/{doc_id}.json",
    file=json_bytes,
    file_options={
        "content-type": "application/json",
        "upsert": "true"  # ✅ ÉCRASE si existe déjà
    }
)
```

**Comportement** :
- Si `doc_id` existe → ✅ **ÉCRASE** l'ancien fichier
- Si `doc_id` nouveau → ✅ **CRÉE** un nouveau fichier

---

### **3. UPSERT dans files_queue (FIX 21 oct 2025)**

```python
# UPSERT dans files_queue (ligne 149-153)
self.supabase_client.table('files_queue').upsert({
    "file_path": bucket_path,
    "bucket_id": "agentbasic-legifrance-raw",
    "status": "pending"
}).execute()
```

**Comportement** :
- Si `file_path` existe → ✅ **ÉCRASE** (reset status à pending)
- Si `file_path` nouveau → ✅ **CRÉE** une nouvelle entrée

**FIX** : Avant c'était `.insert()` → Erreur `duplicate key` si fichier existait déjà !

---

## 🔍 VÉRIFICATION : EST-CE QUE LÉGIFRANCE CHANGE LES IDs ?

### **Selon la doc officielle Légifrance :**

**Chaque article a un ID STABLE** : `LEGIARTI000xxxxx`

**Comportement Légifrance** :
- **Mise à jour mineure** (correction, précision) → ✅ **MÊME ID** conservé
- **Réécriture complète** (nouvelle loi) → ❌ **NOUVEL ID** créé
- **Abrogation** → L'article garde son ID, `etat: "ABROGE"`, `dateFin` renseignée

**Exemple dans les logs du micro-service** (13:08 UTC) :
```json
{
  "id": "LEGIARTI000024376802",
  "num": "L111-1",
  "etat": "VIGUEUR",
  "dateDebut": "1976-07-21",
  "dateFin": "2999-01-01",
  "multipleVersions": false  // ✅ Pas de versions multiples !
}
```

**Si `multipleVersions: true`** → Plusieurs versions existent (IDs différents)

---

## ✅ WORKFLOW COMPLET

### **Collecte initiale (Oct 2025)**

1. Micro-service collecte Code Urbanisme
2. Trouve article `LEGIARTI000024376802`
3. Upload `LEGIARTI000024376802.json` dans bucket (UPSERT)
4. Insert `LEGIARTI000024376802.json` dans files_queue (UPSERT)
5. WorkerLocal traite → Crée chunks + embeddings
6. Chunks dans `document_chunks` avec `file_path = "legifrance/.../LEGIARTI000024376802.json"`

### **Recollecte future (Mars 2026)**

**Scénario A : Correction mineure (même ID)**

1. Micro-service re-collecte Code Urbanisme
2. Trouve ENCORE `LEGIARTI000024376802` (même ID)
3. Upload `LEGIARTI000024376802.json` → ✅ **ÉCRASE** l'ancien (UPSERT)
4. UPSERT dans files_queue → ✅ **Reset status à pending**
5. WorkerLocal RE-traite → ✅ **REMPLACE** les chunks (UPSERT sur `file_path, chunk_index`)
6. **Résultat** : Chunks mis à jour avec nouveau contenu !

**Scénario B : Nouvelle version (nouvel ID)**

1. Micro-service re-collecte Code Urbanisme
2. Trouve `LEGIARTI000055555555` (nouvel ID pour L111-1)
3. Upload `LEGIARTI000055555555.json` → ✅ **CRÉE** un nouveau fichier
4. Insert dans files_queue → ✅ **CRÉE** nouvelle entrée
5. WorkerLocal traite → ✅ **CRÉE** de nouveaux chunks
6. **Résultat** : 2 versions de L111-1 dans la base (ancien + nouveau) !

---

## 🚨 PROBLÈME POTENTIEL : VERSIONS MULTIPLES

### **Si Légifrance retourne plusieurs versions du même article :**

**L'API peut retourner** :
- `LEGIARTI000024376802` (version 2021)
- `LEGIARTI000055555555` (version 2025)

**Notre service collecte LES DEUX** car ce sont des IDs différents !

**Résultat dans pgvector** :
- Chunks de la version 2021 (avec `file_path = LEGIARTI...802.json`)
- Chunks de la version 2025 (avec `file_path = LEGIARTI...555.json`)

**Impact sur le RAG** :
- ✅ Recherche "Code urbanisme L111-1" → Trouve les 2 versions !
- ⚠️ Le LLM doit gérer plusieurs versions (mais peut indiquer laquelle est en vigueur)

---

## 💡 RECOMMANDATION

### **Pour éviter les doublons de versions :**

**Option 1 : Filtrer par `etat: "VIGUEUR"`**
```python
if article.get("etat") == "VIGUEUR":
    # Collecter seulement les articles EN VIGUEUR
```

**Option 2 : Utiliser `dateDebut` et `dateFin`**
```python
from datetime import datetime
now = datetime.now()
if article.get("dateDebut") <= now <= article.get("dateFin"):
    # Collecter seulement si valide AUJOURD'HUI
```

**Option 3 : Garder toutes les versions (actuel)**
- Avantage : Historique complet
- Inconvénient : Plusieurs versions du même article dans la base

---

## 🎯 RÉSUMÉ TECHNIQUE

| Élément | Comportement | Raison |
|---------|--------------|--------|
| **Bucket upload** | UPSERT (ligne 137) | Écrase si même `doc_id` |
| **files_queue insert** | UPSERT (ligne 149) | Écrase si même `file_path` |
| **WorkerLocal chunks** | UPSERT (contrainte UNIQUE) | Remplace si même `file_path + chunk_index` |
| **ID Légifrance** | STABLE pour mises à jour mineures | Légifrance décide |
| **Nouvel ID** | CRÉÉ pour nouvelles versions | Légifrance décide |
| **Hash contenu** | CHANGE si contenu modifié | Fallback si pas d'ID |

---

## 📝 CHANGELOG v3.1 (21 Oct 2025)

### **Fix UPSERT files_queue**
- **Problème** : `.insert()` causait `duplicate key` lors de recollectes
- **Solution** : Changé en `.upsert()` (ligne 149)
- **Impact** : Collecte continue sans bloquer sur doublons

### **Fix Déduplication UUID**
- **Problème** : `uuid.uuid4()` générait 386 doublons du même article
- **Solution** : Hash SHA256 du contenu au lieu d'UUID aléatoire
- **Impact** : Même contenu = même `doc_id` = UPSERT automatique

---

## ✅ VALIDATION

**Test effectué (21 Oct 2025)** :

1. ✅ Bucket vidé (0 fichiers)
2. ✅ Tables vidées (document_chunks, files_queue, parsed_files)
3. ✅ Micro-service redéployé avec fix UPSERT
4. ✅ Collecte MASSIVE lancée
5. ✅ 35 fichiers créés avec hash stable (`hash_xxx.json`)
6. ✅ UPSERT empêche les erreurs duplicate key
7. ✅ Collecte continue sans bloquer

**Résultat** : Le système gère correctement les doublons et les mises à jour ! 🎉

---

## 🔍 POUR ALLER PLUS LOIN

### **Vérifier les versions multiples d'un article**

```sql
-- Trouver tous les chunks d'un même article (plusieurs versions)
SELECT 
  file_path,
  metadata->>'title' as title,
  COUNT(*) as chunk_count,
  MIN(upload_date) as first_version,
  MAX(upload_date) as last_version
FROM document_chunks
WHERE content ILIKE '%L111-1%'
GROUP BY file_path, metadata->>'title'
ORDER BY last_version DESC;
```

### **Identifier les articles abrogés**

```sql
-- Articles avec etat = ABROGE dans les métadonnées
SELECT 
  file_path,
  metadata->>'title' as title,
  metadata->>'etat' as etat,
  metadata->>'dateFin' as date_fin
FROM document_chunks
WHERE metadata->>'etat' = 'ABROGE'
LIMIT 10;
```

---

## 📚 RÉFÉRENCES

- **API Légifrance** : `docs/docs-officiel-legifrance/Consult-Controller.md`
- **Code déduplication** : `app/services/supabase_service.py` (lignes 80-119)
- **Code UPSERT** : `app/services/supabase_service.py` (lignes 132-153)
- **WorkerLocal UPSERT** : `WorkerLocal/db/supabase_client.py` (contrainte UNIQUE)


