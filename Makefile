build:
	docker build -t ghcr.io/glasskube/cloud-storage-backup:latest .

run: build
	docker compose up -d
	docker compose logs s3-backup -f

down:
	docker compose down

clean:
	docker rmi ghcr.io/glasskube/cloud-storage-backup:latest
