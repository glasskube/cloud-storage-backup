build:
	docker build -t ghcr.io/glasskube/cloud-storage-backup:dev .

run: build
	docker compose up -d
	docker compose logs cloud-storage-backup -f

down:
	docker compose down

clean:
	docker rmi ghcr.io/glasskube/cloud-storage-backup:dev
