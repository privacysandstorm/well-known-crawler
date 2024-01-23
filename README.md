# well-known-crawler

[Explainer](https://github.com/GoogleChrome/related-website-sets)
- https
- `/.well-known/related-website-set.json`
- different JSON depending if primary or other



# Error
parallel: Warning: Only enough file handles to run 252 jobs in parallel.
parallel: Warning: Try running 'parallel -j0 -N 252 --pipe parallel -j0'
parallel: Warning: or increasing 'ulimit -n' (try: ulimit -n `ulimit -Hn`)
parallel: Warning: or increasing 'nofile' in /etc/security/limits.conf
parallel: Warning: or increasing /proc/sys/fs/file-max

Solve with 
```
ulimit -n `ulimit -Hn`
```
