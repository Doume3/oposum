require 'rubygems'
require 'json'

file = File.read('config.json')
data = JSON.parse(file)


applications = ["chat", "FTP"]

data["vms"].each do |vm|
	puts "\n"
	puts "### Création de la machine virtuelle '#{vm["nom"]}'"
	res = system("./VMSetup.sh \"#{vm["type"]}\" \"#{vm["nom"]}\"")
	if res != false
		vm.each do |proprietes, value|
			if proprietes == "apps"
				value.each do |app|
					puts "\n"
					path = ""
					if app["personnel"] == "true"
						path = app["path"]
					else
						if applications.include? app["nom"]
							path = "~/app/#{app["nom"]}/#{app["type"]}.c"
						else
							abort("L'application #{app["nom"]} est inconnu")
						end
					end
					puts "### Installation de l'application '#{app["nom"]}'"
					puts `echo './appSetup.sh "#{vm["nom"]}" "#{app["nom"]}" "#{app["type"]}" "#{app["port"]}" "#{path}"'`
				end
			end
		end
	end
	puts "\n\n"
end
puts "\n"
