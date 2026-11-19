# Cloud Run Full-Stack Example

A reference implementation of a web application whose **frontend and backend are packaged in a single container** and deployed to Google Cloud Run.

The frontend is compiled by Node.js during the image build. A Flask application, served by gunicorn, then delivers both the compiled static assets and the HTTP API from one port. This repository was prepared as a supporting example for the CPE334 Final Project, in which each team is provisioned a single Cloud Run service.

> สรุปภาษาไทยอยู่ท้ายเอกสาร (Thai summary at the end of this document).

## Contents

1. [Architecture](#architecture)
2. [Repository structure](#repository-structure)
3. [Prerequisites](#prerequisites)
4. [Running locally](#running-locally)
5. [Deployment](#deployment)
6. [Configuration](#configuration)
7. [Adapting the example](#adapting-the-example)
8. [Scope and limitations](#scope-and-limitations)
9. [Verification status](#verification-status)
10. [สรุปภาษาไทย](#สรุปภาษาไทย)
11. [License](#license)

## Architecture

```
Client ──► https://<service>.run.app
             │
             └─ gunicorn ► Flask application (single process, single port: $PORT)
                   ├─ GET /           → static/index.html   (built by Node.js)
                   ├─ GET /<file>     → static/<file>
                   └─ GET /api/hello  → JSON response from the backend
```

The `Dockerfile` defines two build stages:

| Stage | Base image | Responsibility |
|---|---|---|
| `frontend` | `node:22-slim` | Runs `npm run build` and produces `frontend/dist` |
| final | `python:3.12-slim` | Installs backend dependencies, copies the backend, and copies `dist` to `static/` |

The frontend addresses the backend with a relative path (`fetch('/api/hello')`). Both are served from the same origin, so no CORS configuration and no second service are required.

## Repository structure

```
.
├── Dockerfile
├── frontend/
│   ├── package.json      build script: "node build.js"
│   ├── build.js          copies src/ to dist/ (replace with Vite, webpack, etc.)
│   └── src/index.html
└── backend/
    ├── app.py            Flask application: /api/hello and static file serving
    └── requirements.txt
```

## Prerequisites

- Docker, for building and running the image locally.
- For deployment to the course environment: the Google Cloud CLI (`gcloud`) and the CPE334 Project Kit.

## Running locally

```bash
docker build -t fullstack-example .
docker run --rm -p 8080:8080 -e TEST_FLAG=hello fullstack-example
```

The application is then available at <http://localhost:8080>. The API can be queried at <http://localhost:8080/api/hello>, which returns:

```json
{"example":"fullstack","flag":"hello","has_database_url":false,"ok":true}
```

## Deployment

### Using the CPE334 Project Kit

1. Download the kit from the student portal (**Final Project Kit** tab).
2. Extract it into the root of this repository so that the `project-kit/` directory exists.
3. Run the following commands from the repository root:

```bash
./project-kit/kit.sh doctor    # verify the local setup and access
./project-kit/kit.sh build     # build the image and push it to the team registry
./project-kit/kit.sh deploy    # deploy the image to the team's Cloud Run service
./project-kit/kit.sh status    # display the current revision and image
```

`deploy` uses the image recorded by the most recent `build`. After any code change, run `build` again before `deploy`.

### Using gcloud directly

For any Google Cloud project outside the course environment:

```bash
gcloud run deploy <service-name> --source . --region <region>
```

## Configuration

| Variable | Provided by | Purpose |
|---|---|---|
| `PORT` | Cloud Run | Port on which the server listens. gunicorn reads it automatically |
| `DATABASE_URL` | Deployment configuration | Database connection string (optional; not used by this example) |
| `TEST_FLAG` | Deployment configuration | Demonstration value echoed by `/api/hello` |

Credentials and connection strings must not be committed to the repository. Store sensitive values as secrets.

## Adapting the example

| Objective | Required change |
|---|---|
| Use React, Vue, or Vite | Place the application in `frontend/`. Ensure `npm run build` writes to `frontend/dist`, and install dependencies in the first stage (for example `RUN npm ci`) before the build step |
| Use a different backend language | Replace the final stage. Retain the same structure: copy `dist` beside the server and listen on `$PORT` |
| Add a database | Read the connection string from `DATABASE_URL` |
| Add API routes | Define routes under `/api/` in `backend/app.py`, ahead of the catch-all static route |

## Scope and limitations

- The example deploys **one service** and one container. It does not demonstrate separate frontend and backend services, or multi-container (sidecar) deployments.
- It contains no database access, migrations, automated tests, or authentication.
- The frontend build has no third-party dependencies, which keeps the example small. Builds with real npm dependencies take longer and produce larger images.

## Verification status

- The image was built and run locally with Docker. `/` and `/api/hello` returned HTTP 200.
- An equivalent layout was deployed to a Cloud Run service using the CPE334 Project Kit. `/` and `/api/hello` returned HTTP 200, and an unknown path returned HTTP 404.
- The exact `Dockerfile` in this repository was verified locally. The earlier Cloud Run deployment used an equivalent `CMD` written in shell form.

## สรุปภาษาไทย

- ตัวอย่างนี้รวมหน้าบ้านและหลังบ้านไว้ใน **container เดียว** และใช้พอร์ตเดียว (`$PORT`)
- `Dockerfile` เป็นแบบ multi-stage: ขั้นแรกใช้ Node.js สร้างหน้าบ้าน ขั้นที่สองใช้ Python (Flask และ gunicorn) ให้บริการทั้งหน้าเว็บและ `/api`
- หน้าบ้านเรียก API ด้วยพาธสัมพัทธ์ (`/api/hello`) จึงไม่ต้องตั้งค่า CORS
- การรันในเครื่อง: `docker build -t fullstack-example .` และ `docker run --rm -p 8080:8080 fullstack-example`
- การ deploy ด้วย Project Kit: แตกไฟล์ kit ไว้ในโฟลเดอร์โปรเจกต์ แล้วรัน `doctor`, `build`, `deploy` ตามลำดับ หากแก้โค้ดต้องรัน `build` ใหม่ทุกครั้งก่อน `deploy`
- ข้อจำกัด: ไม่มีฐานข้อมูล, migration, การทดสอบอัตโนมัติ และไม่ได้แยกหน้าบ้านกับหลังบ้านเป็นสอง service

## License

Released under the MIT License. See [LICENSE](LICENSE).
