# Build Mission PBO Workflow

This repository includes a GitHub Actions workflow that packages an Arma 3 mission into a `.pbo` file and optionally publishes a GitHub Release.

The workflow is designed to work directly from this repository without requiring HEMTT or local tooling.

---

## Features

- Builds an Arma 3 mission into a `.pbo` using Arma 3 Tools (AddonBuilder)
- Automatically creates a GitHub Release when a new tag is pushed
- Optional manual version bump via GitHub Actions UI
- Uploads the `.pbo` as a workflow artifact on every build
- Filters out repo-only content before packing the mission

Filtered by default:

- `.git/`
- `.github/`
- `.vscode/`
- `.gitignore`
- `dist/`

---

## Workflow Triggers

### 1. Tag Push (Release Build)

Pushing a version tag (for example `v1.2.0`) will:

- Build the mission `.pbo`
- Create a GitHub Release for that tag
- Attach the `.pbo` as a release asset

```bash
git tag v1.2.0
git push origin v1.2.0
```

For tag builds, the tag name is the **source of truth** for the version.

---

### 2. Manual Workflow Dispatch (Optional Version Bump)

From GitHub:

1. Go to **Actions**
2. Select **Build Mission PBO**
3. Click **Run workflow**
4. Choose a `version_bump`:
   - `none` – build only (no release)
   - `patch`, `minor`, `major` – bumps version, updates README, and creates a release

This is useful when you want GitHub to handle version increments for you.

---

### 3. Branch Pushes and Pull Requests (Build Only)

Pushes to `main` or `Develop`, and pull requests targeting those branches:

- Build the mission `.pbo`
- Upload the `.pbo` as a workflow artifact

No GitHub Release is created unless the run is triggered by a **tag push** or **manual version bump**.

---

## Version Management

### Where the version is stored

The workflow reads and (for manual dispatch bumps only) updates the version in `README.md`
using this format:

    **Current Version**: X.Y.Z

### Tag builds

For tags like `v2.0.1`:

- Tag name: `v2.0.1`
- Version used: `2.0.1`

Tag builds do not modify or commit the README.

---

## Configuration

Edit the mission details in `.github/workflows/build-mission.yml`:

```yaml
env:
  MISSION_NAME: FLOPS_FLO
  MISSION_MAP: Altis
```

This produces a mission folder named:

```
FLOPS_FLO.Altis/
```

and a packed file:

```
FLOPS_FLO.Altis.pbo
```

---

## Build Process

1. A temporary mission folder is created:

   ```
   ${MISSION_NAME}.${MISSION_MAP}
   ```

2. Repository contents are copied into it, excluding:
   - `.git/`
   - `.github/`
   - `.vscode/`
   - `.gitignore`
   - `dist/`

3. Arma 3 Tools (AddonBuilder) packages the folder into a `.pbo`

4. The `.pbo` is placed in the `dist/` directory

5. The `.pbo` is uploaded as:
   - A workflow artifact (all builds)
   - A GitHub Release asset (tag or manual bump builds)

---

## Outputs

### Workflow Artifacts

Every workflow run uploads the generated `.pbo` as an artifact.
Artifacts are retained for 30 days by default.

### GitHub Releases

When a release is created, it includes:

- The mission `.pbo`
- Auto-generated release notes

---

## Customization

### Excluding additional files or folders

Update the exclusion list in the **Prepare Mission Folder** step inside the workflow to filter additional paths.

### Packaging a dedicated mission directory (recommended)

If you move your mission into its own folder (for example `missions/FLOPS_FLO.Altis/`),
the workflow can be simplified to package only that directory instead of copying the entire repository.

This reduces the risk of accidentally shipping non-mission files.

---

## Troubleshooting

### No `.pbo` found in `dist/`

- The build step failed
- Check logs under **Build PBO** in GitHub Actions

### Release not created

Releases are created only when:

- A tag matching `v*` is pushed, or
- The workflow is manually run with a version bump

### README version not updating

The README is updated only during manual version bumps.
Tag builds never modify repository files.

---

## Current Version

**Current Version**: 1.0.0
