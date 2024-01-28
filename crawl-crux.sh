#!/bin/bash

# Variables
crux_top=100000 #top origins we scan, 100k ~= 87% of global traffic seen by Google
crux_url=https://github.com/zakird/crux-top-lists/raw/main/data/global/202310.csv.gz #october 2023
crux_dir=./crux/
crux_gz_path=${crux_dir}crux.csv.gz
crux_csv_path=${crux_dir}crux.csv
crux_origins=${crux_dir}crux_origins_${crux_top}.txt
crux_origins_tmp=${crux_origins}.tmp

mkdir -p $crux_dir

s3_bucket_name=well-known-resources

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

# https://www.gnu.org/software/parallel/parallel_examples.html#example-speeding-up-fast-jobs
parallel --pipepart -a $crux_origins -j32 -q parallel -j0 -X -N20 ./crawl_origins.sh $results_crawl_dir

# cd $results_dir
# tar --zstd -c $crawl_time | aws s3 cp - s3://$s3_bucket_name/$crawl_time.tar.zst
# # rm -r $crawl_time
# cd ..
