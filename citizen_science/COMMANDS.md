# Comandi Utili - Citizen Science PWA

## 🧹 Pulizia

```powershell
# Pulisce la cache e i file di build
flutter clean

# Ricarica le dipendenze
flutter pub get
```

## 🔨 Build

```powershell
# Build web per sviluppo
flutter build web

# Build web per produzione (ottimizzato)
flutter build web --release

# Build con renderer HTML (più compatibile, file più piccoli)
flutter build web --release --web-renderer html

# Build con renderer CanvasKit (migliore qualità grafica)
flutter build web --release --web-renderer canvaskit

# Build con scelta automatica del renderer
flutter build web --release --web-renderer auto

# Build senza Service Worker (per test su HTTP)
flutter build web --release --pwa-strategy none

# Build con strategia offline-first (consigliato per PWA)
flutter build web --release --pwa-strategy offline-first
```

## 🖥️ Server Locale

```powershell
# Avvia server Python (dopo build)
cd build/web
python -m http.server 8080
# Apri: http://localhost:8080

# Torna alla cartella principale
cd ../..
```

## 🚀 Sviluppo

```powershell
# Avvia in Chrome per sviluppo
flutter run -d chrome

# Avvia in Chrome con porta specifica
flutter run -d chrome --web-port=8080

# Avvia con hot reload
flutter run -d chrome --web-renderer html
```

## 📱 Test su Dispositivi

| Dispositivo | Indirizzo |
|-------------|-----------|
| PC (localhost) | `http://localhost:8080` |
| Emulatore Android | `http://10.0.2.2:8080` |
| Dispositivo fisico | `http://<IP-DEL-PC>:8080` |

```powershell
# Trova il tuo IP locale
ipconfig
# Cerca "IPv4 Address" (es. 192.168.1.100)
```

## 🔒 Server HTTPS (per test PWA completo)

```powershell
# Opzione 1: Usa ngrok (consigliato)
# Scarica da https://ngrok.com/download
ngrok http 8080
# Usa l'URL https generato

# Opzione 2: http-server con SSL
npm install -g http-server
cd build/web
http-server -S -C server.cert -K server.key -p 8080
```

## 🔍 Debug e Analisi

```powershell
# Analizza dimensione del build
flutter build web --release --analyze-size

# Mostra dispositivi disponibili
flutter devices

# Verifica stato Flutter
flutter doctor
```

## 📦 Dipendenze

```powershell
# Aggiorna dipendenze
flutter pub upgrade

# Mostra dipendenze obsolete
flutter pub outdated

# Aggiungi una dipendenza
flutter pub add <nome_pacchetto>
```

## 🔄 Workflow Completo

```powershell
# 1. Pulisci
flutter clean

# 2. Ricarica dipendenze
flutter pub get

# 3. Build
flutter build web --release

# 4. Avvia server
cd build/web
python -m http.server 8080

# 5. Apri browser: http://localhost:8080
```

## 🐳 Docker

```powershell
# Build immagine Docker
docker build -t citizen-science-web .

# Run container singolo
docker run -d -p 8080:80 --name citizen-science-pwa citizen-science-web

# Oppure usa Docker Compose (consigliato)
docker-compose up -d

# Build e avvio insieme
docker-compose up -d --build

# Stop container
docker-compose down

# Rebuild dopo modifiche al codice
docker-compose up -d --build

# Vedi logs
docker-compose logs -f

# Vedi stato container
docker-compose ps

# Apri: http://localhost:8080
```

## ⚠️ Note Importanti

- **Service Worker**: Funziona solo su `localhost` o `HTTPS`
- **PWA installabile**: Richiede HTTPS in produzione
- **Test offline**: DevTools → Application → Service Workers → Offline
- **Lighthouse**: DevTools → Lighthouse → Progressive Web App
- **Docker**: Richiede Docker Desktop installato