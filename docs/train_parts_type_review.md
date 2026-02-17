# Train Parts Type Review (Draft)

Adds train-type split on top of part clusters.
No rename applied yet.

- CSV: `docs/train_parts_type_proposal.csv`
- Labels: `blue_commuter`, `green_commuter`, `orange_livery`, `silver_hsr`, `unknown`

## station_train_car_parts
- type distribution:
  - orange_livery: 6
  - silver_hsr: 6
  - blue_commuter: 4
- confidence distribution:
  - high: 16

## train_exterior_parts
- type distribution:
  - blue_commuter: 166
  - silver_hsr: 30
  - green_commuter: 24
  - unknown: 9
  - orange_livery: 8
- confidence distribution:
  - high: 208
  - medium: 20
  - low: 9

## train_interior_parts
- type distribution:
  - orange_livery: 148
  - blue_commuter: 99
  - silver_hsr: 44
  - unknown: 35
  - green_commuter: 12
- confidence distribution:
  - high: 251
  - medium: 52
  - low: 35

