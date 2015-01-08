require_relative 'cdn_report'
require 'byebug'

task :default, [:path_to_config] do |t, args|
  if args.path_to_config.nil?
    path_to_config = 'config.yml'
  else
    path_to_config = args.path_to_config
  end

  CdnReport.new(path_to_config).output
end
