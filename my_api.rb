session = WarsowDemoUpload.new('username', 'password')

demo = {
  :gametype => 'duel',
  :map => 'wdm5',
  :winner => {
    :name => 'nagash',
    :score => 10
  },
  :loser => {
    :name => 'beatrn',
    :score => 8
  },
  :players => [ 
    {
      :name => 'nagash'
    },
    {
      :name => 'beastrn'
    }
  ]
  :file => FileResource.new('filename', 'file-contents')
}
session.demos.create(demo) (or .new and then .save)
=> demo.xml

session.demos[1].map = 'wdm3'
session.demos[1].update (or .save)

