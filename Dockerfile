# Use OpenJDK 11
FROM openjdk:11-jdk

# Set working directory
WORKDIR /opt/tomcat

# Copy the entire pre-built Tomcat structure
COPY tomcat-package.tar.gz /opt/tomcat/

# Extract Tomcat and remove the archive
RUN tar -xzvf /opt/tomcat/tomcat-package.tar.gz -C /opt/tomcat/ --strip-components=1 \
    && rm -f /opt/tomcat/tomcat-package.tar.gz

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Ensure scripts are executable
RUN chmod +x /opt/tomcat/bin/*.sh

# Expose Tomcat's HTTP port
EXPOSE 8080

# Start Tomcat
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
