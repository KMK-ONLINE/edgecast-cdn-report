require 'minitest/autorun'
require_relative '../cdn_report'

describe 'CdnReport'  do

  describe '.initialize' do

    it 'takes a path to the config file and sets the token and customer_id' do
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'fake_config.yml')
      cdn_report.customer_id.must_equal 'fake_customer_id'
      cdn_report.token.must_equal 'fake_token'
    end

  end

end
