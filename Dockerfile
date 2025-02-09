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
    && rm -f /opt/tomcat/tomcat.tar.gz  # Remove tar.gz to save space

# Modify Tomcat Configuration for UTF-8 Support
RUN sed -i 's/<Connector port="8080"/<Connector port="8080" URIEncoding="UTF-8"/g' /opt/tomcat/conf/server.xml

# Improve startup speed by disabling JAR scanning
RUN sed -i 's|<Context>|<Context><JarScanner><JarScanFilter defaultPluggabilityScan="false" /></JarScanner>|g' /opt/tomcat/conf/context.xml

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Create necessary directories
RUN mkdir -p /opt/tomcat/sakai /opt/tomcat/webapps /opt/tomcat/lib /opt/tomcat/mysql-connector

# Copy all Sakai WAR files into Tomcat's webapps folder
COPY sakai-webapps/*.war /opt/tomcat/webapps/

# Copy context.xml to Tomcat configuration directory
COPY sakaiprops/context.xml /opt/tomcat/conf/context.xml

# Copy MySQL Connector TAR file and extract it into Tomcat lib
COPY sakaiprops/mysql-connector-j-8.4.0.tar.gz /opt/tomcat/mysql-connector/

RUN tar -xvzf /opt/tomcat/mysql-connector/mysql-connector-j-8.4.0.tar.gz -C /opt/tomcat/mysql-connector/ \
    && find /opt/tomcat/mysql-connector/ -name "*.jar" -exec mv {} /opt/tomcat/lib/ \; \
    && rm -rf /opt/tomcat/mysql-connector/  # Clean up extracted folder

# Copy sakai.properties after the WAR files are in place
COPY sakaiprops/sakai.properties /opt/tomcat/sakai/sakai.properties

# Expose Tomcat's HTTP port
EXPOSE 8080

# Healthcheck to verify Tomcat is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

# Start Tomcat in the foreground (using exec to ensure proper signal handling)
CMD ["sh", "-c", "catalina.sh run"]
