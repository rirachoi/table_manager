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

#### CSV convert data to HTML <a>tag with attributes(title, alt and so on)
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
    
    #filtering banner and top picks 
    @content.each_with_index do |c, i|
      if c[:product_details].nil? && i < 3 # banner will be within the third colum.
        @news_data[:banner] << c
      else
        @news_data[:top_picks] << c
      end 
      # p @news_data[:top_picks]
    end
  end

  def grab_links(data)
    @data = data
    bannerHTML = '' 
    banners = @data[:banner] 
    top_picks = @data[:top_picks] # from the second element to the last 

    # banners HTML
    @html_banners = []
    banners.each do |b|
      if b[:cta_link] != nil 
        banner_html = "<a href='#{ b[:cta_link]}' title='#{b[:cta]}' alt='#{b[:cta]}' target='_blank'>"     
        @html_banners << banner_html
      else
        p "There is no banner links for BANNERS"
      end 
    end 

    # top picks HTML
    @html_top_picks = []
    top_picks.each do |t|
      # Product for top picks 
      if t[:product_links] != nil
        product_html = "<a href='#{ t[:product_links]}' title='#{t[:product_details]}' alt='#{t[:product_details]}' target='_blank'>"
        @html_top_picks << product_html
      else
        p "There is no product links for TOP PICKS"      
      end 
      # CTA for top picks
      if t[:cta_link] != nil 
        pro_cta_html = "<a href='#{ t[:cta_link]}' title='#{t[:cta]}' alt='#{t[:cta]}' target='_blank'>"
        
        @html_top_picks << pro_cta_html      
      else
        p "There is no cta links for TOP PICKS"
      end 
    end 

    ## TRY TO PRINT THEM HERE,
    # @html_banners
    # @html_top_picks
    # puts 'This is banners,' 
    # puts @html_banners
    # puts 'This is top_picks,'
    # puts @html_top_picks
  end

#### HTML
  def html_with_style(htmlfile)
    td_style = ["<td", "<td style='font-size: 8px;'"]
    img_style = ["<img", "<img style='display: block; border: 0px; font-size: 8px;'"]
    # replacements = [] << td_style << img_style  

    infile = htmlfile
    outfile = "test_output.html"

    text = File.read(htmlfile)
    new_contents = text.gsub("<td", "<td style='font-size: 8px;'")
    new_contents = new_contents.gsub("<img", "<img style='display: block; border: 0px; font-size: 8px;'")
    File.open(outfile, "w") {|out| out << new_contents }

  end

  def insert_links(file_name)


  end 

end


#TESTING
t1 = TableManager.new
t1.open_csv('email_test.csv')
t1.grab_links(t1.news_data)
t1.html_with_style('test_input.html')