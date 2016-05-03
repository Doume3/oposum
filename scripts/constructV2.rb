re 'rubygems'
require 'json'

file = File.read('configV2.json')
data = JSON.parse(file)

def getPortServeur(data, nomVM, nomAPP)
	data["apps"].each do |app|
		if app["nomApp"] == nomAPP AND app["typeApp"] == "serveur"
			return app["port"]
		end
	end
	return false
end

data["apps"].each do |app|
	print "\n"
	for numVM in 1..app["nbVMs"]
		puts "### Création de la machine virtuelle '#{app["nomVMs"]}#{numVM}'"
		resVM = system("./VMSetup.sh \"#{app["typeVMs"]}\" \"#{app["nomVMs"]}#{numVM}\"")
		if resVM != false
			puts "### Machine virtuelle créée avec succès (#{app["nomVMs"]}#{numVM})"
			puts "### Installation de l'application '#{app["nom"]}'"
			if app["typeApp"] == "serveur"
		        	resApp = system("./appSetup.sh \"#{app["nomVMs"]}#{numVM}\" \"#{app["nomApp"]}\" \"#{app["typeApp"]}\" \"../apps/#{app["nomApp"]}\" \"#{app["parametresApp"]}\"")
        		else
				portServeur = getPortServeur(data, app["serveur"], app["nom"])
				resApp = system("./appSetup.sh \"#{app["nomVMs"]}#{numVM}\" \"#{app["nomApp"]}\" \"#{app["typeApp"]}\" \"../apps/#{app["nomApp"]}\" \"#{app["parametresApp"]}\"")
			end
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
