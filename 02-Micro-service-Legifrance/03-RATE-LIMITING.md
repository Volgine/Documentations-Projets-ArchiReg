# ⏱️ RATE LIMITING - QUOTAS PISTE

**Date** : 15 octobre 2025  
**Stratégie** : Différenciation CNIL vs Standard  
**Status** : ✅ CONFIGURÉ ET ACTIF

---

## 📊 QUOTAS OFFICIELS LÉGIFRANCE PISTE

### **Documentation Officielle**

Source : `docs/docs-officiel-legifrance/Restristriction de quota precis.md`

**TOUS les endpoints ont 2 quotas simultanés** :

```
Throttle 280000 message(s) every 1 day(s)   # Standard
Throttle 40 message(s) every 1 second(s)    # CNIL boost
Throttle 24000 message(s) every 1 hour(s)   # Global
Throttle 1000000 message(s) every 1 day(s)  # CNIL total
Throttle 20 message(s) every 1 second(s)    # Standard
```

### **Interprétation**

| Catégorie | Rate (req/s) | Quota Jour | Quota Heure |
|-----------|--------------|------------|-------------|
| **CNIL endpoints** | 40 req/s | 1,000,000 | 24,000 |
| **Standard endpoints** | 20 req/s | 280,000 | 24,000 |
| **TOTAL COMBINÉ** | 60 req/s | 1,280,000 | 24,000 |

---

## 🔧 IMPLÉMENTATION

### **Classe DifferentiatedRateLimiter**

**Fichier** : `app/utils/rate_limiter.py`

```python
class DifferentiatedRateLimiter:
    def __init__(self):
        # CNIL endpoints (40 req/s)
        self.cnil_limiter = SlidingWindowRateLimiter(40, window_size=1)
        self.cnil_quota_monitor = QuotaMonitor(1_000_000)
        
        # Standard endpoints (20 req/s)
        self.standard_limiter = SlidingWindowRateLimiter(20, window_size=1)
        self.standard_quota_monitor = QuotaMonitor(280_000)
    
    def _is_cnil_endpoint(self, endpoint: str) -> bool:
        """Détecte endpoints CNIL"""
        return endpoint in [
            "/consult/getCnilWithAncienId",
            "/consult/cnil"
        ]
    
    async def acquire(self, endpoint: str) -> bool:
        """Route vers bon limiter selon endpoint"""
        if self._is_cnil_endpoint(endpoint):
            # Route CNIL (40 req/s)
            await self.cnil_limiter.acquire()
            await self.cnil_quota_monitor.record_request()
        else:
            # Route Standard (20 req/s)
            await self.standard_limiter.acquire()
            await self.standard_quota_monitor.record_request()
```

---

### **Classe SlidingWindowRateLimiter**

```python
class SlidingWindowRateLimiter:
    """
    Fenêtre glissante pour respect précis des quotas
    """
    def __init__(self, max_requests_per_second: int):
        self.max_requests_per_second = max_requests_per_second
        self.request_times: deque = deque()
    
    async def acquire(self) -> bool:
        """
        Bloque si rate limit atteint
        Calcule temps d'attente optimal
        """
        # Nettoie requêtes anciennes (> 1 seconde)
        # Vérifie si sous la limite
        # Attend si nécessaire
        # Enregistre requête
```

---

### **Classe QuotaMonitor**

```python
class QuotaMonitor:
    """
    Surveillance quotas journaliers
    Alerte à 93.75% du quota
    """
    def __init__(self, max_daily_requests: int):
        self.max_daily_requests = max_daily_requests
        self.alert_threshold = int(max_daily_requests * 0.9375)
        self.daily_count = 0
    
    async def can_make_request(self) -> bool:
        """Vérifie quotas + reset journalier"""
        # Reset si nouveau jour
        # Vérifie < max_daily
        # Alerte si > 93.75%
    
    async def record_request(self):
        """Enregistre requête + log tous les 10k"""
```

---

## 📈 STRATÉGIE PAR MODE

### **Mode MAINTENANCE** (Actuel)

```python
Rate utilisé : 20 req/s (Standard)
Quota/jour   : ~1,000-2,000 req (0.7% du quota)
Codes        : 5 codes × 50 articles
Articles/run : ~250 articles
Runs/jour    : 12 runs (CRON 2h)
Total/jour   : ~3,000 articles
```

**Seuil alerte** : 262,500 req/jour (93.75% de 280k)  
**Marge** : ~260k req/jour libres ✅

---

### **Mode MASSIVE**

```python
Rate utilisé : 60 req/s (40 CNIL + 20 Standard combinés)
Quota/jour   : ~720,000-1,200,000 req (90% du quota)
Codes        : 20 codes × 100 articles
Articles/run : ~1,000-5,000 articles
Runs/jour    : 144 runs (interval 10 min)
Total/jour   : ~50,000-100,000 articles
```

**Seuil alerte** : 1,200,000 req/jour (93.75% de 1.28M)  
**Marge** : ~80k req/jour libres ✅

---

## 🚨 ALERTES & MONITORING

### **Log Périodique**

```python
# Tous les 10,000 requêtes
if self.daily_count % 10000 == 0:
    progress = (self.daily_count / self.max_daily_requests) * 100
    logger.info("📈 Progression quotas",
               daily_count=self.daily_count,
               progress_percent=round(progress, 1))
```

### **Alerte 93.75%**

```python
if self.daily_count >= self.alert_threshold:
    logger.warning("⚠️ SEUIL D'ALERTE QUOTAS ATTEINT",
                 remaining=self.max_daily_requests - self.daily_count)
```

### **Blocage 100%**

```python
if self.daily_count >= self.max_daily_requests:
    logger.error("🚫 QUOTA JOURNALIER DÉPASSÉ")
    return False  # Bloque toutes les requêtes
```

---

## 🔄 GESTION ERREURS 429

### **Backoff Exponentiel**

```python
async def handle_rate_limit_error(self, retry_after: int = None):
    """
    Gère erreur 429 Too Many Requests
    """
    if retry_after:
        # Respect Retry-After header API
        self.backoff_delay = retry_after
    else:
        # Backoff exponentiel (max 5 min)
        self.backoff_delay = min(self.backoff_delay * 2 or 30, 300)
    
    logger.warning("🚫 Rate limit 429 - Backoff", delay=self.backoff_delay)
```

---

## 📊 STATISTIQUES TEMPS RÉEL

### **Endpoint** : `GET /rate-limit/stats`

**Réponse** :
```json
{
  "cnil": {
    "rate_limit": 40,
    "quota_stats": {
      "daily_count": 150,
      "remaining": 999850,
      "progress_percent": 0.015
    }
  },
  "standard": {
    "rate_limit": 20,
    "quota_stats": {
      "daily_count": 62,
      "remaining": 279938,
      "progress_percent": 0.02
    }
  }
}
```

---

## 🎯 Résumé

**Rate limiting intelligent** :
- ✅ Différenciation CNIL (40) vs Standard (20)
- ✅ Quotas journaliers surveillés
- ✅ Alerte à 93.75%
- ✅ Blocage à 100%
- ✅ Backoff exponentiel sur 429
- ✅ Fenêtre glissante précise

**Protection anti-ban garantie !** 🔒

