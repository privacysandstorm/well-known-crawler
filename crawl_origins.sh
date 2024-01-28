#!/bin/sh

if [ "$#" -le 1 ]; then
  echo "Usage: $0 results_dir origin_urls" >&2
  exit 1
fi

well_known_url=.well-known
well_known_related_set=related-website-set.json
well_known_attestation=privacy-sandbox-attestations.json

results_dir=$1
#shift to keep only origin urls
shift

for origin_url in "$@"
do
  # Dir where to store 
  origin_url_stripped=$(echo $origin_url | sed s/':\/\/'/./)
  results_origin_dir=${results_dir}/$origin_url_stripped

  mkdir -p $results_origin_dir
  # grab the 2 files if they exist
  curl -fL -o "$results_origin_dir/#1" --silent --max-time 300 $origin_url/$well_known_url/{$well_known_related_set,$well_known_attestation}

  #check if valid JSON, if not discard
  if [ -f $results_origin_dir/$well_known_related_set ]; then
    if ! jq empty $results_origin_dir/$well_known_related_set 2>/dev/null; then
      rm $results_origin_dir/$well_known_related_set
    fi
  fi

  if [ -f $results_origin_dir/$well_known_attestation ]; then
    if ! jq empty $results_origin_dir/$well_known_attestation 2>/dev/null; then
      rm $results_origin_dir/$well_known_attestation
    fi
  fi

  # Check if directory is empty, if so just delete
  if [ -d $results_origin_dir ]
  then
    if [ -z "$(ls -A $results_origin_dir)" ]; then
      rm -r $results_origin_dir
    fi
  fi
done