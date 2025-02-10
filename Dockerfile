# Use OpenJDK 11
FROM openjdk:11-jdk

# Set working directory for Tomcat
WORKDIR /opt/tomcat

# Copy the pre-built Tomcat package (which includes Sakai)
COPY tomcat-package.tar.gz /opt/tomcat/tomcat-package.tar.gz

# Extract the package and remove the archive
RUN tar -xvzf /opt/tomcat/tomcat-package.tar.gz -C /opt/tomcat --strip-components 1 \
    && rm -f /opt/tomcat/tomcat-package.tar.gz

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Expose Tomcat HTTP port
EXPOSE 8080

# Start Tomcat
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
