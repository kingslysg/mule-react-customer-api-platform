%dw 2.0
output application/json
---
{
  name: payload.name,
  countryCode: payload.countryCode,
  countryName: payload.countryName,
  message: payload.message,
  customer: payload.customer,
  source: payload.source,
  systemApi: payload.systemApi,
  processApi: "Process API"
}
