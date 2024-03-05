# Google PostgreSQL Server

Terrafom module to deploy a PostgreSQL Server on Google Cloud.

- [x] Support standalone(one read-write instance) and replication(one read-write instance and multiple read-only instances, for read write splitting).

## Usage

```hcl
module "postgresql" {
  source = "..."

  infrastructure = {
    vpc_id        = "..."
  }
}
```

## Examples

- [Replication](./examples/replication)
- [Standalone](./examples/standalone)

## Contributing

Please read our [contributing guide](./docs/CONTRIBUTING.md) if you're interested in contributing to Walrus template.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.5.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.5.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.5.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_global_address.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_network.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_service_networking_connection.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_networking_connection) | resource |
| [google_sql_database.database](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database) | resource |
| [google_sql_database_instance.primary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_database_instance.secondary](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance) | resource |
| [google_sql_user.users](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_user) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_architecture"></a> [architecture](#input\_architecture) | Specify the deployment architecture, select from standalone or replication. | `string` | `"standalone"` | no |
| <a name="input_context"></a> [context](#input\_context) | Receive contextual information. When Walrus deploys, Walrus will inject specific contextual information into this field.<br><br>Examples:<pre>context:<br>  project:<br>    name: string<br>    id: string<br>  environment:<br>    name: string<br>    id: string<br>  resource:<br>    name: string<br>    id: string</pre> | `map(any)` | `{}` | no |
| <a name="input_database"></a> [database](#input\_database) | Specify the database name. The database name must be 1-60 characters long and start with any lower letter, combined with number, or symbols: - \_.<br>The database name cannot be PostgreSQL forbidden keyword. | `string` | `"mydb"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Specify the deployment engine version, select from https://cloud.google.com/sql/docs/db-versions. | `string` | `"15.0"` | no |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Specify the infrastructure information for deploying.<br><br>Examples:<pre>infrastructure:<br>  vpc_id: string, optional                  # the ID of the VPC where the PostgreSQL service applies. It is a fully-qualified resource name, such as projects/{project_id}/global/networks/{network_id}.</pre> | <pre>object({<br>    vpc_id = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_password"></a> [password](#input\_password) | Specify the account password. The password must be 8-128 characters long and start with any letter, number, or symbols: ! # $ % ^ & * ( ) \_ + - =.<br>If not specified, it will generate a random password. | `string` | `null` | no |
| <a name="input_replication_readonly_replicas"></a> [replication\_readonly\_replicas](#input\_replication\_readonly\_replicas) | Specify the number of read-only replicas under the replication deployment. | `number` | `1` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Specify the computing resources.<br>The computing resource design of Google Cloud is very complex, it also needs to consider on the storage resource, please view the specification document for more information.<br><br>Examples:<pre>resources:<br>  class: string, optional            # https://cloud.google.com/sql/docs/postgres/instance-settings</pre> | <pre>object({<br>    class = optional(string, "db-f1-micro")<br>  })</pre> | <pre>{<br>  "class": "db-f1-micro"<br>}</pre> | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Specify the storage resources, select from PD\_SSD or PD\_HDD.<br>Choosing the storage resource is also related to the computing resource, please view the specification document for more information.<br><br>Examples:<pre>storage:<br>  class: string, optional        # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance#disk_type<br>  size: number, optional         # in megabyte</pre> | <pre>object({<br>    class = optional(string, "PD_SSD")<br>    size  = optional(number, 10 * 1024)<br>  })</pre> | <pre>{<br>  "class": "PD_SSD",<br>  "size": 10240<br>}</pre> | no |
| <a name="input_username"></a> [username](#input\_username) | Specify the account username. The username must be 1-32 characters long and start with lower letter, combined with number.<br>The username cannot be PostgreSQL forbidden keyword. | `string` | `"rdsuser"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address"></a> [address](#output\_address) | The address, a string only has host, might be a comma separated string or a single string. |
| <a name="output_address_readonly"></a> [address\_readonly](#output\_address\_readonly) | The readonly address, a string only has host, might be a comma separated string or a single string. |
| <a name="output_connection"></a> [connection](#output\_connection) | The connection, a string combined host and port, might be a comma separated string or a single string. |
| <a name="output_connection_readonly"></a> [connection\_readonly](#output\_connection\_readonly) | The readonly connection, a string combined host and port, might be a comma separated string or a single string. |
| <a name="output_context"></a> [context](#output\_context) | The input context, a map, which is used for orchestration. |
| <a name="output_database"></a> [database](#output\_database) | The name of PostgreSQL database to access. |
| <a name="output_password"></a> [password](#output\_password) | The password of the account to access the database. |
| <a name="output_port"></a> [port](#output\_port) | The port of the service. |
| <a name="output_refer"></a> [refer](#output\_refer) | The refer, a map, including hosts, ports and account, which is used for dependencies or collaborations. |
| <a name="output_username"></a> [username](#output\_username) | The username of the account to access the database. |
<!-- END_TF_DOCS -->
