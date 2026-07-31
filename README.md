# Multi-Cloud CSPM Lab — AWS + Azure

A hands-on cloud security posture management (CSPM) project built to demonstrate infrastructure-as-code security practices across AWS and Azure: provisioning intentionally misconfigured infrastructure with Terraform, detecting the misconfigurations with each cloud's native CSPM tooling, remediating everything through code, and building a custom aggregator to unify findings across both clouds.

## Why This Project

Cloud security roles increasingly expect comfort across more than one cloud provider. This project was built to close that gap directly: real Terraform code, real misconfigurations, real findings from AWS Security Hub and Microsoft Defender for Cloud, and a real remediation loop — not a tutorial walkthrough.

## Architecture

**AWS side** (`aws-cspm-lab/`)
- VPC with public and private subnets, internet gateway, route tables
- Two S3 buckets: one intentionally public, one secured (encrypted, versioned, public access blocked)
- Two IAM roles: one with an unrestricted trust policy and full admin permissions, one scoped to read-only access from the account itself
- CloudTrail, multi-region, log file validation enabled
- AWS Security Hub (Essentials plan) — AWS Foundational Security Best Practices + CIS AWS Foundations Benchmark

**Azure side** (`azure-cspm-lab/`)
- Resource group, virtual network, subnet
- Two storage accounts: one intentionally public, one secured (private, TLS 1.2 minimum)
- Two network security groups: one with SSH open to the internet, one scoped to a single IP
- Two Key Vaults: one without purge protection, one fully hardened
- Microsoft Defender for Cloud — Foundational CSPM (free tier)

**Cross-cloud findings aggregation** (`multicloud-findings-report.ps1`)
- A native AWS Security Hub → Azure integration exists (released July 2026) but was not used in production form here — see [Integration Notes](#integration-notes) below.
- Instead, a PowerShell script pulls findings directly from both clouds' APIs (`aws securityhub get-findings` and `az security assessment list`) and merges them into a single report, exported to `multicloud-findings-report.csv`.

## Tools Used

Terraform (`~> 5.0` AWS provider, `~> 4.0` azurerm provider), AWS CLI, Azure CLI, PowerShell, AWS Security Hub, Microsoft Defender for Cloud.

## How to Reproduce

1. Install Terraform, AWS CLI, and Azure CLI.
2. Configure AWS credentials (`aws configure`) and authenticate to Azure (`az login`).
3. `cd aws-cspm-lab && terraform init && terraform apply`
4. `cd azure-cspm-lab && terraform init && terraform apply` (requires `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` environment variables set via an Azure service principal)
5. Enable AWS Security Hub and Microsoft Defender for Cloud (Foundational CSPM) in each console.
6. Allow several hours for both tools to complete their first assessment pass.
7. Run `multicloud-findings-report.ps1` to generate the unified findings report.

## Findings and Remediation

Every misconfiguration built into this lab, the specific finding it triggered, why it's a real-world risk, and how it was fixed — entirely through Terraform code, never the console — is documented in [`findings-and-remediation-log.md`](./findings-and-remediation-log.md). Highlights:

- Public S3 bucket and public Azure storage account, both remediated by re-enabling public access blocks in code.
- Overly permissive AWS IAM role (wildcard trust policy + full admin permissions), remediated by scoping the trust policy to the account and the permissions to least-privilege S3 read access.
- Azure Key Vault without purge protection, remediated by enabling it (a one-way setting in Azure — cannot be reversed once turned on).
- NSG rule allowing SSH from anywhere, remediated by scoping the source IP to a single address.
- Two pre-existing, unrelated findings discovered on the AWS account during the scan (an old public S3 bucket and an Elastic Beanstalk bucket) were also identified, triaged, and cleaned up.

## Integration Notes

AWS Security Hub's native Azure monitoring integration (released July 14, 2026) was evaluated as part of this project. Before executing AWS's auto-generated setup script, a manual review against AWS's own documentation found the script requested 14 Microsoft Graph API permissions when only 3 were actually required — the extra 11 included write access to user authentication methods and conditional access policies, a plausible privilege-escalation vector unrelated to CSPM functionality. The script was corrected before running.

After that fix, the integration hit a confirmed Azure CLI bug (tested against CLI 2.88.0) that blocks role assignments at management-group and tenant-root scope, independently verified as a tool limitation rather than a permissions gap. Given the scope of remaining work depending on that same broken operation, the live integration was stopped in favor of the custom PowerShell aggregator described above — full details in the findings log.

## Key Takeaways

- Reviewing third-party automation before execution and catching an over-scoped permission request is a stronger security practice than trusting generated tooling by default.
- CSPM findings require triage, not blind remediation — some findings (like default VPC security groups) are unavoidable platform behavior, not actionable misconfigurations.
- When a vendor integration is genuinely broken, building a minimal working alternative against the same underlying APIs is often faster and more defensible than open-ended troubleshooting.
