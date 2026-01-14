# Citizen Science - Documentazione Architettura

> **Ultimo aggiornamento:** 14 Gennaio 2026

---

## 📋 Indice

1. [Panoramica](#-panoramica)
2. [Architettura Docker](#-architettura-docker)
3. [Configurazione CORS](#-configurazione-cors)
4. [Nginx Reverse Proxy](#-nginx-reverse-proxy)
5. [Database](#-database)
6. [Variabili d'Ambiente](#-variabili-dambiente)
7. [Comandi Utili](#-comandi-utili)
8. [Accesso ai Servizi](#-accesso-ai-servizi)

---

## 🏗 Panoramica

Il progetto è composto da tre servizi containerizzati:

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│    Frontend     │      │     Backend     │      │    Database     │
│   Flutter Web   │ ───► │  Spring Boot    │ ───► │   PostgreSQL    │
│   (nginx:80)    │      │   (8080)        │      │   (5432)        │
└─────────────────┘      └─────────────────┘      └─────────────────┘
     porta 8081              porta 8080              porta 5432
```

---

## 🐳 Architettura Docker

### Servizi (`docker-compose.yml`)

| Servizio | Immagine | Porta Esterna | Porta Interna |
|----------|----------|---------------|---------------|
| `postgres` | postgres:16-alpine | 5432 | 5432 |
| `backend` | Spring Boot (custom) | 8080 | 8080 |
| `frontend` | nginx:alpine (custom) | 8081 | 80 |

### Ordine di Avvio

1. **PostgreSQL** → avvia per primo, health check con `pg_isready`
2. **Backend** → attende che PostgreSQL sia healthy
3. **Frontend** → attende che Backend sia healthy (actuator/health)

### Rete Docker Interna

Docker crea automaticamente un DNS interno. I container comunicano usando i nomi dei servizi:

```
frontend  ──► backend:8080     (non IP!)
backend   ──► postgres:5432    (non IP!)
```

**Perché?** Gli IP dei container cambiano ad ogni riavvio, i nomi no.

---

## 🔒 Configurazione CORS

**File:** `CitizenScienceBackend/src/main/java/com/citizenScience/config/SecurityConfig.java`

### Cos'è CORS?

CORS (Cross-Origin Resource Sharing) controlla quali **siti web** possono chiamare le API dal browser.

**NON controlla** gli IP degli utenti, ma l'header `Origin` che il browser aggiunge automaticamente.

### Come funziona

```
Browser carica pagina da: http://192.168.1.100:8081
Browser chiama API:       GET /api/test
                          Origin: http://192.168.1.100:8081  ← Header automatico

Backend controlla: "192.168.1.100:8081 è nella whitelist?"
```

### Configurazione attuale

```java
configuration.setAllowedOriginPatterns(List.of(
    "http://localhost:8081",
    "http://127.0.0.1:8081",
    "http://192.168.*.*:8081",  // LAN locale
    "http://10.*.*.*:8081"      // LAN alternativa
));
```

### ⚠️ Nota importante

CORS serve per le chiamate **dirette** browser→backend. Con nginx come reverse proxy, il browser chiama solo il frontend (stessa origine) e CORS non serve per quelle chiamate.

---

## 🔄 Nginx Reverse Proxy

**File:** `citizen_science/nginx.conf`

### Cosa fa Nginx?

1. **Serve file statici** - L'app Flutter (HTML, JS, CSS)
2. **Reverse Proxy** - Inoltra le chiamate `/api/*` al backend

### Configurazione

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;

    # Chiamate API → inoltra al backend
    location /api/ {
        proxy_pass http://backend:8080/api/;
    }

    # Tutto il resto → serve Flutter app
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Flusso delle richieste

```
Browser (http://192.168.1.100:8081)
    │
    ├── GET /                    → Nginx serve Flutter app
    ├── GET /main.dart.js        → Nginx serve file JS
    └── GET /api/test            → Nginx → proxy → backend:8080/api/test
                                          ↓
                                   Risposta dal backend
                                          ↓
                                   Nginx → Browser
```

### Vantaggi

| Senza Proxy | Con Proxy |
|-------------|-----------|
| URL hardcoded (`localhost:8080`) | URL relativi (`/api/*`) |
| Problemi CORS | Nessun CORS (stessa origine) |
| Backend esposto | Backend nascosto |
| Non funziona su dispositivi esterni | Funziona ovunque |

---

## 🗄 Database

### Connessione

| Ambiente | Host | Porta | Database |
|----------|------|-------|----------|
| Docker | `postgres` | 5432 | citizenscience |
| Locale | `localhost` | 5432 | citizenscience |

### Profili Spring Boot

| File | Uso |
|------|-----|
| `application.properties` | Configurazione comune (driver, hibernate, flyway) |
| `application-dev.properties` | Sviluppo locale (`localhost:5432`) |
| `application-docker.properties` | Docker (`postgres:5432`) |

### Flyway Migrations

Le migrazioni del database vanno in:
```
src/main/resources/db/migration/V1__nome_migrazione.sql
```

Convenzione nomi: `V{numero}__{descrizione}.sql`

---

## 🔐 Variabili d'Ambiente

### File `.env` (root del progetto)

```env
POSTGRES_DB=citizenscience
POSTGRES_USER=postgres
POSTGRES_PASSWORD=<password>
```

### File `.env` (CitizenScienceBackend/)

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/citizenscience
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=<password>
```

### ⚠️ Sicurezza

- I file `.env` sono in `.gitignore`
- Mai committare credenziali nel codice
- Usare `.env.example` come template (senza password reali)

---

## 🛠 Comandi Utili

### Docker

```bash
# Avvia tutti i container
docker compose up -d

# Ricostruisci e avvia
docker compose up --build -d

# Ricostruisci senza cache (dopo modifiche Java)
docker compose build --no-cache backend
docker compose up -d

# Ferma tutto
docker compose down

# Vedi log
docker logs citizen-science-backend
docker logs citizen-science-frontend

# Entra in un container
docker exec -it citizen-science-backend sh
```

### Test

```bash
# Test backend dall'interno del container
docker exec citizen-science-backend wget -qO- http://localhost:8080/api/test

# Test health check
curl http://localhost:8080/actuator/health
```

### Sviluppo locale (senza Docker)

```bash
# Backend
cd CitizenScienceBackend
mvn spring-boot:run -Dspring.profiles.active=dev

# Frontend
cd citizen_science
flutter run -d chrome
```

---

## 🌐 Accesso ai Servizi

### Da localhost

| Servizio | URL |
|----------|-----|
| Frontend | http://localhost:8081 |
| Backend API | http://localhost:8080/api/* |
| Actuator Health | http://localhost:8080/actuator/health |
| Database | localhost:5432 |

### Da dispositivo esterno (stesso WiFi)

Sostituisci `localhost` con l'IP del PC:

```powershell
# Trova il tuo IP
ipconfig | Select-String "IPv4"
```

| Servizio | URL |
|----------|-----|
| Frontend | http://192.168.x.x:8081 |
| Backend (via proxy) | http://192.168.x.x:8081/api/* |

### Strumenti consigliati

| Tool | Uso |
|------|-----|
| **Insomnia/Postman** | Test API backend |
| **DataGrip/DBeaver** | Gestione database |
| **Docker Desktop** | Monitoraggio container |

---

## 📝 Changelog

### 14 Gennaio 2026
- ✅ Configurazione iniziale Docker Compose (frontend, backend, postgres)
- ✅ Configurazione health check con wget (Alpine non ha curl)
- ✅ Configurazione Spring Security per endpoint pubblici
- ✅ Configurazione CORS per sviluppo locale e LAN
- ✅ Nginx reverse proxy per chiamate API
- ✅ Spostamento credenziali in variabili d'ambiente (.env)
- ✅ Profili Spring Boot (dev, docker)
