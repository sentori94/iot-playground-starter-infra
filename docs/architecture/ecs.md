# Architecture ECS (Classic)

## 🎯 Vue d'ensemble

L'architecture ECS représente l'approche traditionnelle avec des **conteneurs Docker** qui tournent en permanence sur AWS Fargate. Cette architecture est adaptée aux applications nécessitant une latence constante et prévisible, avec des connexions persistantes vers la base de données.

## 🏗️ Composants Principaux

### ECS Fargate
Les conteneurs Spring Boot tournent sur **Fargate** (serverless containers) sans avoir à gérer les instances EC2. Chaque tâche ECS a 0.5 vCPU et 1 GB de mémoire, suffisant pour l'application IoT Playground.

### RDS PostgreSQL
Base de données relationnelle **PostgreSQL** hébergée sur RDS dans un subnet privé. Elle stocke :
- **Table `runs`** : Métadonnées des simulations
- **Table `sensor_data`** : Données des capteurs avec relations (foreign keys vers runs)

### Application Load Balancer (ALB)
L'ALB distribue le trafic HTTPS vers les conteneurs ECS. Il gère :
- Terminaison SSL/TLS avec certificat ACM
- Health checks vers `/actuator/health`
- Sticky sessions (optionnel)

### Monitoring avec Prometheus
Un conteneur Prometheus tourne sur ECS et scrape les métriques Spring Boot exposées sur `/actuator/prometheus`. Ces métriques incluent :
- Métriques JVM (heap, threads, GC)
- Métriques HTTP (requêtes, latence, erreurs)
- Métriques custom (runs actifs, données capteurs)

### Grafana
Un conteneur Grafana interroge Prometheus et affiche des dashboards temps réel. Grafana est accessible via un domaine personnalisé avec certificat HTTPS.

## 🔄 Flux de Données

1. **Requête entrante** : Le frontend envoie une requête HTTPS vers l'ALB
2. **Routage** : L'ALB route vers un conteneur ECS disponible
3. **Traitement** : Spring Boot traite la requête et interroge PostgreSQL
4. **Réponse** : Les données sont retournées au frontend via l'ALB
5. **Monitoring** : Prometheus scrape les métriques toutes les 15 secondes

## 💰 Coûts

| Ressource | Configuration | Coût mensuel |
|-----------|---------------|--------------|
| Fargate (Spring Boot) | 1 task, 0.5 vCPU, 1 GB | ~$30 |
| RDS PostgreSQL | db.t3.micro | ~$15 |
| Application Load Balancer | Standard | ~$16 |
| Fargate (Prometheus) | 1 task, 0.25 vCPU, 0.5 GB | ~$15 |
| Fargate (Grafana) | 1 task, 0.25 vCPU, 0.5 GB | ~$15 |
| **Total** | | **~$90/mois** |

## 🚀 Déploiement

```bash
cd infra/envs/dev
terraform init
terraform apply
```

Les ressources sont créées dans l'ordre suivant :
1. VPC et subnets (publics/privés)
2. Security Groups
3. RDS PostgreSQL
4. ECS Cluster
5. ALB
6. ECS Services (Spring Boot, Prometheus, Grafana)

Temps total : ~15 minutes

## 🔐 Sécurité

- **VPC** : Réseau isolé avec subnets publics (ALB) et privés (ECS, RDS)
- **Security Groups** : Règles strictes entre composants
- **RDS** : Pas d'accès public, uniquement depuis ECS
- **Secrets** : Mot de passe BDD stocké dans AWS Secrets Manager
- **HTTPS** : Certificat ACM sur l'ALB

## ⚡ Avantages

- **Latence constante** : Pas de cold start
- **Connexions persistantes** : Pool de connexions vers PostgreSQL
- **Debugging facile** : Logs structurés dans CloudWatch
- **Écosystème Java** : Librairies Spring Boot éprouvées

## ⚠️ Inconvénients

- **Coût fixe** : ~$90/mois même sans trafic
- **Scaling manuel** : Nécessite configuration auto-scaling
- **Gestion infrastructure** : Plus complexe que Serverless

