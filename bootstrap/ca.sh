#!/usr/bin/env bash

require_ca_vars() {
  local var
  for var in CA_FQDN CA_PORT CA_DATA_DIR CA_NAME; do
    [[ -n "${!var:-}" ]] || fail "Missing required variable: $var"
  done

  validate_var_fqdn "${CA_FQDN}"
  validate_var_port "${CA_PORT}"
  validate_var_path "${CA_DATA_DIR}"
}

do_ca() {
  require_ca_vars
  common_pkgs
  docker_pkgs
  install -d -m 0755 "${WORKDIR}/step-ca" "${CA_DATA_DIR}"
  render_template "${TEMPLATE_DIR}/docker-compose.step-ca.yml.tpl" "${WORKDIR}/step-ca/docker-compose.yml"

  if [[ ! -f "${CA_DATA_DIR}/config/ca.json" ]]; then
    fail "step-ca is not initialized in ${CA_DATA_DIR}. Initialize it with the official Smallstep image and 'step ca init' using CA_NAME='${CA_NAME}' and CA_FQDN='${CA_FQDN}', then rerun --ca."
  fi

  (
    cd "${WORKDIR}/step-ca"
    docker compose down || true
    docker compose up -d
  )
  ufw allow "${CA_PORT}/tcp" || true
}
