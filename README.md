# Homelab Infrastructure

This repository contains bootstrap scripts and configuration for non-Kubernetes infrastructure in the homelab.

## Scope

- DNS (Unbound)
- NTP (Chrony)
- Identity (Keycloak)

These services run on a dedicated NUC and are intentionally kept separate from Kubernetes (k3s).

---

## Repository Structure

bootstrap/
  nuc/
    bootstrap_shared_services_modular.sh

services/
  unbound/
    sddc.conf
  ntp/
    chrony.conf
  keycloak/
    docker-compose.yml

---

## Prerequisites

- Debian/Ubuntu-based system
- Root or sudo access
- Static IP configured on the host

---

## Usage

All operations are performed via the modular bootstrap script:

bootstrap/nuc/bootstrap_shared_services_modular.sh

Run with:

sudo bash bootstrap/nuc/bootstrap_shared_services_modular.sh <option>

---

## Options

--unbound    Install and configure Unbound DNS  
--ntp        Install and configure Chrony NTP  
--keycloak   Install and configure Keycloak  
--all        Run everything  

---

## Examples

Install DNS only:

sudo bash bootstrap/nuc/bootstrap_shared_services_modular.sh --unbound

Install NTP only:

sudo bash bootstrap/nuc/bootstrap_shared_services_modular.sh --ntp

Install Keycloak:

1. Edit password:

services/keycloak/docker-compose.yml

Replace:
CHANGE_ME

2. Run:

sudo bash bootstrap/nuc/bootstrap_shared_services_modular.sh --keycloak

Run everything:

sudo bash bootstrap/nuc/bootstrap_shared_services_modular.sh --all

---

## What the script does

Unbound:
- Installs Unbound
- Disables systemd-resolved
- Configures authoritative zone for sddc.lab
- Creates A + PTR records (required for VCF 9)
- Starts and enables service

NTP (Chrony):
- Installs Chrony
- Disables systemd-timesyncd
- Configures upstream NTP servers
- Enables internal network access

Keycloak:
- Installs Docker + Compose
- Generates internal CA and TLS certificate
- Deploys Keycloak via Docker Compose
- Exposes service at:

https://auth.sddc.lab:8443

---

## Certificates

Location:

/root/homelab-bootstrap/

Important files:

- homelab-ca.crt → import into clients and VCF trust store
- keycloak-chain.crt → full certificate chain

---

## Important Notes

- Always use FQDN (never IP)
- Forward AND reverse DNS must work
- Import CA cert into:
  - browser
  - OS trust store
  - VCF SSO

---

## Future Improvements

- Replace embedded DB with PostgreSQL
- Add environment-based configuration
- Move toward Ansible for idempotency

---

## Related

Kubernetes workloads are managed separately via GitOps.
