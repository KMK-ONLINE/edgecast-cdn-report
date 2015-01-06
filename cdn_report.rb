require 'httparty'
require 'date'
require 'json'
require 'byebug'

$envs         = ['production', 'staging']
$products     = ['liputan6', 'vidio']
$cname_types  = ['assets', 'tv_streaming', 'eventstreaming','video', 'kickoff']

$tb_inbytes   = 1000000000000
$gb_inbytes   = 1000000000
$mb_inbytes   = 1000000
$underline    = "------------------"

def get_total_use_data_by_month(begin_date_month)
  t_use_data_month = HTTParty.get("#{$base_url}media/3/region/-1/units/2/trafficusage?begindate=#{begin_date_month}",
                           :headers => {"Authorization" => "TOK:#{$header_token}"})

  json_parsed_curr  = JSON.parse("{\"data\":#{t_use_data_month.body.to_s}}")
  return json_parsed_curr['data']['UsageResult']
end


def get_data(datestart,dateend)
  domain_data = HTTParty.get("#{$base_url}media/3/cnamereportcodes?begindate=#{datestart}&enddate=#{dateend}",
                          :headers => {"Authorization" => "TOK:#{$header_token}"})
  domain_data_sort = JSON[domain_data.body.to_s].sort_by { |arry| arry['Bytes'].to_i }

  data = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
  $envs.each do |env|
    $products.each do |product|
      domain_data_sort.each do |contain|
        # assets
        if (contain['Description'].include? env) && (contain['Description'].include? product) && !(contain['Description'].include? 'streaming') && !(contain['Description'].include? 'hls')
           data[env][product]['assets'][contain['Description']]['bytes'] = contain['Bytes']
        end

        # tv_streaming
        if (contain['Description'].include? env) && (contain['Description'].include? product) && (contain['Description'].include? 'livestreaming') && !(contain['Description'].include? 'hls')
           data[env][product]['tv_streaming'][contain['Description']]['bytes'] = contain['Bytes']
        end

        # event_streaming
        if (contain['Description'].include? env) && (contain['Description'].include? product) && (contain['Description'].include? 'eventstreaming')
           data[env][product]['eventstreaming'][contain['Description']]['bytes'] = contain['Bytes']
        end

        # video
        if (contain['Description'].include? env) && (contain['Description'].include? product) && (contain['Description'].include? 'hls') && !(contain['Description'].include? 'kickoff')
           data[env][product]['video'][contain['Description']]['bytes'] = contain['Bytes']
        end

        # kickoff
        if (contain['Description'].include? env) && (contain['Description'].include? product) && (contain['Description'].include? 'kickoff')
           data[env][product]['kickoff'][contain['Description']]['bytes'] = contain['Bytes']
        end

      end
    end
  end

  domain_data_sort.each do |contain|
    if !(contain['Description'].include? $envs[0]) && !(contain['Description'].include? $envs[1])
      data['others'][contain['Description']]['bytes'] = contain['Bytes']
    end
  end

  return data
end

def bytes_convertion(bytes)
    if(bytes/$tb_inbytes > 1)
      return ((bytes.to_f/$tb_inbytes).round(2)).to_s + ' TB'
    end
    if(bytes/$gb_inbytes > 1)
      return ((bytes.to_f/$gb_inbytes).round(2)).to_s + ' GB'
    end
    return ((bytes.to_f/$mb_inbytes).round(2)).to_s + ' MB'
end

def bygroup(domain_data)
  $envs.each do |env|
    envbytes = 0
    puts $underline
    puts "##### #{env.upcase} #####"
    puts $underline

    $products.each do |product|
      productbytes = 0
      $cname_types.each do |cname_type|
        total_cname_types = 0
        buffer_cname = ""
        domain_data[env][product][cname_type].each do |domain, usages|
          total_cname_types += usages['bytes']
          productbytes += usages['bytes']
          buffer_cname += "CNAME : #{domain} : #{bytes_convertion(usages['bytes'])}\n"
        end
        puts "[ #{product.upcase} #{cname_type.upcase} : #{bytes_convertion(total_cname_types)} ]"
        puts buffer_cname += "\n"
        buffer_cname = ""
      end

      puts $underline
      puts "### TOTAL #{product.upcase} : #{bytes_convertion(productbytes)} ###\n"
      puts $underline

      envbytes = envbytes + productbytes
    end

    puts $underline
    puts "### TOTAL #{env.upcase} : #{bytes_convertion(envbytes)} ###\n"
    puts $underline
  end

  puts $underline
  puts "##### ADS #####"
  puts $underline
  ads_bytes = 0
  domain_data['others'].each do |domain, usages|
    ads_bytes += usages['bytes']
    puts "CNAME : #{domain} : #{bytes_convertion(usages['bytes'])} \n"
  end
  puts "### TOTAL ADS : #{bytes_convertion(ads_bytes)}"
end

def total_usage(domain_data)
  totalbytes = 0
  $envs.each do |env|
    $products.each do |product|
      $cname_types.each do |cname_type|
        domain_data[env][product][cname_type].each do |domain,usages|
          totalbytes = totalbytes + usages['bytes']
        end
      end
    end
  end

  domain_data['others'].each do |domain, usages|
    totalbytes = totalbytes + usages['bytes']
  end
  return totalbytes/$gb_inbytes
end

time    = Time.new().to_datetime << 1
timenow = Time.new()
lastmonth_begin_date = Time.utc(time.year, time.month,1)
begin_date_lastmonth = lastmonth_begin_date.strftime("%Y-%m-%d")
begin_date_thismonth = Time.utc(timenow.year, timenow.month,1).strftime("%Y-%m-%d")
current_date = '2015-01-06'#Time.now.utc.strftime("%Y-%m-%d")

if(ARGV[0] != nil)
  begin_date_thismonth = ARGV[0]
end
if(ARGV[1] != nil)
  current_date = ARGV[1]
end

puts "CDN EdgeCast Usage Report #{begin_date_thismonth} - #{current_date}"

#get current month usage data
current_month_usage = get_total_use_data_by_month(begin_date_thismonth)
current_month_data  = get_data(begin_date_thismonth,current_date)

puts $underline
puts "\nCurrent Month Usage : #{(current_month_usage/1000).round(2)} TB"
puts "UnAccounted Month Usage : #{((current_month_usage - total_usage(current_month_data))/1000).round(2)} TB"

bygroup(current_month_data)

if(ARGV.size == 0)
  #get last month usage data
  last_month_usage = get_total_use_data_by_month(begin_date_lastmonth)
  last_month_data  = get_data(begin_date_lastmonth,begin_date_thismonth)

  puts $underline
  puts "\n\nLast Month Usage : #{last_month_usage/1000} TB"
  puts "Unaccounted Last Month Usage : #{((last_month_usage - total_usage(last_month_data))/1000).round(2)} TB"
  puts $underline
  puts "LAST MONTH TOTAL SUMMARY"
  puts $underline
  bygroup(last_month_data)
end

#get current usage data by filename
file_data = HTTParty.get("#{$base_url}media/3/filestats?begindate=#{begin_date_thismonth}&enddate=#{current_date}",
                         :headers => {"Authorization" => "TOK:#{$header_token}"})

file_data_sort = JSON[file_data.body.to_s].sort_by { |arry| arry['DataTransferred'].to_i }
if(file_data_sort.size > 0)
  puts $underline
  file_data_sort.each do |kontain|
    puts "Filename : #{kontain['Path']} : #{kontain['DataTransferred']/$gb_inbytes}G"
  end
  ## Just Print Some variable
  puts $underline
end
