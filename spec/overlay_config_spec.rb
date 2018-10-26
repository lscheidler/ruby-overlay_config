# Copyright 2018 Lars Eric Scheidler
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

    it "responds to get" do
      expect(@config.respond_to? :get).to eq(true)
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

    it "should return test setting for config.test" do
      expect(@config.test).to eq('Hello World!')
    end

    it "responds to set" do
      expect(@config.respond_to? :set).to eq(true)
      expect(@config.respond_to? '[]='.to_sym).to eq(true)
    end

    it "should provide setter method for variables (e.g. config.abs = something)" do
      @config.tes = 'abc'
      expect(@config.tes).to eq('abc')
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

    it "responds to append" do
      expect(@config.respond_to? :append).to eq(true)
    end

    it 'should append config settings' do
      @config.append('<append_test>', {'appended' => 'appended_config_value'})
      expect(@config.get :appended).to eq('appended_config_value')
    end

    it "responds to insert" do
      expect(@config.respond_to? :insert).to eq(true)
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

    it "responds to get_filenames" do
      expect(@config.respond_to? :get_filenames).to eq(true)
    end

    it "returns get_filenames" do
      expect(@config.get_filenames).to eq(["<insert_test>", Dir.pwd + "/spec/data/config.json", "<defaults>", "<append_test>"])
    end

    it "responds to delete_at" do
      expect(@config.respond_to? :delete_at).to eq(true)
    end

    it 'deletes the config file at specified index' do
      expect(@config.length).to be(4)
      expect(@config.delete_at(0)).to eq({:file=>"<insert_test>", :config=>{"test"=>"inserted_config_value"}})
      expect(@config.length).to be(3)
    end

    describe "clone" do
      before(:all) do
        @config = OverlayConfig::Config.new(
          config_scope: 'data',
          config_base_directories: [Dir.pwd + '/spec']
        )
        @cloned = @config.clone
        @cloned.insert(0, '<insert_test>', {'test' => 'inserted_config_value'})
      end

      it "should load test config file" do
        expect(@config.test).to eq('Hello World!')
      end

      it "return value from clone" do
        expect(@cloned.test).to eq('inserted_config_value')
      end

      it "no additional configs in original" do
        expect(@config.length).to be(1)
        expect(@config.delete_at(0)).not_to eq({:file=>"<insert_test>", :config=>{"test"=>"inserted_config_value"}})

        expect(@cloned.length).to be(2)
        expect(@cloned.delete_at(0)).to eq({:file=>"<insert_test>", :config=>{"test"=>"inserted_config_value"}})
      end
    end

    describe "support glob filenames" do
      before(:all) do
        @config = OverlayConfig::Config.new(
          config_scope: 'data',
          config_filenames: ['conf.d/*.yml'],
          config_base_directories: [Dir.pwd + '/spec']
        )
      end

      it 'loads all files matching glob' do
        expect(@config.get :a).to eq('a')
        expect(@config.get :b).to eq('b')
        expect(@config.get :c).to eq('c')
      end

      it "responds to each" do
        expect(@config.respond_to? :each).to eq(true)
      end

      it 'iterates over all configs' do
        index = 0
        @config.each do |filename, config|
          case index
          when 0
            expect(filename).to end_with('data/conf.d/a.yml')
          when 1
            expect(filename).to end_with('data/conf.d/b.yml')
          when 2
            expect(filename).to end_with('data/conf.d/c.yml')
          when 4
            # should not exist
          end
          index += 1
        end
      end
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
