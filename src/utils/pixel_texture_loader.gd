## Module: pixel_texture_loader.gd
## Loads PNG textures from disk without requiring import artifacts.

extends RefCounted

static func load_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(image)
