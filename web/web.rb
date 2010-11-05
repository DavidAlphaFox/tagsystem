require 'rubygems'
require 'sequel'
require 'sinatra'
require 'haml'
require 'sass'

require_relative 'db'

if "dev" == `whoami`.chomp("\n")
  set :environment, :development
else
  set :environment, :production
end

set :run, true
set :bind, '127.0.0.1'

configure :development do
  set :port, 1026
  $pre_dir = "dev"
end

configure :production do
  set :port, 1026
  $pre_dir = "prod"
end

$dim = "600x450"

$db = Sequel.connect('postgres://localhost')

get '/' do
  redirect '/page/0'
end

get '/all' do
  haml :all
end

get '/page/:n' do |n|
  @a = Time.new.to_f

  @gap = 100
  @half = 10

  @n = Integer(n)
  @N = count_bags_nonempty()

  @x = Time.new.to_f

  @last = @N / @gap
  @win = 2*@half + 1

  if @n < @win then
    @min = 0
    @max = @win
  elsif @last - @n < @win then
    @min = @last - @win
    @max = @last
  else
    @min = @n - @half
    @max = @n + @half
  end

  if @max > @last
    @max = @last
  end

  @hasless = true if @min > 0
  @hasmore = true if @max < @last

  @b = Time.new.to_f
  haml :page
end

get '/empty' do
  haml :empty
end

get '/bag/:t/:id' do |t, id|
  @t = t
  @id = id
  haml :bag
end

get '/style.css' do
  sass :style
end

enable :inline_templates

__END__

@@ layout
%html
  %head
    %link{:href=>'/style.css', :rel => 'stylesheet', :type => "text/css"}
  %body
    = yield

@@ page
#menu
  %ul
    %li
      %a{ :href => "/all" } A
    %li
      %a{ :href => "/empty" } E

    -if @n > 0
      %li
        %a{ :href => "/page/0" } <<
    - if @hasless
      %li
        %a{ :href => "/page/#{@n - @win}" } <

    - for i in @min .. @n-1
      %li
        %a{ :href => "/page/#{i}" }=i

    %li
      =@n

    - for i in @n+1 .. @max
      %li
        %a{ :href => "/page/#{i}" }=i

    - if @hasmore
      %li
        %a{ :href => "/page/#{@n + @win}" } >
    - if @n < @last
      %li
        %a{ :href => "/page/#{@last}" } >>

  %br{ :clear => 'left' }

- list_nonempty_bags_by_page(@gap, @n) do |r|
  %p
    %a{ :href => "/bag/#{$dim}/#{r[:bag_id]}" }
      =r[:dir].sub %r{.*/([^/]+/[^/]+/[^/]+)}, '\1'

- c = Time.new.to_f
- puts "X: #{@x - @a}\nB: #{@b - @a}\nC: #{c - @a}"

@@ bag
#menu
  %ul
    %li
      %a{ :href => '/' } ^
    %li
      %a{ :href => "/bag/hi-res/#{@id}" } hi
    %li
      %a{ :href => "/bag/840x630/#{@id}" } mid
    %li
      %a{ :href => "/bag/600x450/#{@id}" } low
  %br{ :clear => 'left' }

- list_files_with_type(@t, @id) do |r|
  %img{ :src => (link_file r[:repo_path]) }

@@ all
%a{ :href => '/' } Up
%p="Total: #{count()}"
%p="Nao vazio: #{count_bags_nonempty()}"
%p="Vazio: #{count_bags_empty()}"
- $db.fetch("select bag_id, dir from bag") do |r|
  %p
    %a{ :href => "/bag/#{$dim}/#{r[:bag_id]}" }
      =File.basename r[:dir]

@@ empty
%a{ :href => '/' } Up
- list_empty_bags do |r|
  %p
    %a{ :href => "/bag/#{$dim}/#{r[:bag_id]}" }
      =File.basename r[:dir]

@@ style
#menu
  width: 100%
  margin: 1em 0
  padding: 0px 0.5em
  background: #eee none

  padding: 0
  background: #fff none
  font-family: DejaVu Sans
  font-size: 105%
  ul
    margin: 0
    padding: 0
    list-style-type: none

  li

    margin: 0
    padding: 0
    float: left

    width: 2.3em
    margin-right: 0.1em
    background: #eee none
    text-align: center
  a
    display: block
    width: 100%
    text-decoration: none
  a:hover
    background: #ff9 none
