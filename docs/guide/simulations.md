# Gestion des simulations

Cette page décrit la logique métier autour des **simulations (runs)**, vue côté utilisateur et côté architecture.

## 🧩 Concepts clés

- **Run** : une simulation de capteurs sur une période donnée (ex: 60s avec une mesure toutes les 5s)
- **Sensor** : un capteur logique (température, multi-mesures, etc.)
- **User** : actuellement, tous les utilisateurs partagent la même "piscine" de runs (limite globale à 5), mais le header `X-User` permet de tracer qui a lancé quoi.

## 🎮 Actions possibles

Depuis le frontend, l'utilisateur peut :

1. **Vérifier s'il peut démarrer une simulation**  
   → Endpoint `/api/runs/can-start` qui renvoie :
   - `canStart` (booléen)
   - `currentRunning` (nombre de runs actifs)
   - `maxAllowed` (limite globale, 5)

2. **Démarrer une simulation**  
   → `/api/runs/start` avec la durée et l'intervalle. Le backend :
   - Vérifie la limite
   - Crée un run `RUNNING` dans la base (PostgreSQL ou DynamoDB selon le mode)
   - Génère une URL Grafana pré-filtrée sur ce run

3. **Lister les simulations en cours**  
   → `/api/runs/running` pour voir les runs `RUNNING`.

4. **Terminer une simulation**  
   → `/api/runs/{id}/finish` pour passer le run à `COMPLETED`.

5. **Interrompre toutes les simulations**  
   → `/api/runs/interrupt-all` qui met à jour tous les runs `RUNNING` vers `INTERRUPTED`.

## 🔁 Cycle de vie d'un run

États principaux d'un run :

- `RUNNING` : simulation active
- `COMPLETED` : s'est terminée normalement
- `FAILED` : erreur (ex: problème technique)
- `INTERRUPTED` : arrêt manuel via l'API

En entretien, tu peux insister sur le fait que **cette logique métier est identique** en ECS et en Serverless, ce qui renforce la comparaison technique entre les deux architectures.

## 🧠 Points intéressants à mentionner

- La **limite globale à 5 runs** illustre la gestion d'un quota simple côté backend.
- `X-User` est déjà en place pour préparer une évolution vers des quotas par utilisateur.
- Chaque run est lié à une **URL Grafana** spécifique, ce qui crée un pont clair entre la couche métier et l'observabilité.
