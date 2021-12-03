terraform {
  required_providers {
    fmc = {
      source  = "CiscoDevNet/fmc"
      version = "0.1.1"
    }
  }
}

provider "fmc" {
  fmc_username             = var.fmc_username
  fmc_password             = var.fmc_password
  fmc_host                 = "fmcrestapisandbox.cisco.com"
  fmc_insecure_skip_verify = true
}

locals {
  natrules = csvdecode(file("./data/nat_rules.csv"))
}

resource "fmc_host_objects" "original" {
  for_each = { for nats in local.natrules : nats.rule => nats }
  name     = "${each.value.original}-tf"
  value    = each.value.original
}
resource "fmc_host_objects" "translated" {
  for_each = { for nats in local.natrules : nats.rule => nats }
  name     = "${each.value.translated}-tf"
  value    = each.value.translated
}
resource "fmc_ftd_nat_policies" "mb_nat_policy" {
  name        = "TST-NAT-POLICY-01"
  description = "Test Policy Managed with Terraform"
}

resource "fmc_ftd_manualnat_rules" "new_rule" {
  # depends_on = ["fmc_host_objects.original", "fmc_host_objects.translated"]
  for_each    = { for nats in local.natrules : nats.rule => nats }
  nat_policy  = fmc_ftd_nat_policies.mb_nat_policy.id
  description = "Manual NAT using TF"
  nat_type    = "static"
  original_source {
    id   = fmc_host_objects.original[each.key].id
    type = fmc_host_objects.original[each.key].type
  }
  translated_source {
    id   = fmc_host_objects.translated[each.key].id
    type = fmc_host_objects.translated[each.key].type
  }
  translate_dns = true
}


/*
FMC  Address: https://fmcrestapisandbox.cisco.com/api/api-explorer/
*/