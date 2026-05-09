# 📦 JellyfinPS

Unofficial PowerShell module for interacting with the Jellyfin API.

## ✨ Overview

**JellyfinPS** is a lightweight PowerShell module that provides convenient functions for querying and interacting with a Jellyfin server via its REST API.

It abstracts common API operations into simple PowerShell commands, making it easier to automate tasks, build scripts, or integrate Jellyfin into your workflows.

---

## 📋 Requirements

* PowerShell 7+
* [FFmpeg](https://www.ffmpeg.org) - Needed for video manipulation
* A running Jellyfin server
* A valid Jellyfin API key

---

## 📥 Installation

### Manual Install

```powershell
apt install ffmpeg
git clone https://github.com/mikethomp/JellyfinPS.git
```

Copy the module folder into your PowerShell modules directory:

```powershell
~/.local/share/powershell/Modules/
```

Then import:

```powershell
Import-Module JellyfinPS
```

---

## 🔑 Authentication

All functions require:

* `JellyfinHost` → Server hostname (e.g. `jellyfin.local:8096`)
* `ApiKey` → Jellyfin API key

---

## ⚠️ Notes

* `-SkipCertificateCheck` is available for self-signed certificates but should be avoided in production.
* Host formatting is expected as `hostname:port`.
* This module has been tested on Ubuntu Linux.

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

---

## 🙌 Acknowledgments

* [Jellyfin](https://github.com/jellyfin) — open-source media system powering the API used by this module.
