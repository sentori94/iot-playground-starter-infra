# Démarrage Rapide

Cette section explique **comment l’utilisateur final utilise la plateforme**, sans entrer dans les détails techniques (pas de commandes, pas de prérequis).

## 🎯 Parcours Utilisateur (Mode Serverless)

1. **Accès au frontend**  
   L’utilisateur ouvre l’interface sur `https://app-iot.sentori-studio.com/`.

2. **Choix du mode**  
   Sur l’écran d’accueil, il peut choisir entre :
   - **Mode ECS** : backend Spring Boot sur ECS + PostgreSQL
   - **Mode Serverless** : backend Lambda + DynamoDB

3. **Création d’une simulation (Run)**  
   En mode Serverless :
   - L’utilisateur indique une **durée** (ex: 60 secondes)
   - Un **intervalle** (ex: 5 secondes entre chaque mesure)
   - Il lance la simulation via un bouton du type "Start Simulation".

   En arrière-plan, le frontend appelle l’API `/api/runs/start` qui :
   - Vérifie qu’on ne dépasse pas le **nombre max de simulations concurrentes** (5)
   - Crée un run dans DynamoDB avec l’état `RUNNING`
   - Retourne un identifiant de run et une URL Grafana associée.

4. **Ingestion des données capteurs**  
   Le frontend (ou un simulateur côté client) envoie régulièrement des mesures pour ce run :
   - Température
   - (éventuellement) Humidité, pression, etc.

   Ces mesures sont stockées dans la table `SensorData` en DynamoDB et loggées dans CloudWatch pour le monitoring.

5. **Visualisation dans Grafana**  
   L’interface propose un lien direct vers le dashboard Grafana correspondant :
   - Vue globale de toutes les températures
   - Filtres par **Run**, **User** et **Sensor**
   - Possibilité de comparer plusieurs runs entre eux.

6. **Fin ou interruption de la simulation**  
   L’utilisateur peut :
   - Laisser la simulation aller jusqu’au bout (durée configurée)
   - La terminer explicitement ("Finish Run")
   - Interrompre toutes les simulations en cours ("Interrupt All")

   Côté backend, l’état du run passe à `COMPLETED`, `FAILED` ou `INTERRUPTED`.

## 🧭 Parcours Utilisateur (Mode ECS)

Le parcours est volontairement **identique** côté frontend :
- Même écrans
- Même endpoints REST
- Même concepts (Runs, Sensors, Users)

La différence est **strictement technique** :
- Les requêtes partent vers l’API ECS (Spring Boot + PostgreSQL)
- Le monitoring passe par Prometheus + Grafana

Cela permet, en entretien, de montrer :
- Que le **contrat fonctionnel** est le même
- Que seule l’implémentation backend change (ECS vs Serverless)

## 🧠 Ce qu’il faut retenir pour l’entretien

- Le projet **ne force pas le lecteur** à exécuter des commandes : tout est pilotable par l’UI.
- Le frontend masque la complexité (Terraform, CI/CD, AWS), l’utilisateur voit juste :
  - Choix du mode (ECS / Serverless)
  - Création et suivi de simulations
  - Visualisation dans Grafana
- C’est donc un **bac à sable IoT** pour comparer deux architectures cloud en conditions quasi réelles, avec :
  - Les mêmes écrans
  - Les mêmes APIs
  - Des stacks techniques radicalement différentes sous le capot.
