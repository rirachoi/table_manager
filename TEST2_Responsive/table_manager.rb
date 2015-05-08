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
      c.delete_if { |k, v| v.nil? }# Delete Nil elements
    end
    @content # Return Content
    
  end

### HTML - Insert numbers into given table. 
  def table_cell_with_number(htmlfile, outputfile)
    str_html = File.read(htmlfile)
    # Save a string from a table generated by Photoshop 
    photoshop_table = str_html.match(/(<html>[.\n\r\s\S]*?)(<table)([.\s\S]*?)(id="Table_01")([.\n\r\s\S]*?)(<\/table>)([.\n\r\s\S]*?<\/html>)/)[0]
    # Used Nokogiri to access IMG elements
    photoshop_table_noko = Nokogiri::HTML(photoshop_table)
    # Created a new array for IMG urls 
    photoshop_images_array = photoshop_table_noko.xpath("//img").map { |img| img }
    # Making arrays for IMG's attributes 
    photoshop_attr_src = []
    photoshop_attr_alt = []
    photoshop_attr_width = []
    photoshop_attr_height = []
    # Putting images arrtibutes into each array
    photoshop_images_array.each do |image|
      photoshop_attr_src << image["src"]
      photoshop_attr_alt << image["alt"]
      photoshop_attr_width << image["width"]
      photoshop_attr_height << image["height"]
    end 

    # Get rid of phtoshop table from the input html
    str_html = str_html.gsub(/(<html>[.\n\r\s\S]*?)(<table)([.\s\S]*?)(id="Table_01")([.\n\r\s\S]*?)(<\/table>)([.\n\r\s\S]*?<\/html>)/,"")
    
    # Insert images into MY_TABLE's td
    my_table_noko = Nokogiri::HTML(str_html)
    my_table_noko.xpath("//td//img").each_with_index do |img, n|
      img["src"] = photoshop_attr_src[n]
      img["alt"] = photoshop_attr_alt[n]
      img["width"] = photoshop_attr_width[n]
      img["height"] = photoshop_attr_height[n]
    end 
    
    # Wrting the result
    File.open(outputfile, "w") {|out| out << my_table_noko } # No need to close the file when using the block for File class.
  end

  # Insert Links compared picture's number to link's order number
  def insert_links_with_numbers(outputfile)
    str_html = File.read(outputfile)
    # First Gsub: Inserting <a> when IMG has alt-number # Second Gsub: Replace some IMGs to &nbsp; IMG has alt-N or letters # Third Gusb: Adjust CTA's TD width to be centered  
    str_html = str_html.gsub(/(<img.*alt=")(\d+)(.*">)/, '<a href="\\2" target="_blank">\\1\\2" title="\\2\\3</a>').gsub(/(<img.*alt=")([A-z]+)(.*">)/, "\&nbsp\;").gsub(/(<td.*width=")(\d+)(".*class="TABS_cta".*)(width=")(\d+)(.*">.*<\/td>)/, "\\1\\5\\3\\4\\5\\6\\7") 
    # With this code, the links in CSV must be in order (same as photoshop slices)
    noko_html = Nokogiri::HTML(str_html)
    # Making a new array for Nokogiri alts - Picture's number should be same as link's index
    pic_number = noko_html.xpath("//a//img//@alt").map { |alt| alt.to_s }
    # Inserting links.  
    noko_html.xpath("//a").each_with_index { |a, i| a["href"] = @content[pic_number[i].to_i].values.last } # Links  
    # Changing alt & title tag to prodouct details. 
    noko_html.xpath("//a//img").each_with_index do |img, n|
      img["title"] = @content[pic_number[n].to_i].values.first # Hover Text(title)
      img["alt"] = @content[pic_number[n].to_i].values.first # Alt text(alt)
    end 
    # Wrting the result
    File.open(outputfile, "w") {|out| out << noko_html }
  end 

  # Clean up the html and leave only a single table
  def last_clean_up(outputfile)
    str_html = File.read(outputfile)
    # Get rid of html tags. Get rid of amp;. Keep &nbsp;
    str_html = str_html.gsub(/(.*[.\n\r\s\S]*?<body>)/,"").gsub(/(<\/body>[.\n\r\s\S]*?).*/,"").gsub(/amp;/,"").gsub(/\&\#160\;/, "\&nbsp\;")
    # Wrting the result
    File.open(outputfile, "w") {|out| out << str_html }
  end   
end # END OF CLASS / TABLE MANAGER 


##########################################################################
########################### TESTING IT START #############################
#################### PRESS [command + B] TO TEST IT ######################
##########################################################################

# Initialize
t1 = TableManager.new
# Open CSV file
the_csv_file = Dir['*'].select {|x| x =~ /_.*(csv)/ }.sort.first
t1.open_csv(the_csv_file)
# Filter data and Convert data to <a>tag
t1.filtering_links
# Open HTML file(input) and wirte new HTML file(output)
the_input_file = Dir['*'].select {|x| x =~ /_.*(html)/ }.sort.first
t1.table_cell_with_number(the_input_file, 'test_output_F.html')
# Insert links with picture's number
t1.insert_links_with_numbers('test_output_F.html')
# Clean up the html and leave only a single table
t1.last_clean_up('test_output_F.html')

##########################################################################