class_name DisjointDataSet

var nodes : Dictionary = {}


func contains_data(dat) -> bool:
	return nodes.has(dat)


func make_set(dat) -> bool:
	if contains_data(dat):
		return false
	
	nodes[dat] = DisjointDataSetNode.new(dat)
	return true


func union(dat_a, dat_b) -> bool:
	var node_a = nodes[dat_a]
	var node_b = nodes[dat_b]
	
	var parent_a = node_a.parent
	var parent_b = node_b.parent
	
	if parent_a == parent_b:
		return false
	
	if parent_a.rank >= parent_b.rank:
		if parent_a.rank == parent_b.rank:
			parent_a.rank += 1
		
		parent_b.parent = parent_a
	else:
		parent_a.parent = parent_b
	
	return true


func _find_set(node : DisjointDataSetNode) -> DisjointDataSetNode:
	var parent = node.parent
	if parent == node:
		return node
	
	node.parent = _find_set(node.parent)
	return node.parent


func find_set(dat):
	return _find_set(nodes[dat]).data


func is_empty() -> bool:
	return nodes.empty()


func clear():
	nodes.clear()


func get_all_sets():
	var sets = {}
	for dat in nodes.keys():
		var presentative = find_set(dat)
		if !sets.has(presentative):
			sets[presentative] = []
		sets[presentative].push_back(dat)
	return sets.values()
