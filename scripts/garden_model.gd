class_name GardenModel
extends RefCounted
var store: SaveStore

func _init(save: SaveStore): store = save

func state() -> Dictionary:
	return store.active().minigames.G01

func available_cells() -> int:
	return [3,6,16][clampi(int(state().level),0,2)]

func plant(cell: int, seed: int) -> bool:
	if cell < 0 or cell >= available_cells() or seed < 0 or seed > 2: return false
	state().plots[str(cell)] = seed
	state().grown = false
	store.persist()
	return true

func rotate_pipe(index: int) -> bool:
	if index < 0 or index > 2: return false
	state().pipes[index] = (int(state().pipes[index])+1)%4
	state().grown = false
	store.persist()
	return true

func connected() -> bool:
	return state().pipes.size() == 3 and int(state().pipes[0]) % 2 == 0 and int(state().pipes[1]) % 2 == 0 and int(state().pipes[2]) % 2 == 0

func grow() -> bool:
	if state().plots.size() < 3 or not connected(): return false
	state().grown = true
	store.persist()
	return true

func keep(slot: int) -> bool:
	if not state().grown or slot < 0 or slot > 2: return false
	while state().arrangements.size() <= slot: state().arrangements.append({})
	var arrangement = {"plots":state().plots.duplicate(true),"level":state().level}
	state().arrangements[slot] = arrangement
	store.active().houses.house_01.flowers = arrangement.duplicate(true)
	store.persist()
	return true

func load_arrangement(slot: int) -> bool:
	if slot < 0 or slot >= state().arrangements.size() or state().arrangements[slot].is_empty(): return false
	var arrangement = state().arrangements[slot]
	state().plots = arrangement.plots.duplicate(true)
	state().level = arrangement.level
	state().pipes = [0,0,0]
	state().grown = true
	store.active().houses.house_01.flowers = arrangement.duplicate(true)
	store.persist()
	return true

func new_bed() -> void:
	state().level = mini(2,int(state().level)+1)
	state().plots = {}
	state().pipes = [1,2,3]
	state().grown = false
	store.persist()
