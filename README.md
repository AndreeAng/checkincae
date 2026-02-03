# Check-In CAE

Aplicación web y móvil para **registro de ingreso/salida** de trabajadores con autenticación, roles y control de evidencias (foto + geolocalización).  
Incluye panel administrador con filtros y exportación a Excel.

## Stack
- **Backend:** Node.js + Express + Prisma + PostgreSQL
- **Frontend:** Flutter (Web + Android)

---

## Requisitos
- Node.js **20.x** (recomendado con nvm)
- PostgreSQL **17/18**
- Flutter **3.38+**

---

## Configuración rápida

### 1) Backend
```bash
cd backend
copy .env.example .env
```
Edita `.env` con tu conexión a PostgreSQL y un `JWT_SECRET` fuerte.

```bash
npx prisma migrate dev --name init
npm run seed:admin
npm run dev
```

### 2) Frontend (Flutter Web)
```bash
cd mobile_web
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

En login:
- **Servidor local:** `http://localhost:4000`
- **Móvil en misma red:** `http://TU_IP:4000`

---

## Admin por defecto
- **Usuario:** `admin`
- **Contraseña:** `Admin123!`

> Cambia esta clave en `.env` antes de producción.

---

## Producción (recomendado)
1. **Backend** detrás de HTTPS
2. **Frontend Flutter Web** en build release:
```bash
flutter build web
```
3. Servir `mobile_web/build/web` con un servidor estático (Nginx/Cloudflare Pages/Netlify)

---

## Estructura
```
backend/        # API + Prisma + almacenamiento de fotos
mobile_web/     # Flutter Web + Android
```

---

## Licencia
MIT
