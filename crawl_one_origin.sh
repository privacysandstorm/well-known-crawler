#!/bin/sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 results_dir origin_url" >&2
  exit 1
fi
results_dir=$1
origin_url=$2

well_known_url=.well-known
well_known_related_set=related-website-set.json
well_known_attestation=privacy-sandbox-attestations.json

# Dir where to store 
origin_url_stripped=$(echo $origin_url | sed s/':\/\/'/./)
results_origin_dir=${results_dir}/$origin_url_stripped

mkdir -p $results_origin_dir

curl -fL -o "$results_origin_dir/#1" --silent $origin_url/$well_known_url/{$well_known_related_set,$well_known_attestation}

