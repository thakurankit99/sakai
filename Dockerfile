# Use OpenJDK 11
FROM openjdk:11-jdk

# Set working directory for Tomcat
WORKDIR /opt/tomcat

# Copy the pre-built Tomcat package (which includes Sakai and Tomcat)
COPY tomcat-package.tar.gz /opt/tomcat/

# Ensure Tomcat directories exist before extraction
RUN mkdir -p /opt/tomcat/bin /opt/tomcat/conf /opt/tomcat/lib /opt/tomcat/logs /opt/tomcat/temp /opt/tomcat/webapps /opt/tomcat/work

# Extract the package and remove the archive
RUN tar -xzvf /opt/tomcat/tomcat-package.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -f /opt/tomcat/tomcat-package.tar.gz

# Verify Tomcat extraction (debugging step)
RUN ls -lah /opt/tomcat/

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Ensure startup.sh and other scripts are executable
RUN chmod +x /opt/tomcat/bin/*.sh

# Expose Tomcat HTTP port
EXPOSE 8080

# Start Tomcat and verify the directory structure before startup
CMD ["sh", "-c", "ls -lah /opt/tomcat/ && ls -lah /opt/tomcat/bin/ && /opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
