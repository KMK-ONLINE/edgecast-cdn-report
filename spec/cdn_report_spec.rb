require 'minitest/autorun'
require 'webmock/minitest'
WebMock.disable_net_connect!(allow_localhost: true)

require_relative '../cdn_report'

describe CdnReport  do

  before do
    report_date = Date.strptime('2014-12-15')
    month_to_date_response = [{
      Bytes: 1*(10**12),
      Description: "cname1.fakedomain.com",
      Hits: 21873348,
      ReportCode: 10042
    },{
      Bytes: 2*(10**12),
      Description: "cname2.fakedomain.com",
      Hits: 34243537,
      ReportCode: 10044
    }]
    stub_request(:get, "https://api.edgecast.com/v2/reporting/customers/fake_customer_id/media/3/cnamereportcodes?begindate=#{report_date.beginning_of_month.strftime('%Y-%m-%d')}&enddate=#{report_date.strftime('%Y-%m-%d')}").
      with(:headers => {'Authorization'=>'TOK:fake_token'}).
      to_return(:status => 200, :body => month_to_date_response.to_json, :headers => {})

    last_month_to_date_response = [{
      Bytes: 2.5*(10**12),
      Description: "cname1.fakedomain.com",
      Hits: 21873348,
      ReportCode: 10042
    },{
      Bytes: 1.5*(10**12),
      Description: "cname2.fakedomain.com",
      Hits: 34243537,
      ReportCode: 10044
    }]
    stub_request(:get, "https://api.edgecast.com/v2/reporting/customers/fake_customer_id/media/3/cnamereportcodes?begindate=#{report_date.last_month.beginning_of_month.strftime('%Y-%m-%d')}&enddate=#{report_date.last_month.strftime('%Y-%m-%d')}").
      with(:headers => {'Authorization'=>'TOK:fake_token'}).
      to_return(:status => 200, :body => last_month_to_date_response.to_json, :headers => {})

    last_month_total_response = [{
      Bytes: 3*(10**12),
      Description: "cname1.fakedomain.com",
      Hits: 21873348,
      ReportCode: 10042
    },{
      Bytes: 2*(10**12),
      Description: "cname2.fakedomain.com",
      Hits: 34243537,
      ReportCode: 10044
    }]
    stub_request(:get, "https://api.edgecast.com/v2/reporting/customers/fake_customer_id/media/3/cnamereportcodes?begindate=#{report_date.last_month.beginning_of_month.strftime('%Y-%m-%d')}&enddate=#{report_date.last_month.end_of_month.strftime('%Y-%m-%d')}").
      with(:headers => {'Authorization'=>'TOK:fake_token'}).
      to_return(:status => 200, :body => last_month_total_response.to_json, :headers => {})

    stub_request(:get, "https://api.edgecast.com/v2/reporting/customers/fake_customer_id/media/3/region/-1/units/2/trafficusage?begindate=#{report_date.beginning_of_month.strftime('%Y-%m-%d')}").
      with(:headers => {'Authorization'=>'TOK:fake_token'}).
      to_return(:status => 200, :body => '{"UsageResult" : 4000}', :headers => {})

    stub_request(:get, "https://api.edgecast.com/v2/reporting/customers/fake_customer_id/media/3/region/-1/units/2/trafficusage?begindate=#{report_date.last_month.beginning_of_month.strftime('%Y-%m-%d')}").
      with(:headers => {'Authorization'=>'TOK:fake_token'}).
      to_return(:status => 200, :body => '{"UsageResult" : 5500}', :headers => {})
  end

  describe '.initialize' do
    it 'takes a path to the config file and sets the token and customer_id' do
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml')
      cdn_report.customer_id.must_equal 'fake_customer_id'
      cdn_report.token.must_equal 'fake_token'
    end

    it 'takes an optional report_date' do
      expected_report_date = Date.strptime('2014-12-12')
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml', expected_report_date)
      cdn_report.customer_id.must_equal 'fake_customer_id'
      cdn_report.token.must_equal 'fake_token'
      cdn_report.report_date.must_equal expected_report_date
    end
  end

  describe '#data_transfer_total' do
    it 'returns the total GB data transfer for a specific month' do
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml')
      cdn_report.total_data_transfer('2014-12').must_equal 4*(10**12)
    end
  end

  describe '#data_transfer_by_cname' do
    it 'returns the GB data transfer by cname for a period' do
      report_date = Date.strptime('2014-12-15')
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml')
      cdn_report.data_transfer_by_cname(report_date.beginning_of_month, report_date).must_equal({'cname1.fakedomain.com' => 1*(10**12), 'cname2.fakedomain.com' => 2*(10**12)})
    end
  end

  describe '#total_row' do
    it 'returns an array of total data transfered for current, last month to date, last month total' do
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml', Date.strptime('2014-12-01'))
      cdn_report.total_row.must_equal ['Total', '4.0 TB', '', '5.5 TB']
    end
  end

  describe '#cname_rows' do
    it 'returns all cnames with current month to date , last month to date, and last month total' do
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml', Date.strptime('2014-12-15'))
      cdn_report.cname_rows.must_equal [
        ['cname1.fakedomain.com', '1000.0 GB', '2.5 TB', '3.0 TB'],
        ['cname2.fakedomain.com', '2.0 TB', '1.5 TB', '2.0 TB']
      ]
    end
  end

  describe '#unaccounted_row' do
    it 'calculates the difference between the total data transferred and sum of the cname data transfered' do
      cdn_report = CdnReport.new(File.dirname(__FILE__)+'/fake_config.yml', Date.strptime('2014-12-15'))
      cdn_report.unaccounted_row.must_equal ['Unaccounted' , '1000.0 GB', '', '500.0 GB']
    end
  end

end
