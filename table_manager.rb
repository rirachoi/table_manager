require 'csv'

class TableManager

  attr_accessor :news_data

### Initialize - Creating empty Hashes
  def initialize(news_data=nil)
    @news_data = {}
    @news_data[:banner] = {}
    @news_data[:top_picks] = {}
    @news_data[:shopping_cta] = {}
  end

### CSV : convert data to HTML <a>tag with attributes  
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
  
  # Filtering the main banner, top picks and shopping cta
  def filtering_links      
    @content.each_with_index do |c, i|
      # Validate URL - Only for CTA, as the product links are picked up from the website
      if !c[:cta].nil? && (c[:cta_link]).split(/\./).first != "http://www" 
        invalid_url = (c[:cta_link]).split(/\./)[1..-1] # If there is no http:// - When start with only 'www.'
        c[:cta_link] = invalid_url.unshift("http://www").join('.')
      else
        c[:cta_link]
      end 

      # HASH FORMAT( title[link] )
      if !c[:cta].nil? && i < 4 # The main banner will be within index of 3.
        @news_data[:banner][c[:cta]] = c[:cta_link]
      elsif !c[:product_details].nil? # The top picks that have product details.
        @news_data[:top_picks][c[:product_details]] = c[:product_links]
      else
        @news_data[:shopping_cta][c[:cta]] = c[:cta_link] # Shopping CTA buttons.
      end 
    end

    @news_data

  end

  def grab_links(news_data)
    @news_data = news_data 
    banners = @news_data[:banner] 
    top_picks = @news_data[:top_picks]
    shopping_ctas = @news_data[:shopping_cta]

    # Banner's HTML
    banners.each do |banner|
      @title = banner.shift
      @href_links = banner.pop
      "<a href=\"#{ @href_links }\" target=\"_blank\" title=\"#{ @title }\">"
    end 

    # Top Picks's HTML
    top_picks.each do |top_pick|
      @title = top_pick.shift
      @href_links = top_pick.pop
      "<a href=\"#{ @href_links }\" target=\"_blank\" title=\"#{ @title }\">"
    end 

    # Shopping CTA's HTML
    shopping_ctas.each do |shopping_cta|
      @title = shopping_cta.shift
      @href_links = shopping_cta.pop
      "<a href=\"#{ @href_links }\" target=\"_blank\" title=\"#{ @title }\">"
    end 
    # p banners
    # p top_picks
    # p shopping_ctas

  end

### HTML - Insert code for Email. 
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

  def insert_links(output_file, news_data)

  # Define data  
    @output_file = output_file
    @news_data = news_data

    @news_data = news_data 
    banners = @news_data[:banner] 
    top_picks = @news_data[:top_picks]
    shopping_ctas = @news_data[:shopping_cta]
 
    # Empty array for <a>tag string.
    banner_to_s = []
    top_pick_to_s = []
    shopping_cta_to_s = []

    array_of_links = [] << banners << top_picks << shopping_ctas

    # Banner's HTML
    banners.each do |banner|
      @title = banner.shift
      @href_links = banner.pop
      banner_to_s << "<a href=\"#{ @href_links }\" target=\"_blank\" title=\"#{ @title }\">"
    end 

    # Top Picks's HTML
    top_picks.each do |top_pick|
      @title = top_pick.shift
      @href_links = top_pick.pop
      top_pick_to_s << "<a href=\"#{ @href_links }\" target=\"_blank\" title=\"#{ @title }\">"
    end 

    # Shopping CTA's HTML
    shopping_ctas.each do |shopping_cta|
      @title = shopping_cta.shift
      @href_links = shopping_cta.pop
      shopping_cta_to_s << "<a href=\"#{ @href_links }\" target=\"_blank\" title=\"#{ @title }\">"
    end 
  # 
    # puts array_of_links
    # p banner_to_s
    # p top_pick_to_s
    # p shopping_cta_to_s
    
  # Matching alt tag(from Photoshop) with @title(from CSV)
    text = File.read('test_output.html')

   content_with_links = text.gsub(/(<img)([.\n\r\s\S]*?[.\s\S]*?alt[:=]"?)([.\n\r\s\S]*?)("?>)/, '<a href="#" title="\\3" target="_blank">\\1\\2\\3\\4</a>')

    # content_with_links = ""
    # text.scan(/(<img)([.\n\r\s\S]*?[.\s\S]*?alt[:=]"?)([.\n\r\s\S]*?)("?>)/) do |x|

    #   if x[-2] != ""
    #     content_with_links << x.join.to_s.gsub(/(<img)([.\n\r\s\S]*?[.\s\S]*?alt[:=]"?)([.\n\r\s\S]*?)("?>)/, '<a href="#" title="\\3" target="_blank">\\1\\2\\3\\4</a>')
    #   else
    #     content_with_links << x.join.to_s
    #   end 
    # end

    File.open('test_output.html', "w") {|out| out << content_with_links}
  end 

end


### TESTING

# Initialize
t1 = TableManager.new

# Open CSV file
the_csv_file = Dir['*'].select {|x| x =~ /_.*(csv)/ }.sort.first
t1.open_csv(the_csv_file)

# Filter data and Convert data to <a>tag
t1.filtering_links
t1.grab_links(t1.news_data)

# Open HTML file(input) and wirte new HTML file(output)
the_input_file = Dir['*'].select {|x| x =~ /_.*(html)/ }.sort.first
t1.html_with_style(the_input_file)

# # Insert links
# t1.insert_links('test_output.html', t1.news_data)

