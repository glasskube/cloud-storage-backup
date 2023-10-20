FROM rclone/rclone:1.64.2

LABEL authors="jakob.steiner@glasskube.eu"

RUN apk --no-cache add bash jq

COPY cloud-storage-backup.sh /usr/local/bin

ENTRYPOINT ["cloud-storage-backup.sh"]
