FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

RUN apk add --no-cache maven

COPY . .

RUN mvn clean package -DskipTests

EXPOSE 8080

CMD ["java", "-jar", "target/be-0.0.1-SNAPSHOT.jar"]
