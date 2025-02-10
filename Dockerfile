# ========================== #
#      Runtime Container     #
# ========================== #
FROM openjdk:11-jdk

# Set working directory
WORKDIR /opt/tomcat

# Copy the entire pre-built Tomcat directory from the CI/CD pipeline
COPY tomcat /opt/tomcat

# Set environment variables for Tomcat
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Ensure necessary permissions
RUN chmod +x /opt/tomcat/bin/setenv.sh

# Expose Tomcat's HTTP port
EXPOSE 8080

# Healthcheck to verify Tomcat is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080 || exit 1

# Start Tomcat using startup.sh (Recommended by Sakai)
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
