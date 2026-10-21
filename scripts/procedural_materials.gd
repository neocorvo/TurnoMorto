class_name ProceduralMaterials
extends Object

## Fábrica de materiais hospitalares com texturas procedurais nativas
## (NoiseTexture2D usada como normal map e roughness map).
## Nenhuma dependência externa: tudo é gerado em runtime pelo Godot.


static var _texture_cache: Dictionary = {}


static func _noise_texture(seed_value: int, frequency: float, octaves: int, bump_strength: float, seamless := true, size := 256) -> NoiseTexture2D:
	var key := "%d|%.4f|%d|%.2f|%s|%d" % [seed_value, frequency, octaves, bump_strength, seamless, size]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	var texture := NoiseTexture2D.new()
	texture.noise = noise
	texture.width = size
	texture.height = size
	texture.seamless = seamless
	texture.generate_mipmaps = true
	texture.bump_strength = bump_strength
	_texture_cache[key] = texture
	return texture


static func _roughness_texture(seed_value: int, frequency: float, octaves: int, low := 0.68, high := 1.0) -> NoiseTexture2D:
	var texture := _noise_texture(seed_value, frequency, octaves, 0.0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(low, low, low))
	ramp.set_color(1, Color(high, high, high))
	texture.color_ramp = ramp
	return texture


static func _base(albedo: Color, roughness: float, metallic := 0.0, name := "") -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = roughness
	material.metallic = metallic
	material.resource_name = name
	return material


static func _apply_surface(material: StandardMaterial3D, normal_texture: Texture2D, normal_scale: float, rough_texture: Texture2D, uv_scale: Vector3) -> StandardMaterial3D:
	if normal_texture != null:
		material.normal_enabled = true
		material.normal_texture = normal_texture
		material.normal_scale = normal_scale
	if rough_texture != null:
		material.roughness_texture = rough_texture
	material.uv1_triplanar = true
	material.uv1_scale = uv_scale
	return material


## Pintura de parede: micro-ondulação sutil e brilho irregular.
static func paint(albedo: Color, uv_scale := 0.45) -> StandardMaterial3D:
	var material := _base(albedo, 0.92, 0.0, "paint")
	return _apply_surface(
		material,
		_noise_texture(11, 0.30, 3, 0.55),
		0.28,
		_roughness_texture(12, 0.055, 2),
		Vector3.ONE * uv_scale
	)


## Piso com textura PBR externa (Poly Haven, CC0): albedo + normal OpenGL +
## mapa ARM empacotado (AO no vermelho, roughness no verde, metal no azul).
## A variação de brilho de baixa frequência continua procedural.
static func external_pbr_floor(diffuse_path: String, normal_path: String, orm_path: String, tint: Color, uv_scale: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = load(diffuse_path)
	material.normal_enabled = true
	material.normal_texture = load(normal_path)
	material.normal_scale = 0.8
	var orm: Texture2D = load(orm_path)
	material.ao_enabled = true
	material.ao_texture = orm
	material.ao_light_affect = 0.6
	material.roughness = 1.0
	material.roughness_texture = orm
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic = 1.0
	material.metallic_texture = orm
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * uv_scale
	material.resource_name = "external_pbr_floor"
	return material


## Piso de resina hospitalar: superfície contínua e lavável, com grão
## "laranja-casca" finíssimo, manchas de brilho suaves e variação tonal
## de baixíssimo contraste — fria e discreta, sem padrão que dispute atenção.
static func resin_floor(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.55, 0.0, "resin_floor")
	var tonal := _noise_texture(23, 0.012, 2, 0.0)
	var tonal_ramp := Gradient.new()
	tonal_ramp.set_color(0, Color(0.9, 0.9, 0.9))
	tonal_ramp.set_color(1, Color.WHITE)
	tonal.color_ramp = tonal_ramp
	material.albedo_texture = tonal
	return _apply_surface(
		material,
		_noise_texture(21, 0.85, 2, 0.45),
		0.14,
		_roughness_texture(22, 0.02, 2, 0.7, 1.0),
		Vector3.ONE * 0.35
	)


## Azulejo de meia-parede: juntas mais marcadas e superfície mais vidrada.
static func tile_wall(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.42, 0.0, "tile_wall")
	return _apply_surface(
		material,
		_noise_texture(31, 0.024, 1, 1.45),
		0.95,
		_roughness_texture(32, 0.010, 2, 0.42, 0.9),
		Vector3.ONE * 1.15
	)


## Teto modular: placas com textura fina de fibra.
static func ceiling_panel(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.96, 0.0, "ceiling")
	return _apply_surface(
		material,
		_noise_texture(41, 0.22, 3, 0.4),
		0.32,
		_roughness_texture(42, 0.03, 2, 0.85, 1.0),
		Vector3.ONE * 0.8
	)


## Aço escovado: linhas finas e reflexo irregular.
static func steel(albedo: Color, metallic := 0.88, roughness := 0.45) -> StandardMaterial3D:
	var material := _base(albedo, roughness, metallic, "steel")
	return _apply_surface(
		material,
		_noise_texture(51, 0.55, 2, 0.30),
		0.22,
		_roughness_texture(52, 0.30, 2, 0.6, 1.15),
		Vector3.ONE * 0.35
	)


## Metal pintado (esmalte hospitalar): gabinetes, portas, bancadas.
static func painted_metal(albedo: Color, metallic := 0.3, roughness := 0.52) -> StandardMaterial3D:
	var material := _base(albedo, roughness, metallic, "painted_metal")
	return _apply_surface(
		material,
		_noise_texture(61, 0.16, 3, 0.5),
		0.35,
		_roughness_texture(62, 0.045, 2, 0.7, 1.05),
		Vector3.ONE * 0.55
	)


static func plastic(albedo: Color, roughness := 0.7) -> StandardMaterial3D:
	var material := _base(albedo, roughness, 0.0, "plastic")
	return _apply_surface(
		material,
		_noise_texture(71, 0.4, 2, 0.25),
		0.18,
		_roughness_texture(72, 0.12, 2, 0.8, 1.1),
		Vector3.ONE * 0.6
	)


static func rubber(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.97, 0.0, "rubber")
	return _apply_surface(
		material,
		_noise_texture(81, 0.5, 3, 0.5),
		0.4,
		null,
		Vector3.ONE * 0.5
	)


static func fabric(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.95, 0.0, "fabric")
	return _apply_surface(
		material,
		_noise_texture(91, 0.42, 3, 0.65),
		0.55,
		null,
		Vector3.ONE * 0.85
	)


static func mattress(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.78, 0.0, "mattress")
	return _apply_surface(
		material,
		_noise_texture(101, 0.09, 2, 0.5),
		0.45,
		_roughness_texture(102, 0.06, 2, 0.75, 1.0),
		Vector3.ONE * 0.7
	)


## Lençol: tecido claro com vincos sutis. Faces internas visíveis.
static func sheet(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.94, 0.0, "sheet")
	material.cull_mode = BaseMaterial3D.CULL_BACK
	return _apply_surface(
		material,
		_noise_texture(91, 0.42, 3, 0.5),
		0.4,
		null,
		Vector3.ONE * 0.9
	)


static func paper(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.9, 0.0, "paper")
	return _apply_surface(
		material,
		_noise_texture(111, 0.8, 2, 0.3),
		0.25,
		null,
		Vector3.ONE * 1.4
	)


static func ceramic(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.35, 0.0, "ceramic")
	return _apply_surface(
		material,
		_noise_texture(121, 0.3, 2, 0.2),
		0.12,
		_roughness_texture(122, 0.08, 2, 0.75, 1.1),
		Vector3.ONE * 0.8
	)


static func wood(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.68, 0.0, "wood")
	return _apply_surface(
		material,
		_noise_texture(131, 0.35, 3, 0.4),
		0.3,
		_roughness_texture(132, 0.09, 2, 0.8, 1.1),
		Vector3.ONE * 0.7
	)


static func glass(albedo: Color) -> StandardMaterial3D:
	var material := _base(albedo, 0.18, 0.55, "glass")
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.42
	return material


## Tela de equipamento: emissão fraca esverdeada.
static func screen(emission_color: Color, energy := 1.15) -> StandardMaterial3D:
	var material := _base(Color(0.03, 0.06, 0.055), 0.42, 0.1, "screen")
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = energy
	return material


## Difusor de luz fluorescente: emissão forte para alimentar o glow.
static func light_panel(emission_color: Color, energy := 1.9) -> StandardMaterial3D:
	var material := _base(Color(0.55, 0.62, 0.6), 0.4, 0.0, "light_panel")
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = energy
	return material


## Superfície de aviso (pisca-pisca de emergência é animado no RoomAtmosphere).
static func warning_light(emission_color: Color, energy := 1.3) -> StandardMaterial3D:
	var material := _base(Color(0.2, 0.04, 0.03), 0.6, 0.0, "warning_light")
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = energy
	return material
