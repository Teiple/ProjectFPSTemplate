class_name DisjointDataSetNode

var data
var parent
var rank : int
	
func _init(dat):
	data = dat
	parent = self
	rank = 0
