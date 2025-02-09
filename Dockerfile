# ========================== #
#      Runtime Container     #
# ========================== #
FROM openjdk:11-jdk

# Set working directory
WORKDIR /opt/tomcat

# Download and install Apache Tomcat 9.0.69
RUN mkdir -p /opt/tomcat \
    && curl -L "https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.69/bin/apache-tomcat-9.0.69.tar.gz" -o /opt/tomcat/tomcat.tar.gz \
    && tar -xvzf /opt/tomcat/tomcat.tar.gz -C /opt/tomcat --strip-components 1

# Modify Tomcat Configuration for UTF-8 Support
RUN sed -i 's/<Connector port="8080"/<Connector port="8080" URIEncoding="UTF-8"/g' /opt/tomcat/conf/server.xml

# Improve startup speed by disabling JAR scanning
RUN sed -i 's|<Context>|<Context><JarScanner><JarScanFilter defaultPluggabilityScan="false" /></JarScanner>|g' /opt/tomcat/conf/context.xml

# Copy Tomcat Optimizations
COPY context.xml /opt/tomcat/conf/

# Set environment variables for Tomcat
ENV CATALINA_HOME /opt/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

# Create the `sakai` directory inside Tomcat
RUN mkdir -p /opt/tomcat/sakai

# Copy sakai.properties from external repository into `/opt/tomcat/sakai/`
COPY sakai.properties /opt/tomcat/sakai/sakai.properties

# Copy Sakai WAR file from GitHub build
COPY sakai.war /opt/tomcat/webapps/sakai.war

# Expose Tomcat's HTTP port
EXPOSE 8080

# Start Tomcat when the container runs
CMD ["./bin/startup.sh"]
