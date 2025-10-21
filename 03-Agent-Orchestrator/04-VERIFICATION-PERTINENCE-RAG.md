# 🔍 VÉRIFICATION DE LA PERTINENCE RAG

**Date** : 21 octobre 2025  
**Status** : ✅ GUIDE COMPLET  
**Objectif** : Vérifier si le LLM ment ou si les réponses sont bien enrichies avec la sémantique

---

## 🎯 LES 5 MÉTHODES DE VÉRIFICATION

### **1️⃣ ENDPOINT DEBUG - Vérification directe**

**URL** : `GET /api/v3/rag/debug-search?query=Code+urbanisme&limit=10`

**Retour** :
```json
{
  "success": true,
  "query": "Code urbanisme",
  "threshold_used": 0.9,
  "total_found": 8,
  "relevant_count": 8,
  "avg_distance": 0.7028,
  "avg_similarity": 0.2972,
  "quality_assessment": {
    "excellent": true,
    "good": false,
    "poor": false,
    "distance_range": "0.7010 - 0.7045"
  },
  "results": [
    {
      "rank": 1,
      "distance": 0.7028,
      "similarity_score": 0.2972,
      "is_relevant": true,
      "title": "Article L111-1 Code Urbanisme",
      "content_preview": "Le territoire français est le patrimoine commun...",
      "content_full": "...",
      "metadata": {...},
      "source": "legifrance"
    }
  ]
}
```

**✅ Comment vérifier** :
- `is_relevant: true` → Distance < 0.85 = pertinent
- `quality_assessment.excellent: true` → ≥5 résultats pertinents
- `avg_distance: 0.70-0.85` → Optimal pour Solon Q8_0
- Comparer `content_full` avec la réponse du LLM

---

### **2️⃣ LOGS BACKEND - Traçabilité complète**

**Logs Render** : `mcp_render_list_logs`

**Ce qu'on voit** :
```
✅ Recherche sémantique terminée : 8 résultats
✅ Threshold : 0.9
✅ Distance : 0.7028
✅ Score : 0.2972
📊 Résultat #1 : distance=0.7028, title="Article L111-1"
```

**✅ Comment vérifier** :
- `results_count > 0` → Semantic search a trouvé des résultats
- `distance ~ 0.70-0.85` → Résultats pertinents
- `threshold = 0.9` → Configuration correcte
- `total_count = 117148` → Base complète indexée

---

### **3️⃣ QUERY SQL DIRECTE - Vérité absolue**

**Requête Supabase** :
```sql
SELECT 
  id,
  metadata->>'title' as title,
  LEFT(content, 200) as preview,
  embedding <=> '[0.123, 0.456, ...]'::vector as distance,
  1 - (embedding <=> '[0.123, 0.456, ...]'::vector) as similarity
FROM document_chunks
WHERE embedding <=> '[0.123, 0.456, ...]'::vector < 0.9
ORDER BY embedding <=> '[0.123, 0.456, ...]'::vector
LIMIT 10;
```

**✅ Comment vérifier** :
1. Récupérer l'embedding de la query via `/api/v3/rag/debug-search`
2. Exécuter la query SQL directement dans Supabase
3. Comparer les résultats SQL avec les résultats du LLM
4. Si identiques → LLM ne ment pas

---

### **4️⃣ COMPARAISON RÉPONSE LLM VS CHUNKS**

**Méthode** :
1. Appeler `/api/v3/rag/debug-search?query=Code+urbanisme`
2. Noter les `content_full` des 8 résultats
3. Poser la même question au LLM
4. Vérifier que la réponse LLM contient des éléments des `content_full`

**✅ Exemple de vérification** :

| Chunk trouvé | Contenu LLM | Match ? |
|--------------|-------------|---------|
| "Le Code de l'Urbanisme regroupe les règles..." | "Le Code de l'Urbanisme (CU) regroupe l'ensemble des règles..." | ✅ OUI |
| "Article L111-1: Principes généraux" | "L111-1: Principes généraux de l'aménagement" | ✅ OUI |
| "PLU définit les zones constructibles" | "Le PLU fixe les règles d'aménagement" | ✅ OUI |

**Si 70%+ des chunks sont repris → LLM est bien enrichi**

---

### **5️⃣ TEST DE COHÉRENCE TEMPORELLE**

**Méthode** :
1. Poser une question sur un document récent (ex: "PLU 94220")
2. Vérifier dans `/api/v3/rag/debug-search` la date `upload_date`
3. Si le LLM cite des infos récentes ET que `upload_date` est récent → OK
4. Si le LLM cite des infos récentes MAIS `upload_date` est ancien → LLM invente

**✅ Exemple** :
```json
{
  "query": "PLU Charenton 94220",
  "results": [
    {
      "title": "PLU Charenton-le-Pont 2023-2029",
      "upload_date": "2023-01-15",
      "content": "Le PLU 2023-2029 de Charenton..."
    }
  ]
}
```

**Si le LLM dit "PLU 2023-2029" ET que le chunk existe → ✅ Enrichi**  
**Si le LLM dit "PLU 2023-2029" MAIS aucun chunk → ❌ LLM invente**

---

## 📊 MÉTRIQUES DE QUALITÉ RAG

### **Seuils de distance (Solon Q8_0)**

| Distance | Similarité | Pertinence | Action |
|----------|------------|------------|--------|
| **0.00-0.50** | 0.50-1.00 | 🟢 Excellent | Utiliser |
| **0.50-0.70** | 0.30-0.50 | 🟢 Très bon | Utiliser |
| **0.70-0.85** | 0.15-0.30 | 🟡 Bon | Utiliser |
| **0.85-0.90** | 0.10-0.15 | 🟠 Moyen | Vérifier manuellement |
| **0.90-1.00** | 0.00-0.10 | 🔴 Faible | Rejeter |

**Avec seuil 0.9** :
- ✅ On garde uniquement distance < 0.9 (similarité > 0.1)
- ✅ En pratique, on trouve surtout 0.70-0.85 (bon à très bon)
- ✅ Très peu de résultats 0.85-0.90 (moyen)

### **Nombre de résultats**

| Résultats trouvés | Qualité | Évaluation |
|-------------------|---------|------------|
| **≥8** | 🟢 Excellent | Beaucoup de contexte |
| **5-7** | 🟢 Très bon | Suffisant |
| **2-4** | 🟡 Bon | Minimum acceptable |
| **1** | 🟠 Moyen | Risque de biais |
| **0** | 🔴 Mauvais | Pas d'enrichissement |

---

## 🛠️ SCRIPT DE VÉRIFICATION AUTOMATIQUE

### **Python - Vérification automatique**

```python
import requests
import json

def verify_rag_enrichment(query: str, llm_response: str):
    """
    Vérifie si la réponse LLM est bien enrichie avec RAG
    
    Returns:
        dict: {
            "is_enriched": bool,
            "confidence": float (0-1),
            "matched_chunks": int,
            "details": {...}
        }
    """
    # 1. Récupérer les chunks trouvés par RAG
    debug_url = f"https://agent-orchestrateur-backend.onrender.com/api/v3/rag/debug-search"
    params = {"query": query, "limit": 10, "similarity_threshold": 0.9}
    
    response = requests.get(debug_url, params=params)
    data = response.json()
    
    # 2. Extraire les contenus des chunks
    chunks = [r["content_full"] for r in data["results"]]
    
    # 3. Vérifier combien de chunks sont présents dans la réponse LLM
    matched_chunks = 0
    total_chunks = len(chunks)
    
    for chunk in chunks:
        # Extraire les mots-clés du chunk (simplification)
        keywords = set(chunk.lower().split()[:50])  # 50 premiers mots
        llm_words = set(llm_response.lower().split())
        
        # Calculer intersection
        intersection = keywords & llm_words
        
        # Si >30% des mots du chunk sont dans la réponse LLM
        if len(intersection) / len(keywords) > 0.3:
            matched_chunks += 1
    
    # 4. Calculer confiance
    confidence = matched_chunks / total_chunks if total_chunks > 0 else 0
    
    # 5. Évaluation
    is_enriched = confidence >= 0.5  # Au moins 50% des chunks utilisés
    
    return {
        "is_enriched": is_enriched,
        "confidence": round(confidence, 2),
        "matched_chunks": matched_chunks,
        "total_chunks": total_chunks,
        "quality": data["quality_assessment"],
        "avg_distance": data["avg_distance"],
        "details": {
            "query": query,
            "threshold": 0.9,
            "results_found": data["total_found"],
            "relevant_count": data["relevant_count"],
        }
    }


# Exemple d'utilisation
query = "Code urbanisme"
llm_response = """
Le Code de l'Urbanisme (CU) regroupe l'ensemble des règles relatives à 
l'aménagement du territoire, à la planification et à l'instruction des 
projets de construction. Il se compose de parties législatives (articles L*) 
et réglementaires (articles R*).
"""

result = verify_rag_enrichment(query, llm_response)
print(json.dumps(result, indent=2))

"""
Output:
{
  "is_enriched": true,
  "confidence": 0.75,
  "matched_chunks": 6,
  "total_chunks": 8,
  "quality": {
    "excellent": true,
    "good": false,
    "poor": false,
    "distance_range": "0.7010 - 0.7045"
  },
  "avg_distance": 0.7028,
  "details": {
    "query": "Code urbanisme",
    "threshold": 0.9,
    "results_found": 8,
    "relevant_count": 8
  }
}
"""
```

---

## 🎯 CHECKLIST DE VÉRIFICATION RAPIDE

### **✅ Avant de faire confiance au LLM**

- [ ] **1. Vérifier `/api/v3/rag/debug-search`**
  - [ ] `total_found > 0`
  - [ ] `relevant_count >= 2`
  - [ ] `avg_distance < 0.85`
  - [ ] `quality_assessment.excellent` ou `good`

- [ ] **2. Vérifier les logs backend**
  - [ ] `✅ Recherche terminée : N résultats`
  - [ ] `distance ~ 0.70-0.85`
  - [ ] `threshold = 0.9`

- [ ] **3. Comparer réponse LLM vs chunks**
  - [ ] Au moins 50% des chunks mentionnés dans la réponse
  - [ ] Vocabulaire technique cohérent
  - [ ] Références juridiques précises (articles, codes)

- [ ] **4. Vérifier les métadonnées**
  - [ ] `source` cohérente (legifrance, PLU, etc.)
  - [ ] `upload_date` récente si info récente
  - [ ] `title` correspond au sujet

- [ ] **5. Test de cohérence**
  - [ ] Réponse différente si on désactive RAG
  - [ ] Réponse identique si on relance la même query
  - [ ] Pas de hallucinations (inventer des articles inexistants)

---

## 🚨 SIGNES QUE LE LLM MENT

### **🔴 Alerte rouge - LLM invente**

1. **Aucun résultat RAG** (`total_found = 0`) MAIS réponse détaillée
2. **Distance > 0.90** MAIS réponse ultra-précise
3. **Articles cités absents** des chunks trouvés
4. **Dates incohérentes** (dit "2023" mais `upload_date = 2015`)
5. **Changement de réponse** si on désactive RAG → Ment

### **🟡 Alerte jaune - Vérifier manuellement**

1. **1-2 résultats trouvés** seulement
2. **Distance 0.85-0.90** (limite)
3. **Réponse générique** (pas de références précises)
4. **Métadonnées vides** ou incohérentes

### **🟢 Tout va bien - LLM enrichi**

1. **≥5 résultats** trouvés
2. **Distance 0.70-0.85**
3. **Réponse avec références** (articles, URLs Légifrance)
4. **Cohérence chunks ↔ réponse**

---

## 📈 SUIVI QUALITÉ EN CONTINU

### **Métriques à suivre**

```sql
-- KPI qualité RAG (à calculer quotidiennement)

-- 1. Taux de réussite recherche sémantique
SELECT 
  COUNT(*) FILTER (WHERE results_count > 0) * 100.0 / COUNT(*) as success_rate
FROM search_logs
WHERE created_at > NOW() - INTERVAL '24 hours';

-- 2. Distance moyenne des résultats
SELECT 
  AVG(avg_distance) as global_avg_distance,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_distance) as median_distance
FROM search_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
  AND results_count > 0;

-- 3. Distribution qualité
SELECT 
  CASE 
    WHEN avg_distance < 0.70 THEN 'Excellent'
    WHEN avg_distance < 0.85 THEN 'Bon'
    WHEN avg_distance < 0.90 THEN 'Moyen'
    ELSE 'Faible'
  END as quality,
  COUNT(*) as count,
  COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage
FROM search_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY 1
ORDER BY 1;
```

### **Dashboard Grafana (recommandé)**

```yaml
metrics:
  - name: rag_search_success_rate
    query: "SELECT COUNT(*) FILTER (WHERE results_count > 0) * 100.0 / COUNT(*) FROM search_logs"
    
  - name: rag_avg_distance
    query: "SELECT AVG(avg_distance) FROM search_logs WHERE results_count > 0"
    
  - name: rag_relevant_count
    query: "SELECT AVG(relevant_count) FROM search_logs WHERE results_count > 0"

alerts:
  - condition: rag_search_success_rate < 80
    severity: warning
    message: "Taux de réussite RAG < 80%"
    
  - condition: rag_avg_distance > 0.85
    severity: warning
    message: "Distance moyenne > 0.85 (qualité dégradée)"
```

---

## 🎉 CONCLUSION

**Pour vérifier si le LLM ment** :

1. ✅ **Utiliser `/api/v3/rag/debug-search`** (méthode la plus simple)
2. ✅ **Comparer chunks vs réponse** (méthode la plus fiable)
3. ✅ **Vérifier les logs** (traçabilité complète)
4. ✅ **Calculer le taux de match** (script Python)
5. ✅ **Suivre les KPI** (métriques en continu)

**Avec seuil 0.9 et modèle Solon Q8_0** :
- Distance **0.70-0.85** = **Excellent** 🟢
- **≥5 résultats** trouvés = **RAG efficace** 🟢
- **50%+ chunks utilisés** = **LLM enrichi** 🟢

**Le LLM ne peut PAS mentir si tu vérifies ces 3 points ! 🔒**

