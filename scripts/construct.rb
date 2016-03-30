require 'rubygems'
require 'json'

file = File.read('config.json') # close le file ?
data = JSON.parse(file)


applicationsDispo = ["chat", "FTP"]

data["vms"].each do |vm|
	print "\n"
	puts "### Création de la machine virtuelle '#{vm["nom"]}'"
	resVM = system("./VMSetup.sh \"#{vm["type"]}\" \"#{vm["nom"]}\"")
	if resVM != false
		puts "### Machine virtuelle créée avec succès (#{vm["nom"]})"
		vm.each do |proprietes, value|
			if proprietes == "apps"
				value.each do |app|
					print "\n"
					if app["publique"] == true
						rep = "pub" 
					else
						rep = "pers"
					end
					if File.directory?("../apps/#{rep}/#{app["nom"]}") == true
						puts "### Installation de l'application '#{app["nom"]}'"
						if app["type"] == "serveur"
	                        resApp = system("./appSetup.sh \"#{vm["nom"]}\" \"#{app["nom"]}\" \"#{app["type"]}\" \"#{app["port"]}\" \"../apps/#{rep}/#{app["nom"]}\"")
        				else
							resApp = system("./appSetup.sh \"#{vm["nom"]}\" \"#{app["nom"]}\" \"#{app["type"]}\" \"#{app["portServeur"]}\" \"../apps/#{rep}/#{app["nom"]}\" \"#{app["IPServeur"]}\"")
						end
	                	    if resApp != false
                	            puts "### Application installée avec succès (#{app["nom"]})"
           	                else
                                puts "### Une erreur est survenue, l'application (#{app["nom"]}) n'a pas été installée"
                            end
					else
						puts "### Application introuvable"
					end
				end
			end
		end
	else
		puts "### Une erreur est survenue, la machine virtuelle (#{vm["nom"]}) n'a pas été créée"
	end
	print "\n\n"
end
print "\n"
