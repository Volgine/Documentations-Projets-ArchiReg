# 🚀 Déploiement Edge Function `system-tests`

---

## 📋 Résumé

Une **nouvelle Edge Function Supabase** a été créée pour remplacer **tous les tests backend** et les centraliser dans une fonction **propre, sécurisée et scalable**.

---

## 🎯 Objectifs

| Critère | Avant (Backend Render) | Après (Edge Function) |
|---------|------------------------|------------------------|
| **Latence** | 200-500ms | 50-150ms ⚡ |
| **Scalabilité** | 1 instance Render | Infini (Supabase CDN) 🌐 |
| **Coût** | $7/mois | Gratuit 💰 |
| **Maintenance** | Backend à redéployer | Edge Function isolée 🔧 |
| **Disponibilité** | 99% | 99.9% ✅ |
| **Sécurité** | Auth backend | JWT Admin requis 🔒 |

---

## 📂 Fichiers Créés

| Fichier | Description |
|---------|-------------|
| `DOCS-ARCHITECTURE/05-EDGE-FUNCTIONS/system-tests/index.ts` | Code TypeScript de l'Edge Function |
| `DOCS-ARCHITECTURE/05-EDGE-FUNCTIONS/system-tests/README.md` | Documentation complète |
| `DOCS-ARCHITECTURE/DEPLOIEMENT-SYSTEM-TESTS.md` | Ce fichier (guide déploiement) |

---

## 🔧 Modifications Frontend

### **Fichier modifié**
- `ArchiReg-Front/pages/admin.tsx`

### **Changements**
1. ✅ **Route unifiée** : Tous les tests appellent maintenant `${SUPABASE_URL}/functions/v1/system-tests?test=<ID>`
2. ✅ **JWT Auth** : Le token JWT est automatiquement passé dans l'Authorization header
3. ✅ **Gestion de réponse** : Le format de réponse de l'Edge Function est correctement parsé
4. ✅ **Fallback** : Si l'Edge Function échoue, un message d'erreur clair est affiché

---

## 🚀 Étapes de Déploiement

### **ÉTAPE 1 : Déployer l'Edge Function sur Supabase**

#### **Option A : Via Dashboard Supabase (Recommandé)**

1. **Se connecter au Dashboard**
   ```
   https://supabase.com/dashboard/project/joozqsjbcwrqyeqepnev/functions
   ```

2. **Créer une nouvelle Edge Function**
   - Cliquer sur **"New Edge Function"**
   - Nom : `system-tests`

3. **Copier le code**
   - Ouvrir `DOCS-ARCHITECTURE/05-EDGE-FUNCTIONS/system-tests/index.ts`
   - Copier **TOUT** le contenu (558 lignes)
   - Coller dans l'éditeur Supabase

4. **Déployer**
   - Cliquer sur **"Deploy"**
   - Attendre confirmation

5. **Vérifier**
   - Aller dans **"Functions" > "system-tests"**
   - Vérifier que le statut est **"Active"**

#### **Option B : Via CLI Supabase (Avancé)**

```bash
# Depuis le dossier DOCS-ARCHITECTURE/05-EDGE-FUNCTIONS/

# 1. Installer la CLI Supabase (si pas déjà fait)
npm install -g supabase

# 2. Se connecter
supabase login

# 3. Lier le projet
supabase link --project-ref joozqsjbcwrqyeqepnev

# 4. Déployer la fonction
supabase functions deploy system-tests --project-ref joozqsjbcwrqyeqepnev

# 5. Vérifier le déploiement
supabase functions list
```

---

### **ÉTAPE 2 : Vérifier la configuration Supabase**

1. **Variables d'environnement**
   - Aller dans **"Project Settings" > "Edge Functions"**
   - Vérifier que ces variables existent :
     - `SUPABASE_URL`
     - `SUPABASE_SERVICE_ROLE_KEY`
     - `BACKEND_URL` (optionnel, défaut : `https://agent-orchestrateur-backend.onrender.com`)
     - `MICROSERVICE_URL` (optionnel, défaut : `https://micro-service-data-legifrance-piste.onrender.com`)
     - `FRONTEND_URL` (optionnel, défaut : `https://archireg-front.vercel.app`)

2. **Permissions**
   - Aller dans **"Database" > "Policies"**
   - Vérifier que les RLS sont bien configurées pour `files_queue`

---

### **ÉTAPE 3 : Tester l'Edge Function**

#### **Test manuel via cURL**

```bash
# Récupérer ton JWT token depuis le frontend
# Tu peux l'obtenir en ouvrant la console navigateur et tapant:
# supabase.auth.getSession()

# Remplace <JWT_TOKEN> par ton token
curl -X GET \
  'https://joozqsjbcwrqyeqepnev.supabase.co/functions/v1/system-tests?test=test-backend' \
  -H 'Authorization: Bearer <JWT_TOKEN>' \
  -H 'Content-Type: application/json'
```

#### **Résultat attendu**
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
  ]
}
```

---

### **ÉTAPE 4 : Déployer le Frontend**

```bash
# Depuis le dossier ArchiReg-Front/

npx vercel --prod --yes
```

---

### **ÉTAPE 5 : Vérifier dans le Frontend**

1. **Se connecter au frontend**
   ```
   https://archireg-front.vercel.app
   Email: test@example.com
   Password: 123456
   ```

2. **Aller dans "Système > Actions"**

3. **Exécuter chaque test**
   - Cliquer sur **"Test Backend"**
   - Vérifier que le résultat est **✅ Backend OK**
   - Répéter pour tous les tests

4. **Vérifier les détails**
   - Chaque test doit afficher un message clair
   - Les détails doivent inclure le temps d'exécution
   - Aucun test ne doit afficher "Aucun détail disponible"

---

## 🧪 Liste des Tests à Vérifier

| Test | Nom | Résultat Attendu |
|------|-----|------------------|
| ✅ | Test Backend | `✅ Backend OK: healthy` |
| ✅ | Test Supabase DB | `✅ DB OK: Connectivité validée` |
| ✅ | Test Supabase Auth | `✅ Auth OK: Service opérationnel` |
| ✅ | Test Supabase Storage | `✅ Storage OK: Bucket accessible` |
| ✅ | Test Security Headers | `✅ Headers OK: OWASP 2025 conformes` |
| ✅ | Test Rate Limiting | `✅ Rate Limiting OK: ...` |
| ✅ | Test JWT Auth | `✅ JWT Auth OK: Protection active` |
| ✅ | Test Modern API | `✅ Modern API OK: ...` |
| ✅ | Test Observability | `✅ Observability OK: Logging structuré actif` |
| ✅ | Test MCP Integration | `✅ MCP OK: Protection MCP active` |
| ✅ | Test Error Handling | `✅ Error Handling OK: Gestion erreurs active` |
| ✅ | Test HTTP/2 | `✅ HTTP/2 OK: Hypercorn configuré` |
| ✅ | Test CORS | `✅ CORS OK: ...` |
| ✅ | Test Microservice | `✅ Micro-service OK: ...` |
| ✅ | Test Circuit Breaker | `✅ Circuit Breaker OK: Protection active` |

---

## 🔍 Debugging

### **Si l'Edge Function ne fonctionne pas**

1. **Vérifier les logs Supabase**
   ```bash
   supabase functions logs system-tests --tail
   ```

2. **Vérifier CORS**
   - Aller dans le Dashboard Supabase
   - Vérifier que `Access-Control-Allow-Origin: *` est bien défini

3. **Vérifier Auth**
   - Vérifier que l'utilisateur est bien admin
   - Vérifier que le JWT token est valide

### **Si un test spécifique échoue**

1. **Test Backend Health**
   - Vérifier que `https://agent-orchestrateur-backend.onrender.com/api/v3/health` répond

2. **Test Supabase DB/Auth/Storage**
   - Vérifier les permissions RLS
   - Vérifier que `SUPABASE_SERVICE_ROLE_KEY` est correctement définie

3. **Test Microservice**
   - Vérifier que `https://micro-service-data-legifrance-piste.onrender.com/health` répond

---

## 📊 Monitoring

### **Métriques à surveiller**

| Métrique | Comment vérifier |
|----------|------------------|
| **Temps d'exécution** | Dashboard Supabase > Functions > system-tests > Metrics |
| **Taux de succès** | Frontend > Système > Actions |
| **Erreurs** | `supabase functions logs system-tests` |
| **Latence** | Dashboard Supabase > Functions > system-tests > Performance |

---

## 🧹 Nettoyage Backend (Optionnel)

Une fois l'Edge Function déployée et testée, tu peux **supprimer** les anciens endpoints backend :

### **Fichiers à supprimer**
```
Agent-Orchestrator/backend/api/v3/admin.py  ✅ DÉJÀ SUPPRIMÉ
Agent-Orchestrator/backend/api/v3/cron.py   ✅ DÉJÀ SUPPRIMÉ
```

### **Fichiers à modifier**
- `Agent-Orchestrator/backend/main.py` : **Déjà fait** (routers commentés)

---

## 📝 Checklist de Déploiement

- [ ] Edge Function créée dans Dashboard Supabase
- [ ] Code copié depuis `index.ts`
- [ ] Edge Function déployée avec succès
- [ ] Variables d'environnement vérifiées
- [ ] Test manuel cURL réussi
- [ ] Frontend redéployé sur Vercel
- [ ] Tous les 15 tests vérifiés dans le frontend
- [ ] Aucun test n'affiche "Aucun détail disponible"
- [ ] Logs Supabase vérifiés (aucune erreur)
- [ ] Documentation lue et comprise

---

## 🎉 Résultat Final

Une fois toutes les étapes terminées :
- ✅ **15 tests système** fonctionnels
- ✅ **Latence < 150ms** par test
- ✅ **Sécurité renforcée** (JWT Admin)
- ✅ **Architecture propre** (Edge Function isolée)
- ✅ **Coût réduit** (gratuit Supabase)
- ✅ **Scalabilité infinie** (Supabase CDN)

---

**Version** : 1.0.0  
**Date** : 2025-10-11  
**Auteur** : ArchiReg Team 🚀

