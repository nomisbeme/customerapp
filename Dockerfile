FROM bitnami/java:1.8-prod
VOLUME /tmp
RUN mkdir /app
COPY ./target/*.war /app/customerapp.war
WORKDIR /app
EXPOSE 8080
CMD ["java","-Djava.security.egd=file:/dev/./urandom","-Dspring.profiles.active=production","-jar","customerapp.war"]
