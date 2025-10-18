# Dual Licensing Implementation Guide

This guide helps teams integrate Artagon's dual licensing materials into
their repositories, build pipelines, and customer workflows.

## 1. File Structure

Place the following files in the repository root:

- `LICENSE`
- `LICENSE-AGPL.txt`
- `LICENSE-COMMERCIAL.txt`
- `LICENSING.md`
- `CLA.md`
- `CLA-CORPORATE.md`
- `README-LICENSE-SECTION.md`
- `SOURCE-FILE-HEADER.txt`
- `TRADEMARK-POLICY.md`
- `IMPLEMENTATION-GUIDE.md`

Ensure version control tracks all license files. Add internal wiki links
pointing to the latest commit for reference.

## 2. Repository Checklist

- [ ] Replace the README licensing section with the contents of
      `README-LICENSE-SECTION.md`.
- [ ] Update issue and pull request templates to reference CLAs.
- [ ] Configure a CLA bot (e.g., CLA Assistant) using `CLA.md` and
      `CLA-CORPORATE.md`.
- [ ] Add repository topics such as `license:agpl-3.0` and
      `dual-license`.
- [ ] Enable branch protection rules requiring CLA status checks.
- [ ] Store countersigned commercial agreements in a secure location.

## 3. Package Manager Metadata

Update project metadata files to reference the dual license:

- **npm / TypeScript `package.json`:**
  ```json
  {
    "license": "AGPL-3.0-or-later",
    "publishConfig": {
      "registry": "https://registry.npmjs.org/"
    }
  }
  ```
  Include a `NOTICE` file linking to the commercial license page and a
  README callout referencing `LICENSE`, `LICENSE-AGPL.txt`, and
  `LICENSE-COMMERCIAL.txt`.

- **TypeScript source header (e.g., `src/main.ts`):**
  ```ts
  /**
   * Copyright (C) 2025 Artagon LLC
   * Dual licensed under AGPL-3.0 or the Artagon Commercial License.
   * See LICENSE-AGPL.txt and LICENSE-COMMERCIAL.txt.
   */
  ```
  Apply the same header to generated declaration files or API
  documentation to maintain clear attribution.

- **Python `pyproject.toml`:**
  ```toml
  [project]
  license = { text = "Dual licensed: AGPL-3.0 and Artagon Commercial License" }
  ```

- **Maven `pom.xml`:**
  ```xml
  <licenses>
    <license>
      <name>GNU Affero General Public License v3.0</name>
      <url>https://www.gnu.org/licenses/agpl-3.0.txt</url>
      <distribution>repo</distribution>
    </license>
    <license>
      <name>Artagon Commercial License</name>
      <url>https://www.artagon.com/pricing</url>
      <distribution>manual</distribution>
    </license>
  </licenses>
  ```
  Add the header from `SOURCE-FILE-HEADER.txt` to Java source files or
  configure your IDE templates accordingly.

- **Gradle (`build.gradle.kts`):**
  ```kotlin
  plugins {
      `java-library`
      `maven-publish`
  }

  publishing {
      publications {
          create<MavenPublication>("main") {
              pom {
                  licenses {
                      license {
                          name.set("GNU Affero General Public License v3.0")
                          url.set("https://www.gnu.org/licenses/agpl-3.0.txt")
                          distribution.set("repo")
                      }
                      license {
                          name.set("Artagon Commercial License")
                          url.set("https://www.artagon.com/pricing")
                          distribution.set("manual")
                      }
                  }
              }
          }
      }
  }
  ```
  Provide a Gradle task (e.g., `tasks.register("showLicense")`) that
  prints the dual license notice for downstream consumers.

- **Go modules (`go.mod`):**
  ```go
  module github.com/artagon/example

  go 1.22

  // Dual licensed under AGPL-3.0 or the Artagon Commercial License.
  // See LICENSE-AGPL.txt and LICENSE-COMMERCIAL.txt.
  ```
  Include the same comment block in `doc.go` so `go doc` users see the
  dual licensing notice. When distributing binaries, add a `--license`
  flag that echoes the paths to the license files.

## 4. CI/CD Integration

- Add a pipeline step that verifies the presence of required license
  files.
- Include automated checks that Contributions contain the header from
  `SOURCE-FILE-HEADER.txt`.
- Provide separate build profiles for AGPL and commercial deployments to
  simplify packaging and compliance.
- Store commercial license keys or entitlements in a secure secrets
  manager; rotate regularly.

## 5. GitHub Settings

- Configure repository visibility and permissions to limit who can close
  licensing-related issues.
- Enable CODEOWNERS with legal or compliance owners for license files.
- Add a `LICENSE` topic and pin a licensing issue to the repository
  homepage.
- Use GitHub Discussions or a dedicated category for licensing FAQs.

## 6. Sales and Support Workflow

1. Direct prospects to https://www.artagon.com/pricing for tier
   comparisons.
2. Provide a request form that captures use case, deployment model,
   seat counts, and desired support level.
3. Route signed commercial agreements to `legal@artagon.com` and
   `sales@artagon.com` for countersignature.
4. Issue license keys or entitlements via the support portal.
5. Document renewal dates and assign account ownership within the CRM.

## 7. Internal Training

- Hold a licensing enablement session for engineering, sales, and
  support teams.
- Maintain an internal FAQ summarizing when to recommend the commercial
  license.
- Review dual license implications during design reviews to prevent
  unintended copyleft obligations.

## 8. Monitoring and Compliance

- Track commercial customer entitlements and active deployments.
- Periodically audit public forks for compliance with source disclosure.
- Maintain a process for handling suspected license violations and
  escalate to `legal@artagon.com`.

## 9. External Resources

- Pricing page: https://www.artagon.com/pricing
- Licensing FAQ: https://www.artagon.com/licensing-faq
- Support portal: https://www.artagon.com/support (commercial access)
- Licensing contact: `licensing@artagon.com`
- Sales contact: `sales@artagon.com`

Keep this guide updated as policies evolve. Schedule annual reviews with
legal counsel to validate compliance and adjust commercial terms.

## 10. Automation Scripts and Workflows

- Run `scripts/setup-artagon-license.sh` inside a new repository to add
  this project as a submodule (default path `.legal/artagon-license`)
  and export the required license files.
- Use `scripts/export-license-assets.sh` whenever the submodule updates
  to copy the latest documents into the repository root.
- Reuse the workflow defined at
  `.github/workflows/update-artagon-license.yml` by calling it from
  other Artagon repositories. The workflow updates the submodule,
  exports assets, and opens a pull request if anything changed.
