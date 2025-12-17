# Architecture ECS vs Serverless

## 📊 Tableau Comparatif

| Aspect | ECS Classic | Serverless Lambda |
|--------|-------------|-------------------|
| **Runtime** | Spring Boot (Java) | Python 3.11 |
| **Base de données** | PostgreSQL (RDS) | DynamoDB |
| **Compute** | ECS Fargate (Always-on) | Lambda (On-demand) |
| **Scaling** | Auto-scaling ECS | Auto-scaling Lambda |
| **Cold Start** | ❌ Aucun | ⚠️ ~1-2s (first request) |
| **Coût idle** | ~$80/mois | ~$1/mois (sans Grafana) |
| **Coût actif** | ~$80/mois (fixe) | Variable selon usage |
| **Monitoring** | Prometheus | CloudWatch Logs |
| **Grafana** | Datasource Prometheus | Datasource CloudWatch |
| **HTTPS** | ✅ ALB + ACM | ✅ API Gateway + ACM |
| **Authentification** | Header X-User | Header X-User |
| **Limite concurrent** | Configurable ECS | 5 runs globaux |

## 🎯 Cas d'Usage Recommandés

### ECS Classic

```mermaid
graph TB
    A[Besoin d'ECS ?] --> B{Trafic continu ?}
    B -->|Oui| C[✅ ECS recommandé]
    B -->|Non| D{Budget fixe ?}
    D -->|Oui| E[✅ ECS si <100 req/min]
    D -->|Non| F[❌ Serverless mieux]
    
    G[Performance critique ?] --> H{Latence <50ms ?}
    H -->|Oui| I[✅ ECS recommandé]
    H -->|Non| J[✅ Les deux OK]
    
    style C fill:#e8f5e9
    style I fill:#e8f5e9
```

**Avantages ECS :**
- ✅ Pas de cold start
- ✅ Connexions persistantes (BDD, cache)
- ✅ Latence prévisible
- ✅ Debugging plus simple (logs structurés)
- ✅ Écosystème Java mature

**Inconvénients ECS :**
- ❌ Coût fixe même sans trafic
- ❌ Gestion de l'infrastructure
- ❌ Scaling moins réactif

### Serverless Lambda

```mermaid
graph TB
    A[Besoin de Serverless ?] --> B{Trafic sporadique ?}
    B -->|Oui| C[✅ Serverless recommandé]
    B -->|Non| D{Budget limité ?}
    D -->|Oui| E[✅ Serverless recommandé]
    D -->|Non| F{Pic de charge ?}
    F -->|Oui| G[✅ Serverless excellent]
    F -->|Non| H[✅ ECS peut suffire]
    
    style C fill:#e8f5e9
    style E fill:#e8f5e9
    style G fill:#e8f5e9
```

**Avantages Serverless :**
- ✅ Pay-per-use (coût = usage réel)
- ✅ Scaling automatique infini
- ✅ Pas de gestion serveur
- ✅ DynamoDB très performant

**Inconvénients Serverless :**
- ❌ Cold start (~1-2s)
- ❌ Timeout max 15 minutes
- ❌ Debugging plus complexe
- ❌ Vendor lock-in AWS

## 💰 Analyse Coûts Détaillée

### Scénario : 1000 req/jour

=== "ECS"

    | Ressource | Coût mensuel |
    |-----------|--------------|
    | Fargate (1 task, 0.5 vCPU, 1 GB) | ~$30 |
    | RDS PostgreSQL (db.t3.micro) | ~$15 |
    | ALB | ~$16 |
    | Prometheus ECS | ~$15 |
    | Grafana ECS | ~$15 |
    | **TOTAL** | **~$90/mois** |

=== "Serverless"

    | Ressource | Coût mensuel |
    |-----------|--------------|
    | Lambda (30k invocations) | ~$0.01 |
    | DynamoDB (on-demand, 30k writes) | ~$0.40 |
    | API Gateway (30k requests) | ~$0.10 |
    | CloudWatch Logs (5 GB) | ~$2.50 |
    | Grafana ECS (si actif) | ~$40 |
    | VPC (NAT, IGW pour Grafana) | ~$40 |
    | **TOTAL (avec Grafana)** | **~$83/mois** |
    | **TOTAL (sans Grafana)** | **~$3/mois** |

### Scénario : 100k req/jour

=== "ECS"

    | Ressource | Coût mensuel |
    |-----------|--------------|
    | Fargate (2 tasks, 1 vCPU, 2 GB) | ~$60 |
    | RDS PostgreSQL (db.t3.small) | ~$30 |
    | ALB | ~$20 |
    | Prometheus ECS | ~$15 |
    | Grafana ECS | ~$15 |
    | **TOTAL** | **~$140/mois** |

=== "Serverless"

    | Ressource | Coût mensuel |
    |-----------|--------------|
    | Lambda (3M invocations) | ~$1.20 |
    | DynamoDB (3M writes) | ~$40 |
    | API Gateway (3M requests) | ~$10 |
    | CloudWatch Logs (50 GB) | ~$25 |
    | Grafana ECS | ~$40 |
    | VPC | ~$40 |
    | **TOTAL** | **~$156/mois** |

```mermaid
graph LR
    A[0 req/jour] -->|ECS| B[$90]
    A -->|Serverless| C[$3]
    
    D[1k req/jour] -->|ECS| E[$90]
    D -->|Serverless| F[$83]
    
    G[100k req/jour] -->|ECS| H[$140]
    G -->|Serverless| I[$156]
    
    J[1M req/jour] -->|ECS| K[$200]
    J -->|Serverless| L[$800+]
    
    style C fill:#e8f5e9
    style F fill:#e8f5e9
```

!!! tip "Conclusion Coûts"
    - **< 10k req/jour** → Serverless **beaucoup** moins cher
    - **10k - 50k req/jour** → Équivalent
    - **> 100k req/jour** → ECS plus économique

## ⚡ Performance

### Latence

```mermaid
graph LR
    subgraph "ECS"
        A[P50: 50ms]
        B[P95: 100ms]
        C[P99: 150ms]
    end
    
    subgraph "Serverless (warm)"
        D[P50: 80ms]
        E[P95: 200ms]
        F[P99: 500ms]
    end
    
    subgraph "Serverless (cold)"
        G[P50: 1500ms]
        H[P95: 2500ms]
        I[P99: 3500ms]
    end
    
    style A fill:#e8f5e9
    style D fill:#fff9c4
    style G fill:#ffebee
```

### Throughput

| Architecture | Max Throughput | Scaling Time |
|--------------|----------------|--------------|
| **ECS** | ~1000 req/s (2 tasks) | 2-3 minutes |
| **Serverless** | ~10000 req/s (1000 lambdas) | < 10 secondes |

## 🔄 Migration

### ECS → Serverless

```mermaid
graph TB
    A[Spring Boot API] -->|1. Analyser| B[Endpoints REST]
    B -->|2. Convertir| C[Lambda Handlers Python]
    C -->|3. Adapter| D[DynamoDB Schema]
    
    E[PostgreSQL] -->|4. Exporter| F[Data JSON]
    F -->|5. Importer| D
    
    G[Prometheus] -->|6. Remplacer| H[CloudWatch Metrics]
    
    I[Grafana] -->|7. Changer datasource| J[CloudWatch Logs]
    
    style C fill:#e8f5e9
    style D fill:#e8f5e9
```

### Serverless → ECS

```mermaid
graph TB
    A[Lambda Python] -->|1. Convertir| B[Spring Boot Controllers]
    B -->|2. Adapter| C[JPA Entities]
    
    D[DynamoDB] -->|3. Exporter| E[Data JSON]
    E -->|4. Importer| F[PostgreSQL]
    
    G[CloudWatch] -->|5. Migrer| H[Prometheus]
    
    I[Grafana] -->|6. Changer datasource| J[Prometheus]
    
    style B fill:#fff3e0
    style C fill:#fff3e0
```

## 🎓 Recommandation

```mermaid
graph TD
    A{Objectif du projet ?} --> B[Apprentissage]
    A --> C[Production]
    
    B --> D[✅ Déployer les DEUX]
    D --> E[Comparer performances]
    D --> F[Comparer coûts]
    D --> G[Comparer dev experience]
    
    C --> H{Budget ?}
    H -->|Limité| I[✅ Serverless]
    H -->|Fixe OK| J{Trafic ?}
    
    J -->|Constant| K[✅ ECS]
    J -->|Sporadique| L[✅ Serverless]
    
    style D fill:#e1f5ff
    style I fill:#e8f5e9
    style K fill:#fff3e0
    style L fill:#e8f5e9
```

!!! success "Pour ce projet"
    **Les deux architectures sont déployées** pour permettre la comparaison :
    
    - **ECS** : `infra/envs/dev/`
    - **Serverless** : `infra/envs/serverless-dev/`
    
    → Choix dans le frontend : "Mode ECS" vs "Mode Serverless"

