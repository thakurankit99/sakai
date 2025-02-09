# Use OpenJDK 11 as the base image
FROM openjdk:11-jdk

# Set the working directory
WORKDIR /opt/sakai

# Copy the source code into the container
COPY . /opt/sakai

# Update package lists and install required dependencies
RUN apt update && apt install -y maven default-mysql-client \
    && mvn clean install -Dmaven.test.skip=true \
    && rm -rf /var/lib/apt/lists/*  # Clean up to reduce image size

# Set up Tomcat
RUN apt install -y wget unzip && \
    wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.78/bin/apache-tomcat-9.0.78.tar.gz && \
    tar -xvzf apache-tomcat-9.0.78.tar.gz && \
    mv apache-tomcat-9.0.78 /opt/tomcat && \
    rm apache-tomcat-9.0.78.tar.gz

# Copy the Sakai built files to Tomcat webapps
RUN cp -r target/sakai /opt/tomcat/webapps/

# Expose Tomcat's default port
EXPOSE 8080

# Start Tomcat when the container runs
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
