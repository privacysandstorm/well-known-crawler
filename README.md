# well-known-crawler

Crawl well-known Resources introduced by The Privacy Sandbox:

- [Related Website Sets](https://github.com/GoogleChrome/related-website-sets)
  - `/.well-known/related-website-set.json`
  - HTTPS only
  - on ETLD+1 only, where [PSL](https://publicsuffix.org/) is authoritative source for ETLD
  - different JSON format depending if primary or other
  - There is a canonical public list of sets, but some (like google.com/youtube.com) are missing from it for instance
  - [Generator](https://rws-json-generator.ue.r.appspot.com/)

- [Attestation File](https://github.com/privacysandbox/attestation)
  - `/.well-known/privacy-sandbox-attestations.json`
  - Submit a form, JSON file sent by Google
  - No public list of who participates

## Dependencies

A `Dockerfile` is provided under `.devcontainer/`; for direct integration with
VS Code or to manually build the image and deploy the Docker container, follow
the instructions in this [guide](https://gist.github.com/yohhaan/b492e165b77a84d9f8299038d21ae2c9).

## Environment Variables

- `CRUX_URL`: The URL to the cached version of CrUX to use (see https://github.com/zakird/crux-top-lists/tree/main/data/global)
- `CRUX_TOP`: Specify how many first top origins to crawl
- `S3_DATA_BUCKET`: The s3 bucket where the crawl raw results are saved
- `RWS_URL`: The URL to the RWS canonical set

## Usage

```bash
./crawl_crux.sh
```

## Gitlab CI/CD Variables

Define the following CI variables to have Gitlab CI building and pushing the
image automatically:
- `AWS_ACCOUNT_ID`: the AWS account ID
- `AWS_REGION`: the AWS region to use
- `AWS_ACCESS_KEY_ID`: of an IAM user with the `AmazonEC2ContainerRegistryPowerUser` policy
- `AWS_SECRET_ACCESS_KEY`: of an IAM user with the `AmazonEC2ContainerRegistryPowerUser` policy

