#! /usr/bin/env ruby

require './bayes_searcher'
require 'ostruct'

class BayesJobs
  attr_reader :args, :crawler

  def initialize
    parse_args
    @crawler = setup
  end

  def run
    @crawler.run
  end

  def setup 
    sels = { links: '#extra .content ul li strong a',
             link_text: '#extra span.headline',
             title: '.postitle span.title',
             company_page: '.postitle strong a',
             company_url: '.basic-info .content dl dd a'}
    collector = BayesSearcher::Kollector.new(selectors: sels)
    BayesSearcher::Krawler.new @args[:url], collector, get_klassifiers
  end

  def get_klassifiers
    klassifiers = OpenStruct.new
    storage = BayesSearcher::Klassifier.get_or_create_storage(title: @args[:title])
    klassifiers.extractor = BayesSearcher::Klassifier.new(@args[:title], train: @args[:train], storage: storage)
    klassifiers.navigator = BayesSearcher::Klassifier.new(@args[:title], train: @args[:train], storage: storage)
    klassifiers
  end

  def parse_args
    # change to optparse later
    url = ENV['TARGETURL']
    #@args = { title: ARGV[0], location: ARGV[1], url: ARGV[2], train: ARGV[3] || false }
    @args = { title: 'test', location: 'new york', url: url, train: true }
    #@args = { title: 'test', location: 'new york', url: url, train: true }
  end
end
