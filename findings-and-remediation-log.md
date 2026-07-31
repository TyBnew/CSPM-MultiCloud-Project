# Findings & Remediation Log

Source: AWS Security Hub (Essentials plan — AWS Foundational Security Best Practices + CIS AWS Foundations Benchmark) and Microsoft Defender for Cloud (Foundational CSPM tier).

## AWS Findings

| Resource | Misconfiguration | Security Hub Finding | Severity | Real-World Risk | Remediation |
|---|---|---|---|---|---|
| Public S3 bucket | Public access block disabled + a bucket policy explicitly granting `s3:GetObject` to any principal | S3 buckets should block public read access | Critical | Publicly readable buckets are one of the most common real-world breach vectors — data exposed to anyone on the internet, no authentication required, often found by automated scanners within minutes | Re-enabled the public access block in Terraform and removed the public bucket policy. Verified fixed via `aws s3api get-public-access-block`. |
| Public S3 bucket | Same bucket, same underlying cause | S3 buckets should block public access | High | Same exposure, flagged by a second control checking the access-block configuration itself | Same fix as above. |
| IAM role + policy | Trust policy allowed any AWS principal to assume the role; attached policy granted full `*` administrative permissions | IAM policies should not allow full "*" administrative privileges | High | Combined, this is a privilege-escalation and lateral-movement path — any AWS account could potentially assume full administrative control | Scoped the trust policy to the account's own root, and scoped the permissions policy to least-privilege S3 read access. Verified via `aws iam get-policy-version`. |

## Azure Findings

| Resource | Misconfiguration | Defender for Cloud Recommendation | Severity | Real-World Risk | Remediation |
|---|---|---|---|---|---|
| Storage account | `allow_nested_items_to_be_public` enabled + a container set to public access | Storage account public access should be disallowed | Medium | Publicly accessible blob storage is functionally identical in risk to a public S3 bucket — unauthenticated data exposure | Disabled public access at the account level and set the container to private in Terraform. Verified via `az storage account show`. |
| Key Vault | Purge protection disabled | Key vaults should have deletion protection enabled | Medium | Without purge protection, secrets and keys can be permanently deleted before the soft-delete retention window applies — no recovery possible | Enabled purge protection in Terraform (a one-way setting in Azure — cannot be reversed once turned on). Verified via `az keyvault show`. |
| Network security group | Inbound rule allowed SSH (port 22) from anywhere (`0.0.0.0/0`) | Security groups should not allow ingress from 0.0.0.0/0 to port 22 (parallel finding on the AWS side; same control category) | High | SSH open to the entire internet is a direct exposure to brute-force and credential-stuffing attacks | Scoped the source address to a single known IP in Terraform. Verified via `az network nsg rule show`. |

## Pre-Existing Issues Found and Cleaned Up

While reviewing findings, several unrelated pre-existing issues on the AWS account were also surfaced by the scan and cleaned up:

- Two old, unused S3 buckets with public access enabled were identified, emptied (including versioned objects and delete markers), and deleted.
- One of those buckets had an Elastic Beanstalk-managed policy explicitly denying deletion, which required removing the bucket policy before the bucket itself could be deleted.
- Two unused security groups with unrestricted inbound access were confirmed to have no attached resources and were deleted.

This is a useful illustration of what CSPM tooling is actually good at: catching accumulated drift and forgotten resources, not just the misconfigurations someone deliberately introduces.

## Cross-Cloud Findings Aggregation

AWS Security Hub's native Azure-monitoring integration (a capability released in mid-2026) was evaluated as a way to view findings from both clouds in one place. Before running the integration's auto-generated setup script, a manual review against the vendor's own published documentation found the script requested substantially more Microsoft Graph API permissions than documented — including write access to user authentication methods and conditional access policies, which have no legitimate purpose in a posture-management integration and represent a plausible privilege-escalation path. The script was corrected to request only the documented permissions before it was run.

After that fix, the integration setup hit a confirmed bug in the Azure CLI version in use, which blocks certain role assignments needed for the integration to complete. This was independently verified as a genuine tool limitation — not a permissions gap — by confirming through multiple methods that the required roles were correctly assigned.

Given the scope of remaining setup work depending on that same broken operation, the native integration was set aside in favor of a lightweight custom solution: a script that pulls findings directly from both AWS Security Hub and Microsoft Defender for Cloud via their respective APIs and merges them into a single report. This produces the same practical outcome — one place to review findings across both clouds — without depending on the broken vendor tooling.

## Lessons and Analyst Notes

**Not every finding needs fixing.** Two AWS default security groups were flagged for not restricting traffic, but default VPC security groups are created automatically by AWS and cannot be deleted or reconfigured in the way the finding implies. Recognizing an unavoidable platform default versus a genuinely actionable finding is a core part of triaging CSPM output — treating every finding as equally urgent creates alert fatigue and wastes remediation effort on things that were never fixable to begin with.

**A permissions error doesn't always mean a permissions problem.** One AWS bucket resisted deletion with an access-denied error even though the deleting account was the account owner. The actual cause was a resource-based policy attached directly to the bucket by an AWS service (Elastic Beanstalk), overriding otherwise-sufficient account permissions. Diagnosing this required checking the resource's own policy, not just the account's IAM permissions.

**Reviewing third-party automation before running it matters.** A vendor-generated setup script requested significantly broader permissions than its own documentation called for. Catching that before execution, rather than trusting generated tooling by default, is a concrete example of applying security judgment rather than just following instructions.

**When a vendor integration is genuinely broken, building a minimal working alternative is often faster than continued troubleshooting.** A short script built directly against both clouds' published APIs delivered the same practical result the broken integration was meant to provide.
