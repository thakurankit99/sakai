# ========================== #
#      Runtime Container     #
# ========================== #

FROM openjdk:11-jdk

WORKDIR /opt/tomcat

# Copy Tomcat Archive and Extract
COPY apache-tomcat-9.0.69.tar.gz /opt/tomcat/tomcat.tar.gz
RUN mkdir -p /opt/tomcat \
    && tar -xvzf /opt/tomcat/tomcat.tar.gz -C /opt/tomcat --strip-components 1 \
    && rm -f /opt/tomcat/tomcat.tar.gz

ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

RUN mkdir -p /opt/tomcat/sakai /opt/tomcat/webapps /opt/tomcat/components /opt/tomcat/lib

# Copy WAR and JAR files
COPY webapps/*.war /opt/tomcat/webapps/
COPY components/*.jar /opt/tomcat/components/

# Copy essential configuration files
COPY context.xml /opt/tomcat/conf/context.xml
COPY server.xml /opt/tomcat/conf/server.xml
COPY sakai.properties /opt/tomcat/sakai/sakai.properties
COPY mysql-connector-j-8.4.0.jar /opt/tomcat/lib/mysql-connector-j-8.4.0.jar
COPY setenv.sh /opt/tomcat/bin/setenv.sh
RUN chmod +x /opt/tomcat/bin/setenv.sh

EXPOSE 8080
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
