require 'csv'
require 'erb'
# require 'require_all'

class TableManager

  attr_accessor :news_data

  def initialize(news_data=nil)
    @news_data = {}
    @news_data[:banner] = []
    @news_data[:top_picks] = []
  end

#HTML
  def open_html(original_html)
    @original_html = original_html.to_s
    erb = ERB.new(File.read(@original_html))
    erb.filename = @original_html
  end

  def new_html(original_html)

  end

#CSV
  def open_csv(file_name)
    @content = []
    CSV.foreach(file_name,
                :headers => true,
                :converters => :all,
                :header_converters => :symbol
                ) do |row|
      # Make CSV data as hash
      hash_row = row.to_hash
      # Get rid of blank cells
      if hash_row[:product_details] != nil || hash_row[:cta_link] != nil
        @content << hash_row
      end
    end
    @news_data[:banner] << @content[1..16]
    @news_data[:top_picks] << @content[17..-1]
  end

  def grab_links(data)
    @data = data
    bannerHTML = '' 
    banners = @data[:banner]
    top_picks = @data[:top_picks] # from the second element to the last 

    array_banner

    # banners.each do |banner|
    #   banner.values.each {|i| array_banner << i if i != nil }
    # end   

    # #EVEN index and ZERO will be titles and ODD index will be urls
    # array_banner.each_with_index do |e, i|
    #   if i % 2 == 0 || i == 0
    #     p "This is title= #{ e }"
    #   else
    #     p "This is URl= #{ e }"
    #   end 
    # end 
  end

end


#TESTING
t1 = TableManager.new
t1.open_csv('email_test.csv')
t1.grab_links(t1.news_data)
# t1.grab_links(t1.news_data[:top_picks])
