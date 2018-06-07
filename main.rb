require 'nokogiri'
require 'open-uri'
require 'pry'
require 'mechanize'
require 'json'
require 'time'


class Scrap
  def initialize
    @link = "http://www.seloger.com/list.htm?idtt=2"
    @search_params = Hash.new
    @search_params["idtypebien"]="1,2" #,3,6,7,8,9,10,11,12,13,14"
    @search_params["naturebien"]="1"
    puts "Surface min?"
    @search_params["surfacemin"] = "40"
    puts "Code postal de la zone ?"
    @cp = "75005" #gets.chomp
    @search_params["cp"] = @cp
    puts "Trier par ?"
    puts "initial/a_surface"
    @search_params["tri"] = "initial" #gets.chomp
  end

  def create_param_url(search_params)
    search_params = @search_params
    url_string = ""
      search_params.each do |key,value|
          url_string = url_string + "&" + key + "=" + value
      end
    @link =  @link + url_string
    p @link
  end

  def parsing_page(link)
  link = @link
  results = Hash.new
  another_page = true
  n_page = 0
  i = 0
  a = Mechanize.new { |agent|
    agent.history_added = Proc.new { sleep 0.5 }
    agent.user_agent_alias = 'Windows Chrome'
  }
    while another_page == true
     a.get(link) do |page|

        page.xpath('//div[@class="c-pa-info"]').each do |node|

          results[i]= Hash.new
           if n_page > 0
          j = i-n_page*19-n_page + 1
          else j = i
          end

          begin
            results[i]["url"] = node.xpath('//div[@class="c-pa-info"]/a[@class="c-pa-link link_AB"]')[j]["href"]
            results[i]["price"] = Integer(node.xpath('//div[@class="c-pa-info"]/div[@class="c-pa-price"]/span[2]')[j].text.gsub(/[\D]/, ""))
            results[i]["surface"] = node.xpath('//div[@class="c-pa-info"]/div[@class="c-pa-criterion"]/em[3]')[j].text.gsub(/[\,]/, ".").gsub(/[^\.\d]/, "").to_f
            results[i]["€/m2"] =  results[i]["price"]/ results[i]["surface"]
            results[i]["adress"] = node.xpath('//div[@class="c-pa-info"]/div[@class="c-pa-city"]')[j].text
             rescue NoMethodError => e
              binding.pry
               p e
               p i
             end
              i = i +1
          end
          another_page = page.search('a.pagination-next').any?
            if another_page == true
            link = page.link_with(:class => "pagination-next").uri
            p "switching page"
            n_page +=1
            else another_page == false
            end
        end
      end
    return results

  end

def write_json (path, output)

  File.open(path,"w") do |f|
    f.write(JSON.pretty_generate(output))
  end
end

  def wrapper
    name_file = "#{Time.now.to_s.gsub(/[\D]/, "")}" + @cp + ".json"
    write_json(name_file, parsing_page(create_param_url(@search_params)))
  end
end

execute = Scrap.new
execute.wrapper
