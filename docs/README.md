# Documentation MkDocs

## 📚 Installation

```bash
# Installer les dépendances
pip install -r requirements-docs.txt
```

## 🚀 Lancer en Local

```bash
# Serveur de développement
mkdocs serve

# Ouvrir http://localhost:8000
```

## 🏗️ Build

```bash
# Générer le site statique
mkdocs build

# Résultat dans ./site/
```

## 📁 Structure

```
docs/
├── index.md                    # Page d'accueil
├── architecture/
│   ├── overview.md            # Vue d'ensemble
│   ├── ecs.md                 # Architecture ECS
│   ├── serverless.md          # Architecture Serverless
│   └── comparison.md          # Comparaison ECS vs Serverless
├── deployment/
│   ├── prerequisites.md       # Prérequis
│   ├── ecs.md                 # Déploiement ECS
│   ├── serverless.md          # Déploiement Serverless
│   ├── grafana.md             # Déploiement Grafana
│   └── github-actions.md      # CI/CD
├── modules/
│   ├── structure.md           # Structure modules Terraform
│   ├── network.md             # Modules réseau
│   ├── database.md            # Modules BDD
│   ├── compute.md             # Modules compute
│   └── monitoring.md          # Modules monitoring
├── guide/
│   ├── quickstart.md          # Démarrage rapide
│   ├── simulations.md         # Gestion simulations
│   ├── grafana.md             # Utilisation Grafana
│   └── troubleshooting.md     # Dépannage
├── api/
│   ├── run-controller.md      # API Run Controller
│   └── sensor-controller.md   # API Sensor Controller
└── costs.md                    # Analyse coûts
```

## 🎨 Thème

Material for MkDocs avec :
- Mode clair/sombre
- Navigation par onglets
- Recherche intégrée
- Syntax highlighting
- Diagrammes Mermaid
- Emojis

## 🌐 Déploiement GitHub Pages

La documentation est automatiquement déployée sur GitHub Pages à chaque push sur `master`.

### Configuration Initiale (1 fois)

1. Aller dans **Settings** → **Pages**
2. Source : `gh-pages` branch
3. Save

### URL de la Documentation

Une fois déployée, accessible sur :
```
https://sentori94.github.io/iot-playground-starter-infra/
```

### Déploiement Manuel

```bash
# Déployer manuellement
mkdocs gh-deploy
```

## 📝 TODO

- [ ] Compléter architecture ECS
- [ ] Ajouter API Sensor Controller
- [ ] Guide monitoring Grafana
- [ ] Screenshots
- [ ] Vidéos démo
- [ ] Page coûts détaillée
- [ ] Guide troubleshooting
- [ ] Modules Terraform détaillés

