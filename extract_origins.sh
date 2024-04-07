#!/bin/sh

if [ "$#" -ne 1 ] || ! [ -d "$1" ]; then
  echo "Usage: $0 RESULTS_CRAWL__DIR" >&2
  exit 1
fi

cd $1
rws_dir=./rws
attestation_dir=./attestation

#Attestation
attestation_origins=../attestation_origins.txt
cd $attestation_dir
if [ -f $attestation_origins ]; then
    rm $attestation_origins
fi
for entry in *
do
    echo $entry | sed -nr "s/https.(.*).json/https:\/\/\1/p" >> $attestation_origins
done

sort -u $attestation_origins -o $attestation_origins
cd ..

#RWS
rws_origins=../rws_origins.txt
cd $rws_dir
if [ -f $rws_origins ]; then
    rm $rws_origins
fi
for entry in *
do
    echo $entry | sed -nr "s/https.(.*).json/https:\/\/\1/p" >> $rws_origins
done

sort -u $rws_origins -o $rws_origins

rws_github_origins=../rws_github_origins.txt
rws_diff_on_github=../rws_diff_on_github.txt
rws_diff_not_on_github=../rws_diff_not_on_github.txt

diff $rws_origins $rws_github_origins | grep ">" | sed 's/^> //g' > $rws_diff_on_github
diff $rws_origins $rws_github_origins | grep "<" | sed 's/^< //g' > $rws_diff_not_on_github

cd ..

