variable "route53_zone_name" {
  description = "Nom de la zone Route53 hébergée (ex: example.com)"
  type        = string
}

variable "records" {
  description = "Liste des enregistrements DNS à créer"
  type = list(object({
    name                   = string
    alb_dns_name          = string
    alb_zone_id           = string
    evaluate_target_health = bool
  }))
  default = []
}
