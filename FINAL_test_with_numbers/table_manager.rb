require 'csv'
require 'nokogiri'

class TableManager

  attr_accessor :content

### Initialize - Creating an empty array
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
      hash_row = row.to_hash # Make CSV data as hash
      # Get rid of blank cells - Putting all data into @content
      if hash_row[:product_links] != nil || hash_row[:cta_link] != nil
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
      # Delete Nil elements
      c.delete_if { |k, v| v.nil? }
    end
    # Return Content
    @content
    
  end

### HTML - Insert code for Email. 
  def html_with_style(htmlfile)
    infile = htmlfile
    outfile = "test_output.html"

    text = File.read(htmlfile)
    # TD Style
    new_contents = text.gsub(/(<td)([.\s\S]*?)>([.\s\S]*?<img[.\s\S]*?width[:=]"?)(\d+)([.\s\S]*?height[:=]"?)(\d+)/, '\\1 width="\\4" height="\\6"\\2 style="font-size: 8px; min-width:\\4px;">\\3\\4\\5\\6')
    new_contents = new_contents.gsub(/<\/td>/, "\n\t\t<\/td>")
    # IMG Style
    new_contents = new_contents.gsub(/<img/, "<img style='display: block; border: 0px; font-size: 8px;'")
    # SPACER GIF Style 
    new_contents = new_contents.gsub('\' src="images/spacer.gif"', ' -webkit-text-size-adjust: none !important; -moz-text-size-adjust:none !important;\' src="images/spacer.gif"')
    # Wrting the result
    File.open(outfile, "w") {|out| out << new_contents } # No need to close the file when using the block for File class.
  end

  def insert_links_with_numbers(output_file)
    html_string = File.read(output_file)
    # Inserting '#' links when the <img> has the alt attribute with picture numbers.
    html_string = html_string.gsub(/(<img.*alt=")(\d)(">)/, '<a href="\\2" target="_blank">\\1\\2" title="\\2\\3</a>')
    # IF THERE IS CODE SPAN IN THE NEWSLETTERS
    html_string = html_string.gsub(/(min-width:.*)(">\n\t\t.*)(<img.*alt=")([a-zA-Z]+)(">)/, 'font-size:20px !important; font-family:Arial, Helvetica, sans-serif; color:#030303; text-align:center; letter-spacing:1px; \\1"><strong>\\4</strong>')
    ## With this code, the links in CSV must be ordered (same as photoshop slices)
    doc = Nokogiri::HTML(html_string)
    # Making a new array for Nokogiri alts - Picture's number should be same as link's number
    picture_number = doc.xpath("//a//img//@alt").map { |alt| alt.to_s }
    # Inserting links in order.  
    doc.xpath("//a").each_with_index do |a, i|
      a["href"] = @content[picture_number[i].to_i].values.last # Links
    end 
    # Changing alt & title tag into prodouct details. 
    doc.xpath("//a//img").each_with_index do |img, n|
      img["title"] = @content[picture_number[n].to_i].values.first # Hover Text(title)
      img["alt"] = @content[picture_number[n].to_i].values.first # Alt text(alt)
    end 

    # Wrting the result
    File.open(output_file, "w") {|out| out << doc.to_s }
  end 

  # Clean up the html and leave only a single table
  def last_clean_up(output_file)
    text = File.read(output_file)
    # MAIN TABLE STYLE
    new_contents = text.gsub(/([.\n\r\s\S]*?)(<table)([.\s\S]*?)(id="Table_01")([.\n\r\s\S]*?)(<\/table>)([.\n\r\s\S]*?<\/html>)/, "<table style='min-width:620px;' align='center'\\5\\6\\3")
    # Delete amp; for tracking the URL. 
    new_contents = new_contents.gsub(/amp;/,"")

    # Wrting the result
    File.open(output_file, "w") {|out| out << new_contents }
  end 

  
end # END OF CLASS / TABLE MANAGER 


######## TESTING

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

# Insert links with picture's number
t1.insert_links_with_numbers('test_output.html')

# Clean up the html and leave only a single table
t1.last_clean_up('test_output.html')

