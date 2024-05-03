#!/bin/bash

if [[ -z "$CRUX_URL" || -z "$CRUX_TOP" || -z "$S3_DATA_BUCKET" || -z "$RWS_URL" ]];then
    echo 'One or more environment variables are undefined'
    exit 1
fi

# Variables and filenames
crux_dir=./crux
crux_gz=${crux_dir}/crux.csv.gz
crux_csv=${crux_dir}/crux.csv
crux_origins=${crux_dir}/crux_${CRUX_TOP}.txt
crux_origins_tmp=${crux_origins}.tmp
crux_origins_tmp2=${crux_origins}.tmp2

results_dir=./results
crawl_time=$(date --utc "+%Y_%m_%d-%H_%M_%S")
results_crawl_dir=$results_dir/$crawl_time

rws_github=${results_crawl_dir}/rws_github.json

#S3 bucket filenames
attestation_known_origins=attestation_known_origins.json
rws_known_origins=rws_known_origins.json
guardduty_origins=origins_flagged_by_guardduty.txt

mkdir -p $crux_dir $results_crawl_dir

# Metadata
ips="$(dig @resolver1.opendns.com myip.opendns.com +short)$(dig -t aaaa +short myip.opendns.com @resolver1.opendns.com)"
echo "{\"start\": \"$crawl_time\", \"ips\": \"$ips\", \"crux\": \"$CRUX_URL\", \"crux_top\": \"$CRUX_TOP\" }" > $results_crawl_dir/crawl.metadata

# CrUX top-list
## Check that crux origins are created
if [ ! -f $crux_csv ]
then
    wget -q -O $crux_gz $CRUX_URL
    gzip -cdk $crux_gz > $crux_csv
    rm $crux_gz
fi
## Extract origins, discard rank, keep only https
head -$(($crux_top + 1)) $crux_csv > $crux_origins_tmp2 && \
sed -i '1d' $crux_origins_tmp2 && \
sed -nr "s/(.*),.*/\1/p" $crux_origins_tmp2 > $crux_origins_tmp && \
rm $crux_origins_tmp2 && \
sed -i '/^http:/d' $crux_origins_tmp

## RWS file from GitHub
wget -q -O $rws_github $RWS_URL #update every time

##extract primary, associatedSets, and serviceSites URLs + ccTLDs
jq -r '.sets[] | .primary' $rws_github >> $crux_origins_tmp
jq -r '.sets[] | select(.associatedSites != null) | .associatedSites[]' $rws_github >> $crux_origins_tmp
jq -r '.sets[] | select(.serviceSites != null) | .serviceSites[]' $rws_github >> $crux_origins_tmp
jq -r '.sets[] | select(.ccTLDs != null) | .ccTLDs | objects | .[] | .[]' $rws_github >> $crux_origins_tmp

# Grab latest known origins for attestation and add to crux origins to crawl
aws s3 cp s3://$S3_DATA_BUCKET/$attestation_known_origins ${results_dir}/${attestation_known_origins}
jq -r '.known_origins[] | .origin' ${results_dir}/${attestation_known_origins} >> $crux_origins_tmp

# Grab latest known origins for RWS and add to crux origins to crawl
aws s3 cp s3://$S3_DATA_BUCKET/$rws_known_origins ${results_dir}/${rws_known_origins}
jq -r '.known_origins[] | .origin' ${results_dir}/${rws_known_origins} >> $crux_origins_tmp

#parse and check that they are only ETLD+1 with PSL
if [ -f $crux_origins_tmp2 ]; then
    rm $crux_origins_tmp2
fi
if [ -f $crux_origins ]; then
    rm $crux_origins
fi
parallel -X -N 1000 -a $crux_origins_tmp -I @@ "python3 etld1_only.py -i @@ >> $crux_origins_tmp2"

#remove domains flagged by Guardduty
aws s3 cp s3://$S3_DATA_BUCKET/$guardduty_origins ${results_dir}/${guardduty_origins}
grep -v -x -f ${results_dir}/${guardduty_origins} $crux_origins_tmp2 > $crux_origins

#keep unique apparitions only
sort -u $crux_origins -o $crux_origins
rm $crux_origins_tmp $crux_origins_tmp2

# https://www.gnu.org/software/parallel/parallel_examples.html#example-speeding-up-fast-jobs
parallel --pipepart -a $crux_origins --jobs 200% --roundrobin -q parallel -j0 -X -N20 ./crawl_origins.sh $results_crawl_dir

#Overwrite metadata
end_time=$(date --utc "+%Y_%m_%d-%H_%M_%S")
echo "{\"start\": \"$crawl_time\", \"end\":\"$end_time\", \"ips\": \"$ips\", \"crux\": \"$CRUX_URL\", \"crux_top\": \"$CRUX_TOP\" }" > $results_crawl_dir/crawl.metadata

#upload folder to s3
cd $results_dir
tar --zstd -c $crawl_time | aws s3 cp - s3://$S3_DATA_BUCKET/$crawl_time.tar.zst
cd ..
