locals {
  dns_records = merge({ for i, v in aws_ses_domain_dkim.this.dkim_tokens : "dkim-${i}" => {
    type    = "CNAME"
    name    = "${v}._domainkey.${aws_ses_domain_dkim.this.domain}"
    records = ["${v}.dkim.amazonses.com"]
    } }, { domain = {
    type    = "TXT"
    name    = "_amazonses.${aws_ses_domain_identity.this.domain}"
    records = [aws_ses_domain_identity.this.verification_token]
  } })
}

resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

module "policy" {
  source  = "ptonini/iam-policy/aws"
  version = "~> 1.0.0"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = "ses:SendRawEmail"
      Resource = aws_ses_domain_identity.this.arn
    }]
  })
}

module "dns_records" {
  source       = "ptonini/route53-record/aws"
  version      = "~> 1.0.0"
  for_each     = var.route53_zone == null ? {} : local.dns_records
  route53_zone = var.route53_zone
  name         = each.value["name"]
  type         = each.value["type"]
  records      = each.value["records"]
}

resource "aws_ses_email_identity" "this" {
  for_each = var.email_identities
  email    = each.value
}
