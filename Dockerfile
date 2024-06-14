FROM rclone/rclone:1.67.0

LABEL authors="jakob.steiner@glasskube.eu"

RUN apk --no-cache add jq

COPY cloud-storage-backup.sh /usr/local/bin

ENTRYPOINT ["cloud-storage-backup.sh"]
