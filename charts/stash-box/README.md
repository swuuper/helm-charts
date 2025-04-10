## Stashapp Box helm chart

This helm chart is a work in progress and can be used with some manual intervention.
1. As of yet, it does not ship with Postgres DB. 
2. You can deploy your own DB and set the credentials in values.yaml
3. Stash Box needs the `pg_trgm` extension in Postgres, make sure to add this before running the StatefulSet
   ```create extension pg_trgm with schema pg_catalog;```


## FAQ 

### Getting 308 permanent redirect
If you are running it behind cloudflare, you must add the following annotation to the nginx ingress:
```yaml
nginx.ingress.kubernetes.io/ssl-redirect: "false"
```