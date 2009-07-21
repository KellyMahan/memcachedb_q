namespace :que do    
    desc "Start up needed ques."    
    task :run => :environment do
      config = YAML.load_file('config/que.yml')
      ques = config["rakeques"]
      ques.each do |qname|
        q = MemcachedbQ.new(qname)
        q.run
      end
    end
    
    
    
    desc "Continuously checks the ques "
    task :start => :environment do
      
      config = YAML.load_file('config/que.yml')
      ques = config["rakeques"]
      #repeater = config["repeater"] ?  : nil
        
      while true
        ques.each do |qname|
          q = MemcachedbQ.new(qname)
          q.run
          sleep 10
        end
      end
    end
end
