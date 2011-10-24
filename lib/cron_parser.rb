module Cronviz
  class CronParser
    # Syntax respected:
    # N      Integer
    # N,N,N  Set
    # N-N    Range inclusive
    # *      All
    # */N    Every N

    # Syntax TODO
    # jan-dec
    # sun-sat
    # @yearly @monthly @weekly @daily @hourly

    # Syntax WONTDO
    # ? L W #

    # Syntax CANTDO
    # @reboot

    # Disregarding http://en.wikipedia.org/wiki/Cron on...
    # Use of sixth field as year value
    # Loose match on *either* field when both day of month and day of week are specified.

    # Expand cron syntax to the corresponding integers, return as iterable.
    def self.expand field, interval
      case
      when interval == interval[/\d+/] # Passed "N" form? We're done.
        [interval.to_i] 
      when interval[/,/] # 6,7
        interval.split(",").map(&:to_i)
      when interval[/-/] # 1-5
        start, stop = interval.split("-").map(&:to_i)
        start.step(stop).to_a
      else # "*" or "*/17"
        expand_recurring field, interval
      end
    end

    # Expand "*" and "*/N" forms, producing collections of integers.
    # Cron interprets "*/17" to include 0, giving us occurrences on
    # :0, :17, :34, :51
    def self.expand_recurring field, interval
      if interval == "*"
        interval = 1
      else
         interval = interval[/\d+/].to_i # Nix any leading "*/".
      end
      case field # :mi, 17 => [0, 17, 34, 51]
      when :mi then 0.step(59, interval)
      when :ho then 0.step(23, interval)
      when :da then 1.step(31, interval)
      when :mo then 1.step(12, interval)
      when :dw then 0.step(6,  interval)
      end.to_a        
    end
  end
end
