#!/bin/bash
find lib -type f -name "*.dart" -exec sed -i 's/buttonGreen/primaryBrandColor/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/Comet Wallet/Fusionfi/g' {} +
sed -i 's/Comet Wallet/Fusionfi/g' pubspec.yaml
sed -i 's/Comet Wallet/Fusionfi/g' README.md
