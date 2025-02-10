# ========================== #
#      Runtime Container     #
# ========================== #

FROM openjdk:11-jdk

WORKDIR /tomcat

# Copy the entire Tomcat directory from the GitHub build
COPY tomcat /tomcat

# Ensure scripts have execute permissions
RUN chmod +x /tomcat/bin/setenv.sh

# Set Environment Variables
ENV CATALINA_HOME=/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Expose Tomcat Port
EXPOSE 8181

# Start Tomcat in Foreground
CMD ["/tomcat/bin/catalina.sh", "run"]
