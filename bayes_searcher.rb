module BayesSearcher
  class Krawler
    attr_reader :data
    require 'open-uri'
    def initialize url, collector
      @links = Queue.new
      @data = []
      @url = url
      @collector = collector
    end

    def run
      open(@url) do |root|
        data, links = @collector.kollect root.read
        @data << data
        links.each { |l| @links << l }
      end
      threads = []

      2.times do
        threads << Thread.new do
          while !@links.empty? && @links.size < 20
            link = @links.pop
            open(link) do |page|
              data, links = @collector.kollect page.read
              @data << data
              links.each { |l| @links << l }
              @collector.save
            end
          end
        end
      end
      threads.each { |t| t.join }
    end
  end

    class Kollector
      require 'nokogiri'
      def initialize klassifiers, **args
        @known = []
        @css_selectors = args[:selectors]
        @extractor = klassifiers[:extractor]
        @navigator = klassifiers[:navigator]
      end

      def kollect page
        @tree = Nokogiri::HTML(page)
        return data, links
      end

      def save
        puts 'saving...'
        @extractor.save_state
        @navigator.save_state
      end
        
      def data
        classify_data
      end

      def links
        classify_links
      end

      def classify_data
        :bob 
      end

      def classify_links
        good_links = []
        extracted_links.each do |link, title|
          puts link
          puts @known.include?(link)
          if !@known.include?(link) && @navigator.run(title) == :good
            good_links << link
          end
          @known << link
        end
        good_links
      end

      def extracted_data
      end

      def extracted_links
        #refactor
        hrefs = @css_selectors[:links]
        anchor_text = @css_selectors[:link_text]
        links = @tree.css(hrefs).map { |l| l.get_attribute('href') }
        link_text = @tree.css(anchor_text).map { |t| t.content }
        Hash[links.zip(link_text)]
        #Hash[@tree.css(hrefs).zip(@tree.css(anchor_text))]
      end
    end

  class Klassifier
    require 'stuff-classifier'
    require 'forwardable'
    attr_accessor :klassifier 
    extend Forwardable
    def_delegators :@klassifier, :classify

    def initialize title, train: false, **opts
      @train = train
      storage = StuffClassifier::FileStorage.new(slugify(title))
      @klassifier = StuffClassifier::Bayes.new(title, storage: storage)
    end

    def run text
      case @train
      when true
        self.train text
      else
        self.classify
      end
    end

    def slugify param
      param.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end

    def train text
      #special user input mode here yo
      puts text
      puts "Best guess: #{self.classify text}"
      puts "Classify as (good/bad): "
      answer = gets.chomp.to_sym
      #refactor
      if answer == :w
        @train = false
      else
        @klassifier.train answer, text
      end
      answer
    end
  end
end
