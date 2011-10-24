module Cronviz
  class CronJob
    attr_reader :events, :command, :times

    # Take a hash describing a job and massage its contents to produce
    # event data for the SIMILE timeline widget.
    def initialize options
      @times      = options[:times]
      @command    = options[:command]
      @event_data = options[:event_data]
      merge_event_data options
    end

    def merge_event_data options
      @events = []
      
      if @event_data.keys.include? options[:times].size
        # Rollup */1 and */5 jobs into a single job for display purposes.
        seed = @event_data[options[:times].size]
        data = {
          "start"       => options[:times][0].iso8601,
          "end"         => options[:times][-1].iso8601,
          "title"       => "#{seed['title_prefix']}#{@command}",
          "description" => "#{seed['title_prefix']}#{@command}"}
        @events = [@event_data[:default].merge(seed).merge(data)]
      else
        options[:times].each do |time|
          data = {
            "start"       => time.iso8601,
            "title"       => "%02d:%02d %s" % [time.hour, time.min, @command],
            "description" => @command}
          @events << @event_data[:default].merge(data)
        end
      end    
    end
    
  end
end
