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

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Set appropriate permissions
RUN chown -R 1001:127 /opt/tomcat/webapps /opt/tomcat/work /opt/tomcat/temp /opt/tomcat/logs \
    && chmod -R +x /opt/tomcat/bin/*.sh

# Expose Tomcat HTTP port
EXPOSE 8181 8089 8005 8443 8009

# Start Tomcat using startup.sh
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
