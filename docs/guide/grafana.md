# Monitoring avec Grafana

Cette page explique comment Grafana est utilisé pour observer les simulations, sans entrer dans les détails de configuration.

## 🎯 Rôle de Grafana

Grafana sert d'interface unique pour :
- Visualiser l'évolution des températures dans le temps
- Filtrer par **Run**, **User** et **Sensor**
- Comparer des simulations côté ECS et côté Serverless

## 📊 Dashboards

Deux grandes familles de dashboards :

1. **Dashboard ECS (Prometheus)**  
   - Datasource : Prometheus
   - Focus sur : métriques techniques JVM, requêtes HTTP, status codes, etc.
   - Sert surtout à analyser le comportement de l'application Spring Boot.

2. **Dashboard Serverless (CloudWatch)**  
   - Datasource : CloudWatch Logs / Metrics
   - Focus sur :
     - Nombre de runs démarrés / terminés
     - Volume de données capteur ingérées
     - Latence et erreurs des Lambdas
     - Température moyenne par run / sensor / user

## 🌐 Accès

- **Frontend** : `https://app-iot.sentori-studio.com` propose des liens directs vers les dashboards
- **Grafana Serverless** : exposé via un ALB avec HTTPS, accessible sur un sous-domaine dédié

L'utilisateur n'a pas besoin de connaître l'URL exacte : le frontend injecte déjà l'URL Grafana liée au run dans les réponses de l'API.

## 🔍 Points intéressants à présenter en entretien

- La **différence de datasource** illustre bien la séparation ECS vs Serverless :
  - Prometheus côté ECS
  - CloudWatch côté Serverless
- Les dashboards sont construits autour des mêmes dimensions métier : user, run, sensor.
- L'URL Grafana est renvoyée par l'API `/api/runs/start`, ce qui montre l'intégration forte entre backend et observabilité.

En résumé, Grafana est la "vitre" qui permet de voir ce qui se passe derrière les deux architectures, avec un focus métier plutôt que purement technique.
