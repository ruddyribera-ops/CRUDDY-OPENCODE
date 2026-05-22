# Deployment Ecosystem & Tools

## Container Composition & Orchestration
| Tool | Purpose | Notes |
|------|---------|-------|
| docker-compose | Multi-container dev | Standard |
| kompose | Compose→K8s conversion | Bridge tool |
| compose-spec | Standard Compose format | OCI-compliant |

## Monitoring & Observability
| Tool | Purpose | Setup |
|------|---------|-------|
| cAdvisor | Container resource metrics | Sidecar or daemon |
| Prometheus + Grafana | Metrics + dashboards | Standard stack |
| Dozzle | Real-time Docker logs (web UI) | Single binary |
| Netdata | Per-second monitoring | Agent on every node |
| Uptime-Kuma | Self-hosted uptime monitoring | HTTP/ping checks |

## Security Scanning
| Tool | What it scans | Integration |
|------|---------------|-------------|
| docker-bench-security | CIS Docker benchmark | `docker run` |
| Trivy | Images, FS, repos, K8s, SBOM | CI, CLI |
| Grype | Image vulnerabilities | syft→grype |
| Falco | Runtime threat detection | Kernel module/eBPF |
| Checkov | IaC (Dockerfile, K8s, TF) | CI, pre-commit |

## Networking & Reverse Proxy
| Tool | Role | Key Feature |
|------|------|-------------|
| Traefik | Reverse proxy + auto-TLS | Auto-discovers Docker labels |
| nginx-proxy | nginx + docker-gen | Auto virtual hosts |
| caddy-docker-proxy | Caddy + Docker labels | Auto HTTPS |
| Tailscale | Mesh VPN for containers | P2P connections |

## Self-Hosted PaaS (Railway alternatives)
| Tool | When to use |
|------|-------------|
| Dokku | Small projects, one VPS |
| CapRover | Teams, multi-app |
| Coolify | Full PaaS on own VPS |
| Dokploy | Docker compose deployments |

## Base Images (Minimal & Secure)
| Image | Size | Use Case |
|-------|------|----------|
| distroless | ~5-20 MB | Production — no shell, no package manager |
| alpine | ~5 MB | Dev+prod when musl compatible |
| slim variants | ~30-50 MB | Smaller, fewer CVEs |
| wolfi | ~5 MB | Chainguard's undebian base |

## Desktop UIs
| Tool | Platform |
|------|----------|
| Portainer | Web UI |
| Lazydocker | TUI (terminal) |
| Dockge | Web UI |

## Container Registries
| Tool | Purpose |
|------|---------|
| Harbor | Enterprise registry (RBAC, scanning) |
| Distribution | Docker Registry v2 |
| zot | Lightweight OCI registry |
