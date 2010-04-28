class Maps < Application
  
  def index
    @maps = Map.all
    display @maps
  end
  
  def show(id)
    @map = Map[id]
    @demos = Demo.all(:map_id => id)
    raise NotFound unless @map
    display @map
  end
  
end
