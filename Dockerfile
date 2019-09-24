# Building Container

FROM gradle:4.10-jdk8 as GradleBuilder

USER 0

COPY ca-certificates/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

RUN apt-get update \
    && apt-get install -y \
        maven \
    && rm -rf /var/lib/apt/lists/*

USER gradle

COPY --chown=gradle:gradle build.gradle /home/gradle/src/build.gradle
COPY --chown=gradle:gradle gradle /home/gradle/src/gradle
COPY --chown=gradle:gradle gradle.properties /home/gradle/src/gradle.properties
COPY --chown=gradle:gradle settings.gradle /home/gradle/src/settings.gradle
COPY --chown=gradle:gradle lib /home/gradle/src/lib
COPY --chown=gradle:gradle src /home/gradle/src/src

WORKDIR /home/gradle/src

ENV GRADLE_USER_HOME=/home/gradle

ENV CREDENTIALS_VERSION=0.5.0-2306.a5a5cdf-0.11.10-002.985e705

RUN mvn install:install-file \
-Dfile=lib/pravega-keycloak-credentials-${CREDENTIALS_VERSION}-shadow.jar \
-DgroupId=io.pravega \
-DartifactId=pravega-keycloak-credentials \
-Dversion=${CREDENTIALS_VERSION} -Dpackaging=jar

RUN gradle installDist \
--no-daemon --info --stacktrace

# Runtime Container

FROM openjdk:8-jre

ENV APP_NAME=pravega-benchmark

COPY --from=GradleBuilder /home/gradle/src/build/install/${APP_NAME} /opt/${APP_NAME}

ENTRYPOINT ["/opt/pravega-benchmark/bin/pravega-benchmark"]
