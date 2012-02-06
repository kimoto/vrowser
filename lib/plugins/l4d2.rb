class Vrowser
  def self.recommend_game_type(info)
    server_name = info.server_name
    game_type = info.suggest_game_type
    if game_type != 'unknown'
      return game_type
    end

    if server_name =~ /co\-?op/i
      return 'coop'
    elsif server_name =~ /scavenge/i
      return 'scavenge'
    elsif server_name =~ /survival/i
      return 'survival'
    elsif server_name =~ /realism/i
      return 'realism'
    elsif server_name =~ /versus/i
      return 'versus'
    elsif server_name =~ /hard(eight|six|twelve)/i
      return 'coop'
    elsif server_name =~ /(exp(ert)?|advance|easy|normal)/i
      return 'coop'
    elsif server_name =~ /RPG/
      return 'coop'
    elsif server_name =~ /4vs4/i
      return 'versus'
    elsif server_name =~ /vs/i
      return 'versus'
    elsif server_name =~ /team/i
      return 'versus'
    elsif server_name =~ /confogl/i
      return 'versus'
    elsif server_name =~ /fresh(\s*config)?/i
      return 'versus'
    elsif server_name =~ /skullsaba/i
      return 'versus'
    elsif server_name =~ /S A M U R A i/i
      return 'versus'
    elsif info.number_of_max_players == '4'
      return 'coop'
    elsif info.number_of_max_players == '8'
      return 'versus'
    else
      return 'unknown'
    end
  end

  def self.before_update(server_info)
    server_info.game_type = recommend_game_type(server_info)
    server_info
  end
end
