namespace :whitespace do
  desc 'Removes trailing whitespace'
  task :cleanup do
    sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
  end
  task :retab do
    sh %{find . -name '*.rb' -exec sed -i '' 's/\t/  /g' {} \\;}
  end
end

