#!/bin/bash

if [ -f .env ]; then
  source .env
fi

if [ -z "$DECIDIM_ENV" ]; then
  echo "Please set the DECIDIM_ENV environment variable"
  echo "You can define it in a .env file and it will be automatically loaded"
  exit 1
fi

docker build . -t decidim_$DECIDIM_ENV

echo "Deploy with:"
echo "docker compose up -d"
