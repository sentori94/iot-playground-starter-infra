# Prérequis

## 🔧 Outils Nécessaires

### AWS CLI
```bash
# Installation
# Windows (PowerShell)
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configuration
aws configure
# AWS Access Key ID: [Votre Access Key]
# AWS Secret Access Key: [Votre Secret Key]
# Default region: eu-west-3
# Default output format: json
```

### Terraform
```bash
# Version requise: >= 1.6.0

# Windows (Chocolatey)
choco install terraform

# macOS
brew install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Vérification
```bash
aws --version
# aws-cli/2.x.x

terraform --version
# Terraform v1.6.0 ou supérieur
```

## 🔐 Permissions IAM Requises

L'utilisateur AWS doit avoir les permissions suivantes :

- **Lambda** : Création et gestion des fonctions
- **DynamoDB** : Création et gestion des tables
- **API Gateway** : Création et configuration
- **ECS** : Gestion des clusters et services
- **RDS** : Création et gestion des bases de données
- **VPC** : Création et gestion du réseau
- **IAM** : Création de rôles et policies
- **CloudWatch** : Logs et métriques
- **Route53** : Gestion DNS
- **ACM** : Certificats SSL/TLS
- **S3** : Stockage état Terraform
- **ECR** : Registry Docker

## 🌐 Domaine DNS

Un domaine configuré dans Route53 est requis :
- Domaine : `sentori-studio.com`
- Hosted Zone configurée dans Route53

## 🔑 GitHub Secrets

Pour les déploiements via GitHub Actions, configurer les secrets suivants dans le repository :

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Configuration : **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

## ✅ Checklist Finale

- [ ] AWS CLI installé et configuré
- [ ] Terraform >= 1.6.0 installé
- [ ] Credentials AWS valides
- [ ] Permissions IAM suffisantes
- [ ] Domaine Route53 configuré
- [ ] GitHub Secrets configurés (pour CI/CD)

