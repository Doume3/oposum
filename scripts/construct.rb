require 'rubygems'
require 'json'

file = File.read('config.json') # close le file ?
data = JSON.parse(file)

def getPortServeur(data, nomVM, nomAPP)
	data["vms"].each do |vm|
		if vm["nom"] == nomVM
			vm["apps"].each do |app|
				if app["nom"] == nomAPP and app["type"] == "serveur"
					return app["port"]
				end
			end
		end
	end
	return false
end

data["vms"].each do |vm|
	print "\n"
	for numVM in 1..vm["nombreCopie"]
		puts "### Création de la machine virtuelle '#{vm["nom"]}#{numVM}'"
		resVM = system("./VMSetup.sh \"#{vm["type"]}\" \"#{vm["nom"]}#{numVM}\"")
		if resVM != false
			puts "### Machine virtuelle créée avec succès (#{vm["nom"]}#{numVM})"
			vm["apps"].each do |app|
				print "\n"
				if app["publique"] == true
					rep = "pub" 
				else
					rep = "pers"
				end
				if File.directory?("../apps/#{rep}/#{app["nom"]}") == true
					puts "### Installation de l'application '#{app["nom"]}'"
					if app["type"] == "serveur"
		         			resApp = system("./appSetup.sh \"#{vm["nom"]}#{numVM}\" \"#{app["nom"]}\" \"#{app["type"]}\" \"../apps/#{rep}/#{app["nom"]}\" \"#{app["port"]}\"")
        				else
						portServeur = getPortServeur(data, app["serveur"], app["nom"])
						resApp = system("./appSetup.sh \"#{vm["nom"]}#{numVM}\" \"#{app["nom"]}\" \"#{app["type"]}\" \"../apps/#{rep}/#{app["nom"]}\" \"#{app["portServeur"]}\" \"#{serveur}\"")
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
		else
			puts "### Une erreur est survenue, la machine virtuelle (#{vm["nom"]}#{numVM}) n'a pas été créée"
		end
		print "\n\n"
	end
end
print "\n"
