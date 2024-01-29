#!/bin/bash

# Variables
crux_top=1000000 #top origins we scan
crux_url=https://github.com/zakird/crux-top-lists/raw/main/data/global/202310.csv.gz #october 2023
crux_dir=./crux/
crux_gz_path=${crux_dir}crux.csv.gz
crux_csv_path=${crux_dir}crux.csv
crux_origins=${crux_dir}crux_origins_${crux_top}.txt
crux_origins_tmp=${crux_origins}.tmp

mkdir -p $crux_dir

s3_bucket_name=well-known-resources

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

# CrUX top-list
## Check that crux origins are created
if [ ! -f $crux_csv_path ]
then
    wget -q -O $crux_gz_path $crux_url
    gzip -cdk $crux_gz_path > $crux_csv_path
    rm $crux_gz_path
fi
## Extract origins, discard rank
if [ ! -f $crux_origins ]
then
    head -$(($crux_top + 1)) $crux_csv_path > $crux_origins_tmp && \
    sed -i '1d' $crux_origins_tmp && \
    sed -nr "s/(.*),.*/\1/p" $crux_origins_tmp > $crux_origins && \
    rm $crux_origins_tmp
fi

crawl_time=$(TZ='America/Chicago' date "+%Y_%m_%d-%H_%M_%S")
results_dir=./results
results_crawl_dir=$results_dir/$crawl_time
mkdir -p $results_crawl_dir

#Write metadata
echo "{\"start\": \"$crawl_time\", \"sha\": \"$git_sha\", \"ips\": \"$ips\", \"crux\": \"$crux_url\", \"crux_top\": \"$crux_top\" }" > $results_crawl_dir/crawl.metadata

# https://www.gnu.org/software/parallel/parallel_examples.html#example-speeding-up-fast-jobs
parallel --pipepart -a $crux_origins -j32 --roundrobin -q parallel -j0 -X -N20 ./crawl_origins.sh $results_crawl_dir

end_time=$(TZ='America/Chicago' date "+%Y_%m_%d-%H_%M_%S")
#Overwrite metadata
echo "{\"start\": \"$crawl_time\", \"end\":\"$end_time\", \"sha\": \"$git_sha\", \"ips\": \"$ips\", \"crux\": \"$crux_url\", \"crux_top\": \"$crux_top\" }" > $results_crawl_dir/crawl.metadata

cd $results_dir
tar --zstd -c $crawl_time | aws s3 cp - s3://$s3_bucket_name/$crawl_time.tar.zst
rm -r $crawl_time
cd ..
