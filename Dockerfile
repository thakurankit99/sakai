# ========================== #
#      Runtime Container     #
# ========================== #
FROM openjdk:11-jdk

# Set working directory
WORKDIR /opt/tomcat

# Download and install Apache Tomcat 9.0.69
RUN mkdir -p /opt/tomcat \
    && curl -L "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.69/bin/apache-tomcat-9.0.69.tar.gz" -o /opt/tomcat/tomcat.tar.gz \
    && tar -xvzf /opt/tomcat/tomcat.tar.gz -C /opt/tomcat --strip-components 1 \
    && rm -f /opt/tomcat/tomcat.tar.gz

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Create necessary directories
RUN mkdir -p /opt/tomcat/sakai /opt/tomcat/webapps /opt/tomcat/lib

# Copy all Sakai WAR files into Tomcat's webapps folder
COPY sakai-webapps/*.war /opt/tomcat/webapps/

# Copy essential configuration files from sakaiprops repo
COPY sakaiprops/context.xml /opt/tomcat/conf/context.xml
COPY sakaiprops/server.xml /opt/tomcat/conf/server.xml
COPY sakaiprops/sakai.properties /opt/tomcat/sakai/sakai.properties
COPY sakaiprops/mysql-connector-j-8.4.0.tar.gz /opt/tomcat/lib/

# Extract MySQL Connector JAR and move it to Tomcat lib
RUN tar -xvzf /opt/tomcat/lib/mysql-connector-j-8.4.0.tar.gz -C /opt/tomcat/lib/ \
    && find /opt/tomcat/lib/ -name "*.jar" -exec mv {} /opt/tomcat/lib/ \; \
    && rm -f /opt/tomcat/lib/mysql-connector-j-8.4.0.tar.gz

# Expose Tomcat's HTTP port
EXPOSE 8080

# Healthcheck to verify Tomcat is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

# Start Tomcat in the foreground
CMD ["sh", "-c", "catalina.sh run"]
