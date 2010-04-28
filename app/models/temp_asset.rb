class TempAsset  
  include DataMapper::Resource
  
  property :filename,           String
  property :content_type,       String
  property :original_filename,  String
  property :size,               Integer
  
  validates_present :filename, :content_type, :original_filename, :size
  validates_is_number :size, :only_integer => true
  
  def uploaded_data=(file_data)
    return nil if file_data.nil? || file_data['size'] == 0
    self.content_type = file_data['content_type']
    self.original_filename = file_data['filename']
    self.size = file_data['size']
    self.filename = File.basename(file_data['tempfile'].path)
  end
end    