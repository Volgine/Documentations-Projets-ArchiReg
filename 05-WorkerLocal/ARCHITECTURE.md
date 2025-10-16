# 🔧 ARCHITECTURE WORKERLOCAL

**Date** : 15 octobre 2025  
**Version** : 3.2  
**Type** : CLI Python (Windows/Linux compatible)  
**Rôle** : Parser documents + Générer embeddings **GLOBAUX**

---

## 🎯 RESPONSABILITÉS

### **CE QU'IL FAIT** ✅

```
1. Lit files_queue (status: pending)
   ↓ Télécharge JSON bucket
2. Parse document légal
   ↓ Extraction texte + métadonnées
3. Génère embedding GLOBAL (GGUF)
   ↓ Document entier → 1 vecteur 768 dims
4. INSERT dans documents table
   ↓ + Embedding pgvector
5. UPDATE files_queue (status: processed)
   ↓ INSERT parsed_files (tracking)
```

**Workflow** :
1. **SELECT** : Récupère fichiers pending depuis `files_queue`
2. **DOWNLOAD** : Télécharge JSON depuis bucket Supabase
3. **PARSE** : Extrait titre, contenu, métadonnées
4. **EMBED** : Génère embedding GLOBAL (document complet)
5. **INSERT** : Stocke dans `documents` + `parsed_files`
6. **UPDATE** : Marque `files_queue` comme processed

### **CE QU'IL NE FAIT PAS** ❌

- ❌ Collecte données (Micro-service Légifrance)
- ❌ Chunking granulaire (WorkerLocal Chunk)
- ❌ Chat LLM (Backend)
- ❌ RAG search (Backend)

---

## 📊 ARCHITECTURE TECHNIQUE

### **Modèle GGUF Local**

**Fichier** : `solon-embeddings-large-0.1-Q8_0.gguf`

**Caractéristiques** :
- **Dimensions** : 768
- **Quantization** : Q8_0 (8-bit)
- **Taille** : ~500 MB
- **Source** : Bucket Supabase `ai-models`
- **Compilation** : Source without AVX2/FMA (compatibility)

---

## 📁 STRUCTURE FICHIERS

```
WorkerLocal/
├── cli.py                      # Point d'entrée CLI
├── config/
│   └── settings.py            # Configuration env
├── db/
│   └── supabase_client.py     # Client asyncpg
├── embedding/
│   └── gguf_service.py        # Service embeddings GGUF
├── storage/
│   └── supabase_storage.py    # Download bucket
├── worker/
│   ├── parser.py              # Parsing JSON légal
│   └── processor.py           # Workflow complet
├── launch/
│   ├── worker_1.bat           # Launcher Worker 1
│   ├── worker_2.bat           # Launcher Worker 2
│   └── worker_3.bat           # Launcher Worker 3
├── cache/                      # Cache modèle GGUF
├── requirements.txt            # Dépendances
└── README.md                   # Documentation
```

---

## 🔧 COMPOSANTS PRINCIPAUX

### **1. CLI** (`cli.py`)

```python
@click.command()
@click.option('--worker-id', required=True, help='Worker ID (1, 2, 3)')
@click.option('--batch-size', default=100, help='Files per batch')
@click.option('--max-iterations', default=None, help='Max iterations')
def main(worker_id: int, batch_size: int, max_iterations: int):
    """
    Lance worker parsing + embedding GLOBAL
    """
    processor = DocumentProcessor(
        worker_id=worker_id,
        batch_size=batch_size
    )
    
    asyncio.run(processor.run(max_iterations=max_iterations))
```

**Lancement** :
```bash
python cli.py --worker-id 1 --batch-size 100
```

---

### **2. DocumentProcessor** (`worker/processor.py`)

```python
class DocumentProcessor:
    def __init__(self, worker_id: int, batch_size: int):
        self.worker_id = worker_id
        self.batch_size = batch_size
        self.db_client = SupabaseDBClient()
        self.storage_client = SupabaseStorageClient()
        self.embedding_service = GGUFEmbeddingService()
        self.parser = LegalDocumentParser()
    
    async def run(self, max_iterations: int = None):
        """
        Workflow principal : Boucle infinie de traitement
        """
        await self.db_client.initialize()
        await self.embedding_service.initialize()
        
        iteration = 0
        
        while max_iterations is None or iteration < max_iterations:
            # 1. Récupérer batch files_queue
            files = await self.db_client.get_pending_files(
                limit=self.batch_size,
                worker_id=self.worker_id
            )
            
            if not files:
                logger.info("⏸️ No pending files, waiting...", worker_id=self.worker_id)
                await asyncio.sleep(60)
                continue
            
            # 2. Traiter chaque fichier
            for file in files:
                try:
                    await self.process_file(file)
                except Exception as e:
                    logger.error("❌ Error processing file", file_path=file['path'], error=str(e))
            
            iteration += 1
    
    async def process_file(self, file: dict):
        """
        Traite un fichier complet
        """
        # 1. Download JSON bucket
        content = await self.storage_client.download(
            bucket=file['bucket_name'],
            path=file['file_path']
        )
        
        # 2. Parse document
        document = self.parser.parse(content)
        
        # 3. Génère embedding GLOBAL
        embedding = await self.embedding_service.generate(document['content'])
        
        # 4. INSERT documents + parsed_files
        await self.db_client.insert_document(
            title=document['title'],
            content=document['content'],
            metadata=document['metadata'],
            embedding=embedding,
            source_file=file['file_path']
        )
        
        # 5. UPDATE files_queue status
        await self.db_client.update_file_status(
            file_id=file['id'],
            status='processed',
            worker_id=self.worker_id
        )
        
        logger.info("✅ File processed", file_path=file['file_path'], worker_id=self.worker_id)
```

---

### **3. GGUFEmbeddingService** (`embedding/gguf_service.py`)

```python
class GGUFEmbeddingService:
    def __init__(self):
        self.model_name = "solon-embeddings-large-0.1-Q8_0.gguf"
        self.llm = None
    
    async def initialize(self):
        """
        Télécharge modèle depuis Supabase + init llama-cpp
        """
        if self.llm is not None:
            return
        
        # Cache local
        cache_dir = Path("cache/models")
        cache_dir.mkdir(parents=True, exist_ok=True)
        
        model_path = cache_dir / self.model_name
        
        if not model_path.exists():
            # Télécharger depuis bucket Supabase
            logger.info("📥 Downloading GGUF model...")
            content = await supabase_storage.download("ai-models", self.model_name)
            
            with open(model_path, "wb") as f:
                f.write(content)
            
            logger.info("✅ Model downloaded")
        
        # Init llama-cpp
        self.llm = Llama(
            model_path=str(model_path),
            embedding=True,
            n_ctx=2048,         # Context window (document entier)
            n_threads=4,
            verbose=False
        )
        
        logger.info("✅ GGUF service initialized")
    
    async def generate(self, text: str) -> List[float]:
        """
        Génère embedding 768 dimensions
        """
        await self.initialize()
        
        embedding = self.llm.embed(text)
        
        if len(embedding) != 768:
            raise ValueError(f"Expected 768 dims, got {len(embedding)}")
        
        return embedding
```

---

### **4. LegalDocumentParser** (`worker/parser.py`)

```python
class LegalDocumentParser:
    def parse(self, json_content: dict) -> dict:
        """
        Parse JSON document Légifrance
        Extrait titre, contenu, métadonnées
        """
        # Gérer structure API PISTE
        if 'article' in json_content:
            article = json_content['article']
        else:
            article = json_content
        
        # Extraction données
        title = self._extract_title(article)
        content = self._extract_content(article)
        metadata = self._extract_metadata(article)
        
        return {
            "title": title,
            "content": content,
            "metadata": metadata
        }
    
    def _extract_content(self, article: dict) -> str:
        """
        Extrait texte depuis texteHtml
        Nettoie HTML
        """
        texte_html = article.get('texteHtml', '')
        
        if not texte_html:
            return ""
        
        # Nettoyage HTML
        texte_clean = re.sub(r'<[^>]+>', ' ', texte_html)
        texte_clean = texte_clean.replace('&nbsp;', ' ').replace('&amp;', '&')
        texte_clean = re.sub(r'\s+', ' ', texte_clean).strip()
        
        return texte_clean
    
    def _extract_metadata(self, article: dict) -> dict:
        """
        Extrait métadonnées pertinentes
        """
        return {
            "article_id": article.get('id'),
            "num": article.get('num'),
            "nature": article.get('nature'),
            "etat": article.get('etat'),
            "dateDebut": article.get('dateDebut'),
            "datePubli": article.get('datePubli'),
            "nota": article.get('nota', '')
        }
```

---

## 🔄 WORKFLOW COMPLET

```mermaid
sequenceDiagram
    participant WL as WorkerLocal
    participant FQ as files_queue
    participant BKT as Bucket
    participant GGUF as GGUF Service
    participant DB as documents table
    
    loop Boucle infinie
        WL->>FQ: SELECT * WHERE status=pending LIMIT 100
        FQ-->>WL: 100 fichiers
        
        loop Pour chaque fichier
            WL->>BKT: Download JSON
            BKT-->>WL: JSON content
            
            WL->>WL: Parse document
            
            WL->>GGUF: generate(content)
            GGUF-->>WL: embedding[768]
            
            WL->>DB: INSERT documents + embedding
            WL->>FQ: UPDATE status=processed
        end
        
        alt Pas de fichiers pending
            WL->>WL: Sleep 60s
        end
    end
```

---

## ⚙️ CONFIGURATION

### **Variables d'environnement**

**Fichier** : `.env`

```bash
# Supabase
SUPABASE_URL=https://joozqsjbcwrqyeqepnev.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
DATABASE_URL=postgresql://postgres.joozqsjbcwrqyeqepnev:***@aws-0-eu-central-1.pooler.supabase.com:5432/postgres

# GGUF Model
GGUF_MODEL_NAME=solon-embeddings-large-0.1-Q8_0.gguf
GGUF_BUCKET_NAME=ai-models
EMBEDDING_DIM=768

# Worker Config
BATCH_SIZE=100
MAX_RETRIES=3
```

---

### **Launchers Windows**

**Fichier** : `launch/worker_1.bat`

```batch
@echo off
cd /d "%~dp0.."
call venv\Scripts\activate
python cli.py --worker-id 1 --batch-size 100
pause
```

**Usage** :
```batch
# Lancer Worker 1
launch\worker_1.bat

# Lancer Worker 2
launch\worker_2.bat

# Lancer Worker 3
launch\worker_3.bat
```

---

## 📊 PERFORMANCE

### **Stats Réelles**

**Configuration** : 3 Workers simultanés

| Métrique | Valeur | Notes |
|----------|--------|-------|
| **Vitesse** | ~12.5 fichiers/s/worker | 37.5/s total (3 workers) |
| **Processed** | 312,000 documents | ✅ Terminé |
| **Latence embedding** | ~50-100ms | GGUF CPU |
| **Taux erreurs** | <0.03% | Très fiable |

---

## 🔧 FIX CRITIQUE

### **Embeddings Incompatibles** (16-FIX-EMBEDDINGS-INCOMPATIBLES.md)

**Problème** : Workers (Windows AVX2) ≠ Backend (Linux no-AVX2)

**Solution** :
```bash
# Forcer compilation source sans AVX2/FMA
pip uninstall llama-cpp-python
pip install --no-binary=llama-cpp-python llama-cpp-python
```

**Résultat** :
- ✅ Embeddings identiques bit-perfect
- ✅ RAG trouve documents (0 → 312k)
- ✅ Backend + Workers alignés

---

## 🎯 Résumé

**WorkerLocal optimisé** :
- ✅ CLI Python multi-workers
- ✅ Parsing JSON Légifrance
- ✅ Embeddings GLOBAUX GGUF (768 dims)
- ✅ 312k documents traités
- ✅ Vitesse : 37.5 fichiers/s (3 workers)
- ✅ Taux erreur <0.03%
- ✅ Compatible Windows/Linux

**Parsing ultra-performant !** 🚀

