require_relative './spec_helper'

# :nodoc:
module Builderator
  RSpec.describe Config, '#load' do
    before(:example) do
      Config.reset!
      Config.load(::File.expand_path('../resource/Buildfile', __FILE__))
    end

    it 'defaults to the gecode solver' do
      Config.compile
      expect(Config.berkshelf.solver).to eq :gecode
    end

    it 'loads a DSL file' do
      expect(Config.layers.length).to eq 1
    end

    it 'compiles loaded DSL' do
      layer = Config.layers.first
      layer.compile.seal

      expect(layer.build_name).to eq 'builderator'
      expect(layer.autoversion.create_tags).to be false

      ## Collection `depends` in Namespace `cookbook`
      expect(layer.cookbook.depends['apt']).to be_kind_of(Config::Attributes::Namespace)
      expect(layer.cookbook.depends['etcd-v2']).to be_kind_of(Config::Attributes::Namespace)
    end

    it 'compiles configuration layers' do
      skip
      Config.compile

      ## Ensure that layer-order is respected
      expect(Config.aws.region).to eq 'us-east-1'
      expect(Config.build_name).to eq 'builderator'
    end
  end

  RSpec.describe Config, '#compile' do
    before(:example) do
      Builderator::Config::GLOBAL_DEFAULTS.reset!
      Builderator::Config.reset!
    end

    it 'compiles a trivial build configuration' do
      expect(Builderator::Config.layers).to be_empty

      Builderator::Config.load(::File.expand_path('../resource/Buildfile-home-directory', __FILE__))
      Builderator::Config.load(::File.expand_path('../resource/Buildfile-simple', __FILE__))

      expect(Builderator::Config.all_layers.any?(&:dirty)).to be false

      expect { Config.compile }.not_to raise_error
    end

    it 'compiles a build with a build-type policy' do
      expect(Builderator::Config.layers).to be_empty

      Builderator::Config.load(::File.expand_path('../resource/Buildfile-home-directory', __FILE__))
      Builderator::Config.load(::File.expand_path('../resource/Buildfile-with-policy', __FILE__))

      expect(Builderator::Config.all_layers.any?(&:dirty)).to be false

      expect { Config.compile }.not_to raise_error
    end

    it 'compiles a build with a build-type policy and overrides' do
      expect(Builderator::Config.layers).to be_empty

      Builderator::Config.load(::File.expand_path('../resource/Buildfile-home-directory', __FILE__))
      Builderator::Config.load(::File.expand_path('../resource/Buildfile-with-overrides', __FILE__))

      expect(Builderator::Config.all_layers.any?(&:dirty)).to be false

      expect { Config.compile }.not_to raise_error
    end

    it 'compiles a build with a build-type policy and overrides, and an extended collection item with hash values' do
      expect(Builderator::Config.layers).to be_empty

      Builderator::Config.load(::File.expand_path('../resource/Buildfile-home-directory', __FILE__))
      Builderator::Config.load(::File.expand_path('../resource/Buildfile-with-overrides2', __FILE__))

      expect(Builderator::Config.all_layers.any?(&:dirty)).to be false

      expect { Config.compile }.not_to raise_error
    end

    it 'compiles a change after an initial compilation' do
      expect(Builderator::Config.layers).to be_empty

      Builderator::Config.load(::File.expand_path('../resource/Buildfile-home-directory', __FILE__))
      Builderator::Config.load(::File.expand_path('../resource/Buildfile-with-overrides2', __FILE__))
      expect(Builderator::Config.all_layers.any?(&:dirty)).to be false
      expect { Config.compile }.not_to raise_error

      Builderator::Config.defaults.version '1.2.3'
      Builderator::Config.defaults.build_number = '4'
      expect { Config.compile }.not_to raise_error

      expect(Builderator::Config.profile('default').tags['version']).to eq '1.2.3-4'
    end
  end
end
