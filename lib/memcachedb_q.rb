

class String
  def f_yaml
    return YAML::load(self)
  end
end

class MemcachedbQ
    
  include Spawn
    
  attr_accessor :cache_db
  attr_accessor :que_name
  attr_accessor :name_space
  attr_accessor :config
  attr_accessor :pid_key
  
  RUNNER_OPTIONS = [:run_time]
  
  def pid
    return self.get(@pid_key).f_yaml
  end
  
  def pid=(data)
    self.set(@pid_key, data.to_yaml)
  end
  
  def add_runner(qclass, method, *data)
    options = data.extract_options!
    begin
      if options[:run_time]
        
        options[:run_time] = starting_runtime(options[:run_time], options[:repeats])
        key = self.add(
          {
            :class=>qclass,
            :method=>method,
            :data=>data,
            :options=>options
          },
          options[:run_time]
        )
        if options[:repeat_name]
          set("repeat_#{options[:repeat_name]}", key)
        end
      else
        key = self.add(
          {
            :class=>qclass,
            :method=>method,
            :data=>data,
            :options=>options
          }
        )
      end
      return key
    rescue
      puts "************* memcache_q error: skipping que"
      puts "#{qclass.to_s.camelize}.send(#{method},#{data})"
      eval(qclass.to_s.camelize).send(method, *data)
    end
  end
  
  def running?
    begin
      Process::kill(0, pid)
      return true
    rescue
      return false
    end
  end
  
  def run
    unless running?
      if data = self.next
        spawnid = spawn do
          while data
            puts "********** memcachedb_q ***********\n\trunning: #{data[:class]}.#{data[:method]}\n"
            variables = data[:data]
            options = data[:options]
            begin
              if (repeats = options[:repeats]) && (get("repeat_#{options[:repeat_name]}") == data[:key])
                options[:run_time] = (options[:run_time]||Time.now) + repeats
                self.add_runner(data[:class].to_sym, data[:method].to_sym, :repeat_name=> options[:repeat_name], :repeats=>repeats, :run_time=>options[:run_time], *variables)
              else
                puts "keys don't match ignoring repeat"
              end
              eval(data[:class].to_s.camelize).send(data[:method], *variables)
            rescue => e
              puts "\t#{e.message}\n#{e.backtrace.join("\n")}"
            end
            data = self.next
            puts "********** memcachedb_q ***********"
          end
        end
        self.pid = spawnid.handle
      else
        return false
      end
    end
  end
  
  def initialize(name)
    @config = YAML.load_file('config/que.yml')
    @name_space = "#{@config["server"]["namespace"]}"
    @pid_key = "memcachedbqpidkey#{name}"
    @cache_db = MemCacheDb.new "#{@config["server"]["host"]}:#{@config["server"]["port"]}", :namespace => @name_space
    @que_name = name.to_s
  end
  
  def set(name, data)
    @cache_db.set(name, data.to_yaml)
  end
  
  def get(name)
    if g = @cache_db.get(name)
      return g.f_yaml
    else
      return nil
    end
  end
  
  def add(data, que_time = Time.now)
    if data
      key = "#{@que_name}#{que_time.to_f.to_s.gsub(/\./,"")}#{rand(9999)}"
      @cache_db.set(key, data.to_yaml)
      return key
    else
      return false
    end
  end
  
  def remove(key)
    @cache_db.delete(key)
  end
  
  def remove_all
    self.get_all.keys.each do |key|
      @cache_db.delete(key)
    end
  end
  
  
  alias :delete :remove
  
  
  def next
    item = @cache_db.get_range("#{@que_name}", "#{@que_name}#{Time.now.to_f.to_s}~", 0, 1, 1)
    begin
      if item != {}
        #puts item.class
        data = item[item.keys[0]].f_yaml
        data[:key] = item.keys[0]
        self.remove(item.keys[0])
        return data
      else
        return nil
      end
    rescue => e
      puts e.message
      puts e.backtrace.join("\n")
      nil
    end
  end
  
  def get_que
    totalque = {}
    temp_que = @cache_db.get_range("#{@que_name}", "#{@que_name}#{Time.now.to_f.to_s}~")
    totalque.merge!(temp_que)
    while temp_que ? temp_que.length == 100 : false 
      temp_que = @cache_db.get_range("#{totalque.keys.sort.last}", "#{@que_name}#{Time.now.to_f.to_s}~", 1)
      totalque.merge!(temp_que)
    end
    return totalque
  end
  
  def get_all
    totalque = {}
    temp_que = @cache_db.get_range("!", "~")
    totalque.merge!(temp_que)
    while temp_que ? temp_que.length == 100 : false 
      temp_que = @cache_db.get_range("#{totalque.keys.sort.last}", "~", 1)
      totalque.merge!(temp_que)
    end
    return totalque
  end
  
  def get_future_que
    totalque = {}
    temp_que = @cache_db.get_range("#{@que_name}#{Time.now.to_f.to_s}", "#{@que_name}~", 1)
    totalque.merge!(temp_que)
    while temp_que ? temp_que.length == 100 : false 
      temp_que = @cache_db.get_range("#{que.keys.sort.last}", "#{@que_name}~", 1)
      totalque.merge!(temp_que)
    end
    return totalque
  end
  
  def starting_runtime(runtime, repeats)
    return runtime if (runtime > Time.now) || (repeats==nil)
    x = ((Time.now-runtime)/repeats).to_i + 1
    return runtime+(repeats*x)
  end
  
end