# Cloud Run Full-Stack Example

A minimal **frontend + backend in one container** that deploys to Google Cloud Run.
A Node build produces the static frontend, and a Flask (gunicorn) backend serves both the web page and the `/api` routes from a single port.

Made as a reference for the CPE334 Final Project, where each team gets one Cloud Run service, so the frontend and backend share one URL and one container.

> ไทย: ตัวอย่างหน้าบ้าน + หลังบ้านรวมใน container เดียว (ดูสรุปภาษาไทยท้ายไฟล์)

## How it works

```
Browser ──► https://<your-service>.run.app
              │
              └─ gunicorn → Flask (one process, one port: $PORT)
                    ├─ GET /            → static/index.html (built by Node)
                    ├─ GET /<file>      → files from static/
                    └─ GET /api/hello   → JSON from the backend
```

The Dockerfile is multi-stage:

1. `node:22-slim` runs `npm run build` and writes `frontend/dist`.
2. `python:3.12-slim` installs the backend requirements, copies the backend, and copies `dist` into `static/`.

The frontend calls the backend with a relative path (`fetch('/api/hello')`), so there is no CORS setup and no second service.

## Project layout

```
.
├── Dockerfile
├── frontend/
│   ├── package.json     # "build": "node build.js"
│   ├── build.js         # copies src/ to dist/ (replace with Vite/webpack/etc.)
│   └── src/index.html
└── backend/
    ├── app.py           # Flask app: /api/hello + static file serving
    └── requirements.txt
```

## Run locally

```bash
docker build -t fullstack-example .
docker run --rm -p 8080:8080 -e TEST_FLAG=hello fullstack-example
```

Then open <http://localhost:8080> and <http://localhost:8080/api/hello>.

Expected API response:

```json
{"example":"fullstack","flag":"hello","has_database_url":false,"ok":true}
```

## Deploy to Cloud Run

### With the CPE334 Project Kit

Download the kit from the student portal (Final Project Kit tab), unzip it into this folder so you have `project-kit/`, then:

```bash
./project-kit/kit.sh doctor    # check your setup
./project-kit/kit.sh build     # build and push the image
./project-kit/kit.sh deploy    # deploy to your team's service
./project-kit/kit.sh status
```

Run `build` again whenever the code changes. `deploy` uses the image recorded by the last `build`.

### With plain gcloud (any Cloud Run project)

```bash
gcloud run deploy my-service --source . --region <region>
```

## Adapt it to your project

| You want to… | Change |
|---|---|
| Use React / Vue / Vite | Put the app in `frontend/`, make `npm run build` write to `frontend/dist` (for Vite, set `build.outDir` or copy it). Install dependencies in the Dockerfile before the build, e.g. `RUN npm ci` |
| Use another backend language | Replace the second stage. Keep the same idea: copy `dist` next to the server and have the server listen on `$PORT` |
| Add a database | Read the connection string from `DATABASE_URL`; never commit it. Use secrets for passwords |
| Add API routes | Add routes under `/api/...` in `backend/app.py`, and keep them before the catch-all static route |

## What this example is not

- It runs **one service**. It does not show separate frontend/backend services or sidecar containers.
- It has no database code, migrations, tests, or authentication.
- The frontend build is intentionally dependency-free so the example stays small. Builds with real npm dependencies take longer and produce larger images.

## Tested

Built and run locally with Docker, and the same layout was deployed to a Cloud Run service with the CPE334 Project Kit. `/` and `/api/hello` returned HTTP 200 and an unknown path returned 404.

## สรุปภาษาไทย

- ตัวอย่างนี้รวมหน้าบ้านและหลังบ้านไว้ใน **container เดียว** ใช้พอร์ตเดียว (`$PORT`)
- Dockerfile แบบ multi-stage: ขั้นแรกใช้ Node build หน้าบ้าน ขั้นสองใช้ Python (Flask + gunicorn) เสิร์ฟทั้งหน้าเว็บและ `/api`
- หน้าบ้านเรียก API ด้วยพาธสัมพัทธ์ (`/api/hello`) จึงไม่ต้องตั้งค่า CORS
- รันในเครื่อง: `docker build -t fullstack-example .` แล้ว `docker run --rm -p 8080:8080 fullstack-example`
- Deploy ด้วย Project Kit: แตกไฟล์ kit ไว้ในโฟลเดอร์นี้ แล้วรัน `doctor` → `build` → `deploy` (ถ้าแก้โค้ดต้อง `build` ใหม่ทุกครั้ง)
- ข้อจำกัด: ตัวอย่างนี้ไม่มีฐานข้อมูล, ไม่มี migration, และไม่ได้แยกหน้าบ้าน/หลังบ้านเป็นสอง service

## License

MIT
