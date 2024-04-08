#!/bin/bash

# Variables
crux_top=1000000 #top origins we scan
crux_url=https://github.com/zakird/crux-top-lists/raw/main/data/global/202310.csv.gz #october 2023
crux_dir=./crux/
crux_gz_path=${crux_dir}crux.csv.gz
crux_csv_path=${crux_dir}crux.csv
crux_origins=${crux_dir}crux_origins_${crux_top}.txt
crux_origins_tmp=${crux_origins}.tmp
crux_origins_tmp2=${crux_origins}.tmp2

s3_bucket_name=well-known-resources

mkdir -p $crux_dir

# Metadata
git_sha=$(git rev-parse --short HEAD)
ips="$(dig @resolver1.opendns.com myip.opendns.com +short)$(dig -t aaaa +short myip.opendns.com @resolver1.opendns.com)"

# Check if git status returns anything
if [ $(git status --porcelain | wc -l) -gt 0 ]
then
    while true; do
        read -p "There are modifications in this Git repository not committed. Continue with crawl? (y or n) :" answer
        case $answer in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

crawl_time=$(date --utc "+%Y_%m_%d-%H_%M_%S")
results_dir=./results
results_crawl_dir=$results_dir/$crawl_time
mkdir -p $results_crawl_dir

#Write metadata
echo "{\"start\": \"$crawl_time\", \"sha\": \"$git_sha\", \"ips\": \"$ips\", \"crux\": \"$crux_url\", \"crux_top\": \"$crux_top\" }" > $results_crawl_dir/crawl.metadata

# CrUX top-list
## Check that crux origins are created
if [ ! -f $crux_csv_path ]
then
    wget -q -O $crux_gz_path $crux_url
    gzip -cdk $crux_gz_path > $crux_csv_path
    rm $crux_gz_path
fi
## Extract origins, discard rank, keep only https
head -$(($crux_top + 1)) $crux_csv_path > $crux_origins_tmp2 && \
sed -i '1d' $crux_origins_tmp2 && \
sed -nr "s/(.*),.*/\1/p" $crux_origins_tmp2 > $crux_origins_tmp && \
rm $crux_origins_tmp2 && \
sed -i '/^http:/d' $crux_origins_tmp


rws_github_url=https://raw.githubusercontent.com/GoogleChrome/related-website-sets/main/related_website_sets.JSON
rws_github_path=${results_crawl_dir}/rws_github.json
rws_github_origins=${results_crawl_dir}/rws_github_origins.txt

## RWS file from GitHub
wget -q -O $rws_github_path $rws_github_url #update every time

##extract primary, associatedSets, and serviceSites URLs
jq -r '.sets[] | .primary' $rws_github_path > $rws_github_origins
jq -r '.sets[] | select(.associatedSites != null) | .associatedSites[]' $rws_github_path >> $rws_github_origins
jq -r '.sets[] | select(.serviceSites != null) | .serviceSites[]' $rws_github_path >> $rws_github_origins
sort -u $rws_github_origins -o $rws_github_origins

#  Add to origins temp file
cat $rws_github_origins >> $crux_origins_tmp

#parse and check that they are only ETLD+1 with PSL
if [ -f $crux_origins ]; then
    rm $crux_origins
fi
parallel -X --bar -N 1000 -a $crux_origins_tmp -I @@ "python3 etld1_only.py -i @@ >> $crux_origins"

#keep unique apparitions only
sort -u $crux_origins -o $crux_origins
rm $crux_origins_tmp

# https://www.gnu.org/software/parallel/parallel_examples.html#example-speeding-up-fast-jobs
parallel --pipepart -a $crux_origins -j32 --roundrobin -q parallel -j0 -X -N20 ./crawl_origins.sh $results_crawl_dir

end_time=$(date --utc "+%Y_%m_%d-%H_%M_%S")
#Overwrite metadata
echo "{\"start\": \"$crawl_time\", \"end\":\"$end_time\", \"sha\": \"$git_sha\", \"ips\": \"$ips\", \"crux\": \"$crux_url\", \"crux_top\": \"$crux_top\" }" > $results_crawl_dir/crawl.metadata

cd $results_dir
tar --zstd -c $crawl_time | aws s3 cp - s3://$s3_bucket_name/$crawl_time.tar.zst
# rm -r $crawl_time
cd ..
