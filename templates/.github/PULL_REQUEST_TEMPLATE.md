# Pull Request

## Description

<!-- Provide a clear and concise description of your changes -->

## Type of Change

Please check the relevant option(s):

- [ ] 🐛 Bug fix (`fix`)
- [ ] ✨ New feature (`feat`)
- [ ] 💥 Breaking change (`feat!` or `fix!`)
- [ ] 📝 Documentation update (`docs`)
- [ ] 🎨 Code style/formatting (`style`)
- [ ] ♻️  Refactoring (`refactor`)
- [ ] ⚡ Performance improvement (`perf`)
- [ ] ✅ Test update (`test`)
- [ ] 🔧 Build/CI update (`build`/`ci`)
- [ ] 🧹 Chore/maintenance (`chore`)

## Linked Issues

<!-- Link to related issues using keywords -->

Closes #
Fixes #
Related to #

## Changes Made

<!-- List the key changes in this PR -->

- Change 1
- Change 2
- Change 3

## Testing

<!-- Describe the tests you ran and their results -->

### Test Environment

- **OS**: (e.g., Ubuntu 22.04, macOS 14.0)
- **Shell**: (e.g., bash 5.2)
- **Relevant tool versions**:

### Test Cases

- [ ] Ran existing tests: `bazel test //...` or equivalent
- [ ] Tested locally with provided examples
- [ ] Added new tests for new functionality
- [ ] Verified documentation examples work
- [ ] Tested in CI environment

### Test Results

```
# Paste relevant test output here
```

## Documentation

<!-- Check all that apply -->

- [ ] Updated relevant documentation in `docs/`
- [ ] Updated `README.md` if user-facing changes
- [ ] Updated `CHANGELOG.md` (or will be updated by maintainer)
- [ ] Added/updated code comments for complex logic
- [ ] Added usage examples

## Screenshots

<!-- If applicable, add screenshots to demonstrate the changes -->

## Breaking Changes

<!-- If this PR introduces breaking changes, describe them and the migration path -->

**Does this PR introduce breaking changes?** Yes / No

If yes, describe:
- What breaks:
- Why it's necessary:
- Migration guide:

## Checklist

<!-- Verify all items before requesting review -->

### Code Quality

- [ ] Code follows the project's style guidelines
- [ ] Used semantic commit messages (see [SEMANTIC-COMMITS.md](../docs/SEMANTIC-COMMITS.md))
- [ ] Branch name follows convention: `<type>/<issue>-<description>`
- [ ] All commits reference the issue number
- [ ] Shellcheck passes (for shell scripts)
- [ ] No linter warnings introduced

### Testing

- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Edge cases are covered
- [ ] Manual testing performed

### Documentation

- [ ] User-facing changes documented
- [ ] API changes documented
- [ ] Examples updated/added
- [ ] Comments added for complex code

### CI/CD

- [ ] All CI checks pass
- [ ] Workflows updated if needed
- [ ] No failing or flaky tests

### Review

- [ ] Self-reviewed the code
- [ ] Checked for potential security issues
- [ ] Verified no secrets or sensitive data committed
- [ ] Ready for maintainer review

## Additional Notes

<!-- Any additional information for reviewers -->

## For Maintainers

<!-- Maintainers: Fill this section when merging -->

- [ ] Version bump needed (major/minor/patch)
- [ ] Changelog updated
- [ ] Release notes prepared
- [ ] Documentation site updated (if applicable)

---

**By submitting this PR, I confirm that my contribution is made under the terms of the project's license.**

See [licenses/CLA.md](../licenses/CLA.md) for details.
