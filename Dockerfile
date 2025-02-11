# ========================== #
#       Build Stage          #
# ========================== #
FROM maven:3.8.6-openjdk-11 AS build

# Set working directory
WORKDIR /opt/sakai

# Copy Sakai source code
COPY . .

# Work around Java bugs with Maven Surefire plugin
ENV JAVA_TOOL_OPTIONS "-Djdk.net.URLClassPath.disableClassPathURLCheck=true"

# Build Sakai (skipping tests to speed up)
RUN mvn clean install -Dmaven.test.skip=true -DskipTests

# ========================== #
#     Runtime Container      #
# ========================== #
FROM openjdk:11-jdk

# Set working directory for Tomcat
WORKDIR /opt/tomcat

# Copy Tomcat from sakaiprops
COPY apache-tomcat-9.0.69.tar.gz /opt/tomcat/

# Extract Tomcat and remove the archive
RUN tar -xzvf /opt/tomcat/apache-tomcat-9.0.69.tar.gz -C /opt/tomcat --strip-components=1 \
    && rm -f /opt/tomcat/apache-tomcat-9.0.69.tar.gz

# Configure Tomcat environment
ENV CATALINA_HOME=/opt/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH

# Copy Sakai build from previous stage
COPY --from=build /opt/sakai /opt/sakai

# Deploy Sakai web applications into Tomcat
RUN mvn sakai:deploy -Dmaven.tomcat.home=/opt/tomcat

# Copy required configuration files
COPY sakai.properties /opt/tomcat/sakai/
COPY context.xml /opt/tomcat/conf/
COPY server.xml /opt/tomcat/conf/
COPY mysql-connector-j-8.4.0.jar /opt/tomcat/lib/
COPY setenv.sh /opt/tomcat/bin/

# Ensure startup scripts are executable
RUN chmod +x /opt/tomcat/bin/*.sh

# Expose Tomcat HTTP port
EXPOSE 8181

# Start Tomcat with Sakai
CMD ["sh", "-c", "/opt/tomcat/bin/startup.sh && tail -f /opt/tomcat/logs/catalina.out"]
