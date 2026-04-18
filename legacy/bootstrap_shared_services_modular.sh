#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKDIR="/root/homelab-bootstrap"
KEYCLOAK_DIR="/opt/keycloak"

usage() {
  cat <<USAGE
Usage:
  sudo bash $0 --unbound
  sudo bash $0 --ntp
  sudo bash $0 --keycloak
  sudo bash $0 --all
USAGE
}

require_root() {
  [[ "$EUID" -eq 0 ]] || { echo "Run as root"; exit 1; }
}

apt_update_once() {
  if [[ "${APT_UPDATED:-0}" -eq 0 ]]; then
    apt-get update
    APT_UPDATED=1
  fi
}

install_pkg() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

common_pkgs() {
  apt_update_once
  install_pkg ca-certificates curl openssl dnsutils ufw
}

unbound_pkgs() {
  apt_update_once
  install_pkg unbound
}

ntp_pkgs() {
  apt_update_once
  install_pkg chrony
}

keycloak_pkgs() {
  apt_update_once
  install_pkg docker.io docker-compose
  systemctl enable docker
  systemctl start docker
}

configure_resolv_conf() {
  systemctl disable systemd-resolved || true
  systemctl stop systemd-resolved || true
  rm -f /etc/resolv.conf
  cat > /etc/resolv.conf <<RESOLV
nameserver 127.0.0.1
search sddc.lab
RESOLV
}

do_unbound() {
  common_pkgs
  unbound_pkgs
  configure_resolv_conf
  install -D -m 0644 "${REPO_ROOT}/services/unbound/sddc.conf" /etc/unbound/unbound.conf.d/sddc.conf
  unbound-checkconf
  systemctl enable unbound
  systemctl restart unbound
  ufw allow 53/tcp || true
  ufw allow 53/udp || true
}

do_ntp() {
  common_pkgs
  ntp_pkgs
  systemctl disable systemd-timesyncd || true
  systemctl stop systemd-timesyncd || true
  install -D -m 0644 "${REPO_ROOT}/services/ntp/chrony.conf" /etc/chrony/chrony.conf
  systemctl enable chrony
  systemctl restart chrony
  ufw allow 123/udp || true
}

generate_certs() {
  mkdir -p "${WORKDIR}" "${KEYCLOAK_DIR}/certs" "${KEYCLOAK_DIR}/data"

  cat > "${WORKDIR}/auth-openssl.cnf" <<CERTCFG
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no

[ req_distinguished_name ]
C  = SE
ST = Skane
L  = Home
O  = Homelab
OU = Identity
CN = auth.sddc.lab

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = auth.sddc.lab
IP.1  = 192.168.12.121
CERTCFG

  openssl genrsa -out "${WORKDIR}/homelab-ca.key" 4096
  openssl req -x509 -new -nodes \
    -key "${WORKDIR}/homelab-ca.key" \
    -sha256 -days 3650 \
    -out "${WORKDIR}/homelab-ca.crt" \
    -subj "/C=SE/ST=Skane/L=Home/O=Homelab/OU=Infra/CN=Homelab Root CA"

  openssl genrsa -out "${WORKDIR}/auth.sddc.lab.key" 2048
  openssl req -new \
    -key "${WORKDIR}/auth.sddc.lab.key" \
    -out "${WORKDIR}/auth.sddc.lab.csr" \
    -config "${WORKDIR}/auth-openssl.cnf"

  openssl x509 -req \
    -in "${WORKDIR}/auth.sddc.lab.csr" \
    -CA "${WORKDIR}/homelab-ca.crt" \
    -CAkey "${WORKDIR}/homelab-ca.key" \
    -CAcreateserial \
    -out "${WORKDIR}/auth.sddc.lab.crt" \
    -days 825 \
    -sha256 \
    -extensions req_ext \
    -extfile "${WORKDIR}/auth-openssl.cnf"

  install -m 0644 "${WORKDIR}/auth.sddc.lab.crt" "${KEYCLOAK_DIR}/certs/auth.sddc.lab.crt"
  install -m 0600 "${WORKDIR}/auth.sddc.lab.key" "${KEYCLOAK_DIR}/certs/auth.sddc.lab.key"
  chown -R 1000:1000 "${KEYCLOAK_DIR}"

  cat "${WORKDIR}/auth.sddc.lab.crt" "${WORKDIR}/homelab-ca.crt" > "${WORKDIR}/keycloak-chain.crt"
}

do_keycloak() {
  common_pkgs
  keycloak_pkgs
  generate_certs
  mkdir -p "${WORKDIR}/keycloak"
  cp "${REPO_ROOT}/services/keycloak/docker-compose.yml" "${WORKDIR}/keycloak/docker-compose.yml"
  cd "${WORKDIR}/keycloak"
  docker compose down || true
  docker compose up -d
  ufw allow 8443/tcp || true
}

require_root

[[ $# -eq 1 ]] || { usage; exit 1; }

case "$1" in
  --unbound) do_unbound ;;
  --ntp) do_ntp ;;
  --keycloak) do_keycloak ;;
  --all) do_unbound; do_ntp; do_keycloak ;;
  -h|--help) usage ;;
  *) usage; exit 1 ;;
esac
