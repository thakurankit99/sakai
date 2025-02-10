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

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV CATALINA_HOME=/opt/tomcat
ENV SAKAI_HOME=/opt/tomcat/sakai
ENV PATH=$JAVA_HOME/bin:$CATALINA_HOME/bin:$PATH

# Ensure required directories exist
RUN mkdir -p $CATALINA_HOME/components $SAKAI_HOME $CATALINA_HOME/lib

# Copy Sakai components and webapps
COPY components/ $CATALINA_HOME/components/
COPY webapps/ $CATALINA_HOME/webapps/

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

# Start Tomcat using catalina.sh (Recommended for Sakai)
CMD ["sh", "-c", "$CATALINA_HOME/bin/catalina.sh run && tail -f $CATALINA_HOME/logs/catalina.out"]
