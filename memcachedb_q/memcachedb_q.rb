

class String
  def f_yaml
    return YAML::load(self)
  end
end


class MemcachedbQ
  
  CACHE_DB = MemCacheDb.new 'localhost:21201', :namespace => 'cart'
  
  attr_accessor :que_name
  
  def initialize(name)
    @que_name = name.to_s
  end
  
  def add(data, que_time = Time.now)
    CACHE_DB.set("#{@que_name}-#{que_time.to_f.to_s}-#{rand(9999)}", data.to_yaml)
  end
  
  def remove(key)
    CACHE_DB.delete(key)
  end
  
  def next
    item = CACHE_DB.get_range("#{@que_name}", "#{@que_name}-#{Time.now.to_f.to_s}~", 0, 1, 1)
    if item
      data = item[item.keys[0]].f_yaml
      self.remove(item.keys[0])
      return data
    else
      nil
    end
  end
  
  def get_que
    totalque = {}
    temp_que = CACHE_DB.get_range("#{@que_name}", "#{@que_name}-#{Time.now.to_f.to_s}~")
    totalque.merge!(temp_que)
    while temp_que ? temp_que.length == 100 : false 
      temp_que = CACHE_DB.get_range("#{que.keys.sort.last}", "#{@que_name}-#{Time.now.to_f.to_s}~", 1)
      totalque.merge!(temp_que)
    end
    return totalque
  end
  
  def get_future_que
    totalque = {}
    temp_que = CACHE_DB.get_range("#{@que_name}-#{Time.now.to_f.to_s}", "#{@que_name}~", 1)
    totalque.merge!(temp_que)
    while temp_que ? temp_que.length == 100 : false 
      temp_que = CACHE_DB.get_range("#{que.keys.sort.last}", "#{@que_name}~", 1)
      totalque.merge!(temp_que)
    end
    return totalque
  end
  
  
end