# 📊 Capacité Client & Plan de Scaling

**Date de création** : 13 octobre 2025  
**Dernière mise à jour** : 13 octobre 2025 12:50 UTC  
**Version** : 1.0  
**Status** : ✅ **DOCUMENTÉ** - Analyse complète infra 65 EUR/mois

---

## 🎯 Vue d'Ensemble

Ce document analyse la capacité client actuelle de l'infrastructure ArchiReg et propose un plan de scaling progressif.

---

## 💰 Infrastructure Actuelle (65 EUR/mois)

### Services Déployés

| Service | Plan | Coût | Ressources | Rôle |
|---------|------|------|------------|------|
| **Render Backend** | Standard | 20 EUR | 2 GB RAM, 1 CPU | Agent-Orchestrator + GGUF |
| **Supabase** | Pro | 20 EUR | 8 GB DB, 100 GB transfer | PostgreSQL + pgvector + Edge Functions |
| **Vercel Frontend** | Pro | 20 EUR | 1000 GB bandwidth | ArchiReg-Front |
| **Redis Cloud** | Basic | 5 EUR | 256 MB | Cache embeddings |
| **TOTAL** | - | **65 EUR** | - | - |

---

## 🔍 Analyse des Goulots d'Étranglement

### 1️⃣ Backend Render Standard (2 GB RAM, 1 CPU)

**Consommation RAM** :
- Modèle GGUF Solon embeddings : ~300 MB
- Subprocess llama-cpp : ~400 MB
- FastAPI + workers : ~500 MB
- Disponible pour requêtes : **~800 MB**

**Performance CPU (1 core)** :
- Génération embedding : 100% CPU pendant 2-3s
- Concurrence max : 3-5 requêtes parallèles (sans cache)
- Avec cache Redis : 15-20 requêtes parallèles
- **Limite** : **20-30 requêtes/minute**

**Capacité journalière** :
- 30 req/min × 60 min × 24h = **43,200 requêtes/jour**

**🔴 GOULOT PRINCIPAL POUR SCALING**

---

### 2️⃣ Supabase Pro (8 GB Database)

**⚠️ PROBLÈME CRITIQUE** :

```
Database actuelle : 9.5 GB
Limite Supabase Pro : 8 GB
Dépassement : +1.5 GB (119%)
```

**🚨 TU AS DÉJÀ DÉPASSÉ LA LIMITE !**

Risques :
- ❌ Nouvelles insertions refusées
- ❌ Crash possible si dépassement continue
- ❌ Performance dégradée

**Solution immédiate** : Upgrade vers **Supabase Team** (50 GB)

**Autres limites** :
- Edge Functions : 500,000 requêtes/mois = **16,666 req/jour**
- Transfer : 100 GB/mois (généreux)

**Recherche pgvector (avec index HNSW)** :
- Après index HNSW : ~100-200 req/sec
- Pas un goulot

---

### 3️⃣ Vercel Pro (1000 GB Bandwidth)

**Performance** :
- Bandwidth : 1000 GB/mois (très généreux)
- Serverless : 100 GB-Hrs/mois
- **Aucun goulot** : Peut gérer 10,000+ clients/jour

---

### 4️⃣ Redis Cloud (256 MB)

**Capacité cache** :
- Embedding : 768 floats × 4 bytes = ~3 KB/query
- Capacité totale : 256 MB / 3 KB = **~85,000 embeddings**
- Éviction : LRU (garde les plus récents)
- **Pas un goulot**

---

## 📊 Capacité Client par Scénario

### Scénario 1 : Usage Léger (10 messages/jour/client)

**Client type** : Particuliers, consultation occasionnelle

**Capacité par goulot** :

| Goulot | Limite | Calcul | Capacité |
|--------|--------|--------|----------|
| Backend Render | 43,200 req/jour | 43,200 / 10 | **4,320 clients/jour** |
| Supabase Edge | 16,666 req/jour | 16,666 / 10 | **1,666 clients/jour** ⚠️ |
| Vercel | Illimité | - | 10,000+ clients/jour |

**🎯 CAPACITÉ FINALE : ~1,500 clients actifs/jour**  
**🎯 CAPACITÉ MENSUELLE : ~45,000 clients actifs/mois**

**Coût par client** : 65 EUR / 45,000 = **0.0014 EUR/mois**

**Revenue potentiel** :
- Prix : 2-5 EUR/client/mois
- Total : 90,000-225,000 EUR/mois
- **ROI : 1,385x - 3,462x** 🚀

---

### Scénario 2 : Usage Moyen (50 messages/jour/client)

**Client type** : PME, architectes professionnels, usage régulier

**Capacité par goulot** :

| Goulot | Limite | Calcul | Capacité |
|--------|--------|--------|----------|
| Backend Render | 43,200 req/jour | 43,200 / 50 | **864 clients/jour** |
| Supabase Edge | 16,666 req/jour | 16,666 / 50 | **333 clients/jour** ⚠️ |
| Vercel | Illimité | - | 10,000+ clients/jour |

**🎯 CAPACITÉ FINALE : ~300 clients actifs/jour**  
**🎯 CAPACITÉ MENSUELLE : ~9,000 clients actifs/mois**

**Coût par client** : 65 EUR / 9,000 = **0.0072 EUR/mois**

**Revenue potentiel** :
- Prix : 5-10 EUR/client/mois
- Total : 45,000-90,000 EUR/mois
- **ROI : 692x - 1,385x** 🚀

---

### Scénario 3 : Usage Intensif (100 messages/jour/client)

**Client type** : Grands cabinets, usage professionnel intensif

**Capacité par goulot** :

| Goulot | Limite | Calcul | Capacité |
|--------|--------|--------|----------|
| Backend Render | 43,200 req/jour | 43,200 / 100 | **432 clients/jour** |
| Supabase Edge | 16,666 req/jour | 16,666 / 100 | **166 clients/jour** ⚠️ |
| Vercel | Illimité | - | 10,000+ clients/jour |

**🎯 CAPACITÉ FINALE : ~150 clients actifs/jour**  
**🎯 CAPACITÉ MENSUELLE : ~4,500 clients actifs/mois**

**Coût par client** : 65 EUR / 4,500 = **0.0144 EUR/mois**

**Revenue potentiel** :
- Prix : 10-20 EUR/client/mois
- Total : 45,000-90,000 EUR/mois
- **ROI : 692x - 1,385x** 🚀

---

## 🚨 Problème Critique : Database Full

**État actuel** :
```
Database : 9.5 GB
Limite Pro : 8 GB
Dépassement : +1.5 GB (119%)
```

**Conséquences** :
- ❌ Nouvelles insertions peuvent échouer
- ❌ Performance dégradée
- ❌ Risque de crash service

**Solution** : Upgrade Supabase Pro → Team (50 USD/mois)

---

## 🚀 Plan de Scaling Progressif

### Étape 1 : Upgrade Supabase (URGENT)

**Budget** : 65 EUR → **70 EUR/mois** (+5 EUR)

**Changements** :
```
Supabase Pro (20 EUR) → Team (50 USD = 47 EUR)
  Database : 8 GB → 50 GB ✅
  Edge Functions : 500k → 2M req/mois ✅
  Transfer : 100 GB → 250 GB ✅
```

**Gains** :
- Database : +525% capacité (résout problème critique)
- Edge Functions : x4 capacité
- **Capacité clients moyens : 300 → 1,200/jour** (x4)

**Revenue potentiel** :
- 1,200 clients × 5 EUR = 6,000 EUR/mois
- ROI : 85x

---

### Étape 2 : Upgrade Backend Render

**Budget** : 70 EUR → **95 EUR/mois** (+25 EUR)

**Changements** :
```
Render Standard (20 EUR) → Pro (25 USD = 23 EUR)
  RAM : 2 GB → 4 GB ✅
  CPU : 1 core → 2 cores ✅
```

**Gains** :
- Concurrence : x2 (60 req/min au lieu de 30)
- RAM : x2 (plus de marge)
- **Capacité clients moyens : 1,200 → 2,400/jour** (x2)

**Revenue potentiel** :
- 2,400 clients × 5 EUR = 12,000 EUR/mois
- ROI : 126x

---

### Étape 3 : Scale Horizontal

**Budget** : 95 EUR → **200 EUR/mois** (+105 EUR)

**Changements** :
```
Supabase Team → Enterprise (négocié)
Render Pro → Pro ×2 + Load Balancer
Redis 256 MB → 1 GB
```

**Gains** :
- Backend : x2 instances (120 req/min)
- Database : 50 GB → 100+ GB
- **Capacité clients moyens : 2,400 → 5,000-10,000/jour** (x2-4)

**Revenue potentiel** :
- 5,000 clients × 5 EUR = 25,000 EUR/mois
- ROI : 125x

---

## 💡 Recommandation Finale

### Pour Démarrer (0-100 clients)

**Budget** : **70 EUR/mois** (Supabase Team + reste inchangé)

**Target** :
- 100-300 clients PME
- 5-10 EUR/client/mois
- 50 messages/jour/client

**Revenue** :
- 100 clients × 7.5 EUR = 750 EUR/mois (ROI : 10.7x)
- 300 clients × 7.5 EUR = 2,250 EUR/mois (ROI : 32x)

**Marge** : 750-2,250 EUR - 70 EUR = **680-2,180 EUR profit/mois**

---

### Pour Scaler (100-500 clients)

**Budget** : **95 EUR/mois** (+ Render Pro)

**Target** :
- 500-1,000 clients PME
- 5-10 EUR/client/mois
- 50 messages/jour/client

**Revenue** :
- 500 clients × 7.5 EUR = 3,750 EUR/mois (ROI : 39x)
- 1,000 clients × 7.5 EUR = 7,500 EUR/mois (ROI : 79x)

**Marge** : 3,750-7,500 EUR - 95 EUR = **3,655-7,405 EUR profit/mois**

---

## 🔧 Optimisations Possibles

### Court Terme (Sans coût supplémentaire)

1. **Cache Redis agressif**
   - TTL : 24h pour embeddings fréquents
   - Hit rate : 60-80%
   - Gain : x2-3 capacité backend

2. **Rate limiting intelligent**
   - 10 req/min/user (évite abus)
   - Burst : 20 req/5min
   - Protège infra

3. **Lazy loading systématique**
   - Modèle GGUF chargé au 1er appel
   - Économise RAM au démarrage

### Moyen Terme (Avec budget)

1. **CDN pour assets statiques**
   - Cloudflare : Gratuit
   - Réduit load Vercel

2. **Worker pool dynamique**
   - Scale backend selon charge
   - Render Auto-scaling (Pro+)

3. **Database partitioning**
   - documents par date (années)
   - Améliore performance queries

---

## 📈 Métriques Cibles par Étape

### Étape 1 (70 EUR/mois)

| Métrique | Valeur |
|----------|--------|
| Clients max | 1,200/jour (moyens) |
| Requêtes/jour | 60,000 |
| Database size | 50 GB max |
| Edge Functions | 2M/mois |
| Revenue target | 6,000 EUR/mois |
| Marge | 5,930 EUR/mois |

### Étape 2 (95 EUR/mois)

| Métrique | Valeur |
|----------|--------|
| Clients max | 2,400/jour (moyens) |
| Requêtes/jour | 120,000 |
| Database size | 50 GB max |
| Edge Functions | 2M/mois |
| Revenue target | 12,000 EUR/mois |
| Marge | 11,905 EUR/mois |

### Étape 3 (200 EUR/mois)

| Métrique | Valeur |
|----------|--------|
| Clients max | 5,000-10,000/jour |
| Requêtes/jour | 250,000-500,000 |
| Database size | 100+ GB |
| Edge Functions | 5M+/mois |
| Revenue target | 25,000-50,000 EUR/mois |
| Marge | 24,800-49,800 EUR/mois |

---

## 🎯 Stratégie Pricing Recommandée

### Segmentation Clients

**1. Particuliers (Freemium → Payant)**
- Gratuit : 5 messages/jour
- Payant : 2-5 EUR/mois (50-100 messages/jour)
- Volume : 500-1,000 clients

**2. PME / Architectes (Cible principale)**
- Standard : 5-10 EUR/mois (50-100 messages/jour)
- Premium : 15-20 EUR/mois (200-300 messages/jour)
- Volume : 100-500 clients
- **Meilleur ROI**

**3. Grands Cabinets (Enterprise)**
- Custom : 50-100 EUR/mois (usage illimité)
- Support dédié
- Volume : 10-50 clients
- **Marge maximale**

---

## 📊 Projection Revenue (12 mois)

### Scénario Conservateur

| Mois | Clients | Prix moyen | Revenue | Coûts | Profit |
|------|---------|------------|---------|-------|--------|
| M1-3 | 50 | 7.5 EUR | 375 EUR | 70 EUR | 305 EUR |
| M4-6 | 150 | 7.5 EUR | 1,125 EUR | 70 EUR | 1,055 EUR |
| M7-9 | 300 | 7.5 EUR | 2,250 EUR | 95 EUR | 2,155 EUR |
| M10-12 | 500 | 7.5 EUR | 3,750 EUR | 95 EUR | 3,655 EUR |

**Total année 1** : 7,500 EUR revenue - 995 EUR coûts = **6,505 EUR profit**

### Scénario Optimiste

| Mois | Clients | Prix moyen | Revenue | Coûts | Profit |
|------|---------|------------|---------|-------|--------|
| M1-3 | 100 | 10 EUR | 1,000 EUR | 70 EUR | 930 EUR |
| M4-6 | 300 | 10 EUR | 3,000 EUR | 95 EUR | 2,905 EUR |
| M7-9 | 600 | 10 EUR | 6,000 EUR | 95 EUR | 5,905 EUR |
| M10-12 | 1,000 | 10 EUR | 10,000 EUR | 200 EUR | 9,800 EUR |

**Total année 1** : 20,000 EUR revenue - 1,355 EUR coûts = **18,645 EUR profit**

---

## 🔧 Actions Immédiates Requises

### 1. ⚠️ CRITIQUE : Upgrade Supabase (Aujourd'hui)

**Problème** : Database 9.5 GB > 8 GB limite

**Action** :
1. Aller sur Supabase Dashboard
2. Settings → Billing
3. Upgrade Pro → Team (50 USD/mois)
4. Confirmer

**Résultat** :
- ✅ Database : 8 GB → 50 GB (résout problème)
- ✅ Edge Functions : 500k → 2M (+300%)
- ✅ Capacité : 300 → 1,200 clients moyens

---

### 2. Monitoring Capacité

**Métriques à surveiller** :

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size('postgres')) as db_size;

-- Edge Functions usage (via Supabase Dashboard)
-- Render metrics (via Render Dashboard)
-- Redis memory (via Redis Cloud Dashboard)
```

**Alertes à configurer** :
- Database > 40 GB (80% de 50 GB Team)
- Edge Functions > 1.6M/mois (80% de 2M)
- Backend RAM > 3.2 GB (80% de 4 GB Pro)

---

### 3. Optimisations Gratuites

**Activer immédiatement** :

1. **Cache agressif** : Embeddings 24h TTL
2. **Rate limiting** : 10 req/min/user
3. **Connection pooling** : pgBouncer Supabase
4. **Compression** : gzip responses API

**Gain attendu** : +50% capacité sans coût

---

## 📚 Références

- [Render Pricing](https://render.com/pricing)
- [Supabase Pricing](https://supabase.com/pricing)
- [Vercel Pricing](https://vercel.com/pricing)
- [Redis Cloud Pricing](https://redis.io/pricing/)

---

---

## 📈 Projection Croissance Database (13 oct 2025)

### ⚠️ Correction : Croissance Permanente

**La database NE va PAS s'arrêter à 13 GB !**

**Sources de croissance continue** :

1. **Légifrance PISTE** (évolution législative permanente)
   - Nouvelles lois, décrets, arrêtés chaque mois
   - Modifications codes juridiques
   - Jurisprudence mise à jour
   - **Estimation** : +10-50k docs/an → +1-5 GB/an

2. **Chunking granulaire** (WorkerLocal Chunk)
   - 1 document → ~7 chunks moyenne
   - 1.1M docs × 7 = **7.7M chunks**
   - Par chunk : ~9 KB data + embedding(768)
   - Table chunks : 7.7M × 9 KB = **69 GB**
   - Index HNSW chunks : **~70 GB**
   - **TOTAL chunks : ~140 GB**

3. **Géoportail PLU** (nouveau micro-service)
   - Plans Locaux d'Urbanisme France
   - ~35,000 communes
   - Documents PDF, shapefiles, règlements
   - **Estimation : +20-50 GB** (moyenne 30 GB)

4. **Uploads utilisateurs** (futur)
   - Documents projets architectes
   - Plans, schémas, photos
   - Variable selon adoption

### 📊 Projection Database Finale

| Composant | Taille Estimée | Détails |
|-----------|----------------|---------|
| **Documents Légifrance** | 13 GB | 1.1M docs + index HNSW (199 MB) |
| **Chunks granulaires** | 140 GB | 7.7M chunks + index HNSW (~70 GB) |
| **Documents PLU** | 30 GB | Géoportail + index |
| **Marge/Évolution** | 17 GB | Croissance future (lois, uploads) |
| **TOTAL FINAL** | **~200 GB** | **Projection réaliste** |

### 💰 Coût Supabase Pro à 200 GB

**Supabase Pro Plan** : Auto-scaling compatible 200 GB ✅

| Item | Montant | Calcul |
|------|---------|--------|
| Plan Pro (base) | 25 USD/mois | Inclus 8 GB |
| Storage surplus | 24 USD/mois | (200-8) × 0.125 USD |
| **TOTAL Supabase** | **49 USD/mois** | **~46 EUR/mois** |

### 🏗️ Infrastructure Finale (200 GB)

| Service | Plan | Coût EUR/mois | Rôle |
|---------|------|---------------|------|
| Render | Standard | 20 EUR | Backend + GGUF |
| **Supabase** | **Pro + 192 GB** | **46 EUR** | **Database + pgvector** |
| Vercel | Pro | 20 EUR | Frontend |
| Redis | Basic | 5 EUR | Cache |
| **TOTAL** | - | **~91 EUR/mois** | **Infra complète** |

**Évolution coût** :
- Actuel (11 GB) : 65 EUR/mois
- Final (200 GB) : 91 EUR/mois
- **Augmentation : +26 EUR/mois** (+40%)

### 🎯 Capacité Client à 200 GB

**Avec infrastructure finale (91 EUR/mois)** :

La capacité client **ne change pas** (goulot = Backend CPU, pas storage) :
- Usage moyen : **300 clients/jour** = 9,000/mois
- Usage léger : **1,500 clients/jour** = 45,000/mois

**Revenue potentiel** :
- 300 clients × 7.5 EUR = 2,250 EUR/mois
- **Coût infra** : 91 EUR/mois
- **Profit** : 2,159 EUR/mois
- **ROI : 24x**

### ✅ Recommandation Finale

**RESTE SUR SUPABASE PRO** avec auto-scaling :
- ✅ Gère 200 GB sans problème
- ✅ Coût raisonnable : 91 EUR/mois
- ✅ Auto-scaling automatique (pas de gestion)
- ✅ ROI excellent : 24x-100x selon clients

**Pas besoin de Team Plan (599 USD/mois)** sauf si :
- Tu veux 2M Edge Functions (vs 500k)
- Tu as besoin SLA 99.9% + support prioritaire
- Tu passes à 1,000+ clients/jour

---

**🎯 CONCLUSION** : Avec **91 EUR/mois** (Supabase Pro auto-scale), tu gères **200 GB database** + **300-1,500 clients/jour** avec revenue potentiel **45-225k EUR/an** 🚀

