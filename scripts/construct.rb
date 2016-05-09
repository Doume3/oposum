require 'rubygems'
require 'json'
require 'colorize'

file = File.read('config.json')
data = JSON.parse(file)

data["apps"].each do |app|
	print "\n"
	for numVM in 1..app["nbVMs"]
		puts "###############################".blue
		puts "   VMSetup (#{app["nomVMs"]}#{numVM})".blue
		puts "###############################".blue
		resVM = system("./VMSetup.sh \"#{app["typeVMs"]}\" \"#{app["nomVMs"]}#{numVM}\"")
		if resVM != false
			puts "######################".blue
			puts "   appSetup (#{app["nomApp"]})".blue
			puts "######################".blue
			if app["typeApp"] == "client"
				tabParam = app["parametresApp"].split(/ /)
				tabParam.each do |param|
					if nomVM = param.match(/{{IPVM:(.+)}}/)
						adr = `rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`
						adr = adr.chomp
						cmd = "ssh root@#{adr} 'source openstack-openrc.sh && nova list --name #{nomVM[1]}1' | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'"
						ip = `#{cmd}`
						ip = ip.chomp
						app["parametresApp"] = app["parametresApp"].gsub(/{{IPVM:.+}}/, ip)
					end
				end
			end
			resApp = system("./appSetup.sh \"#{app["nomVMs"]}#{numVM}\" \"#{app["nomApp"]}\" \"#{app["typeApp"]}\" \"#{app["parametresApp"]}\"")
			if resApp == false
        	               	puts "### Une erreur est survenue, l'application (#{app["nomApp"]}) n'a pas été installée"
        	        end
		else
			puts "### Une erreur est survenue, la machine virtuelle (#{app["nomVMs"]}#{numVM}) n'a pas été créée"
		end
		print "\n##################################################\n".blue
	end
end
print "\n"
