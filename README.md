# EventBridge Bus, Rule & Target

A custom EventBridge event bus, a pattern-filtered rule, and a target wired end-to-end - encryption at rest always on, least-privilege log delivery, and a 24h retry policy with optional DLQ.

This module was **applied to a real AWS account, verified, and destroyed** on 2026-06-30 - not just `terraform validate`d.

Check it yourself, no account needed:

```
curl -s https://www.iac-bazaar.com/api/artifacts/aws-eventbridge/verification
```

The receipt names every check that ran, when it ran, and the SHA-256 of the
archive it describes. Full detail: [www.iac-bazaar.com/catalog/aws-eventbridge](https://www.iac-bazaar.com/catalog/aws-eventbridge)

## Usage

```hcl
module "eventbridge" {
  source  = "registry.terraform.io/CyberCoreSystems/eventbridge/aws"
  version = "~> 1.0"

  # See variables.tf for the full input contract.
}
```

## Why this module

Every module we publish goes through the same checks before release:

| check | what it means |
|---|---|
| `tofu validate` + `tflint` | it parses and lints clean |
| `checkov` | scanned for insecure defaults |
| **live test** | **really applied to a cloud account, outputs verified, then destroyed** |

That last row is the one most module catalogues skip. A module that has never
been applied has never been proven.

## Provider compatibility

```
aws >= 6.0, < 7.0
```

## More modules

This is one of **179 verified Terraform modules across 19 cloud platforms** -
AWS, Azure, GCP, Oracle OCI, Cloudflare, Akamai, DigitalOcean, Linode, Hetzner,
Vultr, Scaleway, Alibaba, IBM, UpCloud, Civo, Exoscale, OVH, Tencent and Huawei.

Browse the full catalogue at **[www.iac-bazaar.com](https://www.iac-bazaar.com)**, including
production landing zones for AWS, Azure and GCP that have each been live-tested
as a single composed apply.

- Module page: [https://www.iac-bazaar.com/catalog/aws-eventbridge](https://www.iac-bazaar.com/catalog/aws-eventbridge)
- How verification works: [https://www.iac-bazaar.com/verified](https://www.iac-bazaar.com/verified)

## Licence

See [LICENSE](./LICENSE).
