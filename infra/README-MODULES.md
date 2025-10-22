# Architecture Modulaire Terraform - IoT Playground Starter

## 🏗️ Structure du Projet

```
infra/
├── modules/                    # Modules réutilisables
│   ├── network/               # VPC, subnets, IGW, NAT
│   ├── database/              # RDS PostgreSQL + Secrets Manager
│   ├── ecs/                   # Cluster ECS
│   ├── ecs_service/           # Service ECS générique
│   ├── alb/                   # Application Load Balancer générique
│   ├── security_groups/       # Security Groups génériques
│   └── bastion/               # Instance Bastion
│
└── envs/
    └── dev/                   # Environnement DEV
        ├── main.tf            # ✨ Appel des modules (très court!)
        ├── variables.tf       # Variables d'entrée
        ├── terraform.tfvars   # Valeurs spécifiques à DEV
        ├── outputs.tf         # Sorties
        ├── providers.tf       # Configuration AWS
        ├── backend.tf         # Backend S3
        └── templates/         # Templates locaux
            ├── prometheus.yml.tpl
            └── grafana-datasource-prometheus.yml.tpl
```

## ✅ Avantages de cette architecture

### 1. **DRY (Don't Repeat Yourself)**
- ✅ Les modules sont écrits **une seule fois**
- ✅ Réutilisables dans tous les environnements (dev, staging, prod)
- ✅ Plus besoin de copier/coller du code

### 2. **Facilité d'ajout d'environnements**
Pour créer un environnement `prod` :
```bash
# Copier le dossier dev
cp -r infra/envs/dev infra/envs/prod

# Modifier seulement terraform.tfvars
# - Changer les tailles d'instances
# - Activer multi-AZ pour RDS
# - Ajuster le desired_count ECS
```

### 3. **Maintenance simplifiée**
- 🔧 Correction d'un bug ? → Modifier le module, tous les environnements en bénéficient
- 🆕 Nouvelle fonctionnalité ? → Ajouter au module, activer par variable

### 4. **Variables centralisées**
Toute la configuration est dans `terraform.tfvars` :
```hcl
env                = "dev"
project            = "iot-playground-starter"
aws_region         = "eu-west-3"
rds_instance_class = "db.t4g.micro"   # ← Petit en dev
ecs_cpu            = "512"             # ← Petit en dev
ecs_memory         = "1024"            # ← Petit en dev
```

## 🚀 Utilisation

### Initialisation
```bash
cd infra/envs/dev
terraform init
```

### Validation
```bash
terraform validate
terraform fmt -recursive
```

### Planification
```bash
terraform plan
```

### Déploiement
```bash
terraform apply
```

### Destruction
```bash
terraform destroy
```

## 📦 Modules disponibles

### `network`
Crée un VPC complet avec subnets publics/privés, NAT Gateway, Internet Gateway.

**Variables principales :**
- `vpc_cidr` : CIDR du VPC
- `public_subnet_cidrs` : Liste des CIDR publics
- `private_subnet_cidrs` : Liste des CIDR privés

### `database`
Déploie PostgreSQL RDS avec Secrets Manager.

**Variables principales :**
- `instance_class` : Taille de l'instance (ex: `db.t3.micro`, `db.t4g.large`)
- `multi_az` : Multi-AZ pour haute disponibilité
- `backup_retention_period` : Durée de rétention des backups

### `ecs_service`
Déploie un service ECS Fargate avec logs CloudWatch.

**Variables principales :**
- `image_url` : URL de l'image Docker
- `cpu` / `memory` : Ressources allouées
- `desired_count` : Nombre de tâches
- `environment_variables` : Variables d'environnement
- `secrets` : Secrets depuis Secrets Manager

### `alb`
Crée un ALB avec target group et listener.

**Variables principales :**
- `target_port` : Port du service backend
- `health_check_path` : Chemin du health check

### `bastion`
Instance EC2 pour accéder à RDS.

**Variables principales :**
- `instance_type` : Taille de l'instance
- `allowed_cidr_blocks` : IPs autorisées en SSH

## 🔄 Créer un environnement PROD (exemple)

```bash
# 1. Copier dev vers prod
cp -r infra/envs/dev infra/envs/prod

# 2. Modifier infra/envs/prod/terraform.tfvars
env                = "prod"
rds_instance_class = "db.t4g.large"  # Plus gros
ecs_cpu            = "1024"           # Plus de CPU
ecs_memory         = "2048"           # Plus de RAM
desired_count      = 3                # 3 instances au lieu de 1

# 3. Activer multi-AZ pour RDS dans main.tf
multi_az = true
backup_retention_period = 30

# 4. Déployer
cd infra/envs/prod
terraform init
terraform plan
terraform apply
```

## 🎯 Chemins des templates

Les templates Prometheus et Grafana sont maintenant dans `infra/envs/dev/templates/` :
- ✅ Plus de chemins `../../` compliqués
- ✅ Utilisation de `${path.module}/templates/`
- ✅ Chaque environnement a ses propres templates si besoin

## 📝 Notes importantes

1. **Secrets** : Les secrets RDS sont gérés automatiquement par le module `database` dans AWS Secrets Manager
2. **Logs** : Tous les services ECS ont des CloudWatch Log Groups avec rétention configurable
3. **Tags** : Les tags communs (`Project`, `Environment`, `ManagedBy`) sont appliqués automatiquement
4. **Security Groups** : Les security groups sont créés automatiquement par les modules

## 🔍 Outputs disponibles

Après le déploiement, Terraform affiche :
- URLs des ALB (Spring App, Prometheus, Grafana)
- Endpoint RDS
- IP publique du Bastion
- VPC ID
- Nom du cluster ECS

## 💡 Bonnes pratiques

1. **Toujours utiliser `terraform plan`** avant `apply`
2. **Versionner les modules** si vous les publiez dans un registry
3. **Utiliser des variables** plutôt que des valeurs en dur
4. **Séparer les environnements** dans des dossiers distincts
5. **Backend S3** : Utiliser un bucket S3 différent par environnement pour le state

## 🐛 Troubleshooting

### Erreur "path.root is ."
✅ Résolu ! Les templates sont maintenant dans `infra/envs/dev/templates/`

### Grafana ne trouve pas le datasource Prometheus
✅ Les templates sont générés automatiquement avec les bonnes URLs d'ALB

### RDS inaccessible depuis ECS
✅ Les security groups sont configurés automatiquement par les modules

