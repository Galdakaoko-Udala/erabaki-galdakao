#!/bin/bash

if [ -z "$DECIDIM_ENV" ]; then
  echo "Please set the DECIDIM_ENV environment variable"
  exit 1
fi

docker build . -t decidim_$DECIDIM_ENV

echo "Deploy with:"
echo "docker compose up -d"
