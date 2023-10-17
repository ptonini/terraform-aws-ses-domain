variable "domain" {}

variable "route53_zone" {
  default = null
}

variable "email_identities" {
  type    = set(string)
  default = []
}
