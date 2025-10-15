# 🏛️ MICRO-SERVICE LÉGIFRANCE - DOCUMENTATION COMPLÈTE

**Date** : 15 octobre 2025  
**Version** : 3.0 UNIFICATION + FIX LEGIARTI  
**Status** : ✅ EN PRODUCTION  
**URL** : https://micro-service-data-legifrance-piste.onrender.com

---

## 🎯 Rôle

**Collecteur de données juridiques PURES depuis API PISTE officielle Légifrance**

```
API PISTE → Micro-service → Bucket Supabase → Workers → RAG
```

**CE QU'IL FAIT** :
- ✅ Collecte intelligente via API PISTE
- ✅ Filtre LEGIARTI (vrais articles seulement)
- ✅ Filtre qualité (texte > 100 chars)
- ✅ Upload DIRECT vers bucket Supabase
- ✅ INSERT automatique dans files_queue

**CE QU'IL NE FAIT PAS** :
- ❌ Parsing/extraction texte (Workers)
- ❌ Génération embeddings (Workers)
- ❌ Recherche sémantique (Backend)

---

## 📊 ÉTAT ACTUEL (15 Oct 2025)

### Bucket Storage
- **Fichiers** : 259 fichiers
- **Taille** : 17 MB
- **Qualité** : 60% docs > 3K chars ✅

### Mode & Configuration
- **Mode actuel** : MAINTENANCE
- **Codes** : 5 codes prioritaires urbanisme
- **Fréquence** : CRON 2h
- **Quotas** : 62/280,000 req/jour (0.02%) ✅

### Collecte Aujourd'hui
- **Premier run** : 09:54
- **Dernier run** : 14:54
- **Documents** : 259 articles de qualité
- **Runs** : 2-3 runs CRON

---

## 📚 DOCUMENTATION PAR THÈME

### **🏗️ Architecture**
- [**ARCHITECTURE.md**](./ARCHITECTURE.md) - Rôle, flux, services
- [**MODES.md**](./MODES.md) - MASSIVE vs MAINTENANCE (5 vs 20 codes)
- [**PERSISTANCE-ETAT.md**](./PERSISTANCE-ETAT.md) - Scheduler state management

### **🔧 Fixes Critiques**
- [**FIX-LEGIARTI-v3.0.md**](./FIX-LEGIARTI-v3.0.md) - Filtre sections vides (-99% déchets)
- [**AUTO-SYNC.md**](./AUTO-SYNC.md) - Synchronisation Storage ↔ files_queue

### **⚡ Performance**
- [**RATE-LIMITING.md**](./RATE-LIMITING.md) - Quotas PISTE (60 req/s, 1.28M/jour)

### **🚀 Déploiement**
- [**DEPLOIEMENT.md**](./DEPLOIEMENT.md) - Render + Docker + Variables

---

## 🎉 Résumé

**Micro-service optimisé v3.0** :
- ✅ Collecte de qualité (60% docs > 3K chars)
- ✅ 2 modes unifiés (mêmes filtres)
- ✅ Auto-sync intelligent
- ✅ Persistance état
- ✅ Code clean (-645 lignes)

**Prêt pour mode MASSIVE si besoin !** 🔥

