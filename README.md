# well-known-crawler

Crawl well-known Resources introduced by The Privacy Sandbox.


## Dependencies
- Install GNU `parallel`, `jq`, `screen`, `curl`, `wget`, `dig` from `dnsutils`

## RWS

[Explainer](https://github.com/GoogleChrome/related-website-sets)
- `/.well-known/related-website-set.json`
- HTTPS only
- on ETLD+1 only, where [PSL](https://publicsuffix.org/) is authoritative source for ETLD
- different JSON format depending if primary or other
- There is a canonical public list of sets, but google.com/youtube.com is
  missing from it for instance
- [Generator](https://rws-json-generator.ue.r.appspot.com/)

## Privacy Sandbox Attestation

[Explainer](https://github.com/privacysandbox/attestation)
- `/.well-known/privacy-sandbox-attestations.json`
- Submit a form, JSON file sent by Google
- No public list of who participates

## TODOs:
- RWS check sets that are not the same as the ones submitted on Github (if ever submitted)

Notes:
- `SCHEMA.json` is wrong: contact should be one level below +anyOf
- canonical list does not seem complete
- `enrollment_site` in new format (v2)?
- RWS generator should enforce more checks (etld+1, anyOf)

