# Use OpenJDK 11
FROM openjdk:11-jdk

# Set working directory for Tomcat
WORKDIR /opt/tomcat

# Create Tomcat directory structure
RUN mkdir -p /opt/tomcat/bin \
    /opt/tomcat/conf \
    /opt/tomcat/lib \
    /opt/tomcat/logs \
    /opt/tomcat/temp \
    /opt/tomcat/webapps \
    /opt/tomcat/work \
    /opt/tomcat/sakai

# Copy the pre-built Tomcat package (which includes Sakai and Tomcat)
COPY tomcat-package.tar.gz /opt/tomcat/

# Extract the package and remove the archive
RUN tar -xzvf /opt/tomcat/tomcat-package.tar.gz -C /opt/tomcat \
    && rm -f /opt/tomcat/tomcat-package.tar.gz

# Verify Tomcat extraction and contents
RUN ls -lah /opt/tomcat/ && \
    ls -lah /opt/tomcat/bin || echo "bin directory missing or empty"

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Make sure the bin directory exists and scripts are executable
RUN chmod -R +x /opt/tomcat/bin || echo "No bin directory found"

# Expose Tomcat HTTP port
EXPOSE 8080

# Set appropriate permissions
RUN chown -R 1001:127 /opt/tomcat/webapps /opt/tomcat/work /opt/tomcat/temp /opt/tomcat/logs

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/portal || exit 1

# Start Tomcat
CMD ["sh", "-c", "ls -lah /opt/tomcat/ && /opt/tomcat/bin/catalina.sh run"]
