class_name ProceduralMeshes
extends Object

## Fábricas de malhas procedurais usadas pela reforma visual.
## Todas devolvem ArrayMesh pronto para MeshInstance3D.
## Convenção de winding: o Godot considera frente o sentido horário visto de fora.


## Caixa com cantos e arestas arredondadas (superelipsoide).
## sharpness: 2.0 = esfera achatada, 6.0-10.0 = caixa com chanfro suave,
## valores altos aproximam uma caixa comum.
static func rounded_box(size: Vector3, sharpness: float = 6.0, segments: int = 20) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var exponent := 2.0 / clampf(sharpness, 1.05, 24.0)
	for ring in range(segments + 1):
		var v := float(ring) / float(segments)
		var phi := v * PI
		for col in range(segments + 1):
			var u := float(col) / float(segments)
			var theta := u * TAU
			var cos_t := cos(theta)
			var sin_t := sin(theta)
			var cos_p := cos(phi)
			var sin_p := sin(phi)
			var point := Vector3(
				half.x * signf(cos_t) * pow(absf(cos_t), exponent) * signf(sin_p) * pow(absf(sin_p), exponent),
				half.y * signf(cos_p) * pow(absf(cos_p), exponent),
				half.z * signf(sin_t) * pow(absf(sin_t), exponent) * signf(sin_p) * pow(absf(sin_p), exponent)
			)
			var normal := Vector3(
				signf(cos_t) * pow(absf(cos_t), 2.0 - exponent) * pow(absf(sin_p), 2.0 - exponent) / half.x,
				signf(cos_p) * pow(absf(cos_p), 2.0 - exponent) / half.y,
				signf(sin_t) * pow(absf(sin_t), 2.0 - exponent) * pow(absf(sin_p), 2.0 - exponent) / half.z
			).normalized()
			if not normal.is_finite() or normal.length_squared() < 0.25:
				normal = Vector3(0.0, signf(cos_p), 0.0)
			st.set_normal(normal)
			st.set_uv(Vector2(u, v))
			st.add_vertex(point)
	for ring in range(segments):
		for col in range(segments):
			var current := ring * (segments + 1) + col
			var below := (ring + 1) * (segments + 1) + col
			st.add_index(current)
			st.add_index(below)
			st.add_index(current + 1)
			st.add_index(current + 1)
			st.add_index(below)
			st.add_index(below + 1)
	return st.commit()


## Tubo ao longo de um caminho de pontos (cabos, puxadores, mangueiras, rodapés).
## Frames por transporte paralelo para não torcer ao longo do caminho.
static func tube(points: PackedVector3Array, radius: float, radial_segments: int = 10, caps := true) -> ArrayMesh:
	if points.size() < 2:
		return ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var tangents: Array[Vector3] = []
	for i in range(points.size()):
		var tangent: Vector3
		if i == 0:
			tangent = points[1] - points[0]
		elif i == points.size() - 1:
			tangent = points[i] - points[i - 1]
		else:
			tangent = points[i + 1] - points[i - 1]
		tangents.append(tangent.normalized())

	var reference := Vector3.UP if absf(tangents[0].dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var frame_normal := reference.cross(tangents[0]).normalized()
	# Cada anel guarda pares [índice do vértice, posição] — SurfaceTool não expõe contagem.
	var ring_data: Array = []
	var accumulated := 0.0
	var vertex_count := 0
	for i in range(points.size()):
		if i > 0:
			accumulated += points[i].distance_to(points[i - 1])
		var tangent: Vector3 = tangents[i]
		frame_normal = (frame_normal - tangent * frame_normal.dot(tangent))
		if frame_normal.length_squared() < 0.25:
			frame_normal = reference.cross(tangent)
		frame_normal = frame_normal.normalized()
		var binormal := tangent.cross(frame_normal).normalized()
		var ring: Array = []
		for s in range(radial_segments + 1):
			var angle := TAU * float(s) / float(radial_segments)
			var radial := frame_normal * cos(angle) + binormal * sin(angle)
			var vertex := points[i] + radial * radius
			st.set_normal(radial)
			st.set_uv(Vector2(float(s) / float(radial_segments), accumulated / maxf(radius, 0.001)))
			st.add_vertex(vertex)
			ring.append([vertex_count, vertex])
			vertex_count += 1
		ring_data.append(ring)

	for i in range(points.size() - 1):
		for s in range(radial_segments):
			var a: int = ring_data[i][s][0]
			var b: int = ring_data[i][s + 1][0]
			var c: int = ring_data[i + 1][s][0]
			var d: int = ring_data[i + 1][s + 1][0]
			st.add_index(a)
			st.add_index(c)
			st.add_index(d)
			st.add_index(a)
			st.add_index(d)
			st.add_index(b)

	if caps:
		_add_cap(st, ring_data[0], tangents[0], true, vertex_count)
		_add_cap(st, ring_data[points.size() - 1], tangents[points.size() - 1], false, vertex_count)
	return st.commit()


static func _add_cap(st: SurfaceTool, ring: Array, tangent: Vector3, start: bool, vertex_count: int) -> void:
	var center := Vector3.ZERO
	for entry: Array in ring:
		center += entry[1]
	center /= float(ring.size())
	st.set_normal(-tangent if start else tangent)
	st.add_vertex(center)
	var center_index := vertex_count
	for s in range(ring.size() - 1):
		var first: int = ring[s][0]
		var second: int = ring[s + 1][0]
		if start:
			st.add_index(center_index)
			st.add_index(first)
			st.add_index(second)
		else:
			st.add_index(center_index)
			st.add_index(second)
			st.add_index(first)


## Sólido de revolução a partir de um perfil (raio, altura) — copos, difusores, bacias.
## O perfil vai do fundo (menor y) para o topo.
static func lathe(profile: PackedVector2Array, radial_segments: int = 20, cap_bottom := true) -> ArrayMesh:
	if profile.size() < 2:
		return ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile_normals: Array[Vector2] = []
	for p in range(profile.size()):
		var incoming := Vector2.ZERO
		var outgoing := Vector2.ZERO
		if p > 0:
			incoming = (profile[p] - profile[p - 1]).normalized()
		if p < profile.size() - 1:
			outgoing = (profile[p + 1] - profile[p]).normalized()
		var slope := (incoming + outgoing).normalized() if incoming.length_squared() > 0.0 else outgoing
		if slope.length_squared() < 0.5:
			slope = Vector2.UP
		# Perpendicular externa ao perfil (raio, altura), apontando para fora do eixo.
		var outward := Vector2(slope.y, -slope.x)
		if outward.x < 0.0:
			outward = -outward
		profile_normals.append(outward.normalized())
	for s in range(radial_segments + 1):
		var angle := TAU * float(s) / float(radial_segments)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		for p in range(profile.size()):
			var point := profile[p]
			var normal2 := profile_normals[p]
			st.set_normal(Vector3(normal2.x * direction.x, normal2.y, normal2.x * direction.z))
			st.set_uv(Vector2(float(s) / float(radial_segments), float(p) / float(profile.size() - 1)))
			st.add_vertex(Vector3(point.x * direction.x, point.y, point.x * direction.z))
	for s in range(radial_segments):
		for p in range(profile.size() - 1):
			var current := p * (radial_segments + 1) + s
			var below := (p + 1) * (radial_segments + 1) + s
			st.add_index(current)
			st.add_index(current + 1)
			st.add_index(below)
			st.add_index(current + 1)
			st.add_index(below + 1)
			st.add_index(below)
	if cap_bottom:
		var center_index: int = (radial_segments + 1) * profile.size()
		st.set_normal(Vector3.DOWN)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(Vector3(0.0, profile[0].y, 0.0))
		for s in range(radial_segments):
			st.add_index(center_index)
			st.add_index(s)
			st.add_index(s + 1)
	return st.commit()
