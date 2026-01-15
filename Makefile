.PHONY: start-project stop-project test clean

start-project:
	docker-compose up -d --build

stop-project:
	docker-compose down

test:
	./tests/run_tests.sh

clean:
	docker-compose down -v
	rm -f deployments/nginx/certs/nginx.crt deployments/nginx/certs/nginx.key deployments/nginx/.htpasswd
