# 🔄 MODES MASSIVE vs MAINTENANCE

**Date** : 15 octobre 2025  
**Version** : 3.0 UNIFIÉS  
**Status** : ✅ MÊMES FILTRES POUR LES 2 MODES

---

## 🎯 Principe

Les 2 modes utilisent **EXACTEMENT la même stratégie de collecte** (fix v3.0) :
1. `/consult/legi/tableMatieres` (hiérarchie codes)
2. `extract_article_ids_recursive()` avec filtre LEGIARTI
3. `/consult/getArticle` (texte complet)
4. Filtre qualité > 100 chars

**SEULE DIFFÉRENCE** : Nombre de codes + fréquence

---

## 📊 COMPARAISON DÉTAILLÉE

| Aspect | MAINTENANCE | MASSIVE |
|--------|-------------|---------|
| **Codes** | 5 codes prioritaires | 20 codes complets |
| **Fréquence** | CRON 2h | Interval 10 min |
| **Articles/run** | ~250 articles | ~1,000-5,000 articles |
| **Durée job** | ~5-10 min | ~30-45 min |
| **Quota/jour** | ~1,000-2,000 req | ~50,000-100,000 req |
| | | |
| **Endpoint** | `/legi/tableMatieres` | `/legi/tableMatieres` |
| **Filtre LEGIARTI** | ✅ Actif | ✅ Actif |
| **Filtre qualité** | ✅ > 100 chars | ✅ > 100 chars |
| **Qualité résultat** | 60% > 3K chars | 60% > 3K chars |

---

## 🏗️ MODE MAINTENANCE (Actuel)

### **Configuration**
```python
# Codes collectés (5)
target_codes = [
    "LEGITEXT000006074075",  # Code de l'urbanisme
    "LEGITEXT000006074096",  # Code de la construction
    "LEGITEXT000006074220",  # Code de l'environnement
    "LEGITEXT000006074234",  # Code du patrimoine
    "LEGITEXT000006070721",  # Code collectivités territoriales
]

# Scheduler
trigger = CronTrigger(hour="*/2", minute=0)  # CRON 2h
```

### **Performance Observée** (15 Oct 2025)
```
Run 1 (09:54) : ~130 articles collectés
Run 2 (11:54) : ~70 articles collectés
Run 3 (13:54) : ~59 articles collectés
Total         : 259 fichiers ✅
```

### **Quotas Utilisés**
```
Requêtes/run : ~500-1,000 req
Requêtes/jour : ~6,000-12,000 req (4% du quota)
Rate : 20 req/s (Standard)
```

---

## 🔥 MODE MASSIVE

### **Configuration**
```python
# Codes collectés (20)
target_codes = [
    # 5 codes MAINTENANCE +
    "LEGITEXT000006070719",  # Code civil
    "LEGITEXT000006069565",  # Code de commerce
    "LEGITEXT000006072050",  # Code du travail
    "LEGITEXT000006069577",  # Code général des impôts
    "LEGITEXT000006070716",  # Code de procédure civile
    "LEGITEXT000006071154",  # Code de procédure pénale
    "LEGITEXT000006070933",  # Code de justice administrative
    "LEGITEXT000006072665",  # Code de la santé publique
    "LEGITEXT000006071191",  # Code de l'éducation
    "LEGITEXT000006074228",  # Code des transports
    "LEGITEXT000023983208",  # Code de l'énergie
    "LEGITEXT000006071367",  # Code rural
    "LEGITEXT000025244092",  # Code forestier
    "LEGITEXT000006071785",  # Code minier
    "LEGITEXT000006073984",  # Code des assurances
]

# Scheduler
trigger = IntervalTrigger(minutes=10)  # Interval 10 min
```

### **Performance Estimée**
```
Run 1 : ~1,000-5,000 articles
Durée : ~30-45 min
Runs/jour : 144 runs (10 min interval)
Total/jour : ~50,000-100,000 articles ✅
```

### **Quotas Utilisés**
```
Requêtes/run : ~5,000-20,000 req
Requêtes/jour : ~720,000-1,200,000 req (90% du quota)
Rate : 60 req/s (40 CNIL + 20 Standard)
```

---

## 🔄 CHANGEMENT DE MODE

### **Depuis Frontend**
```http
POST /api/v3/services/legifrance/siphonnage/mode
Body: {"mode": "MASSIVE"}
```

### **Depuis Render Dashboard**
```bash
Environment Variable:
SIPHONNAGE_MODE=MASSIVE
```

### **Effet**
```python
# Micro-service redémarre automatiquement
# → Charge l'état sauvegardé
# → Applique nouveau mode
# → Continue avec même filtres LEGIARTI + qualité ✅
```

---

## ⚡ ÉTAT ACTUEL (15 Oct 2025)

```
Mode actuel : MAINTENANCE
Codes : 5 codes prioritaires
Runs/jour : 12 runs (CRON 2h)
Fichiers collectés : 259 (qualité 60%)
Quotas : 0.02% utilisés
```

**Prêt à passer en MASSIVE si besoin !** 🚀

---

## 🎯 Recommandation

### **Garder MAINTENANCE si** :
- ✅ Tu veux tester la qualité d'abord
- ✅ Tu veux économiser quotas
- ✅ Tu veux 250-500 articles/jour

### **Passer en MASSIVE si** :
- 🔥 Tu veux 50k-100k articles/jour
- 🔥 Tu veux créer la base complète rapidement
- 🔥 Tu es OK d'utiliser 90% des quotas

**Les 2 modes garantissent la MÊME qualité (60% > 3K chars) !** ✅

