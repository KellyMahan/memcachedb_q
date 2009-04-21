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
end
