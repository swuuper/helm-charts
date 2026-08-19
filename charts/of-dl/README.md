# of-dl

Runs [OF-DL](https://github.com/sim0n00ps/OF-DL) as a Kubernetes CronJob in non-interactive
(`--cli`) mode.

```console
helm repo add swuuper https://swuuper.github.io/helm-charts
helm install of-dl swuuper/of-dl -f values.yaml
```

## How it works

The chart renders the four files OF-DL expects in `/config` and seeds them there with an init
container before every run:

| File | Comes from | Object |
|---|---|---|
| `config.conf` | `config` (or `configRaw`) | ConfigMap |
| `rules.json` | `rules` | ConfigMap |
| `auth.json` | `auth` | Secret |
| `cdm/devices/<name>/device_*` | `cdm` | Secret |

`/config` itself is a PVC, so `users.db` — the incremental-download state — survives between runs.
The image's own entrypoint only writes defaults when a file is missing, so the init container
overwrites the four generated files each run; a values change therefore takes effect on the next
run rather than being masked by the copy already on disk.

`command` is deliberately left empty. The image entrypoint seeds directories, starts supervisord
and Xvfb, waits for the X server and only then strips `--cli` and execs the CLI binary. Setting
`command` bypasses all of that and the application will not start.

## Downloads

Nothing is mounted at the download path by default, so downloads land on the pod's ephemeral
filesystem and vanish when the job ends. Mount real storage there and point the config at it:

```yaml
config:
  Download:
    DownloadPath: "/data"

volumes:
  - name: downloads
    csi:
      driver: smb.csi.k8s.io
      volumeAttributes:
        source: //nas.example/share
        secretName: smbcreds
        mountOptions: dir_mode=0777,file_mode=0777,cache=strict,actimeo=30,nobrl

volumeMounts:
  - name: downloads
    mountPath: /data
```

`nobrl` is worth keeping on SMB: OF-DL writes SQLite databases, and byte-range locks over SMB are a
common cause of `database is locked`.

## Configuration

`config` is written out as HOCON verbatim — the nesting in `values.yaml` mirrors the sections of the
`config.conf` shipped inside the image, and any key the application understands can be set without a
chart change. Set `configRaw` to a complete `config.conf` instead to bypass the renderer entirely.

Two values must stay as they are for scheduled runs: `Interaction.NonInteractiveMode: true` (there
is no terminal attached to a CronJob pod) and `Download.disablebrowserauth: true` (browser auth
needs an interactive X session).

Note that `rules.app-token` is spelled with a hyphen — that is the key the application reads. Fetch
current values from
[onlyfans-dynamic-rules](https://raw.githubusercontent.com/deviint/onlyfans-dynamic-rules/main/dynamicRules.json).

## CDM keys

DRM-protected media needs Widevine device keys. Supply them base64-encoded:

```console
base64 -w0 cdm/devices/chrome_1610/device_client_id_blob
base64 -w0 cdm/devices/chrome_1610/device_private_key
```

```yaml
cdm:
  deviceName: chrome_1610
  deviceClientIdBlob: <base64>
  devicePrivateKey: <base64>
```

Or point `cdm.existingSecret` at a Secret you manage yourself, with keys `device_client_id_blob` and
`device_private_key` holding the raw files.

## Values

| Key | Default | Description |
|---|---|---|
| `image.repository` | `ghcr.io/sim0n00ps/of-dl` | |
| `image.tag` | `""` | Defaults to the chart `appVersion`. |
| `imagePullSecrets` | `[]` | Needed for a private mirror of the image. |
| `schedule` | `0 */2 * * *` | |
| `concurrencyPolicy` | `Forbid` | Scrapes are long; overlapping runs are never wanted. |
| `successfulJobsHistoryLimit` / `failedJobsHistoryLimit` | `3` / `3` | |
| `startingDeadlineSeconds` | `300` | |
| `backoffLimit` | `0` | No retry — the next schedule is the retry. |
| `activeDeadlineSeconds` | `null` | Hard stop for one run. |
| `args` | `["--cli"]` | |
| `auth` | placeholder | `USER_ID`, `USER_AGENT`, `X_BC`, `COOKIE`. |
| `rules` | placeholder | Dynamic rules, `app-token` with a hyphen. |
| `config` | see `values.yaml` | Rendered to `config.conf` as HOCON. |
| `configRaw` | `""` | Verbatim `config.conf`; overrides `config`. |
| `cdm.existingSecret` | `""` | Bring your own CDM Secret. |
| `cdm.deviceName` | `chrome_1610` | Directory under `cdm/devices/`. |
| `persistence.enabled` | `true` | `/config` PVC holding `users.db` and logs. |
| `persistence.storageClass` | `""` | Set explicitly if the cluster has more than one default. |
| `persistence.size` | `5Gi` | |
| `volumes` / `volumeMounts` | `[]` | Mount the download target here. |

## Running on demand

```console
kubectl create job --from=cronjob/of-dl-run-download of-dl-manual
kubectl logs -f job/of-dl-manual
```
