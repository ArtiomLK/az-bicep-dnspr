# Azure DNS Private Resolver

[![DEV - Deploy Azure Resource](https://github.com/ArtiomLK/azure-bicep-dnspr/actions/workflows/dev.orchestrator.yml/badge.svg?branch=main&event=push)](https://github.com/ArtiomLK/azure-bicep-dnspr/actions/workflows/dev.orchestrator.yml)

## Notes

- No other resources can exist in the same subnet with the inbound endpoint.
- No other resources can exist in the same subnet with the outbound endpoint.
- [The inbound endpoint is a highly available, load-balanced service that provides a only a single IP address that automatically scales based on the number of queries it receives, and it has a built-in health probe to monitor its availability.][3]

## Additional Resources

- DNSPR
- [MS | Learn | Single region scenario - Private Link and DNS in Azure Virtual WAN][7]
- [MS | Learn | Guide to Private Link and DNS in Azure Virtual WAN][8]
- [MS | Learn | What is Azure DNS Private Resolver? | What is Azure DNS Private Resolver?][1]
- [MS | Learn | What are the usage limits for Azure DNS Private Resolver?][2]
- [MS | Learn | Private resolver architecture][4]
- [MS | Learn | Using Azure DNS Private Resolver to simplify hybrid recursive Domain Name System (DNS) resolution][5]
- [MS | Learn | Tutorial: Set up DNS failover using private resolvers][6]

[1]: https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview#subnet-restrictions
[2]: https://learn.microsoft.com/en-us/azure/dns/dns-faq#what-are-the-usage-limits-for-azure-dns-
[3]: https://learn.microsoft.com/en-us/azure/dns/private-resolver-endpoints-rulesets
[4]: https://learn.microsoft.com/en-us/azure/dns/private-resolver-architecture
[5]: https://learn.microsoft.com/en-us/azure/architecture/example-scenario/networking/azure-dns-private-resolver
[6]: https://learn.microsoft.com/en-us/azure/dns/tutorial-dns-private-resolver-failover
[7]: https://learn.microsoft.com/en-us/azure/architecture/guide/networking/private-link-virtual-wan-dns-single-region-workload
[8]: https://learn.microsoft.com/en-us/azure/architecture/guide/networking/private-link-virtual-wan-dns-guide