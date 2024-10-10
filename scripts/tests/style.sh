#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

pylint

check=working-tree-changes ./scripts/githooks/check-english-usage.sh && \
  check=staged-changes ./scripts/githooks/check-english-usage.sh
