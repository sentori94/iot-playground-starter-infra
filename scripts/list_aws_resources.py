
#!/usr/bin/env python3
"""
scripts/list_aws_resources.py

Affiche (read-only) un inventaire rapide des ressources AWS par région + quelques ressources globales.
Ne modifie rien - uniquement pour audit et détection des ressources coûteuses.
"""
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
import sys

def safe_client(service, region=None):
    """Crée un client AWS en gérant les erreurs."""
    try:
        return boto3.client(service, region_name=region) if region else boto3.client(service)
    except Exception as e:
        print(f"  ! impossible de créer client {service} ({region}): {e}")
        return None

def list_regions():
    """Liste toutes les régions AWS actives."""
    ec2 = safe_client("ec2", region="us-east-1")
    if not ec2:
        return []
    try:
        resp = ec2.describe_regions(AllRegions=False)
        return [r["RegionName"] for r in resp.get("Regions", [])]
    except Exception as e:
        print("Erreur récupération régions:", e)
        return []

def list_global():
    """Liste les ressources AWS globales (S3, Route53, etc.)."""
    print("=" * 60)
    print("RESSOURCES GLOBALES")
    print("=" * 60)

    # S3 buckets
    s3 = safe_client("s3")
    if s3:
        try:
            buckets = s3.list_buckets().get("Buckets", [])
            print(f"\n📦 S3 Buckets: {len(buckets)}")
            for b in buckets:
                name = b.get('Name')
                print(f"  - {name}")
                # Taille approximative (peut être coûteux sur gros buckets)
                try:
                    location = s3.get_bucket_location(Bucket=name).get('LocationConstraint') or 'us-east-1'
                    print(f"    Région: {location}")
                except:
                    pass
        except Exception as e:
            print(f"  ! s3 list failed: {e}")

    # Route53 zones
    r53 = safe_client("route53")
    if r53:
        try:
            zones = r53.list_hosted_zones().get("HostedZones", [])
            print(f"\n🌐 Route53 Hosted Zones: {len(zones)}")
            for z in zones[:10]:
                print(f"  - {z.get('Name')} (ID: {z.get('Id')})")
        except Exception as e:
            print(f"  ! route53 list failed: {e}")

    # Secrets Manager
    sm = safe_client("secretsmanager")
    if sm:
        try:
            secrets = sm.list_secrets(MaxResults=100).get("SecretList", [])
            print(f"\n🔐 Secrets Manager: {len(secrets)} secrets")
            for s in secrets[:20]:
                print(f"  - {s.get('Name')}")
        except Exception as e:
            print(f"  ! secretsmanager list failed: {e}")

def list_region_resources(region):
    """Liste les ressources AWS dans une région spécifique."""
    print("\n" + "=" * 60)
    print(f"RÉGION: {region}")
    print("=" * 60)

    total_cost_indicators = []

    # EC2: instances
    ec2 = safe_client("ec2", region)
    if ec2:
        try:
            reservations = ec2.describe_instances().get("Reservations", [])
            instances = [i for r in reservations for i in r.get("Instances", []) if i.get("State", {}).get("Name") != "terminated"]
            if instances:
                print(f"\n💻 EC2 Instances: {len(instances)}")
                for i in instances[:20]:
                    state = i.get("State", {}).get("Name", "unknown")
                    itype = i.get("InstanceType", "unknown")
                    iid = i.get("InstanceId", "unknown")
                    print(f"  - {iid} ({itype}) - État: {state}")
                    if state == "running":
                        total_cost_indicators.append(f"EC2 running: {itype}")

            # EBS volumes
            vols = ec2.describe_volumes().get("Volumes", [])
            total_size = sum(v.get('Size', 0) for v in vols)
            if vols:
                print(f"\n💾 EBS Volumes: {len(vols)} (Total: {total_size} GiB)")
                for v in vols[:10]:
                    print(f"  - {v.get('VolumeId')} ({v.get('Size')} GiB, {v.get('VolumeType')})")
                total_cost_indicators.append(f"EBS: {total_size} GiB")

            # Elastic IPs
            addrs = ec2.describe_addresses().get("Addresses", [])
            if addrs:
                print(f"\n🌍 Elastic IPs: {len(addrs)}")
                for a in addrs:
                    eip = a.get("PublicIp", "N/A")
                    assoc = a.get("AssociationId", "Non associée")
                    print(f"  - {eip} ({'✓ Associée' if assoc != 'Non associée' else '❌ NON ASSOCIÉE (COÛT!!)'})")
                    if assoc == "Non associée":
                        total_cost_indicators.append("EIP non associée (coût récurrent!)")

            # NAT Gateways
            ngws = ec2.describe_nat_gateways(Filters=[{"Name": "state", "Values": ["available"]}]).get("NatGateways", [])
            if ngws:
                print(f"\n🚪 NAT Gateways: {len(ngws)} ⚠️  COÛT ÉLEVÉ!")
                for n in ngws:
                    print(f"  - {n.get('NatGatewayId')} (Subnet: {n.get('SubnetId')})")
                total_cost_indicators.append(f"NAT Gateway x{len(ngws)} (⚠️  très coûteux!)")
        except ClientError as e:
            print(f"  ! ec2 describe failed: {e}")

    # Load Balancers
    elb = safe_client("elbv2", region)
    if elb:
        try:
            lbs = elb.describe_load_balancers().get("LoadBalancers", [])
            if lbs:
                print(f"\n⚖️  Load Balancers (ALB/NLB): {len(lbs)}")
                for lb in lbs:
                    print(f"  - {lb.get('LoadBalancerName')} ({lb.get('Type')})")
                total_cost_indicators.append(f"ALB/NLB x{len(lbs)}")
        except Exception as e:
            print(f"  ! elbv2 describe failed: {e}")

    # RDS
    rds = safe_client("rds", region)
    if rds:
        try:
            dbs = rds.describe_db_instances().get("DBInstances", [])
            if dbs:
                print(f"\n🗄️  RDS Instances: {len(dbs)}")
                for db in dbs:
                    print(f"  - {db.get('DBInstanceIdentifier')} ({db.get('DBInstanceClass')}, {db.get('AllocatedStorage')} GB)")
                total_cost_indicators.append(f"RDS x{len(dbs)}")
        except Exception as e:
            print(f"  ! rds describe failed: {e}")

    # ElastiCache
    ecache = safe_client("elasticache", region)
    if ecache:
        try:
            clusters = ecache.describe_cache_clusters().get("CacheClusters", [])
            if clusters:
                print(f"\n🔄 ElastiCache Clusters: {len(clusters)}")
                for c in clusters:
                    print(f"  - {c.get('CacheClusterId')} ({c.get('CacheNodeType')})")
                total_cost_indicators.append(f"ElastiCache x{len(clusters)}")
        except Exception as e:
            print(f"  ! elasticache describe failed: {e}")

    # EFS
    efs = safe_client("efs", region)
    if efs:
        try:
            fss = efs.describe_file_systems().get("FileSystems", [])
            if fss:
                print(f"\n📁 EFS Filesystems: {len(fss)}")
                for fs in fss:
                    print(f"  - {fs.get('FileSystemId')} ({fs.get('ThroughputMode')})")
                total_cost_indicators.append(f"EFS x{len(fss)}")
        except Exception as e:
            print(f"  ! efs describe failed: {e}")

    # Redshift
    red = safe_client("redshift", region)
    if red:
        try:
            clusters = red.describe_clusters().get("Clusters", [])
            if clusters:
                print(f"\n📊 Redshift Clusters: {len(clusters)} ⚠️  COÛT TRÈS ÉLEVÉ!")
                for c in clusters:
                    print(f"  - {c.get('ClusterIdentifier')} ({c.get('NodeType')}, {c.get('NumberOfNodes')} nodes)")
                total_cost_indicators.append(f"Redshift x{len(clusters)} (⚠️  très coûteux!)")
        except Exception as e:
            print(f"  ! redshift describe failed: {e}")

    # Lambda
    lam = safe_client("lambda", region)
    if lam:
        try:
            funcs = lam.list_functions().get("Functions", [])
            if funcs:
                print(f"\n⚡ Lambda Functions: {len(funcs)}")
                for f in funcs[:10]:
                    print(f"  - {f.get('FunctionName')} (Runtime: {f.get('Runtime')})")
        except Exception as e:
            print(f"  ! lambda list failed: {e}")

    # Résumé coûts région
    if total_cost_indicators:
        print(f"\n💰 INDICATEURS DE COÛT pour {region}:")
        for indicator in total_cost_indicators:
            print(f"  ⚠️  {indicator}")

def main():
    """Point d'entrée principal."""
    try:
        print("\n" + "🔍" * 30)
        print("AUDIT DES RESSOURCES AWS (Read-Only)")
        print("🔍" * 30 + "\n")

        regions = list_regions()
        if not regions:
            print("❌ Aucune région trouvée ou erreur. Vérifier credentials et permissions.")
            sys.exit(1)

        print(f"✅ {len(regions)} régions AWS trouvées\n")

        # Ressources globales
        list_global()

        # Ressources par région
        for r in regions:
            try:
                list_region_resources(r)
            except NoCredentialsError:
                print("❌ Credentials AWS introuvables.")
                sys.exit(1)
            except Exception as e:
                print(f"⚠️  Erreur région {r}: {e}")

        print("\n" + "=" * 60)
        print("✅ AUDIT TERMINÉ")
        print("=" * 60)

    except NoCredentialsError:
        print("❌ Credentials AWS introuvables.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Erreur générale: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

