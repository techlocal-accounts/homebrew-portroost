# typed: strict
# frozen_string_literal: true

cask_path = File.expand_path("../Casks/codex-server-monitor.rb", __dir__)
cask = File.read(cask_path)

checks = {
  "semantic version"          => cask.match?(/^\s*version "\d+\.\d+\.\d+"$/),
  "SHA-256 checksum"          => cask.match?(/^\s*sha256 "[0-9a-f]{64}"$/),
  "immutable GitHub release"  => cask.include?("/releases/download/v\#{version}/"),
  "single-repository release" => cask.include?(
    "techlocal-accounts/homebrew-codex-server-monitor/releases",
  ),
  "application artifact"      => cask.include?('app "Codex Server Monitor.app"'),
}

failures = checks.reject { |_name, passed| passed }.keys
abort "Cask checks failed: #{failures.join(", ")}" unless failures.empty?

puts "Codex Server Monitor cask checks passed"
