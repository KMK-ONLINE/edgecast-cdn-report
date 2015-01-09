# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "edgecast_cdn_report"
  spec.version       = "0.0.1"
  spec.authors       = ["Kurniawan and Mohan Krishnan"]
  spec.email         = ["pair+kurniawan+mohan@kmkonline.co.id"]
  spec.summary       = "Simple script to generate edgecast report by cnames"
  spec.description   = "This script will help you generate a text report of your current month Edgecast CDN data transfer"
  spec.homepage      = "https://github.com/KMK-ONLINE/edgecast-cdn-report"
  spec.license       = "BSD"
  spec.files         = ["lib/edgecast_cdn_report.rb"]
  spec.executables << 'edgecast_cdn_report'

  spec.add_runtime_dependency 'httparty', '0.13.3'
  spec.add_runtime_dependency 'activesupport', '4.1.6'
  spec.add_runtime_dependency 'terminal-table', '1.4.5'
  spec.add_runtime_dependency "rake", "10.3.2"

  spec.add_development_dependency 'minitest', '5.5.0'
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency 'webmock', '1.19.0'
end
