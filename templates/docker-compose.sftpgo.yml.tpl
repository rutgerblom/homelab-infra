services:
  sftpgo:
    image: drakkan/sftpgo:v2.7.0
    restart: unless-stopped
    environment:
      SFTPGO_HTTPD__BINDINGS__0__PORT: "8080"
      SFTPGO_HTTPD__BINDINGS__0__ENABLE_HTTPS: "1"
      SFTPGO_HTTPD__BINDINGS__0__CERTIFICATE_FILE: /var/lib/sftpgo/certs/sftpgo.crt
      SFTPGO_HTTPD__BINDINGS__0__CERTIFICATE_KEY_FILE: /var/lib/sftpgo/certs/sftpgo.key
    ports:
      - "${SFTP_PORT}:2022"
      - "${SFTP_ADMIN_PORT}:8080"
    volumes:
      - ${SFTP_DATA_DIR}:/srv/sftpgo
      - ${SFTP_HOME_DIR}:/var/lib/sftpgo
      - ${SFTP_CERT_DIR}:/var/lib/sftpgo/certs:ro
