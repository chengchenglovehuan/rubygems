require 'rubygems/command'
require 'rubygems/version_option'

class Gem::Commands::ContentsCommand < Gem::Command

  include Gem::VersionOption

  def initialize
    super 'contents', 'Display the contents of the installed gems',
          :specdirs => [], :lib_only => false, :prefix => true

    add_version_option

    add_option(      '--all',
               "Contents for all gems") do |all, options|
      options[:all] = all
    end

    add_option('-s', '--spec-dir a,b,c', Array,
               "Search for gems under specific paths") do |spec_dirs, options|
      options[:specdirs] = spec_dirs
    end

    add_option('-l', '--[no-]lib-only',
               "Only return files in the Gem's lib_dirs") do |lib_only, options|
      options[:lib_only] = lib_only
    end

    add_option(      '--[no-]prefix',
               "Don't include installed path prefix") do |prefix, options|
      options[:prefix] = prefix
    end
  end

  def arguments # :nodoc:
    "GEMNAME       name of gem to list contents for"
  end

  def defaults_str # :nodoc:
    "--no-lib-only --prefix"
  end

  def usage # :nodoc:
    "#{program_name} GEMNAME [GEMNAME ...]"
  end

  def execute
    version = options[:version] || Gem::Requirement.default

    spec_dirs = options[:specdirs].map do |i|
      [i, File.join(i, "specifications")]
    end.flatten

    path_kind = if spec_dirs.empty? then
                  spec_dirs = Gem::SourceIndex.installed_spec_directories
                  "default gem paths"
                else
                  "specified path"
                end

    si = Gem::SourceIndex.from_gems_in(*spec_dirs)

    gem_names = if options[:all] then
                  si.map { |_, spec| spec.name }
                else
                  get_all_gem_names
                end

    gem_names.each do |name|
      spec = si.find_name(name, version).last

      unless spec then
        say "Unable to find gem '#{name}' in #{path_kind}"

        if Gem.configuration.verbose then
          say "\nDirectories searched:"
          spec_dirs.each { |dir| say dir }
        end

        terminate_interaction 1 if gem_names.length == 1
      end

      gem_path = spec.full_gem_path

      files = if options[:lib_only] then
                glob = File.join(gem_path, "{#{spec.require_paths.join ','}}",
                                 '**/*')

                Dir[glob]
              else
                Dir[File.join(gem_path, '**/*')]
              end

      gem_path = File.join gem_path, '' # to strip trailing /

      files.each do |file|
        next if File.directory? file

        file = file.sub gem_path, '' unless options[:prefix]

        say file
      end
    end
  end

end

