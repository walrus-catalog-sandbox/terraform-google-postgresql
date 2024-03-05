#
# Contextual Fields
#

variable "context" {
  description = <<-EOF
Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.

Examples:
```
context:
  project:
    name: string
    id: string
  environment:
    name: string
    id: string
  resource:
    name: string
    id: string
```
EOF
  type        = map(any)
  default     = {}
}

#
# Infrastructure Fields
#

variable "infrastructure" {
  description = <<-EOF
Specify the infrastructure information for deploying.

Examples:
```
infrastructure:
  vpc_id: string, optional                  # the ID of the VPC where the PostgreSQL service applies. It is a fully-qualified resource name, such as projects/{project_id}/global/networks/{network_id}.
```
EOF
  type = object({
    vpc_id = optional(string)
  })
  default = {}
}

#
# Deployment Fields
#

variable "architecture" {
  description = <<-EOF
Specify the deployment architecture, select from standalone or replication.
EOF
  type        = string
  default     = "standalone"
  validation {
    condition     = var.architecture == "" || contains(["standalone", "replication"], var.architecture)
    error_message = "Invalid architecture"
  }
}

variable "replication_readonly_replicas" {
  description = <<-EOF
Specify the number of read-only replicas under the replication deployment.
EOF
  type        = number
  default     = 1
  validation {
    condition     = var.replication_readonly_replicas == 0 || contains([1, 3, 5], var.replication_readonly_replicas)
    error_message = "Invalid number of read-only replicas"
  }
}

variable "engine_version" {
  description = <<-EOF
Specify the deployment engine version, select from https://cloud.google.com/sql/docs/db-versions.
EOF
  type        = string
  default     = "15.0"
  validation {
    condition     = var.engine_version == "" || contains(["15.0", "14.0", "13.0", "12.0", "11.0", "10.0", "9.6"], var.engine_version)
    error_message = "Invalid version"
  }
}

variable "database" {
  description = <<-EOF
Specify the database name. The database name must be 1-60 characters long and start with any lower letter, combined with number, or symbols: - _.
The database name cannot be PostgreSQL forbidden keyword.
EOF
  type        = string
  default     = "mydb"
  validation {
    condition     = var.database == "" || can(regex("^[a-z][-a-z0-9_]{1,60}[a-z0-9]$", var.database))
    error_message = format("Invalid database: %s", var.database)
  }
}

variable "username" {
  description = <<-EOF
Specify the account username. The username must be 1-32 characters long and start with lower letter, combined with number.
The username cannot be PostgreSQL forbidden keyword.
EOF
  type        = string
  default     = "rdsuser"
  validation {
    condition = var.username == "" || (
      !can(regex("^(root)$", var.username)) &&
      can(regex("^[a-z][a-z0-9_]{1,32}[a-z0-9]$", var.username))
    )
    error_message = format("Invalid username: %s", var.username)
  }
}

variable "password" {
  description = <<-EOF
Specify the account password. The password must be 8-128 characters long and start with any letter, number, or symbols: ! # $ % ^ & * ( ) _ + - =.
If not specified, it will generate a random password.
EOF
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.password == null || var.password == "" || can(regex("^[A-Za-z0-9\\!#\\$%\\^&\\*\\(\\)_\\+\\-=]{8,128}", var.password))
    error_message = "Invalid password"
  }
}

variable "resources" {
  description = <<-EOF
Specify the computing resources.
The computing resource design of Google Cloud is very complex, it also needs to consider on the storage resource, please view the specification document for more information.

Examples:
```
resources:
  class: string, optional            # https://cloud.google.com/sql/docs/postgres/instance-settings
```
EOF
  type = object({
    class = optional(string, "db-f1-micro")
  })
  default = {
    class = "db-f1-micro"
  }
}

variable "storage" {
  description = <<-EOF
Specify the storage resources, select from PD_SSD or PD_HDD.
Choosing the storage resource is also related to the computing resource, please view the specification document for more information.

Examples:
```
storage:
  class: string, optional        # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#disk_type
  size: number, optional         # in megabyte
```
EOF
  type = object({
    class = optional(string, "PD_SSD")
    size  = optional(number, 10 * 1024)
  })
  default = {
    class = "PD_SSD"
    size  = 10 * 1024
  }
  validation {
    condition     = var.storage == null || try(var.storage.size >= 10240, true)
    error_message = "Storage size must be larger than 10240Mi"
  }
}