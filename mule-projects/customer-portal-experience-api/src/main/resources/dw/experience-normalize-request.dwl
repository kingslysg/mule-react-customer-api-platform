%dw 2.0
output application/json
---
{
  name: trim((payload.name default "Guest") as String),
  countryCode: upper((payload.countryCode default "US") as String)
}
