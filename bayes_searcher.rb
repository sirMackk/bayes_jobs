module BayesSearcher
  class Krawler
    attr_reader :data
    require 'open-uri'
    def initialize url, collector
      @visited = []
      @links = Queue.new
      @data = []
      @url = url
      @collector = collector
    end

    def kollector_collect(page)
      @collector.kollect(page.read)
    end

    def collect_links(links_titles)
      links_titles.each do |link, title|
        if !@visited.include?(link) || @collector.navigator.run(title) == :good
          @links << link
        end
      end
    end

    def parse_page(link)
      open(link) do |page|
        data, links_titles = kollector_collect(page)
        @data << data
        collect_links(links_titles)
        @visited << link
      end
    end

    def run
      parse_page(@url)
      threads = []

      2.times do
        threads << Thread.new do
          while !@links.empty? && @links.size < 80
            link = @links.pop
            parse_page(link)
          end
        end
      end
      threads.each { |t| t.join }
    end
  end

    class Kollector
      attr_accessor :extractor, :navigator
      require 'nokogiri'
      def initialize klassifiers, **args
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
        @extractor.klassifier.save_state
        @navigator.klassifier.save_state
      end
        
      #get rid of
      def data
        :bob 
      end

      def links
        #good_links = []
        #extracted_links.each do |link, title|
          #if @navigator.run(title) == :good
            #good_links << link
          #end
        #end
        #good_links
        extracted_links
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
        self.classify text
      end
    end

    def slugify param
      param.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end

    def train text
      #special user input mode here yo
      # refactor yo
      unless text.empty?
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
      else
        :bad
      end
    end
  end
end
