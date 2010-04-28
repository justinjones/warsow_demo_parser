class Players < Application
  
  def index
    @players = Player.all(:order => 'rating DESC, demos_count DESC')
    display @players
  end
  
  def show(id)
    @player = Player[id]
    raise NotFound unless @player
    @demos = @player.demos
    display @player
  end
  
end
