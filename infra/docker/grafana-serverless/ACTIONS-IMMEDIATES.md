# 🚨 ACTIONS IMMÉDIATES À FAIRE

## Problème 1 : Athena "No output location"

**Cause :** Le workgroup Athena n'a pas été mis à jour par Terraform.

### ✅ Solution Rapide (2 minutes) - AWS Console

1. **AWS Console** → **Athena**
2. En haut à droite, cliquer sur **"Workgroup"**
3. Chercher et sélectionner : `iot-playground-grafana-grafana-serverless-dev`
4. Cliquer sur **"Edit"**
5. Dans la section **"Query result location"**, entrer :
   ```
   s3://iot-playground-athena-results-grafana-serverless-dev/results/
   ```
6. ✅ Cocher **"Override client-side settings"**
7. Cliquer sur **"Save changes"**

**C'EST TOUT !** Maintenant `SHOW TABLES;` fonctionnera.

---

## Problème 2 : Pas de dashboard dans Grafana

**Cause :** L'image Docker n'a pas encore été rebuildée avec le nouveau Dockerfile.

### ✅ Solution (5 minutes) - GitHub Actions

1. **Commit et push** vos modifications actuelles
2. **GitHub** → **Actions**
3. Workflow : **"Build & Push Grafana Serverless Image"**
4. **Run workflow**
5. Attendre 4-5 minutes
6. Le service ECS redémarrera automatiquement avec la nouvelle image

**Résultat :**
- ✅ Plugin Athena installé
- ✅ Dashboard visible dans Grafana
- ✅ Tables Athena créées automatiquement

---

## Vérification Finale

### Dans Athena Console (après étape 1) :

```sql
SHOW TABLES;
```

**Doit afficher :**
```
runs
sensor_data
```

### Dans Grafana (après étape 2) :

1. **Dashboards** (menu gauche)
2. Chercher : **"IoT Serverless - DynamoDB Data"**
3. Le dashboard doit être là avec 7 panels

---

## Alternative Temporaire

Si vous voulez tester Athena MAINTENANT sans attendre :

**Dans Athena Console :**
1. Sélectionner workgroup : **"primary"** (au lieu du workgroup custom)
2. Lancer vos requêtes → Ça fonctionnera immédiatement

---

## Ordre d'Exécution

1. ✅ **D'abord** : Corriger le workgroup Athena (AWS Console - 2 min)
2. ✅ **Ensuite** : Rebuilder l'image Grafana (GitHub Actions - 5 min)
3. ✅ **Enfin** : Profiter ! 🎉

