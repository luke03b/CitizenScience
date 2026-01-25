# ═══════════════════════════════════════════════════════════════
# STAGE 1: Build Flutter Web
# ═══════════════════════════════════════════════════════════════
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copia i file di configurazione prima (per cache layer)
COPY pubspec.yaml pubspec.lock* ./

# Scarica le dipendenze
RUN flutter pub get

# Copia gli asset prima del resto del codice
COPY assets/ ./assets/

# Copia tutto il progetto
COPY . .

# Build web release
RUN flutter build web --release

# ═══════════════════════════════════════════════════════════════
# STAGE 2: Serve con Nginx
# ═══════════════════════════════════════════════════════════════
FROM nginx:alpine

# Copia il build Flutter
COPY --from=build /app/build/web /usr/share/nginx/html

# Copia configurazione Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Esponi porta 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
