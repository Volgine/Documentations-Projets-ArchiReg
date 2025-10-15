# 💾 PERSISTANCE ÉTAT SCHEDULER

**Date** : 15 octobre 2025  
**Version** : 2.4.0  
**Fichier** : `/tmp/scheduler_state.json`  
**Status** : ✅ FONCTIONNEL

---

## 🎯 Principe

Le scheduler **se rappelle de son état** après un crash/redémarrage :
- ✅ Running ou Stopped ?
- ✅ Mode MASSIVE ou MAINTENANCE ?

```json
{
  "running": true,
  "mode": "MAINTENANCE"
}
```

---

## 🔄 WORKFLOW COMPLET

### **1. Démarrage Service**

**Fichier** : `app/main.py` (ligne 60-76)

```python
# Création scheduler
scheduler = CollectorScheduler(legifrance_service, supabase_service)

# 💾 CHARGEMENT ÉTAT SAUVEGARDÉ
saved_state = SchedulerStateManager.load_state()

# Restaurer le mode
scheduler.siphonnage_mode = saved_state.get("mode", "MAINTENANCE")

# Redémarrer si l'état était RUNNING
if saved_state.get("running", False):
    await scheduler.start()  # ✅ Redémarre automatiquement
    logger.info("🔄 Scheduler REDÉMARRÉ automatiquement", mode=...)
else:
    logger.info("⏸️ Scheduler créé - en attente START", mode=...)
```

---

### **2. Actions Utilisateur**

#### **START** (`/aspirage/start` ligne 274)
```python
await scheduler.start()
# 💾 SAUVEGARDER L'ÉTAT
SchedulerStateManager.save_state(running=True, mode=scheduler.siphonnage_mode)
```

#### **STOP** (`/aspirage/stop` ligne 309)
```python
await scheduler.stop()
# 💾 SAUVEGARDER L'ÉTAT
SchedulerStateManager.save_state(running=False, mode=scheduler.siphonnage_mode)
```

#### **CHANGE MODE** (`/siphonnage/mode` ligne 517)
```python
scheduler.siphonnage_mode = new_mode
# 💾 SAUVEGARDER L'ÉTAT
SchedulerStateManager.save_state(
    running=scheduler.is_running(),
    mode=new_mode
)
```

---

### **3. Shutdown Propre**

**Fichier** : `app/main.py` (ligne 135-148)

```python
# Avant arrêt du service
was_running = scheduler.is_running()
current_mode = scheduler.siphonnage_mode

# 💾 SAUVEGARDER AVANT ARRÊT
SchedulerStateManager.save_state(
    running=was_running,
    mode=current_mode
)

await scheduler.stop()
```

---

## 📁 GESTIONNAIRE D'ÉTAT

### **Classe SchedulerStateManager**

**Fichier** : `app/scheduler/scheduler_state.py`

```python
class SchedulerStateManager:
    """Persistance simple via JSON"""
    
    @staticmethod
    def save_state(running: bool, mode: str):
        """Sauvegarde dans /tmp/scheduler_state.json"""
        state = {"running": running, "mode": mode}
        with open("/tmp/scheduler_state.json", "w") as f:
            json.dump(state, f)
    
    @staticmethod
    def load_state() -> Dict:
        """Charge état ou retourne défaut si absent"""
        if not Path("/tmp/scheduler_state.json").exists():
            return {
                "running": os.getenv("ENABLE_SCHEDULER", "false") == "true",
                "mode": os.getenv("SIPHONNAGE_MODE", "MAINTENANCE")
            }
        
        with open("/tmp/scheduler_state.json", "r") as f:
            return json.load(f)
    
    @staticmethod
    def clear_state():
        """Supprime fichier (reset complet)"""
        os.remove("/tmp/scheduler_state.json")
```

---

## 🎯 SCÉNARIOS D'UTILISATION

### **Scénario 1 : Premier Démarrage**
```
1. Boot service → Fichier state absent
2. Load state → Défaut {running: false, mode: MAINTENANCE}
3. Scheduler créé mais PAS démarré
4. Frontend → START → Démarre + Save {running: true}
```

### **Scénario 2 : Crash en Production**
```
1. Service running → Collecte en cours
2. Crash/Redémarrage inopiné
3. Boot service → Lit state {running: true, mode: MASSIVE}
4. Redémarre AUTO en mode MASSIVE ✅
5. Continue collecte sans perte
```

### **Scénario 3 : Arrêt Manuel**
```
1. Service running
2. Frontend → STOP → Arrête + Save {running: false}
3. Crash/Redémarrage
4. Boot service → Lit state {running: false}
5. RESTE ARRÊTÉ (pas de redémarrage auto) ✅
```

### **Scénario 4 : Changement Mode**
```
1. Service en MAINTENANCE running
2. Frontend → MODE MASSIVE → Save {running: true, mode: MASSIVE}
3. Crash/Redémarrage
4. Redémarre AUTO en MASSIVE ✅
```

---

## 🔒 SÉCURITÉ RENDER

### **Pourquoi /tmp/ ?**

```bash
/app/       → Read-only sur Render (code déployé)
/tmp/       → Read-write autorisé (fichiers temporaires)
```

**Alternative refusée** :
```python
# ❌ NE MARCHE PAS SUR RENDER
state_file = "/app/scheduler_state.json"  # Read-only !

# ✅ MARCHE SUR RENDER
state_file = "/tmp/scheduler_state.json"  # Read-write ✅
```

---

## 📊 MONITORING

### **Vérifier État Actuel**

```http
GET /aspirage/status

Response:
{
  "running": true,
  "mode": "MAINTENANCE",
  "massive_active": false,
  "timestamp": "2025-10-15T15:00:00Z"
}
```

### **Logs Démarrage**

```
[info] 💾 État scheduler sauvegardé avant arrêt
       running=true, mode=MAINTENANCE

[info] ✅ État scheduler chargé
       state={'running': True, 'mode': 'MAINTENANCE'}

[info] 🔄 Scheduler REDÉMARRÉ automatiquement
       mode=MAINTENANCE
       reason=État sauvegardé indique running=true
```

---

## ✅ AVANTAGES

1. **Résilience** : Survit aux crashs/redémarrages
2. **Simplicité** : 1 fichier JSON, 3 méthodes
3. **Performance** : Lecture/écriture instantanée
4. **Contrôle** : Frontend maître de l'état
5. **Compatibilité** : Fonctionne sur Render

---

## 🎉 Résumé

**Persistance intelligente** :
- ✅ Sauvegarde à chaque action (START/STOP/MODE)
- ✅ Chargement au boot
- ✅ Redémarrage auto si crash
- ✅ Compatible Render (/tmp/)
- ✅ Format JSON simple

**Le scheduler ne perd jamais son état !** 💾

