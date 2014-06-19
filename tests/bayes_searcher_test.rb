require 'minitest/autorun'
require 'mocha/mini_test'
require_relative '../bayes_searcher'

class TestKrawler < MiniTest::Test
  def setup
    kollector = mock
    klassifiers = mock
    @krawler = BayesSearcher::Krawler.new('url', kollector, klassifiers)
  end

  def test_kollector_collect
    page = mock
    page.expects(:read).returns(nil)
    @krawler.kollector.expects(:kollect)
    @krawler.kollector_collect(page)
  end

  def test_parse_page
    @krawler.expects(:open).yields(mock('page'))
    @krawler.expects(:kollector_collect).returns([0, 1])
    @krawler.expects(:collect_info).at_least(2)
    @krawler.parse_page('link')
  end

end

class TestKollector < MiniTest::Test
  def setup
    @selectors = {selectors: {links: '.links', link_text: '.link_text',
                  title: '.title', company_page: '.company_page'}}
    @kollector = BayesSearcher::Kollector.new(@selectors)
    @page = 'string'
  end

  def test_kollect
    Nokogiri::HTML::Document.expects(:parse).with(instance_of(String), nil, nil, instance_of(Fixnum))
    @kollector.expects(:extract).with(instance_of(String), instance_of(String)).at_least(2)
    @kollector.kollect(@page)
  end

  def test_extract
    tree = mock
    item = mock
    item.expects(:content).returns(1)
    item.expects(:get_attribute).returns(1)
    tree.expects(:css).with(instance_of(String)).returns([item]).at_least(2)
    @kollector.instance_variable_set(:@tree, tree)
    result = @kollector.extract('link', 'text')
    assert_instance_of(Hash, result)
  end
end

class TestKlassifier < MiniTest::Test
  def setup
    @title = 'test' 
    @text = 'Senior Ruby Developer'
    @klassifier = BayesSearcher::Klassifier.new(@title, storage: nil)
  end

  def test_get_or_create_storage
    storage = BayesSearcher::Klassifier.get_or_create_storage(title: @title)
    assert_respond_to(storage, :save_state)
  end

  def test_slugify
    slug = BayesSearcher::Klassifier.slugify('test message - for -- test')
    assert_equal('test-message---for----test', slug)
  end

  def test_train_false
    mock = MiniTest::Mock.new
    mock.expect(:train, :w, [String])
    @klassifier.klassifier = mock
    ans = @klassifier.train('')
    assert_equal(ans, :bad)
  end

  def test_train_true
    @klassifier.expects(:get_user_input).returns(:good)
    @klassifier.klassifier.expects(:train).with(instance_of(Symbol), instance_of(String)).returns(:w)
    @klassifier.klassifier.expects(:classify).with(instance_of(String)).returns(:good)
    @klassifier.instance_variable_set(:@train, true)
    ans = @klassifier.train('developer')
    assert_equal(ans, :good)
  end

  def test_run_text_empty
    Random.expects(:rand).returns(0.5)
    klass = @klassifier.run('')
    assert_equal(:good, klass)
  end

  def test_run_train_true
    @klassifier.instance_variable_set(:@train, true)
    @klassifier.expects(:train).with(@text).returns(:good)
    klass = @klassifier.run(@text)
    assert_equal(:good, klass)
  end

  def test_run_train_false
    @klassifier.expects(:classify).with(@text).returns(:good)
    klass = @klassifier.run(@text)
    assert_equal(:good, klass)
  end
end
