require 'rake'
require 'rubygems'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/clean'

require 'fileutils'

###############################################
# GLOBAL
###############################################

FL = FileList
NAME = "arrayclass"
FU = FileUtils

readme = "README"

rdoc_extra_includes = [readme, "LICENSE"]
rdoc_options = ['--main', readme, '--title', NAME]

lib_files = FL["lib/**/*"]
dist_files = lib_files + FL[readme, "LICENSE", "Rakefile", "{specs}/**/*"]
changelog = 'CHANGELOG'

###############################################
# ENVIRONMENT
###############################################
ENV["OS"] == "Windows_NT" ? WIN32 = true : WIN32 = false
$gemcmd = "gem"
if WIN32
  unless ENV["TERM"] == "cygwin"
    $gemcmd << ".cmd"
  end
end


###############################################
# DOC
###############################################
Rake::RDocTask.new do |rd|
  rd.main = readme
  rd.rdoc_files.include rdoc_extra_includes
  rd.options.push( *rdoc_options )
end

desc "create html docs"
task :html_docs do
  css = 'doc/src/style.css'
  FU.mkpath 'doc/output'
  FU.cp css, 'doc/output/'
  index = 'doc/output/index.html'
  header = 'doc/src/header'
  File.open(index, 'w') do |index|
    index.puts '<html>'
    index.puts IO.read(header)
    index.puts '<html><body>'
    index.puts `bluecloth --fragment #{readme}`

    # add contact info:
    index.puts '<h2>Contact</h2>'

    jtprince_gmail_email_encrypted = '<a href="mailto:%6a%74%70%72%69%6e%63%65%40%67%6d%61%69%6c%2e%63%6f%6d">&#106;&#116;&#112;&#114;&#105;&#110;&#99;&#101;&#64;&#103;&#109;&#97;&#105;&#108;&#46;&#99;&#111;&#109;</a>'
    index.puts jtprince_gmail_email_encrypted

    index.puts '</body></html>'
  end
end

desc "create and upload docs to server"
task :upload_docs => :html_docs do
  sh "scp -i ~/.ssh/rubyforge_key -r doc/output/* jtprince@rubyforge.org:/var/www/gforge-projects/arrayclass/"
end


###############################################
# TESTS
###############################################


desc 'Default: Run specs.'
task :default => :spec

desc 'Run specs.'
Rake::TestTask.new(:spec) do |t|
  # can specify SPEC=<file>_spec.rb or TEST=<file>_spec.rb
  ENV['TEST'] = ENV['SPEC'] if ENV['SPEC']  
  t.libs = ['lib']
  t.test_files = Dir.glob( File.join('spec', ENV['pattern'] || '**/*_spec.rb') )
  t.verbose = true
  t.warning = true
end


#desc "Run all specs with RCov"
#Spec::Rake::SpecTask.new('rcov') do |t|
#  Rake::Task[:ensure_gem_is_uninstalled].invoke
#  t.spec_files = FileList['specs/**/*_spec.rb']
#  t.rcov = true
#  t.libs = ['lib']
#  t.rcov_opts = ['--exclude', 'specs']
#end

#task :spec do
#  uninstall_gem
#  # files that match a key word
#  files_to_run = ENV['SPEC'] || FileList['specs/**/*_spec.rb']
#  if ENV['SPECM']
#    files_to_run = files_to_run.select do |file|
#      file.include?(ENV['SPECM'])
#    end
#  end
#  files_to_run.each do |spc|
#    system "ruby -I lib -S spec #{spc} --format specdoc"
#  end
#end

###############################################
# PACKAGE / INSTALL / UNINSTALL
###############################################

def get_summary(readme)
  string = ''
  collect = false
  IO.foreach(readme) do |line|
    if collect
      if line =~ /[^\s]/
        string << line
      else
        break
      end
    elsif line =~ /^AXML - .*/
      string << line
      collect = true
    end
  end
  string.gsub!("\n", " ")
end

# looks for a header, collects the paragraph after the space
def get_section(header, file)
  get_space = false
  found_space = false
  string = ''
  IO.foreach(file) do |line|
    if found_space
      if line =~ /[^\s]/
        string << line
      else
        break
      end
    elsif get_space
      if line !~ /[^\s]/
        found_space = true
        get_space = false
      end
    elsif line =~ /^#{header}/ 
      get_space = true
    end
  end
  string.gsub!("\n", ' ')
end

def get_description(readme)
  get_section('Description', readme)
end


tm = Time.now

desc "Create packages."
gemspec = Gem::Specification.new do |t|
  t.platform = Gem::Platform::RUBY
  t.name = NAME
  t.rubyforge_project = NAME
  t.version =  IO.readlines(changelog).grep(/##.*version/).pop.split(/\s+/).last.chomp
  t.homepage = "http://arrayclass.rubyforge.org"
  t.date = "#{tm.year}-#{tm.month}-#{tm.day}"
  t.summary = "low memory class based on Array"
  t.email = "jtprince@gmail.com"
  t.has_rdoc = true
  t.authors = ['John Prince']
  t.files = dist_files
  t.test_files = FL["specs/*_spec.rb"]
  t.rdoc_options = rdoc_options
end

desc "Create packages."
Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end


task :remove_pkg do 
  FileUtils.rm_rf "pkg"
end

task :install => [:reinstall]

desc "uninstalls the package, packages a fresh one, and installs"
task :reinstall => [:remove_pkg, :clean, :package] do
  reply = `#{$gemcmd} list -l #{NAME}`
  if reply.include?(NAME + " (")
    %x( #{$gemcmd} uninstall -a -x #{NAME} )
  end
  FileUtils.cd("pkg") do
    cmd = "#{$gemcmd} install #{NAME}*.gem"
    puts "EXECUTING: #{cmd}" 
    system cmd
  end
end

