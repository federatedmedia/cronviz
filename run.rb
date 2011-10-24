require 'rubygems'
require 'json'
require 'haml'

require 'lib/crontab'
require 'lib/cron_job'
require 'lib/cron_parser'


EVENT_DATA = {
  :default => {
    "color"       => "#7FFFD4",
    "textColor"   => "#000000",
    "classname"   => "default",
    "durationEvent" => false},

  :every_minute => {
    "title_prefix"  => "Every minute: ",
    "color"         => "#f00",
    "durationEvent" => true},

  :every_five_minutes => {
    "title_prefix"  => "Every five minutes: ",
    "color"         => "#fa0",
    "durationEvent" => true}
}


def main
  earliest_time = "2011-10-17 00:00"
  latest_time   = "2011-10-17 23:59"

  json = Cronviz::Crontab.new(:earliest_time=>earliest_time, :latest_time=>latest_time, :event_data=>EVENT_DATA).to_json
  haml = open("assets/container.haml").read
  html = Haml::Engine.new(haml).render(Object.new,
                                       :earliest_time => earliest_time,
                                       :latest_time   => latest_time,
                                       :cron_json     => json)                                       

  open("output.html", "w") do |f|
    f.write html
  end

end

main()
