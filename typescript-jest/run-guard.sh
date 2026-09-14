#!/usr/bin/env bash
set -euo pipefail
npm ci
npm test -- --testNamePattern 'never exposes internal products in a public category'
