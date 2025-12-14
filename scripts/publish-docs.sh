#!/bin/sh
# Copyright (C) Huawei Technologies Co., Ltd. 2025. All rights reserved.
# SPDX-License-Identifier: MIT

set -eu

usage() {
    cat <<'EOF'
Usage: $(basename "$0") (--version vX.Y.Z | --main) [--project NAME] [--docs-dir PATH] [--checkout-dir PATH] [--repo-url URL | --ssh] [--dry-run]

Options:
  --version vX.Y.Z    Publish under <project>/api/vX.Y.Z
  --main              Publish under <project>/api/main
  --project NAME      Project folder name under the pages repo (default: $PUBLISH_PROJECT or current directory name)
  --docs-dir PATH     Path to generated docs (default: ./doc/api)
  --checkout-dir PATH Directory to clone/update open-s4c.github.io (default: temp dir)
  --repo-url URL      Override pages repo URL (default: https://github.com/open-s4c/open-s4c.github.io.git or PUBLISH_REPO_URL)
  --ssh               Use SSH for pages repo (sets repo URL to git@github.com:open-s4c/open-s4c.github.io.git)
  --dry-run           Sync files but skip git commit/push
  -h, --help          Show this help
EOF
    exit 1
}

require_arg() {
    if [ $# -lt 1 ] || [ -z "$1" ]; then
        echo "Missing argument" >&2
        usage
    fi
}

version=""
publish_main=0
docs_dir=""
checkout_dir=""
repo_url="${PUBLISH_REPO_URL:-https://github.com/open-s4c/open-s4c.github.io.git}"
repo_branch="${PUBLISH_REPO_BRANCH:-main}"
project_name="${PUBLISH_PROJECT:-}"
dry_run=0
use_ssh=0

while [ $# -gt 0 ]; do
    case "$1" in
        --version)
            shift
            require_arg "$1"
            version="$1"
            ;;
        --main)
            publish_main=1
            ;;
        --docs-dir)
            shift
            require_arg "$1"
            docs_dir="$1"
            ;;
        --project)
            shift
            require_arg "$1"
            project_name="$1"
            ;;
        --checkout-dir)
            shift
            require_arg "$1"
            checkout_dir="$1"
            ;;
        --repo-url)
            shift
            require_arg "$1"
            repo_url="$1"
            ;;
        --ssh)
            use_ssh=1
            ;;
        --dry-run)
            dry_run=1
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
    shift
done

if [ -n "${version}" ] && [ "${publish_main}" -eq 1 ]; then
    echo "Use either --version or --main, not both" >&2
    usage
fi
if [ -z "${version}" ] && [ "${publish_main}" -eq 0 ]; then
    echo "One of --version or --main is required" >&2
    usage
fi

if [ -z "${docs_dir}" ]; then
    docs_dir="$(pwd)/doc/api"
fi
if [ ! -d "${docs_dir}" ]; then
    echo "Docs directory '${docs_dir}' not found; run 'cmake --build build --target markdown' first or pass --docs-dir" >&2
    exit 1
fi
if [ -z "${project_name}" ]; then
    project_name="$(basename "$(pwd)")"
fi
if [ "${use_ssh}" -eq 1 ]; then
    repo_url="git@github.com:open-s4c/open-s4c.github.io.git"
fi

if [ -z "${checkout_dir}" ]; then
    checkout_dir="$(mktemp -d "${TMPDIR:-/tmp}/vatomic-docs.XXXXXX")"
    trap 'rm -rf "${checkout_dir}"' EXIT
else
    mkdir -p "${checkout_dir}"
fi

pages_dir="${checkout_dir}"

if [ -d "${pages_dir}/.git" ]; then
    git -C "${pages_dir}" fetch origin "${repo_branch}"
    git -C "${pages_dir}" checkout "${repo_branch}"
    git -C "${pages_dir}" reset --hard "origin/${repo_branch}"
else
    git clone --branch "${repo_branch}" "${repo_url}" "${pages_dir}"
fi

if [ "${publish_main}" -eq 1 ]; then
    target="main"
else
    target="${version}"
fi

target_path="${project_name}/api/${target}"
dest_dir="${pages_dir}/${target_path}"

rm -rf "${dest_dir}"
mkdir -p "${dest_dir}"

if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${docs_dir}/" "${dest_dir}/"
else
    (cd "${docs_dir}" && find . -maxdepth 0 >/dev/null)
    cp -R "${docs_dir}/." "${dest_dir}/"
fi

if [ "${dry_run}" -eq 1 ]; then
    echo "[dry-run] Synced docs to ${dest_dir}; skipping commit/push"
    exit 0
fi

cd "${pages_dir}"
git add "${target_path}"
if git diff --staged --quiet; then
    echo "No changes to publish."
    exit 0
fi

git commit -m "Publish vatomic docs ${target}"
git push origin "${repo_branch}"
