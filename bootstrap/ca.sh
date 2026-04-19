#!/usr/bin/env bash

require_ca_vars() {
  local var
  for var in WORKDIR CA_FQDN CA_PORT CA_DATA_DIR CA_NAME CA_PROVISIONER_NAME CA_PASSWORD_FILE CA_ENABLE_ACME; do
    [[ -n "${!var:-}" ]] || fail "Missing required variable: $var"
  done

  validate_var_path "${WORKDIR}"
  validate_var_fqdn "${CA_FQDN}"
  validate_var_port "${CA_PORT}"
  validate_var_path "${CA_DATA_DIR}"
  validate_var_path "${CA_PASSWORD_FILE}"
  [[ "${CA_ENABLE_ACME}" == "true" || "${CA_ENABLE_ACME}" == "false" ]] || \
    fail "CA_ENABLE_ACME must be either true or false"
  [[ "${CA_PASSWORD_FILE}" == "${CA_DATA_DIR}"/* ]] || \
    fail "CA_PASSWORD_FILE must be located under CA_DATA_DIR so it is mounted into the container"
}

do_ca() {
  common_pkgs
  docker_pkgs
  install -d -m 0755 "${WORKDIR}/step-ca" "${CA_DATA_DIR}" "$(dirname "${CA_PASSWORD_FILE}")"

  if [[ ! -f "${CA_PASSWORD_FILE}" ]]; then
    echo "CA password file not found. Generating one..."
    require_command openssl
    openssl rand -base64 32 > "${CA_PASSWORD_FILE}"
    chmod 600 "${CA_PASSWORD_FILE}"
    echo "Generated CA password at: ${CA_PASSWORD_FILE}"
  fi

  require_ca_vars

  CA_PASSWORD_FILE_IN_CONTAINER="/home/step/${CA_PASSWORD_FILE#${CA_DATA_DIR}/}"
  if [[ "${CA_ENABLE_ACME}" == "true" ]]; then
    CA_ACME_ENV_BLOCK='      DOCKER_STEPCA_INIT_ACME: "true"'
  else
    CA_ACME_ENV_BLOCK=""
  fi
  export CA_PASSWORD_FILE_IN_CONTAINER CA_ACME_ENV_BLOCK

  render_template "${TEMPLATE_DIR}/docker-compose.step-ca.yml.tpl" "${WORKDIR}/step-ca/docker-compose.yml"

  (
    cd "${WORKDIR}/step-ca"
    docker compose down || true
    docker compose up -d
  )
  ufw allow "${CA_PORT}/tcp" || true
}
