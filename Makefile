build:
	mvn clean package
run:
	java -jar target/customerapp-0.1.2.war
docker:
	docker build -t nomisbeme/customerapp:0.1.2 .
	docker push nomisbeme/customerapp:0.1.2
