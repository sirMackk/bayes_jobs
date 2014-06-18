# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :minitest, test_folders: ['tests'] do
  # with Minitest::Unit
  watch(%r{^tests/([a-z_]*)\.rb$})
  watch(%r{^([a-z_]*)\.rb$})     { |m| "tests/#{m[1]}_test.rb" }
end
