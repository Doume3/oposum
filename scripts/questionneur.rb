#!/bin/ruby
@user = ENV['USER']

@applis = {}

def ajouter_app(chemin)
    "Depuis votre laptop faire : \nscp -p -r chemin @user@access.grid5000.fr:\$site:xp5k-openstack/oposum/apps/priv\n"
end

loop do 
    print "Quelles applications souhaitez vous déployer parmi : \n"
    %x{ls ~/xp5k-openstack/oposum/apps/pub}
    app = gets.chomp
    exit -1 unless reponse
    
    print "Combien de #{app} souhaitez vous démarrer ? : \n"
    nb = gets.chomp.to_i
    @applis[app] = nb
    
    
    #TODO: Se vider dans le JSON
    
    
    
    print "Souhaitez vous déployer d'autres applications ? (vide sinon) : "
  break if gets.chomp == ""
end
