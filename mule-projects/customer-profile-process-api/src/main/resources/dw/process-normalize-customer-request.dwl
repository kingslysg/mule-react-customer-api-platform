%dw 2.0
output application/json
var countryCode = upper((payload.countryCode default "US") as String)
var countries = {
  "US": "United States",
  "IN": "India",
  "CA": "Canada",
  "GB": "United Kingdom"
}
var countryName = countries[(countryCode)] default "Unknown country"
---
{
  name: trim((payload.name default "Guest") as String),
  countryCode: countryCode,
  countryName: countryName
}
