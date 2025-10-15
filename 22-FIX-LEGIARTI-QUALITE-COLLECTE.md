# 🔥 FIX LEGIARTI - Qualité Collecte Légifrance

**Date** : 15 octobre 2025  
**Commit** : `6434c93` (Micro-service)  
**Impact** : +50% qualité documents, -90% documents vides, -645 lignes code mort  
**Status** : ✅ **EN PRODUCTION**

---

## 🚨 PROBLÈME DÉCOUVERT

### Symptômes
- **10,000 documents** collectés mais **90% < 300 chars** après nettoyage HTML
- Contenu : Titres vides ("Partie législative", "Annexes", "Livre Ier")
- WorkerLocal générait des embeddings sur du contenu vide
- Base RAG polluée avec résultats non pertinents

### Cause Racine
L'API `/consult/legi/tableMatieres` retourne 2 types d'éléments :

```json
{
  "sections": [
    {
      "cid": "LEGISCTA000006107992",  // ❌ Section structurelle SANS texte
      "num": null,
      "title": "Partie législative",
      "articles": [...]
    },
    {
      "cid": "LEGIARTI000006815075",  // ✅ Article réel AVEC texteHtml
      "num": "L110-1",
      "title": "Article L110-1"
    }
  ]
}
```

**Problème** : Le micro-service extrayait **TOUS les `cid`** sans distinction !

---

## ✅ SOLUTION IMPLÉMENTÉE

### 1. Filtre LEGIARTI dans `extract_article_ids_recursive()`

**Fichier** : `Micro-service-data-legifrance-piste/app/services/legifrance_service.py`

```python
def extract_article_ids_recursive(self, articles: List[Dict], _first_call=True) -> List[str]:
    """
    Extrait récursivement SEULEMENT les vrais articles (LEGIARTI)
    Ignore les sections structurelles vides (LEGISCTA)
    """
    article_ids = []
    
    for article in articles:
        article_id = article.get("cid") or article.get("id")
        
        # ✅ FILTRE LEGIARTI : Garder SEULEMENT vrais articles
        if article_id and article_id.startswith("LEGIARTI"):
            article_ids.append(article_id)
            logger.debug("✅ Article extrait", id=article_id, num=article.get("num"))
        
        elif article_id and article_id.startswith("LEGISCTA"):
            # Section vide ignorée
            logger.debug("⏭️ Section ignorée (pas de texte)", 
                        id=article_id, 
                        title=article.get("title"))
        
        # Récursion sur les enfants
        if "articles" in article and isinstance(article["articles"], list):
            child_ids = self.extract_article_ids_recursive(article["articles"], _first_call=False)
            article_ids.extend(child_ids)
    
    return article_ids
```

### 2. Filtre Qualité dans `_run_collection_job()`

**Fichier** : `Micro-service-data-legifrance-piste/app/scheduler/collector_scheduler.py`

```python
# Nettoyer HTML pour mesurer le texte réel
texte_clean = re.sub(r'<[^>]+>', ' ', texte_html)
texte_clean = texte_clean.replace('&nbsp;', ' ').replace('&amp;', '&')
texte_clean = re.sub(r'\s+', ' ', texte_clean).strip()

# ✅ FILTRE QUALITÉ : Texte > 200 chars après nettoyage
if texte_clean and len(texte_clean) >= 200:
    await self.supabase_service.save_legal_document(full_article, "architecture_urbanisme")
    documents_saved += 1
    logger.debug("✅ Article sauvegardé", clean_length=len(texte_clean))
else:
    logger.info("⏭️ Article ignoré (texte < 200 chars)", 
               clean_length=len(texte_clean),
               html_length=len(texte_html))
```

### 3. Fix Parsing dans Workers

**WorkerLocal & WorkerLocal Chunk** : Gestion du wrapper `article` de `/consult/getArticle`

```python
if 'legifrance_data' in data:
    legifrance = data['legifrance_data']
    
    # ✅ FIX : Gérer wrapper "article" de /consult/getArticle
    # API retourne : {"article": {"texteHtml": "...", "num": "..."}}
    if 'article' in legifrance and isinstance(legifrance['article'], dict):
        article_data = legifrance['article']
        
        # Extraire numéro article
        if 'num' in article_data and article_data['num']:
            text_parts.append(f"Article {article_data['num']}")
        
        # Extraire et nettoyer texteHtml
        if 'texteHtml' in article_data:
            clean_text = self._clean_html(article_data['texteHtml'])
            if clean_text:
                text_parts.append(clean_text)
```

---

## 🔄 UNIFICATION MAINTENANCE = MASSIVE

### Avant Fix ❌
- **MAINTENANCE** : `/legi/tableMatieres` + LEGIARTI + qualité 200 chars
- **MASSIVE** : Recherche mots-clés (85+) **SANS filtre LEGIARTI** → métadonnées vides

**Incohérence** : MASSIVE créait la DB avec docs vides, MAINTENANCE la maintenait avec docs qualité !

### Après Fix ✅
**MÊME STRATÉGIE** pour les 2 modes :
1. `/consult/legi/tableMatieres` (hiérarchie complète codes)
2. `extract_article_ids_recursive()` avec **filtre LEGIARTI**
3. `/consult/getArticle` pour chaque ID
4. **Filtre qualité** : texte > 200 chars après nettoyage HTML

**Différence** :
- **MAINTENANCE** : 5 codes prioritaires urbanisme, CRON 2h
- **MASSIVE** : 20 codes complets, Interval 10 min (collecte continue)

---

## 🧹 NETTOYAGE CODE

### Suppressions (Total : -645 lignes)

**`legifrance_service.py`** : 1031 → 526 lignes (-505 lignes)
- ✅ `massive_architecture_siphon()` + 6 fonctions privées (325 lignes)
- ✅ `list_administrative_docs()` (27 lignes)
- ✅ `search_urbanisme_documents()` (56 lignes)
- ✅ `list_all_codes()` (20 lignes)
- ✅ `search_architecture_transversal()` (62 lignes)
- ✅ `get_table_matieres()` **DOUBLON** (19 lignes)

**`collector_scheduler.py`** : 582 → 442 lignes (-140 lignes)
- ✅ `_continuous_massive_siphon()` (71 lignes)
- ✅ `_quota_monitoring_job()` (34 lignes)
- ✅ `pause_massive_siphon()`, `resume_massive_siphon()` (24 lignes)
- ✅ `is_massive_siphon_running()` (5 lignes)
- ✅ Simplification `start()` et `stop()` (6 lignes)

### Commits
```bash
46e15bf - REFACTOR SCHEDULER: Unifier MAINTENANCE et MASSIVE
d378f7c - CLEAN SCHEDULER: Supprimer 5 fonctions obsolètes
e9184d3 - CLEAN LEGIFRANCE_SERVICE: Supprimer massive_architecture_siphon + 6 fonctions
3a13223 - CLEAN: Supprimer import os + doublon get_table_matieres + 4 fonctions test
6434c93 - FIX CRITIQUE extract_article_ids_recursive: Filtrer LEGISCTA
```

---

## 📊 RÉSULTATS

### Avant Fix ❌
- **10,000 documents** collectés
- **90% < 300 chars** (titres vides, sections structurelles)
- **10% > 3K chars** (contenu réel)
- WorkerLocal traitait 90% de documents inutiles

### Après Fix ✅
- **28 documents** collectés (filtre qualité strict)
- **0% < 200 chars** (filtre micro-service)
- **60% > 3K chars** (17/28 docs)
- **13 docs = 10K chars** (limite troncature)

**Distribution qualité** :
```
= 10K chars (PARFAIT)    : 13 docs ████████████
5-10K chars (BON)        :  3 docs ███
3-5K chars               :  1 doc  █
1-3K chars               :  3 docs ███
< 1000 chars             :  8 docs ████████
```

### Exemples Documents Collectés
1. **PRINCIPES DE L'OCDE DE BONNES PRATIQUES** (10K chars)
2. **NOMENCLATURE DES INSTALLATIONS CLASSÉES** (10K chars)
3. **LISTE DE DÉCHETS** (10K chars)
4. **CATÉGORIES D'AMÉNAGEMENTS enquête publique** (10K chars)
5. **RÉPARTITION DÉPARTEMENTS zones sismicité** (10K chars)

---

## 🔄 WORKERS ALIGNÉS

### Fix Article Wrapper

**Problème** : `/consult/getArticle` retourne `{"article": {"texteHtml": "..."}}`  
Workers cherchaient `legifrance_data.texteHtml` au lieu de `legifrance_data.article.texteHtml`

**Solution** :
- ✅ WorkerLocal : Commit `ff008a8` - Fix article wrapper + fonction `_clean_html()`
- ✅ WorkerLocal Chunk : Commit `fd25b43` - Fix article wrapper + nettoyage HTML inline

**Impact** : Extraction correcte du contenu complet des articles

---

## 📈 MÉTRIQUES FINALES

### Base de données
- **Bucket** : 28 fichiers (1.8 MB)
- **Documents** : 28 documents (161 KB texte)
- **Qualité** : **17/28 docs > 3K chars (60%)**
- **Parsed** : 28 fichiers traités ✅

### Micro-service
- **Status** : ✅ LIVE (deploy `3a13223`)
- **Mode** : MAINTENANCE (5 codes, CRON 2h)
- **Collecte** : 1 run réussi, 28 docs, 0 erreurs
- **Quotas** : 62/280,000 (0.02%) ✅
- **Code** : 968 lignes (vs 1613 avant)

### Workers
- **WorkerLocal** : ✅ Aligné (commit `ff008a8`)
- **WorkerLocal Chunk** : ✅ Aligné (commit `fd25b43`)

---

## 🎯 ENDPOINTS UNIFIÉS

### Modes Disponibles
```http
POST /siphonnage/mode
Body: {"mode": "MAINTENANCE"}  # 5 codes, CRON 2h
Body: {"mode": "MASSIVE"}      # 20 codes, Interval 10min

POST /aspirage/start   # Démarre collecte (mode actuel)
POST /aspirage/stop    # Arrête collecte
GET  /aspirage/status  # État scheduler
GET  /stats            # Statistiques complètes
```

### Endpoints Supprimés
- ❌ `/aspirage/urbanisme` - Redondant (intégré dans MAINTENANCE/MASSIVE)

---

## 🚀 PROCHAINES ÉTAPES

1. **Tester la recherche RAG** avec les nouveaux documents de qualité
2. **Lancer WorkerLocal Chunk** pour générer chunks granulaires
3. **Activer mode MASSIVE** pour collecter les 20 codes (10-50K articles)
4. **Monitoring continu** de la qualité des documents collectés

---

## 📚 RÉFÉRENCES

- **Micro-service README** : `Micro-service-data-legifrance-piste/README.md`
- **Doc API PISTE** : `Micro-service-data-legifrance-piste/docs/docs-officiel-legifrance/`
- **WorkerLocal README** : `WorkerLocal/README.md`
- **WorkerLocal Chunk README** : `WorkerLocal Chunk/README.md`

---

**FIN DU DOCUMENT**

