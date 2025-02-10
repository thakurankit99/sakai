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
ENV SAKAI_HOME=$CATALINA_HOME/sakai

# Ensure required directories exist
RUN mkdir -p $CATALINA_HOME/components $SAKAI_HOME $CATALINA_HOME/lib

# Copy essential configuration files
COPY context.xml $CATALINA_HOME/conf/context.xml
COPY server.xml $CATALINA_HOME/conf/server.xml
COPY sakai.properties $SAKAI_HOME/sakai.properties
COPY mysql-connector-j-8.4.0.jar $CATALINA_HOME/lib/mysql-connector-j-8.4.0.jar

# Copy setenv.sh and make it executable
COPY setenv.sh $CATALINA_HOME/bin/setenv.sh
RUN chmod +x $CATALINA_HOME/bin/setenv.sh

# Expose Tomcat's HTTP port
EXPOSE 8181

# Healthcheck to verify Tomcat is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8181 || exit 1

# Start Tomcat using startup.sh (Recommended by Sakai)
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
