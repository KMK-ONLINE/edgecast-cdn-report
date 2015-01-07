require 'httparty'
require 'date'
require 'json'
require 'byebug'
require 'yaml'
require 'active_support/core_ext/date/calculations.rb'
require 'active_support/core_ext/time/calculations.rb'
require 'terminal-table'

class CdnReport

  BASE_URI = "https://api.edgecast.com/v2/reporting/customers"

  TB_INBYTES   = 10**12
  GB_INBYTES   = 10**9
  MB_INBYTES   = 10**6

  attr_accessor :customer_id, :token, :report_date

  def initialize(config_file, report_date=Date.today)
    config = YAML.load_file(config_file)

    self.customer_id = config['customer_id']
    self.token = config['token']
    self.report_date = report_date
  end

  def base_uri
    BASE_URI+'/'+customer_id
  end

  def get uri
    response = HTTParty.get(base_uri + uri, :headers => {"Authorization" => "TOK:#{token}"})
    JSON.parse(response.body)
  end

  def total_data_transfer(month)
    result = self.get "/media/3/region/-1/units/2/trafficusage?begindate=#{month}-01"
    result['UsageResult'].to_f * GB_INBYTES
  end

  def data_transfer_by_cname(start_date, end_date)
    result = self.get "/media/3/cnamereportcodes?begindate=#{start_date}&enddate=#{end_date}"
    data_transfers = {}

    result.each do |cname_data|
      data_transfers[cname_data['Description']] = cname_data['Bytes'].to_f
    end

    data_transfers
  end

  #month_to_date_data
  def mtd_data_by_cname
    @mtd_data_by_cname ||= data_transfer_by_cname(report_date.beginning_of_month, report_date)
  end

  #last_month_data
  def lm_data_by_cname
    @lm_data_by_cname ||= data_transfer_by_cname(report_date.last_month.beginning_of_month, report_date.last_month.end_of_month)
  end

  #last_month_to_date_data
  def lmtd_data_by_cname
    @lmtd_data_by_cname ||= data_transfer_by_cname(report_date.last_month.beginning_of_month, report_date.last_month)
  end

  #total_current_month_data
  def tcm_data
    @tcm_data ||= total_data_transfer(report_date.strftime("%Y-%m"));
  end

  #total_last_month_data
  def tlm_data
    @tlm_data ||= total_data_transfer(report_date.last_month.strftime("%Y-%m"))
  end

  def total_row
    ['Total', f(tcm_data), '',  f(tlm_data)]
  end

  def cname_rows
    cnames = [mtd_data_by_cname, lmtd_data_by_cname, lm_data_by_cname].flat_map(&:keys).uniq
    cnames.map do |cname|
      [cname, f(mtd_data_by_cname[cname]), f(lmtd_data_by_cname[cname]), f(lm_data_by_cname[cname])]
    end
  end

  def unaccounted_row
    total_todate_cname     = mtd_data_by_cname.values.reduce(:+)
    total_last_month_cname = lm_data_by_cname.values.reduce(:+)

    ['Unaccounted', f(tcm_data-total_todate_cname), '', f(tlm_data-total_last_month_cname)]
  end

  #format
  def f(bytes)
    if bytes.nil?
      "Na"
    elsif(bytes/TB_INBYTES > 1)
      (bytes.to_f/TB_INBYTES).round(2).to_s + ' TB'
    elsif(bytes/GB_INBYTES > 1)
      (bytes.to_f/GB_INBYTES).round(2).to_s + ' GB'
    else
      (bytes.to_f/MB_INBYTES).round(2).to_s + ' MB'
    end
  end

  def output
    header = ['CNAME', 'Cur MTD', 'Last MTD', 'Last Total']
    table = Terminal::Table.new headings: header, rows: (cname_rows  << unaccounted_row) << total_row
    puts "Report CDN : #{report_date} \n"
    puts table
  end

end
