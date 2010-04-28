class Demos < Application
  #before :login_required, :only => %w(new create edit update destroy)
  #before :api_login_required # only run when content_type != :xml
  
  provides :html, :xml, :yaml
  
  def index
    @demos = Demo.all
    @popular_players = Player.popular
    @popular_demos = Demo.popular
    display @demos
  end
  
  def show(id)
    @demo = Demo[id]
    @other_demos = []
    @demo.players.each do |player|
      @other_demos = player.demos.to_a if @other_demos.empty?
      @other_demos = @other_demos & player.demos.to_a
    end
    @other_demos = @other_demos - [ @demo ]
    raise NotFound unless @demo
    display @demo
  end
  
  def new
    only_provides :html
    @demo = Demo.new
    display @demo
  end
  
  def create(demo)
    @demo = Demo.new(demo)
    if @demo.save
      content_type == :html ? redirect(url(:demo, @demo)) : display(@demo)
    else
      content_type == :html ? render(:new) : display(@demo.errors)
    end
  end
  
  def edit(id)
    only_provides :html
    @demo = Demo[id]
    raise NotFound unless @demo
    display @demo
  end
  
  def update(id, demo)
    @demo = Demo[id]
    raise NotFound unless @demo
    if @demo.update_attributes(demo)
      content_type == :html ? redirect(url(:demo, @demo)) : display(@demo)
    else
      content_type == :html ? render(:edit) : display(@demo.errors)
    end
  end
  
  def destroy(id)
    @demo = Demo[id]
    raise NotFound unless @demo
    if @demo.destroy!
      content_type == :html ? redirect(url(:demos)) : nil
    else
      raise BadRequest
    end
  end
  
  def upload # Api Upload
    tempfile = Tempfile.new(:Merb) << request.raw_post
    tempfile.rewind
    @demo = Demo.from_demo_reader(tempfile.path)
  end
  
  def download
    @demo = Demo[params[:id]]
    @demo.increment_downloads
    
    send_file(@demo.full_filename)
    File.read(@demo.full_filename)
  end
end