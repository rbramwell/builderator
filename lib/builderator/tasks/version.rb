require 'thor'

require_relative '../patch/thor-actions'
require_relative '../control/version'
require_relative '../util'

module Builderator
  module Tasks
    ##
    # Tasks to detect and increment package versions
    ##
    class Version < Thor
      include Thor::Actions

      def self.exit_on_failure?
        true
      end

      desc 'current', 'Print the current version and write it to file'
      def current
        unless Config.autoversion.search_tags
          say_status :disabled, 'Automatically detecting version informantion '\
                                'from SCM tags is disabled', :red
          return
        end

        say_status :version, "#{Control::Version.current} (#{Control::Version.current.ref})"
        Control::Version.write
        Control::Version.set_config_version
      end

      desc 'bump TYPE [PRERELEASE_NAME]', 'Increment the package version, optionally with a named prerelease'
      def bump(type = :auto, prerelease_name = nil)
        ## Guard: Don't try to create a new version if `create_tags` is explicitly disabled
        ## or `search_tags` is disabled as we won't have a valid current version to increment
        unless Config.autoversion.create_tags && Config.autoversion.search_tags
          say_status :disabled, 'Tag creation is disabled for this build. Not '\
          'creating new SCM tags!', :red

          ## Try to read the current version anyway, incase `search_tags == true`
          current

          return
        end

        say_status :bump, "by #{type} version"
        Control::Version.bump(type, prerelease_name)

        ## Print the new version and write out a VERSION file
        current

        ## Try to create and push a tag
        run "git tag #{Control::Version.current}"
        run 'git push --tags'
      end
    end
  end
end
