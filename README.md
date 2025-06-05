# Chatwoot - Local Setup & Development Guide

This document covers how to fully set up the Chatwoot project locally — including prerequisites, environment setup, common issues we encountered, and how to solve them.

---

## 🖥️ Prerequisites

Before starting, ensure the following tools are installed on your system:

---

### 1️⃣ Docker Desktop

Required to run Chatwoot services in containers.

📥 Download: https://www.docker.com/products/docker-desktop

Install and launch Docker Desktop — you should see the whale icon in your menu bar.

Check version:

```bash
docker --version
docker compose version
```

---

### 2️⃣ Git

Required to clone the Chatwoot repository.

📥 Download: https://git-scm.com/downloads

macOS:  
Git usually comes pre-installed. Check:

```bash
git --version
```

If not installed:

```bash
brew install git
```

---

### 3️⃣ (Optional) rbenv + Ruby

This is not required if using Docker only — but helpful if running Rails directly for debugging.

Install Homebrew first if not installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then install rbenv + ruby-build:

```bash
brew install rbenv ruby-build
rbenv init
```

Verify rbenv:

```bash
rbenv --version
```

Install Ruby 3.4.4:

```bash
rbenv install 3.4.4
rbenv global 3.4.4
ruby --version
```

---

### 4️⃣ Postgres (via Docker)

Postgres will be provided by the docker-compose.yaml — no need to install Postgres manually!

---

#### Summary of Prerequisites:

✅ Docker Desktop  
✅ Docker Compose (comes with Docker Desktop)  
✅ Git  
✅ (Optional) rbenv + Ruby

---

## 🖥️ Frontend Notes

- Chatwoot uses Vite for the frontend (Vue/JavaScript).
- The frontend code is included in this monorepo—no separate clone or setup is required.
- When you run `docker compose up`, the `vite` service (frontend dev server) automatically starts on port 3036.
- The Rails backend proxies all frontend requests, so you only need to visit [http://localhost:3000](http://localhost:3000) to use the full application (both backend and frontend).

---

## 🚀 Project Setup

### 1️⃣ Clone the Repository

Fork the original repo on GitHub and clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/chatwoot.git
cd chatwoot
```

---

### 2️⃣ Environment Variables

Copy the sample env file and edit as needed:

```bash
cp .env.example .env
```

👉 **Important:**  
In `.env`, set `POSTGRES_PASSWORD` (do not leave it blank):

```
POSTGRES_PASSWORD=your_strong_password
```

---

### 3️⃣ Build & Start the Containers

```bash
docker compose build
docker compose up
```

---

### 4️⃣ Initialize the Database

In a new terminal window:

```bash
docker compose exec rails bin/rails db:create
docker compose exec rails bin/rails db:migrate
```

---

### 5️⃣ Create Admin User for Login

Enter Rails console:

```bash
docker compose exec rails bin/rails console
```

Then run:

```ruby
user = User.create!(
  email: 'admin@example.com',
  password: 'YourStrongPassword1!',
  password_confirmation: 'YourStrongPassword1!',
  name: 'Admin User',
  confirmed_at: Time.now
)
```

---

### 6️⃣ Access the Application

Visit: [http://localhost:3000](http://localhost:3000)

Login using the admin user you just created.

---

## 🧪 Testing

### Backend (Rails) Tests

Run in a separate terminal:

```bash
docker compose exec rails bundle exec rspec
```

**Notes:**
- You may see sendmail connection errors — this is expected if Mailhog is not running in test mode.
- These errors do not block the test run. You can ignore them unless you specifically configure Mailhog for test.

---

## 🛠️ Testing Core Functionality

- Login as admin
- Create inboxes, contacts, and conversations
- Send test messages
- Explore Settings & Automation features

---

## 🐞 Troubleshooting / Issues We Faced

### ❌ 1. could not translate host name "postgres"

**Cause:** The Rails app couldn’t connect to Postgres because Postgres wasn’t ready yet.

**Solution:**  
Use `docker compose exec` instead of `docker compose run`, so Rails connects to already running Postgres:

```bash
docker compose exec rails bin/rails db:create
docker compose exec rails bin/rails db:migrate
```

---

### ❌ 2. pg_isready - no response

**Cause:** Postgres takes time to start on first run.

**Solution:**  
Just re-run the exec commands after a few seconds — Postgres will eventually be ready.

---

### ❌ 3. Password validation errors when creating User

**Cause:** Chatwoot enforces strong password rules.

**Solution:**  
Use a password that includes:
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character

---

### ❌ 4. ActiveModel::UnknownAttributeError: unknown attribute 'role' for User

**Cause:** `role` attribute was removed in latest Chatwoot — use administrator through account permissions.

**Solution:**  
Omit `role:` field and just set:

```ruby
confirmed_at: Time.now
```

---

## ⚡ Useful Commands

- **Start containers:**
  ```bash
  docker compose up
  ```
- **Stop containers:**
  ```bash
  docker compose down
  ```
- **Rails console:**
  ```bash
  docker compose exec rails bin/rails console
  ```
- **Create DB:**
  ```bash
  docker compose exec rails bin/rails db:create
  ```
- **Run migrations:**
  ```bash
  docker compose exec rails bin/rails db:migrate
  ```

---

## ✅ Summary

By following this guide, you should now have:

✅ All prerequisites installed  
✅ Chatwoot running locally via Docker Compose  
✅ Database created and migrated  
✅ Admin user created  
✅ Able to login and test core functionality

---

## 📌 Notes

- We intentionally provided strong password in `.env` — do not leave `POSTGRES_PASSWORD` blank.
- You can rerun `docker compose up` anytime — database and volumes will persist.
- If migrations fail on first try (due to Postgres not ready), just run again after a few seconds.

---
