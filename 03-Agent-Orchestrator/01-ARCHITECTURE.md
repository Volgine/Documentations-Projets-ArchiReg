# 🏗️ ARCHITECTURE BACKEND AGENT-ORCHESTRATOR

**Date** : 16 janvier 2025  
**Version** : 5.0.0  
**Framework** : FastAPI 0.115.5 + Python 3.12  
**Host** : Render.com (Starter Plan)

⚠️ **DOCUMENTATION V5.0 COMPLÈTE** : [Agent-Orchestrator/docs/01-ARCHITECTURE.md](../../../Agent-Orchestrator/docs/01-ARCHITECTURE.md) ⭐

---

## ⚠️ CHANGEMENTS v5.0 (16/01/2025)

### **Code nettoyé**
- ✅ 42 fichiers code mort supprimés
- ✅ 3 sanitizers fusionnés en 1 (OWASP 2025)
- ✅ Features enterprise ajoutées (ML security, Pydantic validator)

### **Migration Edge Functions**
- ❌ `api/v3/admin.py` → 🌐 Edge Function `admin-stats`
- ❌ `api/v3/cron.py` → 🌐 Edge Function `cron-manager`
- ❌ Tests (18) → 🌐 Edge Function `system-tests`

### **Architecture mise à jour**
- ✅ Python 3.12 (au lieu de 3.11)
- ✅ CI/CD security (audit CVE auto)
- ✅ Documentation complète (5,100+ lignes)

---

## 🎯 RESPONSABILITÉS BACKEND

### **CE QU'IL FAIT** ✅

```
1. API Chat Groq LLM
   ↓ Streaming SSE
2. Recherche RAG pgvector
   ↓ Retrieval embeddings GGUF
3. Health checks + System Tests
   ↓ Monitoring
4. Proxy Micro-service Légifrance
   ↓ Contrôle scheduler
5. Admin API
   ↓ Metrics dashboard
```

**Fonctions clés** (Backend) :
1. **Chat LLM** : API Groq streaming SSE + historique Supabase
2. **RAG** : Recherche sémantique dans 312k documents pgvector
3. **Embeddings** : Génération locale via GGUF (Solon-embeddings-large Q8_0)
4. **Projects** : CRUD projets ArchiReg
5. **Storage** : Upload fichiers Supabase
6. **Proxy** : Contrôle Micro-service Légifrance (start/stop/mode)
7. **User Stats** : Analytics utilisateur
8. **Tests Backend** : 9 tests système directs
9. **Monitoring** : Structlog JSON + OpenTelemetry + Prometheus

**Fonctions migrées** 🌐 (Edge Functions Supabase) :
- 🌐 **Admin stats** : Métriques dashboard (gain -99.7% latence)
- 🌐 **Cron manager** : Liste jobs pg_cron (read-only sécurisé)
- 🌐 **System tests** : 18 tests système (gain -59% latence)

### **CE QU'IL NE FAIT PAS** ❌

- ❌ Collecte données (Micro-service Légifrance)
- ❌ Parsing/chunking documents (Workers locaux)
- ❌ Stockage fichiers (Supabase Storage direct)
- ❌ Auth utilisateurs (Supabase Auth)
- ❌ Admin dashboard (Edge Functions Supabase)

---

## 📊 SERVICES PRINCIPAUX

### **1. ChatService** (`api/v3/chat.py`)

**Rôle** : Gestion conversation LLM + streaming

```python
async def chat_streaming(
    user_message: str,
    conversation_id: str,
    user_id: str,
    system_prompt: str = None
) -> AsyncGenerator[str, None]:
    """
    Streaming Server-Sent Events (SSE)
    """
    # 1. Recherche RAG documents pertinents
    docs = await rag_service.search(user_message, limit=5)
    
    # 2. Construire contexte RAG
    context = build_context(docs)
    
    # 3. Appel Groq LLM
    async for chunk in groq_client.stream(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": context},
            {"role": "user", "content": user_message}
        ]
    ):
        yield chunk
    
    # 4. Sauvegarder dans Supabase
    await save_message(conversation_id, user_message, assistant_response)
```

**Endpoints** :
```http
POST /api/v3/chat/streaming    # Streaming SSE
POST /api/v3/chat/completions  # Legacy batch
GET  /api/v3/conversations      # Historique
```

---

### **2. RAGService** (`api/v3/rag.py`)

**Rôle** : Recherche sémantique pgvector

```python
class RAGService:
    async def search(
        self,
        query: str,
        limit: int = 10,
        similarity_threshold: float = 0.7
    ) -> List[Document]:
        """
        1. Générer embedding requête (GGUF local)
        2. Recherche cosine similarity pgvector
        3. Filtrer par seuil
        4. Retourner documents ordonnés
        """
        # Embedding query
        query_embedding = await self.embedding_service.generate(query)
        
        # Recherche vectorielle
        results = await self.db.execute(
            f"""
            SELECT 
                id, title, content,
                embedding <=> $1 AS distance
            FROM documents
            WHERE embedding <=> $1 < {1 - similarity_threshold}
            ORDER BY embedding <=> $1
            LIMIT {limit}
            """,
            query_embedding
        )
        
        return [Document(**row) for row in results]
```

**Performance** :
- ✅ <200ms avec index HNSW
- ✅ 312k vecteurs indexés (383 MB)
- ✅ Recall >95%

---

### **3. GGUFEmbeddingService** (`services/embeddings/gguf_service.py`)

**Rôle** : Génération embeddings locaux

```python
class GGUFEmbeddingService:
    def __init__(self):
        self.model_name = "solon-embeddings-large-0.1-Q8_0.gguf"
        self.bucket_name = "ai-models"
        self.llm = None  # Lazy loading
    
    async def initialize(self):
        """
        Lazy loading : Télécharge modèle depuis Supabase
        Seulement au premier appel embedding
        """
        if self.llm is None:
            local_path = await self._download_from_supabase()
            self.llm = Llama(
                model_path=local_path,
                embedding=True,
                n_ctx=512,
                n_threads=4,
                verbose=False
            )
    
    async def generate(self, text: str) -> List[float]:
        """Génère embedding 768 dimensions"""
        await self.initialize()  # Lazy loading
        return self.llm.embed(text)
```

**Modèle utilisé** :
- **Nom** : Solon-embeddings-large-0.1
- **Quantization** : Q8_0
- **Dimensions** : 768
- **Source** : Hugging Face → Bucket Supabase `ai-models`

---

### **4. MicroserviceProxyService** (`api/v3/services_legifrance.py`)

**Rôle** : Proxy sécurisé vers Micro-service Légifrance

```python
class MicroserviceProxyService:
    async def start_collection(self):
        """POST /aspirage/start"""
        return await self._forward_request("POST", "/aspirage/start")
    
    async def stop_collection(self):
        """POST /aspirage/stop"""
        return await self._forward_request("POST", "/aspirage/stop")
    
    async def change_mode(self, mode: str):
        """POST /siphonnage/mode"""
        return await self._forward_request(
            "POST", 
            "/siphonnage/mode",
            json={"mode": mode}
        )
    
    async def get_status(self):
        """GET /aspirage/status"""
        return await self._forward_request("GET", "/aspirage/status")
```

**Endpoints** :
```http
POST /api/v3/legifrance/start        # Démarre collecte
POST /api/v3/legifrance/stop         # Arrête collecte
POST /api/v3/legifrance/mode         # Change MASSIVE ↔ MAINTENANCE
GET  /api/v3/legifrance/status       # État scheduler
GET  /api/v3/legifrance/stats        # Stats collecte
```

---

### **5. SystemTestsService** (`api/v3/admin/system_tests.py`)

**Rôle** : Tests système hybrides (9 Backend + 18 Edge)

```python
class SystemTestsService:
    async def test_supabase(self) -> TestResult:
        """Test connexion DB"""
        try:
            result = await self.db.execute("SELECT 1")
            return TestResult(success=True, latency=...)
        except Exception as e:
            return TestResult(success=False, error=str(e))
    
    async def test_rag(self) -> TestResult:
        """Test RAG complet (embedding + search)"""
        query = "urbanisme PLU"
        docs = await self.rag_service.search(query, limit=5)
        return TestResult(
            success=len(docs) > 0,
            data={"docs_found": len(docs)}
        )
    
    async def test_groq_llm(self) -> TestResult:
        """Test Groq API"""
        response = await self.groq_client.chat(...)
        return TestResult(success=bool(response))
```

**9 Tests Backend** :
1. `test-supabase` : Connexion DB
2. `test-admin-api` : Edge Function admin-stats
3. `test-health-check` : Health endpoint
4. `test-pgvector` : Extension vector + HNSW
5. `test-materialized-view` : Vue admin_metrics_view
6. `test-cron-jobs` : pg_cron actif
7. `test-groq-llm` : API Groq
8. `test-simple` : Config backend
9. `run-unit-tests` : Tests unitaires Python

---

## 🔄 FLUX RAG COMPLET

```mermaid
sequenceDiagram
    participant FE as Frontend
    participant BE as Backend
    participant GGUF as GGUF Service
    participant PG as pgvector
    participant GROQ as Groq API
    
    FE->>BE: POST /chat/streaming<br/>{message: "PLU..."}
    
    Note over BE: 1. Recherche RAG
    BE->>GGUF: generate_embedding(query)
    GGUF-->>BE: [0.1, 0.2, ..., 768 dims]
    
    BE->>PG: SELECT ... <=> embedding
    PG-->>BE: 5 documents pertinents
    
    Note over BE: 2. Construire contexte
    BE->>BE: build_context(docs)
    
    Note over BE: 3. Stream LLM
    BE->>GROQ: stream(context + query)
    loop Chunks streaming
        GROQ-->>BE: chunk
        BE-->>FE: SSE: data: {chunk}
    end
    
    Note over BE: 4. Sauvegarder
    BE->>PG: INSERT conversations/messages
```

---

## 📁 STRUCTURE FICHIERS

```
Agent-Orchestrator/backend/
├── main.py                      # Application FastAPI
├── core/
│   ├── startup.py              # Lifespan + init services
│   ├── config.py               # Configuration env
│   ├── security.py             # Auth JWT + admin
│   └── logging_config.py       # Structlog JSON
├── api/
│   └── v3/
│       ├── chat.py             # Chat streaming SSE
│       ├── rag.py              # Recherche RAG
│       ├── services_legifrance.py  # Proxy micro-service
│       └── admin/
│           ├── system_tests.py      # Tests système
│           └── database_stats.py    # Métriques DB (legacy)
├── services/
│   ├── embeddings/
│   │   └── gguf_service.py     # Embeddings GGUF local
│   ├── groq_service.py         # API Groq LLM
│   └── supabase_service.py     # Client Supabase
├── db/
│   └── supabase_client.py      # Pool asyncpg + Supavisor
└── middleware/
    ├── rate_limiting.py        # Protection DDoS
    └── security.py             # Headers OWASP
```

---

## 🔐 VARIABLES D'ENVIRONNEMENT

### **Supabase**
```bash
SUPABASE_URL=https://joozqsjbcwrqyeqepnev.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
DATABASE_URL=postgresql://postgres.joozqsjbcwrqyeqepnev:***@aws-0-eu-central-1.pooler.supabase.com:5432/postgres?sslmode=require&connect_timeout=10
```

### **Groq API**
```bash
GROQ_API_KEY=xxx
GROQ_MODEL=llama-3.3-70b-versatile
```

### **Micro-service**
```bash
MICROSERVICE_LEGIFRANCE_URL=https://micro-service-data-legifrance-piste.onrender.com
```

### **GGUF Embeddings**
```bash
GGUF_MODEL_NAME=solon-embeddings-large-0.1-Q8_0.gguf
GGUF_BUCKET_NAME=ai-models
EMBEDDING_DIM=768
```

### **Configuration**
```bash
ENVIRONMENT=production
LOG_LEVEL=INFO
ENABLE_CORS=true
```

---

## 🚀 DÉPLOIEMENT RENDER

### **render.yaml**
```yaml
services:
  - type: web
    name: Agent-Orchestrateur-Backend
    runtime: python
    plan: starter
    buildCommand: pip install -r requirements.txt
    startCommand: hypercorn backend.main:app --bind 0.0.0.0:$PORT --workers 1 --worker-class uvloop --access-logfile - --log-level info
    healthCheckPath: /health
    autoDeploy: true
```

### **Hypercorn Configuration**
```python
# HTTP/2 + HTTPS
# Uvloop worker (performance)
# 1 worker (Starter Plan)
# Auto-restart on crash
```

---

## 🎯 FLUX STARTUP

```
1. main.py - lifespan()
    ↓
2. Initialisation services
   - SupabaseService (pool asyncpg)
   - GGUFEmbeddingService (lazy loading)
   - GroqService
    ↓
3. Tests connexion
   - Health check DB
   - Verify pgvector extension
    ↓
4. ✅ Service prêt
   - API listening :10000
   - Health check OK
```

---

## 📊 OPTIMISATIONS CRITIQUES

### **1. Fix Asyncpg Pool** (21-FIX-POOL-ASYNCPG.md)

**Problème** : `{:shutdown, :client_termination}` sur RAG search

**Solution** :
```python
# Supavisor Session Mode (IPv4 compatible)
DATABASE_URL = "postgresql://...pooler.supabase.com:5432/...?sslmode=require&connect_timeout=10&application_name=backend"

# Pool asyncpg
pool = await asyncpg.create_pool(
    DATABASE_URL,
    min_size=2,
    max_size=10,
    command_timeout=60.0,
    server_settings={
        'application_name': 'backend-rag',
        'jit': 'off'
    }
)
```

**Résultat** :
- ✅ RAG fonctionne (0 → 100% success)
- ✅ Latence <200ms
- ✅ Connexions stables

---

### **2. Fix Embeddings Incompatibles** (16-FIX-EMBEDDINGS-INCOMPATIBLES.md)

**Problème** : Workers (Windows AVX2) ≠ Backend (Linux no-AVX2)

**Solution** :
```python
# Forcer compilation source sans AVX2/FMA
pip install --no-binary=llama-cpp-python llama-cpp-python
```

**Résultat** :
- ✅ Embeddings identiques Workers ↔ Backend
- ✅ RAG trouve documents (0 → 312k)
- ✅ Similarité cohérente

---

## 🎉 Résumé Architecture

**Backend ultra-optimisé** :
- ✅ RAG pgvector performant (<200ms)
- ✅ Chat streaming SSE Groq
- ✅ Embeddings GGUF locaux
- ✅ Pool asyncpg stable
- ✅ Proxy micro-service sécurisé
- ✅ Tests hybrides (Backend + Edge)
- ✅ Hypercorn HTTP/2

**Architecture propre, rapide, résiliente !** 🚀

