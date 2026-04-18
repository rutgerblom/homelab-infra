services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    restart: unless-stopped
    ports:
      - "8443:8443"
