# Backend Check-In CAE

## Requisitos
- Node.js 18+ (en tu caso ya tienes Node 24)
- PostgreSQL 14+

## Configuracion
1. Copia `.env.example` a `.env` y ajusta los valores.
2. Crea la base de datos en PostgreSQL (por ejemplo `checkin_cae`).

## Prisma
Ejecuta las migraciones y genera el cliente:
```bash
npx prisma migrate dev --name init
npx prisma generate
```

## Crear administrador inicial
```bash
npm run seed:admin
```

## Ejecutar
```bash
npm run dev
```

## Endpoints principales
- `POST /auth/login`
- `GET /auth/me`
- `POST /checkins` (multipart: `photo`, `latitude`, `longitude`, `activity`)
- `GET /checkins/me`
- `GET /admin/users`, `POST /admin/users`, `PUT /admin/users/:id`, `DELETE /admin/users/:id`
- `GET /admin/worksites`, `POST /admin/worksites`, `PUT /admin/worksites/:id`, `DELETE /admin/worksites/:id`
- `GET /admin/checkins`
- `GET /admin/checkins/export` (descarga `.xlsx`)
