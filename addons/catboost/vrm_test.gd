# MIT License
# 
# Copyright (c) 2020 K. S. Ernest (iFire) Lee & V-Sekai
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends Skeleton3D

@export
var catboost_path : String = "catboost"

@export 
var bones : Dictionary

func _ready():
	var catboost = load("res://addons/catboost/catboost.gd").new()
	var write_path = "catboost/test.tsv"
	catboost._write_import(self, true, write_path)
	var stdout = [].duplicate()
	var ret = OS.execute("CMD.exe", ["/C", "catboost calc -m catboost/model.bin --column-description catboost/test_description.txt --output-columns BONE,LogProbability --input-path %s --output-path stream://stdout --has-header" % [write_path]], stdout)	
	var bones : Dictionary
	for elem_stdout in stdout:
		var line : PackedStringArray = elem_stdout.split("\n")
		var keys : PackedStringArray
		var columns_first = line[0].split("\t")
		keys.resize(columns_first.size())
		for c in columns_first.size():					
			var key_name = columns_first[c]
			var split = key_name.split("=", true, 1)
			if split.size() == 1:
				keys[c] = split[0]
			else:
				keys[c] = split[1]
		line.remove_at(0)
		line.reverse()
		for i in line.size():
			var columns = line[i].split("\t")
			var bone_name : String
			for c in columns.size():
				if c == 0:
					bone_name = columns[c]
					continue
				var column_name : String = keys[c]
				var bone : Array
				if bones.has(column_name):
					bone = bones[column_name]
				var value = columns[c].pad_decimals(1).to_float()
				var probability = value
				bone.push_back([probability, bone_name])
				bones[column_name] = bone
	var seen : PackedStringArray
	var results : Array
	var non_results : Array
	for tolerance in range(5):
		for bone in bones.keys():
			bones.values().sort_custom(sort_desc)
			var values = bones[bone]
			for value in values:
				var vrm_name = value[1]
				var improbability = abs(value[0])
				if vrm_name == bone:
					break
				elif seen.has(bone) or seen.has(vrm_name):
					continue
				elif not catboost.vrm_humanoid_bones.has(bone):
					continue
				elif improbability >= (tolerance * 0.4):
					continue
				results.push_back([bone, improbability, vrm_name])				
				seen.push_back(vrm_name)
				seen.push_back(bone)
	for tolerance in range(20):
		for bone in bones.keys():
			bones.values().sort_custom(sort_desc)
			var values = bones[bone]
			for value in values:
				var vrm_name = value[1]
				var improbability = abs(value[0])
				if vrm_name == bone:
					break
				elif seen.has(bone) or seen.has(vrm_name):
					continue
				elif not catboost.vrm_humanoid_bones.has(bone):
					continue
				elif improbability >= (tolerance * 0.4):
					continue
				non_results.push_back([bone, improbability, vrm_name])				
				seen.push_back(vrm_name)
				seen.push_back(bone)
	print("## Certain results.")
	for res in results:
		print("%s: improbability %s guessed %s" % res)
	print("Returned %d certain results" % [results.size()])
	print("## Uncertain results.")
	for res in non_results:
		print("%s: improbability %s guessed %s" % res)		
	print("Returned %d uncertain results" % [non_results.size()])
	if ret != 0:
		print("Catboost returned " + str(ret))
		return null

func sort_desc(a, b):
	if a[0] > b[0]:
		return true
	return false
