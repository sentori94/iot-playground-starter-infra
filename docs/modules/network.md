# Module Réseau (VPC & Subnets)
## 🧩 Utilisation dans le projet
- Cette structure est proche des best practices AWS (2–3 AZ, subnets publics/privés, etc.).
- On sépare clairement les ressources exposées (ALB) des ressources privées (ECS/RDS/Grafana).
- Le réseau est **factorisé** dans un module pour éviter la duplication.

## 💡 Points à mentionner en entretien

  - VPC dédié pour Grafana serverless (séparé du reste)
- Environnement `grafana-serverless-dev` :
  - VPC principal pour ECS, RDS, Prometheus, Grafana
- Environnement `dev` (ECS) :

  - Accès limité entrant via ALB uniquement
  - Accès Internet sortant
- Configurer les routes pour :
- Découper en **subnets publics** (ALB, NAT, bastion) et **subnets privés** (ECS, RDS, Grafana)
- Créer un **VPC** isolé

## 🎯 Rôle du module

Ce module gère la partie **réseau** commune : VPC, sous-réseaux, tables de routage, Internet Gateway, etc.


