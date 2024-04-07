#!/bin/sh

if [ "$#" -le 1 ]; then
  echo "Usage: $0 results_dir origin_urls" >&2
  exit 1
fi

well_known_url=.well-known
well_known_related_set=related-website-set.json
well_known_attestation=privacy-sandbox-attestations.json

results_dir=$1
rws_dir=$results_dir/rws
attestation_dir=$results_dir/attestation
mkdir -p $rws_dir $attestation_dir

#shift to keep only origin urls
shift

for origin_url in "$@"
do
  # Dir where to store
  origin_url_stripped=$(echo $origin_url | sed s/':\/\/'/./)

  #RWS
  rws_file=$rws_dir/$origin_url_stripped.json
  # grab file if it exists
  curl -fL -o $rws_file --silent --max-time 180 --connect-timeout 90 $origin_url/$well_known_url/$well_known_related_set
  #check if file exists
  if [ -f $rws_file ]; then
  #check if valid JSON
    python3 validate_json.py $rws_file
    if [ $? -ne 0 ]; then
      rm $rws_file
    fi
  fi

  #Attestation
  attestation_file=$attestation_dir/$origin_url_stripped.json
  # grab file if it exists
  curl -fL -o $attestation_file --silent --max-time 180 --connect-timeout 90 $origin_url/$well_known_url/$well_known_attestation
  #check if file exists
  if [ -f $attestation_file ]; then
    #check if valid JSON
    python3 validate_json.py $attestation_file
    if [ $? -ne 0 ]; then
      rm $attestation_file
    fi
  fi

done