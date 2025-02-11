# Use OpenJDK 11
FROM openjdk:11-jdk

# Set working directory for Tomcat
WORKDIR /opt/tomcat

# Copy the original Apache Tomcat package (ensure it contains all necessary folders)
COPY apache-tomcat-9.0.69.tar.gz /opt/tomcat/

# Extract Tomcat and remove the archive
RUN tar -xzvf /opt/tomcat/apache-tomcat-9.0.69.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -f /opt/tomcat/apache-tomcat-9.0.69.tar.gz

# Verify extraction (debugging step)
RUN ls -lah /opt/tomcat/

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Make sure all scripts are executable
RUN chmod +x /opt/tomcat/bin/*.sh

# Expose Tomcat HTTP port
EXPOSE 8080

# Start Tomcat and ensure all directories exist
CMD ["sh", "-c", "ls -lah /opt/tomcat/ && /opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
