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
end


#TESTING
t1 = TableManager.new
t1.open_csv('email_test.csv')
