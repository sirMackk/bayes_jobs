module BayesSearcher
  class Krawler
    attr_reader :data, :kollector, :klassifiers
    require 'open-uri'
    require 'set'
    def initialize url, kollector, klassifiers
      @visited = Set.new
      #@visited = []
      @links = Queue.new
      @data = []
      @url = url
      @collector = kollector
      @klassifiers = klassifiers
      @mutex = Mutex.new
    end

    def kollector_collect(page)
      @collector.kollect(page.read)
    end

    def collect_links(links_titles)
      links_titles.each do |link, title|
        if (!@visited.include?(link) || 
            @klassifiers.navigator.run(title) == :good)
          @visited << link
          @links << link
        end
      end
    end

    def parse_page(link)
      open(link) do |page|
        data, links_titles = kollector_collect(page)
        @data << data
        @mutex.synchronize do
          collect_links(links_titles)
          @visited.add(link)
          #@visited << link
        end
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
      require 'nokogiri'
      def initialize(**args)
        @css_selectors = args[:selectors]
      end

      def kollect(page)
        @tree = Nokogiri::HTML(page)
        return data, links
      end

      #get rid of
      def data
        :bob 
      end

      def links
        links = @tree.css(link_extractor).map { |l| l.get_attribute('href') }
        link_text = @tree.css(link_text_extractor).map { |t| t.content }
        Hash[links.zip(link_text)]
      end

      def link_extractor
        @css_selectors[:links]
      end

      def link_text_extractor
        @css_selectors[:link_text]
      end

    end

  class Klassifier
    require 'stuff-classifier'
    require 'forwardable'
    attr_accessor :klassifier 
    extend Forwardable
    def_delegators :@klassifier, :classify


    def initialize(title, train: false, **opts)
      @train = train
      storage = opts[:storage] || Klassifier.get_or_create_storage(title)
      @klassifier = StuffClassifier::Bayes.new(title, storage: storage)
    end

    def run(text)
      case @train
      when true
        self.train(text)
      else
        self.classify(text)
      end
    end

    def self.get_or_create_storage(title: 'test')
      StuffClassifier::FileStorage.new(Klassifier.slugify(title))
    end

    def self.slugify(param)
      param.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end

    def train text
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
