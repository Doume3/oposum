require 'rubygems'
require 'json'

file = File.read('config.json')
data = JSON.parse(file)

data["apps"].each do |app|
	print "\n"
	for numVM in 1..app["nbVMs"]
		puts "### Création de la machine virtuelle '#{app["nomVMs"]}#{numVM}'"
		resVM = system("./VMSetup.sh \"#{app["typeVMs"]}\" \"#{app["nomVMs"]}#{numVM}\"")
		if resVM != false
			puts "### Machine virtuelle créée avec succès (#{app["nomVMs"]}#{numVM})"
			puts "### Installation de l'application '#{app["nomApp"]}'"
			if app["typeApp"] == "client"
				tabParam = app["parametresApp"].split(/ /)
				tabParam.each do |param|
					if nomVM = param.match(/{{IPVM:(.+)}}/)
						puts "NOMVM : #{nomVM[1]}"
						adr = `rake roles:show | grep 'controller' | grep -o -E '[^: ]*\.grid5000\.fr'`
						puts "ADR : #{adr}"
						cmd = "ssh root@#{adr} 'source openstack-openrc.sh && nova list --name #{nomVM[1]}1' | grep -o -E '(10\.([0-9]{1,3}\.){2}[0-9]{1,3})'"
						puts "CMD : #{cmd}"
						ip = `#{cmd}`
						puts "IP : #{ip}"
						app["parametresApp"] = app["parametresApp"].gsub(/{{IPVM:.+}}/, ip)
						puts "PARAM : #{app["parametresApp"]}"
					end
				end
			end
			resApp = system("./appSetup.sh \"#{app["nomVMs"]}#{numVM}\" \"#{app["nomApp"]}\" \"#{app["typeApp"]}\" \"#{app["parametresApp"]}\"")
			if resApp != false
        	      		puts "### Application installée avec succès (#{app["nomApp"]})"
        	   	else
        	               	puts "### Une erreur est survenue, l'application (#{app["nomApp"]}) n'a pas été installée"
        	        end
		else
			puts "### Une erreur est survenue, la machine virtuelle (#{app["nomVMs"]}#{numVM}) n'a pas été créée"
		end
		print "\n\n"
	end
end
print "\n"
