# Laravel Docker

[![Requires Docker](https://img.shields.io/badge/prerequisite-Docker-blue)](https://www.docker.com)
[![Latest Release](https://img.shields.io/github/v/release/kishor-rajbanshi/laravel-docker)](https://github.com/kishor-rajbanshi/laravel-docker/releases)
[![License](https://img.shields.io/github/license/kishor-rajbanshi/laravel-docker)](LICENSE)

A ready-to-use Docker setup for Laravel applications. Quickly spin up a complete, configurable environment with Nginx, PHP, MySQL and more, tailored for both development and production.

---

## 📚 Documentation

Full documentation is available on the [Wiki](https://github.com/kishor-rajbanshi/laravel-docker/wiki).

---

## ⚡ Features

- Pre-configured environment for Laravel applications
- Services are defined and can be configured via `.env`
- Each service may have its own configuration file for fine-tuning

> **Note:** Never modify the `.docker` folder manually — it contains the package code. Changing or adding files there can break your current environment and will prevent successful updates.

---

## 📦 Installation

### Pull the installer image

```sh
docker pull krajbanshi/laravel-docker
```

- 🐳 [Installer Docker Image](https://hub.docker.com/r/krajbanshi/laravel-docker)
- 📦 [Installer Repository](https://github.com/kishor-rajbanshi/laravel-docker-installer)

---

Once the installer image is pulled, you can use it to set up the [Laravel Docker package](https://github.com/kishor-rajbanshi/laravel-docker) in your project.

The installer will:

- Create the `.docker` folder in your project root
- Generate the `compose.yml` file
- Merge or create `.env` and `.env.example`

### Run the installer container in your Laravel project root

Unix Shell (Linux / macOS)

```sh
docker run --rm -v "$(pwd):/app" -u "$(id -u):$(id -g)" krajbanshi/laravel-docker
```

PowerShell (Windows)

```powershell
docker run --rm -v "${PWD}:/app" krajbanshi/laravel-docker
```

CMD (Windows)

```cmd
docker run --rm -v "%cd%:/app" krajbanshi/laravel-docker
```

### Install a Specific Version

To install a specific version, just pass it as an argument:

```sh
docker \
    run \
    --rm \
    -v "$(pwd):/app" \
    -u "$(id -u):$(id -g)" \
    krajbanshi/laravel-docker <version>
```

---

## 🔄 Updating the Package

This package includes an **update service** that can upgrade itself to the latest version or to a specific version, branch, or commit hash.

### Update to the Latest Version

```bash
docker compose run --rm update
```

### Update to a Specific Version / Branch / Commit

```bash
docker compose run --rm update <version|branch|commit>
```

### Notes

- Works only in versions where the `update` service is available.
- Updating to very old versions may fail or remove the ability to self-update.
- `.docker` folder contains the package code. Do **not** edit or add files here to avoid breaking.

#### 📖 See the [Update Guide](https://github.com/kishor-rajbanshi/laravel-docker/wiki/Update-Guide) for detailed instructions

---

## ⚙️ Configuration

All services in Laravel Docker are fully configurable via the `.env` file and optional per-service configuration files.

### Environment Variables

- Each service has its own prefix for clarity. Examples:

  - `NGINX_` → Nginx-specific variables
  - `PHP_` → PHP-specific variables
  - `MYSQL_` → MySQL-specific variables

- Some services may **use variables from other services**.

### Per-Service Configuration Files

- Beyond `.env`, you can create dedicated configuration files for each service on the project root (e.g., `nginx.conf`).
- These files allow advanced customization without editing the main `.docker` package code.
- **Warning:** Do not modify other files in `.docker/`, as it may break the environment and updates.

### Detailed Documentation

- Full list of configurable variables and per-service config examples can be found in the [Wiki](https://github.com/kishor-rajbanshi/laravel-docker/wiki/Configuration).

---

### 🏁 Usage

You can manage your Laravel Docker environment using standard Docker Compose commands. Here are some essential examples:

- **Start the environment**

  ```bash
  docker compose up -d
  ```

- **Stop all running services**

  ```bash
  docker compose down
  ```

- **Rebuild containers with updated configuration**

  ```bash
  docker compose up -d --build
  ```

- **View real-time logs for all services**

  ```bash
  docker compose logs -f
  ```

---

## 📜 License

This project is licensed under the [MIT License](./LICENSE).
