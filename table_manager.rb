require 'csv'
require 'nokogiri'

class TableManager

  attr_accessor :content

### Initialize - Creating empty Hashes
  def initialize(content=nil)
    @content = []
  end

### CSV : convert data to HTML <a>tag with attributes  
  # Open CSV File and Save @content without empty cells
  def open_csv(file_name)
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


  # Filtering links
  def filtering_links     
    @content.each_with_index do |c, i|
      # Validate URL - Only for CTA, as the product links are picked up from the website
      if !c[:cta].nil? && (c[:cta_link]).split(/\./).first != "http://www" 
        invalid_url = (c[:cta_link]).split(/\./)[1..-1] # If there is no http:// - When start with only 'www.'
        c[:cta_link] = invalid_url.unshift("http://www").join('.')
      else
        c[:cta_link]
      end 
    end
    # puts @content

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
    File.open(outfile, "w") {|out| out << new_contents } # No need to close the file when using the block for File class.
  end

  def insert_links(output_file)

  ## Matching alt tag(from Photoshop) with @title(from CSV)
    html_string = File.read(output_file)

    # Inserting '#' links when the <img> has alt tag.
    html_string = html_string.gsub(/(<img.*alt=")(.+)(">)/, '<a href="#" target="_blank">\\1\\2" title="\\2\\3</a>')

    # Inserting products links
    doc = Nokogiri::HTML(html_string)

    doc.xpath("//a").each_with_index do |a, i|
    next if i > @content.length - 1 or @content[i][:product_links].nil? or !@content[i][:product_links].include? 'http'
      a['href'] = @content[i][:product_links]
    end

    File.open(output_file, "w") {|out| out << doc.to_s }
    
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

# Open HTML file(input) and wirte new HTML file(output)
the_input_file = Dir['*'].select {|x| x =~ /_.*(html)/ }.sort.first
t1.html_with_style(the_input_file)

# Insert links
t1.insert_links('test_output.html')

