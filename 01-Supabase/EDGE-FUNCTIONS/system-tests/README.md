# Edge Function : system-tests

## 📋 Description

Edge Function Supabase complète pour tester tous les services actifs ArchiReg :
- **ArchiReg-Front** (Frontend Vercel)
- **Agent-Orchestrator** (Backend Render)
- **Micro-service Légifrance** (Micro-service Render)
- **Supabase** (Database + Storage + Auth + Realtime + Edge Functions)

---

## 🎯 Tests Inclus (15 tests)

### **1️⃣ Backend Agent-Orchestrator (11 tests)**
| Test ID | Nom | Description |
|---------|-----|-------------|
| `test-backend` | Backend Health | Teste `/api/v3/health` |
| `test-security-headers` | Security Headers | Vérifie OWASP 2025 (X-Content-Type-Options, X-Frame-Options, HSTS) |
| `test-rate-limiting` | Rate Limiting | Teste protection DDoS |
| `test-jwt-auth` | JWT Auth | Vérifie middleware auth |
| `test-modern-api` | Modern API | Teste `/api/v3/core/test-simple` |
| `test-observability` | Observability | Vérifie logging structuré |
| `test-mcp-integration` | MCP Integration | Teste protection MCP endpoints |
| `test-error-handling` | Error Handling | Vérifie HTTPException handlers |
| `test-http2` | HTTP/2 | Vérifie Hypercorn HTTP/2 |
| `test-cors` | CORS | Teste `/api/v3/core/cors-test` |
| `test-circuit-breaker` | Circuit Breaker | Vérifie failover |

### **2️⃣ Supabase (4 tests)**
| Test ID | Nom | Description |
|---------|-----|-------------|
| `test-supabase-db` | Supabase DB | Teste connectivité database |
| `test-supabase-auth` | Supabase Auth | Teste service auth |
| `test-supabase-storage` | Supabase Storage | Teste bucket `agentbasic-legifrance-raw` |
| `test-supabase` | Supabase (alias) | Alias de `test-supabase-db` |

### **3️⃣ Micro-service Légifrance (1 test)**
| Test ID | Nom | Description |
|---------|-----|-------------|
| `test-microservice` | Microservice Légifrance | Teste `/health` du micro-service PISTE |

---

## 🚀 Déploiement

### **Méthode 1 : Via Dashboard Supabase (Recommandé)**

1. **Se connecter au Dashboard Supabase**
   ```
   https://supabase.com/dashboard/project/joozqsjbcwrqyeqepnev/functions
   ```

2. **Créer une nouvelle Edge Function**
   - Nom : `system-tests`
   - Copier le contenu de `index.ts`

3. **Déployer**
   - Cliquer sur "Deploy"

### **Méthode 2 : Via CLI Supabase**

```bash
# Depuis le dossier DOCS-ARCHITECTURE/05-EDGE-FUNCTIONS/

# 1. Se connecter
supabase login

# 2. Lier le projet
supabase link --project-ref joozqsjbcwrqyeqepnev

# 3. Déployer la fonction
supabase functions deploy system-tests --project-ref joozqsjbcwrqyeqepnev

# 4. Vérifier le déploiement
supabase functions list
```

---

## 📡 Utilisation

### **Endpoint**
```
GET https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/system-tests
```

### **Headers requis**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

### **Query Parameters**

| Paramètre | Type | Description | Exemple |
|-----------|------|-------------|---------|
| `test` | `string` | ID du test à exécuter | `test-backend` |
| `test=all` | `string` | Exécute tous les tests | `all` (défaut) |

### **Exemples**

#### Test individuel
```bash
curl -X GET \
  'https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/system-tests?test=test-backend' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json'
```

#### Tous les tests
```bash
curl -X GET \
  'https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/system-tests?test=all' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json'
```

---

## 📥 Format de Réponse

### **Réponse complète (test individuel)**
```json
{
  "summary": "1/1 tests réussis",
  "status": "passed",
  "execution_time": "0.15s",
  "timestamp": "2025-10-11T12:34:56.789Z",
  "results": [
    {
      "name": "Backend Health",
      "status": "success",
      "message": "Backend OK: healthy",
      "details": "HTTP 200 | Temps: 150ms",
      "execution_time_ms": 150,
      "timestamp": "2025-10-11T12:34:56.789Z"
    }
  ],
  "details": "Tests système complets | Total: 150ms"
}
```

### **Réponse complète (tous les tests)**
```json
{
  "summary": "14/15 tests réussis",
  "status": "partial",
  "execution_time": "2.34s",
  "timestamp": "2025-10-11T12:34:56.789Z",
  "results": [
    {
      "name": "Backend Health",
      "status": "success",
      "message": "Backend OK: healthy",
      "details": "HTTP 200 | Temps: 150ms",
      "execution_time_ms": 150,
      "timestamp": "2025-10-11T12:34:56.789Z"
    },
    {
      "name": "Supabase DB",
      "status": "success",
      "message": "DB OK: Connectivité validée",
      "details": "Temps: 45ms",
      "execution_time_ms": 45,
      "timestamp": "2025-10-11T12:34:56.834Z"
    }
    // ... 13 autres tests
  ],
  "details": "Tests système complets | Total: 2340ms"
}
```

---

## 🔒 Sécurité

### **Authentification**
- ✅ **JWT Admin requis** : Seuls les utilisateurs avec `app_metadata.role === 'admin'` peuvent exécuter les tests
- ✅ **Service Role Key** : L'Edge Function utilise `SUPABASE_SERVICE_ROLE_KEY` pour accéder aux données sensibles
- ✅ **CORS configuré** : Autorise uniquement les origines approuvées

### **Rate Limiting**
- ⚠️ **Pas de rate limiting natif** : À implémenter si nécessaire au niveau Supabase
- 💡 **Recommandation** : Utiliser Cloudflare ou un middleware custom

---

## 📊 Monitoring

### **Logs Supabase**
```bash
# Afficher les logs en temps réel
supabase functions logs system-tests --tail

# Afficher les logs récents
supabase functions logs system-tests --limit 100
```

### **Métriques à surveiller**
- ✅ Temps d'exécution moyen par test
- ✅ Taux de succès global
- ✅ Erreurs récurrentes
- ✅ Latence réseau vers services externes

---

## 🛠️ Maintenance

### **Ajouter un nouveau test**

1. **Créer la fonction de test**
   ```typescript
   async function testMyNewFeature(): Promise<TestResult> {
     const start = Date.now()
     try {
       // Logic here
       return {
         name: 'My New Feature',
         status: 'success',
         message: 'Feature OK',
         details: `Temps: ${Date.now() - start}ms`,
         execution_time_ms: Date.now() - start,
         timestamp: new Date().toISOString()
       }
     } catch (error) {
       return {
         name: 'My New Feature',
         status: 'error',
         message: `Erreur: ${error.message}`,
         execution_time_ms: Date.now() - start,
         timestamp: new Date().toISOString()
       }
     }
   }
   ```

2. **Ajouter au mapping**
   ```typescript
   const TEST_FUNCTIONS: Record<string, () => Promise<TestResult>> = {
     // ... existing tests
     'test-my-new-feature': testMyNewFeature,
   }
   ```

3. **Redéployer**
   ```bash
   supabase functions deploy system-tests
   ```

4. **Mettre à jour le frontend**
   - Ajouter le test dans `executeAction` switch case
   - Ajouter la modale de confirmation dans `doAction`

---

## 🔄 Migration depuis Backend

### **Ancien système (Backend Render)**
```
POST https://agent-orchestrateur-backend.onrender.com/api/v3/admin/tests/run
```

### **Nouveau système (Edge Function)**
```
GET https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/system-tests?test=<ID>
```

### **Avantages**
| Critère | Ancien (Backend) | Nouveau (Edge Function) |
|---------|------------------|-------------------------|
| **Latence** | 200-500ms | 50-150ms |
| **Scalabilité** | Limitée (1 instance) | Infinie (Supabase CDN) |
| **Maintenance** | Backend à redéployer | Edge Function isolée |
| **Coût** | $7/mois Render | Gratuit (Free Tier Supabase) |
| **Disponibilité** | 99% | 99.9% |

---

## 📝 Notes

- ⚠️ **Tests mock** : Certains tests (JWT Auth, Observability, MCP, Error Handling, HTTP/2, Circuit Breaker) sont des tests mock car ils ne peuvent pas être testés directement via HTTP
- 💡 **Amélioration future** : Implémenter des tests réels pour ces fonctionnalités
- ✅ **Tests fonctionnels** : Les tests Backend Health, Security Headers, Rate Limiting, Modern API, CORS, Supabase DB/Auth/Storage, et Microservice sont des tests réels

---

## 📞 Support

Pour toute question ou problème :
1. Vérifier les logs : `supabase functions logs system-tests`
2. Tester manuellement un endpoint : `curl` ou Postman
3. Vérifier la configuration CORS et JWT

---

**Version** : 1.0.0  
**Dernière mise à jour** : 2025-10-11  
**Auteur** : ArchiReg Team

