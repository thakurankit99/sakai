FROM openjdk:11-jdk

WORKDIR /opt/sakai

COPY . /opt/sakai

RUN apt update && apt install -y maven mysql-client \
    && mvn clean install -Dmaven.test.skip=true

EXPOSE 8080

CMD ["java", "-jar", "target/sakai.war"]
