server:
    interface: 0.0.0.0
    access-control: ${ALLOW_NET_1} allow
    access-control: ${ALLOW_NET_2} allow
    access-control: ${ALLOW_NET_3} allow

local-zone: "${SEARCH_DOMAIN}." static

${PROVIDER_BOX_DNS_BLOCK}

${DNS_RECORD_BLOCK}

forward-zone:
    name: "."
    forward-addr: ${UNBOUND_FORWARDER}
