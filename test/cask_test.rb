# typed: strict
# frozen_string_literal: true

cask_path = File.expand_path("../Casks/portroost.rb", __dir__)
cask = File.read(cask_path)

checks = {
  "semantic version"          => cask.match?(/^\s*version "\d+\.\d+\.\d+"$/),
  "SHA-256 checksum"          => cask.match?(/^\s*sha256 "[0-9a-f]{64}"$/),
  "immutable GitHub release"  => cask.include?("/releases/download/v\#{version}/"),
  "single-repository release" => cask.include?(
    "techlocal-accounts/homebrew-portroost/releases",
  ),
  "released archive checksum" => cask.include?(
    'sha256 "102aaffb4a79d8d10f0e39cd508527be8a4042fcd9065928e5da4fbc8fc9c7ae"',
  ),
  "current install guidance"  => cask.include?("Open Anyway"),
  "legacy command alias"      => cask.include?('target: "codex-server-monitor"'),
  "application artifact"      => cask.include?('app "PortRoost.app"'),
}

failures = checks.reject { |_name, passed| passed }.keys
abort "Cask checks failed: #{failures.join(", ")}" unless failures.empty?

puts "PortRoost cask checks passed"
