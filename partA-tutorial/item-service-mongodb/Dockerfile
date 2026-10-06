# ---------------------------------------------------------------
# Part A - Tutorial: "item-service-mongodb" (Spring Boot, Java 11)
# The course uses:   FROM openjdk:11 / ADD target/app.jar / ENTRYPOINT
# with the jar built on the host. The openjdk images are deprecated
# and we do not want to depend on a local JDK/Maven, so we use a
# MULTI-STAGE build: the jar is compiled inside Docker (Maven wrapper)
# and only the jar is copied into a small JRE-only Alpine image.
# ---------------------------------------------------------------

# ---- Stage 1: build the jar with the Maven wrapper ----
FROM eclipse-temurin:11-jdk-alpine AS build
WORKDIR /build
# 1) wrapper + pom only -> dependency layer cached between builds
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -q -B dependency:go-offline
# 2) sources (change often) -> only this layer is rebuilt
COPY src ./src
RUN ./mvnw -q -B package -DskipTests        # -> target/app.jar (finalName=app)

# ---- Stage 2: runtime image (JRE only, no build tools) ----
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
RUN addgroup -S spring && adduser -S spring -G spring   # non-root user
COPY --from=build /build/target/app.jar app.jar
USER spring
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
