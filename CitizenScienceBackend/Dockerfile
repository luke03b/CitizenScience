# ═══════════════════════════════════════════════════════════════
# STAGE 1: Build con Maven
# ═══════════════════════════════════════════════════════════════
FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /app

# Copia i file di configurazione Maven (per cache layer)
COPY pom.xml .

# Scarica le dipendenze (cacheable)
RUN mvn dependency:go-offline -B

# Copia il codice sorgente
COPY src ./src

# Build del progetto (skip tests per velocizzare)
RUN mvn clean package -DskipTests -B

# ═══════════════════════════════════════════════════════════════
# STAGE 2: Runtime
# ═══════════════════════════════════════════════════════════════
FROM eclipse-temurin:25-jre-alpine

WORKDIR /app

# Copia il JAR dalla fase di build
COPY --from=build /app/target/*.jar app.jar

# Esponi porta 8080
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Avvia l'applicazione
ENTRYPOINT ["java", "-jar", "app.jar"]
