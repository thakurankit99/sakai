# ========================== #
#      Runtime Container     #
# ========================== #
FROM openjdk:11-jdk

# Set working directory
WORKDIR /opt/tomcat

# Copy Tomcat Archive
COPY apache-tomcat-9.0.69.tar.gz /opt/tomcat/tomcat.tar.gz

# Extract and set up Tomcat
RUN mkdir -p /opt/tomcat \
    && tar -xvzf /opt/tomcat/tomcat.tar.gz -C /opt/tomcat --strip-components 1 \
    && rm -f /opt/tomcat/tomcat.tar.gz

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Create necessary directories
RUN mkdir -p /opt/tomcat/sakai /opt/tomcat/webapps /opt/tomcat/lib

# Copy all pre-built Sakai WAR files
COPY sakai-webapps/*.war /opt/tomcat/webapps/

# Copy essential configuration files
COPY context.xml /opt/tomcat/conf/context.xml
COPY server.xml /opt/tomcat/conf/server.xml
COPY sakai.properties /opt/tomcat/sakai/sakai.properties
COPY mysql-connector-j-8.4.0.jar /opt/tomcat/lib/mysql-connector-j-8.4.0.jar

# Copy setenv.sh and make it executable
COPY setenv.sh /opt/tomcat/bin/setenv.sh
RUN chmod +x /opt/tomcat/bin/setenv.sh

# Expose Tomcat's HTTP port
EXPOSE 8080

# Healthcheck to verify Tomcat is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

# Start Tomcat using startup.sh (Recommended by Sakai)
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
