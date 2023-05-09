# Azure DNS Private Resolver

[![DEV - Deploy Azure Resource](https://github.com/ArtiomLK/azure-bicep-dnspr/actions/workflows/dev.orchestrator.yml/badge.svg?branch=main&event=push)](https://github.com/ArtiomLK/azure-bicep-dnspr/actions/workflows/dev.orchestrator.yml)

## Notes

- No other resources can exist in the same subnet with the inbound endpoint.
- No other resources can exist in the same subnet with the outbound endpoint.
- The IP address assigned to an inbound endpoint is not a static IP address that you can choose.
