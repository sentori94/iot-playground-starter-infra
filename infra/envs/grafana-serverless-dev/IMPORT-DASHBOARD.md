# 📥 Guide Rapide : Importer le Dashboard Grafana

## 🎯 Objectif
Importer le dashboard "IoT Serverless - DynamoDB Data" en 2 minutes chrono !

---

## ✅ Prérequis

1. ✅ Les tables Athena sont créées (via Terraform)
2. ✅ Le datasource Athena affiche "Success" dans Grafana
3. ✅ Le fichier `dashboard-iot-serverless.json` existe

---

## 🚀 Import en 3 Étapes

### Étape 1 : Ouvrir le menu d'import

Dans Grafana :
1. Cliquer sur **"+"** (menu de gauche)
2. Sélectionner **"Import"**

### Étape 2 : Importer le fichier JSON

1. Cliquer sur **"Upload JSON file"**
2. Sélectionner le fichier : `dashboard-iot-serverless.json`
3. Ou **copier-coller** le contenu JSON directement dans la zone de texte

### Étape 3 : Configurer et importer

1. **Name** : `IoT Serverless - DynamoDB Data` (pré-rempli)
2. **Folder** : `General` (ou sélectionner un dossier existant)
3. **UID** : `iot-serverless-dynamodb` (pré-rempli)
4. **Datasources** :
   - **Athena-DynamoDB** : Sélectionner votre datasource Athena
   - **CloudWatch** : Sélectionner votre datasource CloudWatch
5. Cliquer sur **"Import"**

---

## 🎉 C'est Fini !

Le dashboard est maintenant disponible dans Grafana avec **7 panels** :

1. 📊 **Runs par Statut** (Pie Chart)
2. 📋 **Derniers Runs** (Table)
3. 📈 **Sensor Readings** (Time Series)
4. 📊 **Sensor Data par Type** (Bar Chart)
5. 📋 **Statistiques par Sensor** (Table)
6. 📈 **Lambda Invocations** (CloudWatch)
7. 📈 **Custom Metrics** (CloudWatch)

---

## 🐛 Troubleshooting

### Le dashboard affiche "No data"

**Cause :** Pas encore de données dans DynamoDB

**Solution :**
1. Vérifier qu'Athena peut lire les tables :
   ```sql
   SELECT COUNT(*) FROM runs;
   SELECT COUNT(*) FROM sensor_data;
   ```
2. Si les tables sont vides, ajouter des données de test (voir `ATHENA-TEST-QUERIES.md`)

### Le datasource "athena-dynamodb" n'est pas trouvé

**Cause :** L'UID du datasource ne correspond pas

**Solution :**
1. Aller dans **Configuration → Data sources**
2. Cliquer sur votre datasource Athena
3. Vérifier l'UID (en bas de la page)
4. Si différent de `athena-dynamodb`, éditer le dashboard JSON avant import :
   - Remplacer `"uid": "athena-dynamodb"` par votre UID

### Les requêtes Athena échouent

**Cause :** Problème de configuration Athena

**Solution :**
1. Tester les requêtes dans **AWS Athena Console** d'abord
2. Vérifier que le workgroup est bien configuré : `iot-playground-grafana-grafana-serverless-dev`
3. Voir `ATHENA-TEST-QUERIES.md` pour les tests

---

## 📝 Personnalisation

Après import, vous pouvez :
- ✏️ Modifier les requêtes SQL
- 🎨 Changer les visualisations
- 📊 Ajouter de nouveaux panels
- 💾 **Sauvegarder** les modifications

---

## 🔗 Fichiers Utiles

- `dashboard-iot-serverless.json` - Le dashboard à importer
- `ATHENA-TEST-QUERIES.md` - Requêtes pour tester Athena
- `MANUEL-DASHBOARD-SETUP.md` - Guide complet de création manuelle

---

**Import terminé ! Votre dashboard est prêt ! 🎉**

