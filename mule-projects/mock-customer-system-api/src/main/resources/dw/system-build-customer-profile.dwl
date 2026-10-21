%dw 2.0
output application/json
var name = trim((payload.name default "Guest") as String)
var countryCode = upper((payload.countryCode default "US") as String)
var countryName = payload.countryName default "Unknown country"
---
{
  name: name,
  countryCode: countryCode,
  countryName: countryName,
  message: "Hello, " ++ name ++ "! Here is your mock customer profile for " ++ countryName ++ ".",
  customer: {
    id: "CUST-1001",
    status: "ACTIVE",
    plan: "Learning Demo"
  },
  source: "System API mock data",
  systemApi: "System API"
}
