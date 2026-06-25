# Build stage: Maven + Temurin 26 JDK (¡Actualizado a Java 26!)
FROM maven:3.9.11-eclipse-temurin-26-noble AS build
WORKDIR /workspace

# copy pom and download dependencies to leverage cache
COPY pom.xml .
RUN mvn -B -f pom.xml -DskipTests dependency:go-offline

# copy source and build the project
COPY . .
RUN mvn -B -DskipTests package

# Runtime stage: Temurin 26 JRE (¡Actualizado a Java 26!)
FROM eclipse-temurin:26-jre-noble
WORKDIR /app

# copy the built jar (adjust glob if your artifact name is known)
COPY --from=build /workspace/target/*.jar app.jar

# defaults: dev profile and port 8091 (can be overridden with -e)
ENV SPRING_PROFILES_ACTIVE=dev
ENV PORT=8091
ENV JAVA_OPTS=""

EXPOSE 8091

# allow passing JAVA_OPTS and override profile/port via env vars
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -Dserver.port=${PORT} -jar /app/app.jar"]
