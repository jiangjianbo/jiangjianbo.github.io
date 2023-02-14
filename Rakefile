require "rubygems"
require 'rake'
require 'yaml'
require 'time'

SOURCE = "."
CONFIG = {
  'version' => "12.3.2",
  'themes' => File.join(SOURCE, "_includes", "themes"),
  'layouts' => File.join(SOURCE, "_layouts"),
  'posts' => File.join(SOURCE, "_posts"),
  'post_ext' => "md",
  'theme_package_version' => "0.1.0"
}

# Usage: rake post title="A Title" subtitle="A sub title"
desc "Begin a new post in #{CONFIG['posts']}"
task :post do
  abort("rake aborted: '#{CONFIG['posts']}' directory not found.") unless FileTest.directory?(CONFIG['posts'])
  title = ENV["title"] || "new-post"
  subtitle = ENV["subtitle"] || "This is a subtitle"
  slug = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  begin
    date = (ENV['date'] ? Time.parse(ENV['date']) : Time.now).strftime('%Y-%m-%d')
  rescue Exception => e
    puts "Error - date format must be YYYY-MM-DD, please check you typed it correctly!"
    exit -1
  end
  filename = File.join(CONFIG['posts'], "#{date}-#{slug}.#{CONFIG['post_ext']}")
  if File.exist?(filename)
    abort("rake aborted!") if ask("#{filename} already exists. Do you want to overwrite?", ['y', 'n']) == 'n'
  end

  puts "Creating new post: #{filename}"
  open(filename, 'w') do |post|
    post.puts "---"
    post.puts "layout: post"
    post.puts "title: \"#{title.gsub(/-/,' ')}\""
    post.puts "subtitle: \"#{subtitle.gsub(/-/,' ')}\""
    post.puts "date: #{date}"
    post.puts "author: \"BigTall\""
    post.puts "header-img: \"img/post-bg-sunset.jpg\""
    post.puts "tags: "
    post.puts "    - 文章"
    post.puts "---"
  end
end # task :post

desc "Launch preview environment"
task :preview do
  system "jekyll --auto --server"
end # task :preview

#Load custom rake scripts
Dir['_rake/*.rake'].each { |r| load r }

# copy from https://www.sitepoint.com/jekyll-plugins-github/
# 
#GH_PAGES_DIR = "blog-site"
GH_PAGES_DIR = "gh-pages"

desc "Build Jekyll site and copy files"
task :build do
  system "jekyll build"
  system "rm -r ../#{GH_PAGES_DIR}/*" unless Dir['../#{GH_PAGES_DIR}/*'].empty?
  system "cp -r _site/* ../#{GH_PAGES_DIR}/"
  system "echo nojekyll > ../#{GH_PAGES_DIR}/.nojekyll"
end

desc "commit Jekyll site and push to github repository"
task :publish do
  title = ENV['TITLE'] || "at #{Date.today}"

  system "echo commit and push to gh-pages"
  system "cd ../#{GH_PAGES_DIR} && git commit -a -m \"publish #{title}\""
  system "cd ../#{GH_PAGES_DIR} && git push origin gh-pages"
end
