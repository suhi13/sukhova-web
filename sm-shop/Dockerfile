FROM adoptopenjdk/openjdk11-openj9:alpine
RUN mkdir /opt/app
RUN mkdir /files
COPY target/shopizer.jar /opt/app
COPY SALESMANAGER.h2.db /
COPY ./files /files
# Contrast security
COPY contrast.jar /opt/app
COPY contrast_security.yaml /opt/app
CMD ["java", "-javaagent:/opt/app/contrast.jar", "-Dcontrast.config.path=/opt/app/contrast_security.yaml", "-jar", "/opt/app/shopizer.jar"]
#CMD ["java", "-jar", "/opt/app/shopizer.jar"]
