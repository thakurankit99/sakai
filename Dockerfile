# ========================== #
#      Runtime Container     #
# ========================== #

FROM openjdk:11-jdk

WORKDIR /tomcat

# Copy the entire Tomcat directory from the build
COPY tomcat /tomcat

# Ensure permissions are set
RUN chmod -R 755 /tomcat/

# Set environment variables
ENV CATALINA_HOME=/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Expose Tomcat's HTTP port
EXPOSE 8080

# Start Tomcat in the foreground
CMD ["/tomcat/bin/catalina.sh", "run"]
