# Publishing vatomic API documentation

This project generates markdown API docs with `mdox`/Doxygen (target `markdown`)
and publishes them to `open-s4c/open-s4c.github.io` under `vatomic/api/`.

## Generate docs locally

```sh
cmake -S . -B build
cmake --build build --target markdown
```

By default the output ends up in `doc/api`.

## Publish locally

Use `scripts/publish-docs.sh` from the repo root:

- Versioned release:

  ```sh
  scripts/publish-docs.sh --version vX.Y.Z --docs-dir doc/api
  ```

- Latest main snapshot:

  ```sh
  scripts/publish-docs.sh --main --docs-dir doc/api
  ```

Optional flags:

- `--checkout-dir <path>` reuse/inspect the pages checkout
- `--repo-url <url>` override the pages repo (defaults to
  `https://github.com/open-s4c/open-s4c.github.io.git` or `$PUBLISH_REPO_URL`)
- `--ssh` use SSH for the pages repo (sets `git@github.com:open-s4c/open-s4c.github.io.git`)
- `--project <name>` change the top-level folder (defaults to `$PUBLISH_PROJECT`
  or the current directory name)
- `--dry-run` sync files but skip commit/push

The script wipes the target folder (`<project>/api/<version|main>`) before
copying to avoid stale files.

## CI publishing

The `publish-docs` workflow builds `markdown` and then calls
`scripts/publish-docs.sh`:

- Tag `v*` pushes publish to `vatomic/api/<tag>`
- Manual `workflow_dispatch` publishes to `vatomic/api/main`

The workflow uses `GITHUB_TOKEN` to push to `open-s4c/open-s4c.github.io`.
