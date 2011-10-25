require 'time'

DEFAULT_FILE = "crontab"


module Cronviz
  class Crontab
    attr_reader :jobs
    
    def initialize options={}
      @earliest_time = options[:earliest_time]
      @latest_time   = options[:latest_time]
      @input         = options[:input] || DEFAULT_FILE

      prepare_event_data options[:event_data]

      @jobs = []
      get_lines { |line| @jobs << line_to_jobs(line) }
    end

    # Find out how many minutes there are between the two times user specified
    # so that CronJob can roll up every-X-minute jobs even for unusual periods.
    def prepare_event_data event_data
      # Subtracting a minute from @earliest_time via - 60 because
      # we're not trying to determine a difference between two times,
      # but rather a duration across them, so avoid the off-by-one.
      # That is, 1:05 - 1:01 gives us :04, when really there are 5
      # whole minutes to consider, since execution happens at the
      # start of each -- :01, :02, :03, :04, :05.
      num_minutes = (((Time.parse(@latest_time)) - (Time.parse(@earliest_time) - 60)) / 60).to_i

      # Minutes is easy because it's cron's finest level of granularity.
      # Five minutes is a bit different since cron doesn't fire,
      # e.g. "every five minutes" so much as "on the minutes marked
      # :00, :05, :10", etc. So if user has passed in a
      # non-evenly-divisible start or start period, we have to know
      # not the quantity of minutes contained, but which particular
      # intervals are inside the earliest/latest times. We get this
      # by doing a mini-cronparse call for */5 minutes.
      h = Hash.new.tap do |h|
        h[:mi] = Cronviz::CronParser.expand(:mi, "*/5")
        [:ho, :da, :mo, :dw].each do |k| # * the remaining fields.
          h[k] = Cronviz::CronParser.expand(k, "*")
        end
      end
      num_five_minutes = fan_out(h).size

      # We now know how many minute and five-minute intervals are in
      # the user's selected period. Merge that in event_data so that
      # we can roll these periods up along with whatever custom
      # settings they've defined.
      @event_data = event_data.merge(num_minutes      => event_data[:every_minute],
                                     num_five_minutes => event_data[:every_five_minutes])
    end
    
    def get_lines
      # Allow a filepath or a string of cron jobs to be passed in.
      # If nothing passed in, default to filename DEFAULT_FILE in the
      # working directory.
      # If that doesn't exist, raise and exit.
      begin
        open @input
      rescue Errno::ENOENT
        raise "Defaulted to ./crontab but no such file found!" if @input == DEFAULT_FILE
        @input
      end.each_line do |x|
        yield x.chop if x.strip.match /^[\*0-9]/
      end
    end

    # Turn a cronjob line into a command and list of occurring times.
    def line_to_jobs line
      elements = {}

      # minute hour day month dayofweek command
      mi, ho, da, mo, dw, *co = line.split
      {:mi => mi, :ho => ho, :da => da, :mo => mo, :dw => dw}.each_pair do |k, v|
        elements[k] = CronParser.expand(k, v)
      end

      CronJob.new(:command => co, :times => fan_out(elements), :event_data => @event_data)
    end

    # Accept a blueprint of a job as an exploded list of time elements,
    # and return any qualifying times as Time objects.
    # minutes=[15,45] hours=[4] => [Time(4:15), Time(4:45)]
    # day-of-week is a filter on top of the day field, so we filter by
    # it but do not iterate over it.
    def fan_out els
      good = []

      # "2011-...", "2011-..." => [2011]
      years = (@earliest_time.split("-")[0].to_i..@latest_time.split("-")[0].to_i).to_a

      years.each do |ye|
        els[:mo].each do |mo|
          els[:da].each do |da|
            els[:ho].each do |ho|
              els[:mi].each do |mi|
                good << Time.parse("#{ye}-#{mo}-#{da} #{ho}:#{mi}") if date_in_bounds?(ye, mo, da, ho, mi)
              end
            end
          end
        end
      end
      apply_weekday_filter(good, els[:dw])
    end

    def date_in_bounds? ye, mo, da, ho, mi
      # Comparing dates element-wise in string form turns out to be
      # like 6x faster than casting to DateTime objects first... so, don't.
      date = "%s-%02d-%02d %02d:%02d" % [ye, mo, da, ho, mi]
      @earliest_time <= date and date <= @latest_time
    end

    def apply_weekday_filter dates, filter
      # Avoid comparison if we can.
      dates.reject! {|d| !filter.include? d.wday } unless filter.size == 7
      dates
    end
    
    def to_json(*a)
      events = []
      @jobs.each do |job|
        job.events.each do |event|
          events << event
        end
      end
      {"dateTimeFormat" => "iso8601", "events" => events.sort_by {|x| x['title']}}.to_json
    end
  end
end
