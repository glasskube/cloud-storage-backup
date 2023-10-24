# Cloud Storage Backup

## About

This project is a very straight forward bash script that can be used to take regular backups of a cloud storage bucket.
When invoked, the script copies all files from the source bucket into a subdirectory of the target bucket, optionally
deleting any backups older than the specified TTL.

## Supported Providers

Internally, [rclone](https://rclone.org/) is used to interact with cloud storage providers.
All [storage systems supported by rclone](https://rclone.org/overview/) should work, however only Minio and Generic S3
are officially tested.

## Installation

### Linux

1. Ensure that the following dependencies are installed on your system:
    - `sh` (any POSIX compliant shell will work)
    - `coreutils` (preferred) or `busybox` (used for `printf`, `date`)
    - `rclone` (used to interact with cloud storage)
    - `jq` (used to parse output of `rclone lsjson`)
2. Setup one or two remotes using `rclone config` (depending on your use-case).
3. Clone this git repository
4. Run `./s3-backup.sh` with appropriate environment variables

### Docker

We also publish a docker image that comes with all dependencies preinstalled.
Check out `docker-compose.yaml` for an example.

## Configuration

Cloud Storage Backup supports configuration via the following environment variables:

| Name       | Description                                                                                                                                        | Default               |
|------------|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------|
| SRC_REMOTE | Name of the rclone remote used as source.                                                                                                          | no default (required) |
| SRC_BUCKET | Name of the storage bucket used as source.                                                                                                         | no default (required) |
| DST_REMOTE | Name of the rclone remote used as destination.                                                                                                     | no default (required) |
| DST_BUCKET | Name of the storage bucket used as destination.                                                                                                    | no default (required) |
| BACKUP_TTL | Time to live for old backups in seconds. Backups older than this will be pruned after a successful copy. Leave empty if nothing should be deleted. | no default            |
| DEBUG      | Set to 1 for more verbose output.                                                                                                                  | `0`                   |

## Development

You can run `docker compose up -d minio` to start a local minio container with ephemeral storage.