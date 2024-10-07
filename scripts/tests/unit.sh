#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

make dependencies
poetry install
poetry run pytest
