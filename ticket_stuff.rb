{ 
  :zoo => {
    :name => 'Los Angeles Zoo',
    :animals => [
      { :name => 'Lion' },
      { :name => 'Tiger' }
    ]
  }
}.to_xml

# Should return something along the lines of:
#
# <zoo>
#   <name>Los Angeles Zoo</name>
#   <animals>
#     <animal>
#       <name>Lion</name>
#     </animal>
#     <animal>
#       <name>Tiger</name>
#     </animal>
#   </animals>
# </zoo>

# Hash.from_xml() on the same string gives:
=> {"zoo"=>{"name"=>"Los Angeles Zoo", "animals"=>{"animal"=>[{"name"=>"Lion"}, {"name"=>"Tiger"}]}}}
# It should be "animals"=>[The array] instead of "animals"["animal"]=>[The array]

# Also, nil case is not handled correctly
Hash.from_xml('<name type="integer"></name>')
=> {"name"=>{"type"=>"integer"}} # Should be {"name"=>nil}


