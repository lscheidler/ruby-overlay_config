require "spec_helper"

describe OverlayConfig do
  it "has a version number" do
    expect(OverlayConfig::VERSION).not_to be nil
  end

  describe OverlayConfig::Config do
    before(:all) do
      @config = OverlayConfig::Config.new(
        config_scope: 'data',
        config_base_directories: [Dir.pwd + '/spec'],
        defaults: {
          default_a: 'This is default a',
          test: 'This should not be returned'
        }
      )
    end

    it "should load test config file" do
      expect(@config.get :test).to eq('Hello World!')
      expect(@config[:test]).to eq('Hello World!')
    end

    it "should return default, if config could not be found in config files" do
      expect(@config.get :default_a).to eq('This is default a')
    end

    it "should return default, if config could not be found in config files" do
      expect(@config.get :doesntexist, default: 'default value').to eq('default value')
    end

    it "should return nil, if config could not be found in config files" do
      expect(@config.get :doesntexist).to be(nil)
    end

    it "should have length == 2" do
      expect(@config.length).to be(2)
    end

    it 'should log unsupported config file extensions' do
      expect {
        log = Logger.new $stdout
        log.level = Logger::INFO

        OverlayConfig::Config.new(
          config_scope: 'data',
          config_base_directories: [Dir.pwd + '/spec'],
          config_filenames: ['unsupported.cfg'],
          log: log
        )
      }.to output(/unsupported.cfg, file extension not known./).to_stdout
    end

    it 'should parse unsupported config file extensions with default_parser, if set' do
      config = OverlayConfig::Config.new(
        config_scope: 'data',
        config_base_directories: [Dir.pwd + '/spec'],
        config_filenames: ['unsupported.cfg'],
        default_parser: :yaml
      )
      expect(config.get :with_default_parser).to eq('it works')
    end

    it 'should raise an exception, if default_parser is wrong' do
      expect {
        OverlayConfig::Config.new(
          config_scope: 'data',
          config_base_directories: [Dir.pwd + '/spec'],
          config_filenames: ['unsupported.cfg'],
          default_parser: :json
        )
      }.to raise_error(JSON::ParserError)
    end

    it 'should log missing config files' do
      expect {
        log = Logger.new $stdout
        log.level = Logger::DEBUG

        OverlayConfig::Config.new(log: log)
      }.to output(/config.json not found/).to_stdout
    end

    it 'should append config settings' do
      @config.append('<append_test>', {'appended' => 'appended_config_value'})
      expect(@config.get :appended).to eq('appended_config_value')
    end

    it 'should insert config settings' do
      @config.insert(0, '<insert_test>', {'test' => 'inserted_config_value'})
      expect(@config.get :test).to eq('inserted_config_value')
    end

    it 'should set config values' do
      @config[:set] = 'set'
      expect(@config.get :set).to eq('set')
      expect(@config.get 'set').to eq('set')
      expect(@config.has_key? 'set').to be(true)
    end
  end

  describe Hash do
    before(:all) do
      @hash = {
        symbol: 'Hello Symbol World',
        'string' => 'Hello String World',
        hash: {
          'cascade' => {
            final: 'inner value'
          }
        }
      }
    end

    it 'should return symbol value' do
      expect(@hash.get :symbol, default: 'nanana').to eq('Hello Symbol World')
    end

    it 'should return symbol value' do
      expect(@hash.get 'symbol', default: 'nanana').to eq('Hello Symbol World')
    end

    it 'should return string value' do
      expect(@hash.get :string, default: 'nanana').to eq('Hello String World')
    end

    it 'should return string value' do
      expect(@hash.get 'string', default: 'nanana').to eq('Hello String World')
    end

    it 'should return value from inner hash' do
      expect(@hash.get [:hash, :cascade, 'final']).to eq('inner value')
    end

    it 'should return default value' do
      expect(@hash.get :doesntexist, default: 'default value').to eq('default value')
    end

    it 'should return default value' do
      expect(@hash.get [:hash, :cascade, :doesntexist], default: 'default value').to eq('default value')
    end

    it 'should return nil' do
      expect(@hash.get :doesntexist).to be(nil)
    end
  end
end
