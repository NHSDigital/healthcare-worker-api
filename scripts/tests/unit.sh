#!/bin/bash

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

make build
pytest
