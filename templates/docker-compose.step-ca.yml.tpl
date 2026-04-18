services:
  step-ca:
    image: smallstep/step-ca:latest
    restart: unless-stopped
    ports:
      - "${CA_PORT}:9000"
    volumes:
      - ${CA_DATA_DIR}:/home/step
