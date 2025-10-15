# 📑 INDEX - MICRO-SERVICE LÉGIFRANCE

**Date** : 15 octobre 2025  
**Version** : 3.0 UNIFICATION + FIX LEGIARTI  
**Status** : ✅ EN PRODUCTION

---

## 🎯 DÉMARRAGE RAPIDE

**Nouveau ?** Commence par :
1. **[README.md](./README.md)** - Vue d'ensemble micro-service
2. **[01-ARCHITECTURE.md](./01-ARCHITECTURE.md)** - Architecture technique
3. **[02-MODES.md](./02-MODES.md)** - MASSIVE vs MAINTENANCE

---

## 📚 DOCUMENTATION COMPLÈTE

### **🏗️ ARCHITECTURE** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) | **Architecture technique** complète (services, workflow, déploiement) | 369 lignes | ⭐⭐⭐ |

**Contenu** :
- 5 services principaux (LegiffranceService, SupabaseService, CollectorScheduler, etc.)
- Flux de données complet
- Structure fichiers
- Variables d'environnement
- Docker multi-stage
- Workflow startup

---

### **⚙️ CONFIGURATION** (2 fichiers)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [02-MODES.md](./02-MODES.md) | **Modes MASSIVE vs MAINTENANCE** (différences, stratégies, quotas) | 169 lignes | ⭐⭐⭐ |
| [04-PERSISTANCE-ETAT.md](./04-PERSISTANCE-ETAT.md) | **Persistance état** scheduler (/tmp/scheduler_state.json) | 247 lignes | ⭐⭐ |

**Quick Links** :
- Comprendre les modes → [02-MODES.md](./02-MODES.md)
- État scheduler → [04-PERSISTANCE-ETAT.md](./04-PERSISTANCE-ETAT.md)

---

### **⏱️ RATE LIMITING** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [03-RATE-LIMITING.md](./03-RATE-LIMITING.md) | **Quotas PISTE** (CNIL 40/s vs Standard 20/s, 1.28M/jour) | 248 lignes | ⭐⭐⭐ |

**Contenu** :
- Quotas officiels Légifrance PISTE
- Implémentation DifferentiatedRateLimiter
- Stratégie par mode (MASSIVE vs MAINTENANCE)
- Alertes & monitoring
- Gestion erreurs 429

---

### **🔄 SYNCHRONISATION** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [05-AUTO-SYNC.md](./05-AUTO-SYNC.md) | **Auto-sync** Storage ↔ files_queue (cohérence automatique) | 162 lignes | ⭐⭐ |

**Contenu** :
- Vérification cohérence au démarrage
- Auto-sync intelligent (<100k fichiers)
- Sync manuel (>100k fichiers)
- Workflow complet

---

### **🔧 FIXES CRITIQUES** (1 fichier)

| Fichier | Description | Taille | Importance |
|---------|-------------|--------|-----------|
| [06-FIX-LEGIARTI-v3.0.md](./06-FIX-LEGIARTI-v3.0.md) | **Fix qualité collecte** (LEGIARTI + 100 chars minimum) | 194 lignes | ⭐⭐⭐ |

**Contenu** :
- Problème : 90% documents vides (LEGISCTA vs LEGIARTI)
- Solution : Filtre LEGIARTI + qualité 100 chars
- Résultat : 100% qualité collecte
- Impact : 1.47M → 259 fichiers (qualité garantie)

---

## 🎯 GUIDES PAR NIVEAU

### **🚀 DÉBUTANT : Comprendre le micro-service**
1. [README.md](./README.md) - Vue d'ensemble
2. [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) - Architecture technique
3. [02-MODES.md](./02-MODES.md) - Modes MASSIVE/MAINTENANCE

### **🔧 DÉVELOPPEUR : Configurer et déployer**
1. [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) - Structure code
2. [03-RATE-LIMITING.md](./03-RATE-LIMITING.md) - Quotas API
3. [04-PERSISTANCE-ETAT.md](./04-PERSISTANCE-ETAT.md) - État scheduler
4. [05-AUTO-SYNC.md](./05-AUTO-SYNC.md) - Sync automatique

### **⚙️ DEVOPS : Maintenir en production**
1. [02-MODES.md](./02-MODES.md) - Changer mode (MASSIVE ↔ MAINTENANCE)
2. [03-RATE-LIMITING.md](./03-RATE-LIMITING.md) - Surveiller quotas
3. [05-AUTO-SYNC.md](./05-AUTO-SYNC.md) - Vérifier cohérence
4. [06-FIX-LEGIARTI-v3.0.md](./06-FIX-LEGIARTI-v3.0.md) - Fix appliqué

### **🔬 EXPERT : Optimiser et débugger**
1. [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) - Workflow complet
2. [03-RATE-LIMITING.md](./03-RATE-LIMITING.md) - Rate limiting avancé
3. [04-PERSISTANCE-ETAT.md](./04-PERSISTANCE-ETAT.md) - Gestion état
4. [06-FIX-LEGIARTI-v3.0.md](./06-FIX-LEGIARTI-v3.0.md) - Qualité données

---

## 🔍 RECHERCHE PAR SUJET

### **Architecture & Services**
- Architecture complète → [01-ARCHITECTURE.md](./01-ARCHITECTURE.md)
- Services Python → [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) (section Services)

### **Configuration**
- Modes collecte → [02-MODES.md](./02-MODES.md)
- Persistance état → [04-PERSISTANCE-ETAT.md](./04-PERSISTANCE-ETAT.md)
- Variables env → [01-ARCHITECTURE.md](./01-ARCHITECTURE.md) (section Config)

### **API PISTE**
- Rate limiting → [03-RATE-LIMITING.md](./03-RATE-LIMITING.md)
- Quotas → [03-RATE-LIMITING.md](./03-RATE-LIMITING.md) (section Quotas)

### **Qualité Données**
- Fix LEGIARTI → [06-FIX-LEGIARTI-v3.0.md](./06-FIX-LEGIARTI-v3.0.md)
- Auto-sync → [05-AUTO-SYNC.md](./05-AUTO-SYNC.md)

---

## 📊 STATISTIQUES DOCUMENTATION

### **Fichiers**
- **Total fichiers** : 8 (6 numérotés + README + INDEX)
- **Total lignes** : ~1,500 lignes

### **Par Catégorie**
- Architecture : 1 fichier
- Configuration : 2 fichiers
- Rate Limiting : 1 fichier
- Synchronisation : 1 fichier
- Fixes : 1 fichier

---

## ✅ ÉTAT ACTUEL PRODUCTION

### **Statistiques Réelles** (15 Oct 2025)

| Métrique | Valeur | Status |
|----------|--------|--------|
| **Mode actif** | MAINTENANCE | ✅ |
| **Scheduler** | Running | ✅ |
| **Fichiers collectés** | 259 | ✅ (post-fix qualité) |
| **Codes ciblés** | 5 codes prioritaires | ✅ |
| **Fréquence** | CRON 2h (12×/jour) | ✅ |
| **Rate limiting** | 20 req/s (Standard) | ✅ |
| **Quota utilisé** | ~0.7% (1-2k/280k jour) | ✅ |
| **Qualité collecte** | 100% (LEGIARTI + 100 chars) | ✅ |

### **Filtres Qualité Actifs**
1. ✅ **LEGIARTI** : Garde seulement vrais articles (ignore LEGISCTA)
2. ✅ **Texte > 100 chars** : Filtre documents vides
3. ✅ **HTML cleaning** : Nettoyage texte pour vérification

### **Auto-Sync**
- ✅ Vérification cohérence au démarrage
- ✅ Auto-sync si 5-100k manquants
- ✅ Sync manuel si >100k manquants

---

## 🔗 LIENS UTILES

### **Déploiement**
- **URL Production** : https://micro-service-data-legifrance-piste.onrender.com
- **Host** : Render.com (Free tier)
- **Health Check** : `/health`

### **Endpoints API**
- `POST /aspirage/start` - Démarre collecte
- `POST /aspirage/stop` - Arrête collecte
- `POST /siphonnage/mode` - Change mode
- `GET /aspirage/status` - État scheduler
- `GET /stats` - Stats complètes

### **Documentation Externe**
- API PISTE Légifrance : Voir dossier `docs/docs-officiel-legifrance/`
- Quotas officiels : [03-RATE-LIMITING.md](./03-RATE-LIMITING.md)

---

## 🎉 RÉSUMÉ

**Micro-service Légifrance v3.0** :
- ✅ 8 fichiers organisés (01-06 + README + INDEX)
- ✅ Architecture complète documentée
- ✅ Modes MASSIVE/MAINTENANCE unifiés
- ✅ Rate limiting différencié
- ✅ Auto-sync intelligent
- ✅ Qualité collecte 100%
- ✅ En production stable

**Service optimisé et documenté !** 🚀

