

class String
  def f_yaml
    return YAML::load(self)
  end
end


class MemcachedbQ
  
  
  attr_accessor :cache_db
  attr_accessor :que_name
  attr_accessor :name_space
  
  def initialize(name, name_space)
    @name_space = name_space.to_s
    @cache_db = MemCacheDb.new 'localhost:21201', :namespace => "#{@name_space}"
    @que_name = name.to_s
  end
  
  def add(data, que_time = Time.now)
    key = "#{@que_name}#{que_time.to_f.to_s.gsub(/\./,"")}#{rand(9999)}"
    @cache_db.set(key, data.to_yaml)
    return key
  end
  
  def remove(key)
    @cache_db.delete(key)
  end
  
  def next
    item = @cache_db.get_range("#{@que_name}", "#{@que_name}#{Time.now.to_f.to_s}~", 0, 1, 1)
    begin
      data = item[item.keys[0]].f_yaml
      self.remove(item.keys[0])
      return data
    rescue
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
  
  
end