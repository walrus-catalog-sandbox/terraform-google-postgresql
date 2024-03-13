locals {
  project_name     = coalesce(try(var.context["project"]["name"], null), "default")
  project_id       = coalesce(try(var.context["project"]["id"], null), "default_id")
  environment_name = coalesce(try(var.context["environment"]["name"], null), "test")
  environment_id   = coalesce(try(var.context["environment"]["id"], null), "test_id")
  resource_name    = coalesce(try(var.context["resource"]["name"], null), "example")
  resource_id      = coalesce(try(var.context["resource"]["id"], null), "example_id")

  namespace = join("-", [local.project_name, local.environment_name])

  tags = {
    "Name" = local.resource_name

    "walrus.seal.io-catalog-name"     = "terraform-google-postgresql"
    "walrus.seal.io-project-id"       = local.project_id
    "walrus.seal.io-environment-id"   = local.environment_id
    "walrus.seal.io-resource-id"      = local.resource_id
    "walrus.seal.io-project-name"     = local.project_name
    "walrus.seal.io-environment-name" = local.environment_name
    "walrus.seal.io-resource-name"    = local.resource_name
  }

  architecture = coalesce(var.architecture, "standalone")
}

locals {
  version = lookup({
    "9.6"  = "POSTGRES_9_6",
    "10.0" = "POSTGRES_10",
    "11.0" = "POSTGRES_11",
    "12.0" = "POSTGRES_12",
    "13.0" = "POSTGRES_13",
    "14.0" = "POSTGRES_14",
    "15.0" = "POSTGRES_15",
  }, var.engine_version, "POSTGRES_15")
}

# create network.
resource "google_compute_network" "default" {
  count = var.infrastructure.vpc_id == null ? 1 : 0

  name = local.fullname
}

resource "google_compute_global_address" "default" {
  count = var.infrastructure.vpc_id == null ? 1 : 0

  name          = local.fullname
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.default[0].id
}

# create private vpc connection.
resource "google_service_networking_connection" "default" {
  count = var.infrastructure.vpc_id == null ? 1 : 0

  network                 = google_compute_network.default[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.default[0].name]
  deletion_policy         = "ABANDON"
}

#
# Random
#

# create a random password for blank password input.

resource "random_password" "password" {
  length      = 16
  special     = false
  lower       = true
  min_lower   = 3
  min_upper   = 3
  min_numeric = 3
}

# create the name with a random suffix.

resource "random_string" "name_suffix" {
  length  = 10
  special = false
  upper   = false
}

#
# Deployment
#

# create server.

locals {
  name     = join("-", [local.resource_name, random_string.name_suffix.result])
  fullname = format("walrus-%s", md5(join("-", [local.namespace, local.name])))
  database = coalesce(var.database, "mydb")
  username = coalesce(var.username, "rdsuser")
  password = coalesce(var.password, random_password.password.result)

  replication_readonly_replicas = var.replication_readonly_replicas == 0 ? 1 : var.replication_readonly_replicas

  labels = {
    "walrus-seal-io-catalog-name"     = "terraform-google-postgresql"
    "walrus-seal-io-project-id"       = local.project_id
    "walrus-seal-io-environment-id"   = local.environment_id
    "walrus-seal-io-resource-id"      = local.resource_id
    "walrus-seal-io-project-name"     = local.project_name
    "walrus-seal-io-environment-name" = local.environment_name
    "walrus-seal-io-resource-name"    = local.resource_name
  }
}

resource "google_sql_database_instance" "primary" {
  name             = local.fullname
  database_version = local.version

  settings {
    tier        = var.resources.class
    disk_type   = var.storage.class
    disk_size   = try(var.storage.size / 1024, 10)
    user_labels = local.labels

    #tfsec:ignore:google-sql-encrypt-in-transit-data
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.infrastructure.vpc_id == null ? google_compute_network.default[0].id : var.infrastructure.vpc_id
    }

    backup_configuration {
      enabled = true
    }
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.default]
}

resource "google_sql_database_instance" "secondary" {
  count = var.architecture == "replication" ? local.replication_readonly_replicas : 0

  name                 = "${local.fullname}-secondary-${count.index}"
  database_version     = local.version
  master_instance_name = google_sql_database_instance.primary.name

  settings {
    tier        = var.resources.class
    disk_type   = var.storage.class
    disk_size   = try(var.storage.size / 1024, 10)
    user_labels = local.labels

    #tfsec:ignore:google-sql-encrypt-in-transit-data
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.infrastructure.vpc_id == null ? google_compute_network.default[0].id : var.infrastructure.vpc_id
    }
  }

  deletion_protection = false

  depends_on = [google_service_networking_connection.default]
}

# create database.

resource "google_sql_database" "database" {
  name      = local.database
  instance  = google_sql_database_instance.primary.name
  charset   = "utf8"
  collation = "en_US.UTF8"

  lifecycle {
    ignore_changes = [
      name,
      charset,
      collation
    ]
  }
}

resource "google_sql_user" "users" {
  name     = local.username
  instance = google_sql_database_instance.primary.name
  password = local.password

  lifecycle {
    ignore_changes = [
      name,
      password,
    ]
  }
}
