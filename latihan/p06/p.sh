#!/usr/bin/env bash
exec docker compose exec -T postgres psql -U msbd -d pagila -X "$@"
