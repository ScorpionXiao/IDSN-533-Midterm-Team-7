#!/bin/bash
set -euo pipefail
task_repo_root="$(cd "$(dirname "$0")/.." && pwd)"
task_checks_dir="$(mktemp -d /private/tmp/vibemate-checks.XXXXXX)"
cd "$task_repo_root"
xcrun swiftc -module-cache-path "$task_checks_dir/cache" \
  "Data Sets/Data Sets/Models/Attribute.swift" \
  "Data Sets/Data Sets/Models/DataModels.swift" \
  "Data Sets/Data Sets/Models/DataStore.swift" \
  "Data Sets/Data Sets/Models/TypeCalculator.swift" \
  "Data Sets/Data Sets/Models/DemoModels.swift" \
  "Data Sets/Data Sets/Models/DatingAppState.swift" \
  "Data Sets/Data Sets/Models/RecommendationEngine.swift" \
  Tests/DatingStateChecks.swift -o "$task_checks_dir/checks"
"$task_checks_dir/checks"
