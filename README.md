# Provider Box

Lightweight Ubuntu-based shared-services host for:
- DNS (Unbound)
- NTP (Chrony)
- Identity (Keycloak)

## Setup

cp config/provider-box.env.example config/provider-box.env
cp config/unbound.records.example config/unbound.records

Edit files, then run:

sudo bash bootstrap/provider-box.sh --all
