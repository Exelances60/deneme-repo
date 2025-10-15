# ---- Build stage
FROM gradle:8.7-jdk17 AS build
WORKDIR /workspace

# Gradle cache için önce wrapper ve build dosyaları
COPY gradlew ./
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Bağımlılıkları indirt (cache için)
RUN chmod +x gradlew && ./gradlew --no-daemon dependencies || true

# Uygulama kaynakları
COPY . .

# Jar üret
RUN ./gradlew --no-daemon clean bootJar

# ---- Runtime stage
FROM openjdk:17
WORKDIR /app

# Üretilen jar'ı kopyala (adı ne olursa olsun)
COPY --from=build /workspace/build/libs/*.jar /app/app.jar

ENV JAVA_OPTS=""
EXPOSE 8080
ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar /app/app.jar"]
