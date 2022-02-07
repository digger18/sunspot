type column = {
  label: string,
  minWidth: int,
}

let columns = [
  {
    label: "collection",
    minWidth: 200,
  },
  {
    label: "event",
    minWidth: 120,
  },
  {
    label: "price",
    minWidth: 120,
  },
  {
    label: "properties",
    minWidth: 120,
  },
  {
    label: "destination",
    minWidth: 120,
  },
]

type priceRule = {modifier: string, price: string}
type propertyRule = {traitType: string, displayValue: string}
type rule =
  | PriceRule(priceRule)
  | PropertyRule(propertyRule)

@deriving(accessors)
type destination = {
  primary: string,
  secondary: option<string>,
  iconUrl: option<string>,
}

@deriving(accessors)
type row = {
  id: string,
  collectionName: option<string>,
  collectionSlug: string,
  collectionImageUrl: option<string>,
  externalUrl: string,
  eventType: string,
  rules: array<rule>,
  disabledInfo: option<string>,
  destination: option<destination>,
}
