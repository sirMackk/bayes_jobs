module BayesSearcher
  class Krawler
    attr_reader :data, :kollector, :klassifiers
    require 'open-uri'
    require 'set'
    require 'yaml'

    def initialize(url, kollector, klassifiers)
      @visited = Set.new
      @links = Queue.new
      @data = []
      @url = url
      @kollector = kollector
      @klassifiers = klassifiers
      @mutex = Mutex.new
    end

    def run
      parse_page(@url)
      threads = []

      2.times do
        threads << Thread.new do
          while !@links.empty?
            link = @links.pop
            parse_page(link)
            save_navigator
          end
        end
      end
      threads.each { |t| t.join }
    end

    def kollector_collect(page)
      @kollector.kollect(page.read)
    end

    def parse_page(link)
      open(link) do |page|
        data, links_titles = kollector_collect(page)
        #@data << data
        @mutex.synchronize do
          collect_info(links_titles, :navigator)
          @visited.add(link)
          collect_info(data, :extractor)
        end
      end
    end

    private

    def save_navigator
      if @links.size % 100 == 0
        @klassifiers.navigator.save_state
      end
    end

    def collect_info(links_titles, klassifier)
      links_titles.each do |link, title|
        # debug msgs
        if klassifier == :navigator
          puts title
          puts !@visited.include?(link)
          puts @klassifiers[klassifier].run(title)
        end
        if (!@visited.include?(link) && 
            @klassifiers[klassifier].run(title) == :good)
          case klassifier
          when :navigator
            collect_navigation_links(link)
          else
            collect_and_save_data(link)
          end
        end
      end
    end

    def collect_navigation_links(link)
      puts "collecting link: #{link}"
      @visited << link
      @links << link
    end

    def collect_and_save_data(link)
      puts 'collecting data'
      @data << link
      if @data.size > 50
        File.open("temp#{Time.now.to_i}", 'wb') do |f|
          f.write(@data.to_yaml)
          @data = []
        end
      end
    end
  end

  class Kollector
    require 'nokogiri'
    def initialize(**args)
      @css_selectors = args[:selectors]
    end

    def kollect(page)
      @tree = Nokogiri::HTML(page)
      return extract(title_extractor, company_link_extractor), extract(link_text_extractor, link_extractor)
    end

    def extract(text_ext, link_ext)
      job_titles = @tree.css(text_ext).map { |t| t.content }
      company_links = @tree.css(link_ext).map { |l| l.get_attribute('href') }
      Hash[company_links.zip(job_titles)]
    end

    private

    def link_extractor
      @css_selectors[:links]
    end

    def link_text_extractor
      @css_selectors[:link_text]
    end

    def title_extractor
      @css_selectors[:title]
    end

    def company_link_extractor
      @css_selectors[:company_page]
    end
  end

  class Klassifier
    require 'stuff-classifier'
    require 'forwardable'
    attr_accessor :klassifier 
    extend Forwardable
    def_delegators :@klassifier, :classify, :save_state


    def initialize(title, train: false, **opts)
      @train = train
      @klassifier = StuffClassifier::Bayes.new(title, storage: opts[:storage])
    end

    def run(text)
      unless text.empty?
        if @train
          self.train(text)
        else
          self.classify(text)
        end
      else
        if Random.rand >= 0.5
          :good
        else
          :bad
        end
      end
    end

    def self.get_or_create_storage(title: 'test')
      StuffClassifier::FileStorage.new(Klassifier.slugify(title))
    end

    def self.slugify(param)
      param.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    end

    def get_user_input
      gets.chomp.to_sym
    end

    def human_train(text)
      puts text
      puts "Best guess: #{self.classify text}"
      puts "Classify as (good/bad): "
      answer = get_user_input
      if answer == :w
        @train = false
      else
        @klassifier.train(answer, text)
      end
      answer.to_sym
    end

    def train(text)
      unless text.empty?
        human_train(text)
      else
        :bad
      end
    end
  end
end
