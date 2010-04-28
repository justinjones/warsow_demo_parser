class Assets < Application
  
  def show(id)
    @asset = Asset[id]
    raise NotFound unless @demo
    send_file(@asset.full_filename, :filename => @asset.filename, :type => @asset.content_type)
    File.read(@asset.full_filename)
  end
  
  def create(asset)
    only_provides :xml, :yaml
    
    @asset = Asset.new(asset)
    
    if @asset.save
      display(@asset)
    else
      display(@asset.errors)
    end
  end
end
  