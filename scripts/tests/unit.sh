#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

make dependencies
make build
python -m pytest
