=begin
/*
* Copyright 2019 Oath Inc.
* Licensed under the terms of the BSD 3-clause license.
* Please see LICENSE file in the project root for terms.
*/
=end

require 'rexml/document'
require 'fileutils'

class Junit  
  @@testresults = 0
  def initialize(dir, setui)  
    @dir = dir  
    @setui = setui 
    @total = @pass = @failures = @errors = 0
    @odir = "#{ENV['SD_ARTIFACTS_DIR']}/#{ENV['SD_BUILD_ID']}-test-results"
    @pdir = "#{@odir}/tests-pass"
    @fdir = "#{@odir}/tests-failure"
    @edir = "#{@odir}/tests-error"
    FileUtils.rm_rf("#{@pdir}" "#{@fdir}" "#{@edir}")
  end  

  def process_report
    files = Dir.glob("#{@dir}/*.xml")
    if files.empty?
      p "no files found in @dir. Exiting!"
      exit
    end
    files.each do |file|
      # p "=> #{file}"
      next if file == '.' or file == '..' or File.zero?("#{file}")
      xmlfile = File.new(file)
      xmldoc = REXML::Document.new(xmlfile)
      if (! xmldoc.elements["testsuites"] && ! xmldoc.elements["testsuite"])
        p "Element testsuites | testsuite not found! Exiting..."
        exit -1 
      end
      elem = REXML::XPath.match( xmldoc, "//testsuite" )
      elem = REXML::XPath.match( xmldoc, "//testsuites/testsuite" ) if xmldoc.elements["testsuites"]
      # p "Elements in #{file} is " + "#{elem.length}"
      elem.each do |root|
        # p "Total tests default: #{@total}, Total Failures: #{@failures}, Total Errors: #{@errors}, Total Pass: #{@pass}"
        total = pass = failures = errors = 0
        total = root.attributes["tests"].to_i if root.attributes["tests"]
        failures = root.attributes["failures"].to_i if root.attributes["failures"]
        errors = root.attributes["errors"].to_i if root.attributes["errors"]
        pass = total - failures - errors
        @total += total
        @failures += failures
        @errors += errors
        @pass += pass
        # p "Aggregated Total = #{@total}, Failures = #{@failures}, Errors = #{@errors}, Passed = #{@pass}"
        ## Generate report if failures or errors
        root.elements.each("testcase") do |e|
          # p "Checking #{e.attributes['classname']}"
          if e.elements['failure']
            FileUtils.mkdir_p("#{@fdir}") unless File.exists?("#{@fdir}")
            ffile = File.open("#{@fdir}/#{e.attributes['classname']}", "a")
            ffile.write("\n#{e.attributes['name']}:\n #{e.elements['failure']}\n")
            ffile.close
          elsif e.elements['error']
            FileUtils.mkdir_p("#{@edir}") unless File.exists?("#{@edir}")
            efile = File.open("#{@edir}/#{e.attributes['classname']}", "a")
            efile.write("\n#{e.attributes['name']}:\n #{e.elements['error']}\n")
            efile.close
          else
            FileUtils.mkdir_p("#{@pdir}") unless File.exists?("#{@pdir}")
            pfile = File.open("#{@pdir}/#{e.attributes['classname']}", "a")
            pfile.write("\n#{e.attributes['name']}, #{e.attributes['classname']}, #{e.attributes['duration']}")
            pfile.close
          end
        end
      end
      @@testresults = "#{@pass}/#{@total}"
    end
  end

  def setui
    p "meta set tests.results #{@@testresults}" if @setui
    system("meta set tests.results '#{@@testresults}'") if @setui
  end

  def failures
    p "Tests passed are logged under directory #{@pdir}" if @pass.to_i > 0
    p "Test failures are logged under directory #{@fdir}" if @failures.to_i > 0
    p "Test errored are looged under directory #{@edir}" if @errors.to_i > 0
    return @failures.to_i + @errors.to_i if @failures.to_i + @errors.to_i > 0
    return 0
  end

end

run = Junit.new(ARGV[0],ARGV[1])

# Basic Sanity Checks
p "Finding Surefire report in #{ARGV[0]} with set UI #{ARGV[1]}"
if ! File.directory?("#{ARGV[0]}")
  p "Directory #{ARGV[0]} is invalid. Exiting!"
  exit -1
end

if ! (["true", "false"].include? ARGV[1].downcase)
  p "Invalid Set UI argument: #{ARGV[1]}. Valid options: true, false"
  exit -1
end

# All good
run.process_report
run.setui
NUM_FAILED_TESTS = run.failures
p "Number of failed tests: #{NUM_FAILED_TESTS}"
exit NUM_FAILED_TESTS if NUM_FAILED_TESTS > 0
