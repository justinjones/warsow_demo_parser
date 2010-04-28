class DuelMatch
  def initialize(players)
    @players = players
    
    games
    build_stats
  end
  
  def games
    @games ||= (@players.first.demos & @players.last.demos)
  end
  
  def build_stats
    @players.each do |player|
      @games.each do |game|
        unless game.draw?
          player.stats.wins += 1 if game.winner == player
          player.stats.losses += 1 if game.loser == player
        else
          player.stats.draws += 1
        end

        game.scores.each do |score|
          player.stats.frags_for += score if score.player == player
          player.stats.frags_against += score unless score.player == player
        end
      end
    end
  end      
end