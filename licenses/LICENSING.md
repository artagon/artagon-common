# Artagon Licensing Guide

This guide explains how Artagon LLC licenses its software, how to stay
compliant, and when to choose the commercial alternative. Please review
this document alongside `LICENSE`, `LICENSE-AGPL.txt`, and
`LICENSE-COMMERCIAL.txt`. Always consult legal counsel before relying on
these materials.

## Dual License Overview

Artagon distributes the project under a dual license model:

- **GNU Affero General Public License v3.0 (AGPL-3.0):** Free for open
  source use with strong copyleft obligations, including the network
  use clause.
- **Artagon Commercial License:** Paid option for organizations that
  require proprietary rights, confidentiality, or tailored support.

Both licenses cover the same code base. You must select and comply with
one option for each deployment.

## Quick Selection Checklist

| Requirement | Choose AGPL-3.0 | Choose Commercial |
|-------------|-----------------|-------------------|
| Source code disclosure acceptable | ✅ | ❌ |
| Operating SaaS without sharing code | ❌ | ✅ |
| Need warranty, indemnity, or SLAs | ❌ | ✅ |
| Internal open source contribution | ✅ | ✅ *(with CLA)* |
| Distributing proprietary product | ❌ | ✅ |
| Budget sensitivity | ✅ | Depends |

If any Commercial column item applies, contact `sales@artagon.com` for
pricing and execution of `LICENSE-COMMERCIAL.txt`.

## Compliance Steps

### AGPL-3.0 Users

1. **Provide prominent license notice** referencing `LICENSE-AGPL.txt`.
2. **Disclose complete corresponding source** for any distribution or
   network deployment. Include build scripts and interface definition
   files.
3. **Offer source to network users** via an accessible link or download.
4. **Retain copyright and attribution** banners.
5. **Publish modifications** under AGPL-3.0 within a reasonable time.

### Commercial Licensees

1. **Execute Order Form** and receive countersigned agreement.
2. **Maintain license records** (metrics, developer seats, deployments).
3. **Follow Trademark Policy** when referencing Artagon.
4. **Include required notices** from `SOURCE-FILE-HEADER.txt` in any
   redistributed source files.
5. **Renew support and subscription** per agreement to maintain access
   to updates.

## Contributor License Agreements

All contributors must sign the appropriate CLA before pull requests can
be merged:

- Individuals: `CLA.md`
- Corporate contributors: `CLA-CORPORATE.md`

Submit signed agreements to `cla@artagon.com`. The CLA ensures that
Artagon may continue offering the project under both AGPL-3.0 and the
commercial license.

## Frequently Asked Questions

**Can I start under AGPL-3.0 and upgrade later?**  
Yes. Contact sales when you need the commercial license. Existing AGPL
deployments remain under AGPL; new deployments can transition after the
commercial agreement is executed.

**Do I need to release internal tooling changes?**  
If the tooling interacts with users over a network (even internal users
behind VPN), AGPL-3.0 requires source disclosure. The commercial
license removes this obligation.

**What if I only consume the public API?**  
API usage is governed by the terms of the service you access. If you
deploy the software yourself, you must comply with the selected license.

**How do I handle third-party dependencies?**  
Review each dependency's license. Ensure compatibility with the
selected license and comply with attribution requirements.

**Can I resell Artagon software?**  
Resale or re-hosting requires a commercial license with appropriate
reseller provisions. Contact `sales@artagon.com`.

## Contact and Resources

- Licensing questions: `licensing@artagon.com`
- Sales inquiries and quotes: `sales@artagon.com`
- Support (commercial customers): `support@artagon.com`
- Pricing information: https://www.artagon.com/pricing
- Licensing FAQ: https://www.artagon.com/licensing-faq

## Next Steps

- Review the implementation checklist in `IMPLEMENTATION-GUIDE.md`.
- Update your README using `README-LICENSE-SECTION.md`.
- Ensure CI workflows verify CLA status and license notices.
- Schedule legal review before publishing or distributing the project.
