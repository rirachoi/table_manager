require 'csv'

class TableManager

  attr_accessor :news_data

  def initialize(news_data=nil)
    @news_data = {}
    @news_data[:banner] = {}
    @news_data[:top_picks] = {}
    @news_data[:shopping_cta] = {}
  end

#### CSV : convert data to HTML <a>tag with attributes
  
  # Open CSV File and Save @content without empty cells
  def open_csv(file_name)
    @content = []
    CSV.foreach(file_name,
                :headers => true,
                :converters => :all,
                :header_converters => :symbol
                ) do |row|
      # Make CSV data as hash
      hash_row = row.to_hash
      # Get rid of blank cells - Putting all data into @content
      if hash_row[:product_details] != nil || hash_row[:cta_link] != nil
        @content << hash_row
      end
    end
  end 
  
  #Filtering the main banner, top picks and shopping cta
  def filtering_links      
    @content.each_with_index do |c, i|
      # Validate URL
      if !c[:cta].nil? && (c[:cta_link]).split(/\./).first != "http://www" 
        invalid_url = (c[:cta_link]).split(/\./)[1..-1] # If there is no http:// - start with only 'www.'
        c[:cta_link] = invalid_url.unshift("http://www").join('.')
      else
        c[:cta_link]
      end 

      #HASH FORMAT( title[link] )
      if !c[:cta].nil? && i < 4 # The main banner will be within indext of 3.
        @news_data[:banner][c[:cta]] = c[:cta_link]
      elsif !c[:product_details].nil? # The top picks that have product details.
        @news_data[:top_picks][c[:product_details]] = c[:product_links]
      else
        @news_data[:shopping_cta][c[:cta]] = c[:cta_link] # Shopping cta buttons.
      end 
    end
    @news_data
    # p @news_data[:banner] 
    # p @news_data[:top_picks] 
    # p @news_data[:shopping_cta]      
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
        "There is no product links for TOP PICKS"      
      end 
      # CTA for top picks
      if t[:cta_link] != nil 
        pro_cta_html = "<a href='#{ t[:cta_link]}' title='#{t[:cta]}' alt='#{t[:cta]}' target='_blank'>"
        
        @html_top_picks << pro_cta_html      
      else
        "There is no cta links for TOP PICKS"
      end  
    end 

    ## TRY TO PRINT THEM HERE,
    @html_banners
    @html_top_picks
    puts 'This is banners,' 
    puts @html_banners
    puts 'This is top_picks,'
    puts @html_top_picks
  end

#### HTML
  def html_with_style(htmlfile)
    infile = htmlfile
    outfile = "test_output.html"

    text = File.read(htmlfile)

    # MAIN TABLE STYLE
    new_contents = text.gsub(/([.\n\r\s\S]*?)(<table)([.\s\S]*?)(id="Table_01")([.\n\r\s\S]*?)(<\/table>)([.\n\r\s\S]*?<\/html>)/, "<table style='min-width:620px;' align='center'\\5\\6\\3")
    # TD Style
    new_contents = new_contents.gsub(/(<td)([.\s\S]*?)>([.\s\S]*?<img[.\s\S]*?width[:=]"?)(\d+)([.\s\S]*?height[:=]"?)(\d+)/, '\\1 width="\\4" height="\\6"\\2 style="font-size: 8px; min-width:\\4px;">\\3\\4\\5\\6')
    # IMG Style
    new_contents = new_contents.gsub(/<img/, "<img style='display: block; border: 0px; font-size: 8px;'")
    # TR SPACER GIF Style 
    new_contents = new_contents.gsub('\' src="images/spacer.gif"', ' -webkit-text-size-adjust: none !important; -moz-text-size-adjust:none !important;\' src="images/spacer.gif"')
    # TEST OUTPUT html
    File.open(outfile, "w") {|out| out << new_contents }
  end

  def insert_links(file_name)

  end 

end


#TESTING


t1 = TableManager.new
t1.open_csv('email_test.csv')
t1.filtering_links
# t1.grab_links(t1.news_data)
# Grab input html file
the_input_file = Dir['*'].select {|x| x =~ /_.*(html)/ }.sort.first
t1.html_with_style(the_input_file)
