vaclass Asset
  include DataMapper::Resource
  
  property :size,                     Integer
  property :content_type,             String
  property :filename,                 String
  property :demo_id,                  Integer
  
  validates_present :filename, :content_type, :size
  after :create, :move_tempfile
  belongs_to :demo

  def uploaded_data=(file_data)
    return nil if file_data.nil? || file_data['size'] == 0
    self.content_type = file_data['content_type']
    self.size         = file_data['size']
    @file = file_data['tempfile']
  end
  
  def full_filename
    Merb.root + "/demos/#{self.id}/#{self.filename}"
  end
  
  def filename_from_demo
    [ 'DS', demo.players.join('_vs_'), demo.map.name ].join('_') + ".wd#{demo.protocol}"
  end
  
  protected
  def move_tempfile
    FileUtils.mkdir_p Merb.root + "/demos/#{self.id}"
    FileUtils.mv @file.path, Merb.root + "/demos/#{id}/#{self.filename_from_demo}"
  end
end