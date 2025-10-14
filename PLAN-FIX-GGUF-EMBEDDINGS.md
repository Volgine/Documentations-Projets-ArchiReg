# 🔧 PLAN COMPLET : FIX GGUF EMBEDDINGS BACKEND

**Date création** : 11 octobre 2025  
**Date résolution** : 13 octobre 2025 08:30 UTC  
**Version** : 2.0 **RÉSOLU**  
**Status** : ✅ **RÉSOLU** - RAG fonctionnel avec llama-cpp-python==0.3.16 + threshold 0.70

---

## 🎉 RÉSOLUTION FINALE (13 oct 2025)

**Problème racine identifié** : Version `llama-cpp-python` flexible (`>=0.2.20`) vs exacte (`==0.3.16`)

**Solution appliquée** :
```python
# requirements.txt
llama-cpp-python==0.3.16  # ✅ VERSION EXACTE (pas >=)
```

**Commits de résolution** :
- `409f98a` : Retrait 7 paramètres Llama différents
- `9cb8038` : Lock asyncio subprocess
- `66d7f5d` : Fix version ==0.3.16
- `7caeec7` : Threshold 0.70 confirmé

**Résultats tests** :
- ✅ "Quelles sont les regles urbanisme" → 3 documents (distance 0.6774)
- ✅ "urbanisme" → 5 documents (distance 0.5977)
- ✅ Threshold 0.70 optimal pour Solon-base

**Pour détails complets, voir** : `09-RAG-EMBEDDINGS.md` section "Fix Version llama-cpp-python"

---

## 🚨 PROBLÈME INITIAL (11 oct 2025)

---

## 🚨 PROBLÈME IDENTIFIÉ

### **Symptômes**
```
❌ RAG retourne 0 résultats (base vide ou embeddings en chargement)
❌ [warning] Aucun modèle d'embedding fourni. Le cache sémantique sera désactivé.
❌ [error] Embedding service not ready: not_started
❌ worker_mode=adaptive (obsolète)
```

### **Log critique** :
```python
File "/app/services/supabase_embedding_service.py", line 201
raise Exception(f"Embedding service not ready: {self._initialization_status}")
# Status: "not_started"
```

---

## ✅ DIAGNOSTIC COMPLET (VIA MCP)

### **1️⃣ Modèle GGUF Supabase** ✅
```json
{
  "bucket_id": "ai-models",
  "name": "Solon-embeddings-base-0.1.Q8_0.gguf",
  "size_bytes": "303138240"  // ~289 MB ✅
}
```
**Status** : ✅ **MODÈLE PRÉSENT ET ACCESSIBLE**

---

### **2️⃣ Documents avec Embeddings** ✅
```json
{
  "total_docs": 930394,           // 🚀 930k documents !
  "docs_with_embeddings": 930394  // ✅ 100% ont embeddings !
}
```
**Status** : ✅ **930,394 DOCUMENTS INDEXÉS AVEC EMBEDDINGS**

---

### **3️⃣ Index pgvector** ✅
```sql
CREATE INDEX documents_embedding_idx 
ON documents 
USING ivfflat (embedding vector_cosine_ops) 
WITH (lists='100')
```
**Status** : ✅ **INDEX PGVECTOR CRÉÉ ET OPÉRATIONNEL**

---

### **4️⃣ Backend GGUF Service** ❌ **PROBLÈME ICI !**
```
[error] Embedding service not ready: not_started
```

**Analyse du code** :

#### **`startup.py` - Ligne 82-93** :
```python
async def initialize_heavy(self):
    """
    ✅ PHASE 2: Chargement LOURD - llama-cpp seulement
    """
    logger.info("🔄 Début chargement services LOURDS (llama-cpp)...")
    
    # ❌ PROBLÈME: Charge llama-cpp mais PAS embedding service !
    await self._init_llama_cpp_only()
    
    logger.info("✅ Services LOURDS chargés")
```

#### **`startup.py` - Ligne 155-170** :
```python
async def _init_llama_cpp_only(self):
    """Initialise SEULEMENT llama-cpp (sans embedding)"""
    # ❌ PLACEHOLDER VIDE !
    logger.info("🔬 Llama-cpp initialisé (via embedding service).")
    # ❌ NE FAIT RIEN !
```

#### **`startup.py` - Ligne 125-154** :
```python
async def _init_embedding_service(self):
    """✅ CORRECTION #7: Initialise le service d'embedding"""
    async with self._embedding_lock:
        if self._embedding_inited:
            return
        
        self.embedding_status = "loading"
        embedding_service = get_embedding_service()
        await embedding_service.initialize()  # ✅ BOM CODE !
        self._embedding_inited = True
        self.embedding_status = "ready"
```

**MAIS** : Cette fonction `_init_embedding_service()` **N'EST JAMAIS APPELÉE** ! ❌

---

## 🔍 CAUSE RACINE

### **Flow Actuel (CASSÉ)** ❌

```
Backend Startup
  ↓
initialize_light() ✅
  ↓ Supabase + Cache + Search Service (sans embedding)
Health Check OK ✅
  ↓
initialize_heavy() ❌
  ↓ _init_llama_cpp_only() → FAIT RIEN !
  ❌ _init_embedding_service() → JAMAIS APPELÉ !
  ↓
GGUFEmbeddingService._initialization_status = "not_started" ❌
  ↓
RAG call → get_embedding() → raise Exception ❌
```

---

## 🔧 SOLUTION COMPLÈTE

### **Flow Correct (FIX)** ✅

```
Backend Startup
  ↓
initialize_light() ✅
  ↓ Supabase + Cache + Search Service (sans embedding)
Health Check OK ✅ (< 90s)
  ↓ Render valide le service ✅
initialize_heavy() ✅
  ↓ PHASE 2: _download_model_if_needed() (30-60s)
  ↓ Téléchargement 289 MB depuis bucket Supabase
  ↓ PHASE 3: _init_embedding_service() (60-120s)
  ↓ Chargement llama-cpp subprocess
  ↓
GGUFEmbeddingService._initialization_status = "ready" ✅
  ↓
RAG call → get_embedding() → Recherche pgvector ✅
```

---

## 🛠️ CODE À CORRIGER

### **FICHIER 1 : `backend/core/startup.py`**

#### **Ligne 82-93 : `initialize_heavy()`** (AVANT)
```python
async def initialize_heavy(self):
    """
    ✅ PHASE 2: Chargement LOURD - llama-cpp seulement
    """
    logger.info("🔄 Début chargement services LOURDS (llama-cpp)...")
    
    # ❌ PROBLÈME: Ne charge PAS embedding service !
    await self._init_llama_cpp_only()
    
    logger.info("✅ Services LOURDS chargés")
```

#### **Ligne 82-93 : `initialize_heavy()`** (APRÈS) ✅
```python
async def initialize_heavy(self):
    """
    ✅ PHASE 2 & 3: Télécharger GGUF puis charger llama-cpp
    Se déclenche APRÈS que Render valide le health check (évite timeout)
    Chargement séquentiel pour éviter saturation RAM
    """
    logger.info("🔄 Début chargement GGUF embeddings...")
    
    # PHASE 2: Télécharger le modèle GGUF (30-60s)
    await self._init_embedding_service()
    
    # PHASE 3: Charger llama-cpp LLM si nécessaire (placeholder)
    await self._init_llama_cpp_only()
    
    logger.info("✅ Services LOURDS chargés - système pleinement opérationnel")
```

---

### **FICHIER 2 : `backend/core/config.py`**

#### **Ligne 22 : `worker_mode`** (AVANT)
```python
worker_mode: str = os.getenv("WORKER_MODE", "adaptive")  # ❌ Obsolète
```

#### **Ligne 22 : `worker_mode`** (APRÈS) ✅
```python
worker_mode: str = os.getenv("WORKER_MODE", "read_only")  # ✅ Correct
```

---

### **FICHIER 3 : `backend/services/supabase_embedding_service.py`**

#### **Ligne 195-210 : `get_embedding()`** (AVANT)
```python
async def get_embedding(self, text: str) -> GGUFEmbeddingResponse:
    """Génère un embedding"""
    if not self._initialized:
        await self.initialize()  # ✅ OK
    
    if self._initialization_status != "ready":
        # ❌ RAISE DIRECT = CRASH !
        raise Exception(f"Embedding service not ready: {self._initialization_status}")
```

#### **Ligne 195-210 : `get_embedding()`** (APRÈS) ✅
```python
async def get_embedding(self, text: str) -> GGUFEmbeddingResponse:
    """Génère un embedding avec attente si nécessaire"""
    # ✅ Initialiser si pas démarré
    if self._initialization_status == "not_started":
        await self.initialize()
    
    # ✅ Attendre si en cours de chargement (max 120s)
    if self._initialization_status == "loading":
        max_wait = 120
        waited = 0
        while self._initialization_status == "loading" and waited < max_wait:
            await asyncio.sleep(1)
            waited += 1
        
        if self._initialization_status != "ready":
            raise Exception(f"Embedding timeout after {waited}s: {self._initialization_status}")
    
    # ✅ Vérifier statut final
    if self._initialization_status == "failed":
        raise Exception(f"Embedding service failed: {self._initialization_error}")
    
    if self._initialization_status != "ready":
        raise Exception(f"Embedding service not ready: {self._initialization_status}")
    
    # ✅ Continuer avec génération embedding...
```

---

## 📊 ORDRE D'EXÉCUTION CORRECT

### **Phase 1 : Light Init (< 90s)** ✅
```
1. setup_logging()
2. validate_all()
3. _init_supabase()
4. _init_cache_manager()
5. _init_search_service()  // Sans embedding
6. _init_mcp_servers()
7. _init_agent_service()
```

**Résultat** : Health check répond ✅ → Render valide le service ✅

---

### **Phase 2 : Download GGUF (30-60s)** 📥
```
1. get_embedding_service()
2. _download_model_if_needed()
   - Vérifier cache local
   - Si absent: Download depuis bucket Supabase
   - 289 MB → cache/shared/
```

**Résultat** : Modèle GGUF local ✅

---

### **Phase 3 : Load llama-cpp (60-120s)** 🧠
```
1. start_background_initialization()
2. _attempt_initialization()
   - Lancer subprocess llama_server.py
   - Attendre signal READY
   - Communiquer via stdin/stdout
```

**Résultat** : `_initialization_status = "ready"` ✅

---

### **Phase 4 : RAG Ready** 🎯
```
1. User query "test urbanisme"
2. get_embedding() → Génère embedding query [768 dims]
3. Recherche pgvector → 930k documents
4. Retourne top 10 résultats
```

---

## 🎯 CORRECTIONS À APPLIQUER

### **1. Corriger `startup.py`** ✅
```python
# Ligne 82-93
async def initialize_heavy(self):
    logger.info("🔄 Début chargement GGUF embeddings...")
    await self._init_embedding_service()  # ✅ AJOUT
    logger.info("✅ Services LOURDS chargés")
```

### **2. Corriger `config.py`** ✅
```python
# Ligne 22
worker_mode: str = os.getenv("WORKER_MODE", "read_only")  # ✅ FIX
```

### **3. Améliorer `supabase_embedding_service.py`** ✅
```python
# Ligne 195-210
async def get_embedding(self, text: str):
    # ✅ Attendre si loading
    if self._initialization_status == "loading":
        max_wait = 120
        waited = 0
        while self._initialization_status == "loading" and waited < max_wait:
            await asyncio.sleep(1)
            waited += 1
    
    # ✅ Vérifier ready
    if self._initialization_status != "ready":
        raise Exception(...)
```

---

## 📋 CHECKLIST DE VALIDATION

### **Avant le fix** ❌
- [ ] Health check OK
- [x] Modèle GGUF présent (289 MB)
- [x] 930k documents avec embeddings
- [x] Index pgvector créé
- [ ] GGUF service initialisé ❌
- [ ] RAG retourne résultats ❌

### **Après le fix** ✅
- [ ] Health check OK (< 90s)
- [ ] Modèle GGUF téléchargé (30-60s après health)
- [ ] GGUF service ready (90-180s après health)
- [ ] RAG retourne résultats (query test urbanisme)
- [ ] worker_mode = read_only
- [ ] Logs sans warning embedding

---

## 🚀 ÉTAPES DE DÉPLOIEMENT

### **1. Appliquer les corrections**
```bash
cd Agent-Orchestrator
# Modifier 3 fichiers:
# - backend/core/startup.py
# - backend/core/config.py
# - backend/services/supabase_embedding_service.py
```

### **2. Commit & Push**
```bash
git add -A
git commit -m "fix: GGUF embeddings initialization + worker_mode read_only"
git push origin dev
```

### **3. Render Auto-Deploy**
- Render détecte le push sur `dev`
- Build Docker (3-5 min)
- Deploy nouveau container
- Health check validé
- GGUF téléchargement en background
- llama-cpp init en background
- RAG ready après ~3-5 min total

### **4. Validation**
```bash
# Test health embedding
curl https://agent-orchestrateur-backend.onrender.com/api/v3/health/embedding

# Test RAG
curl "https://agent-orchestrateur-backend.onrender.com/api/v3/rag/search-legifrance?query=test+urbanisme&limit=3" \
  -H "Authorization: Bearer YOUR_JWT"
```

---

## 📊 TIMELINE ATTENDUE

| Phase | Durée | Status |
|-------|-------|--------|
| **Health Check** | 30-60s | ✅ Render valide |
| **Download GGUF** | 30-60s | 📥 Background |
| **Load llama-cpp** | 60-120s | 🧠 Background |
| **Total Ready** | 2-4 min | ✅ RAG opérationnel |

---

## 🎯 POINTS CLÉS

### **1. Health Check NE DOIT PAS bloquer sur GGUF** ⚠️
```python
# ✅ BON
async def initialize_light():
    # ... services légers uniquement
    # PAS d'init embedding ici !
    
# ❌ MAUVAIS
async def initialize_light():
    await self._init_embedding_service()  # ❌ TIMEOUT !
```

---

### **2. Embedding DOIT être téléchargé AVANT llama-cpp** ⚠️
```python
# ✅ BON: Téléchargement PUIS chargement
await embedding_service._download_model_if_needed()  # 30-60s
await embedding_service.initialize()  # 60-120s (subprocess)

# ❌ MAUVAIS: Chargement direct
await embedding_service.initialize()  # ❌ Cherche fichier inexistant → CRASH
```

---

### **3. worker_mode doit être "read_only"** ⚠️
```python
# ✅ BON
worker_mode: str = "read_only"

# ❌ MAUVAIS
worker_mode: str = "adaptive"  # Obsolète
```

---

## 🧪 TEST DE VALIDATION

### **Test 1 : Health Check (< 90s)**
```bash
curl https://agent-orchestrateur-backend.onrender.com/api/v3/health
# ✅ Doit répondre rapidement sans bloquer
```

### **Test 2 : Embedding Health (après 2-4 min)**
```bash
curl https://agent-orchestrateur-backend.onrender.com/api/v3/health/embedding
# ✅ Doit retourner:
{
  "embedding_service": "ready",
  "model": "Solon-embeddings-base-0.1.Q8_0.gguf",
  "dimension": 768
}
```

### **Test 3 : RAG Search (après 2-4 min)**
```bash
curl "https://agent-orchestrateur-backend.onrender.com/api/v3/rag/search-legifrance?query=test+urbanisme&limit=3" \
  -H "Authorization: Bearer JWT"
# ✅ Doit retourner:
{
  "success": true,
  "results": [...],  // Au moins 1-3 résultats
  "total_found": 3
}
```

---

## 🎯 RÉSUMÉ

| Composant | Status Actuel | Status Attendu |
|-----------|---------------|----------------|
| **Modèle GGUF** | ✅ Présent (289 MB) | ✅ Présent |
| **Documents DB** | ✅ 930k avec embeddings | ✅ 930k |
| **Index pgvector** | ✅ Créé (ivfflat) | ✅ Créé |
| **Health Check** | ✅ < 90s | ✅ < 90s |
| **GGUF Download** | ❌ Pas appelé | ✅ Background (30-60s) |
| **llama-cpp Load** | ❌ Pas chargé | ✅ Background (60-120s) |
| **RAG Search** | ❌ 0 résultats | ✅ 1-10 résultats |
| **worker_mode** | ❌ adaptive | ✅ read_only |

---

**FIN DU PLAN** 🎯

