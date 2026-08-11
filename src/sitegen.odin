package sitegen

Directory :: struct {
	name:           string,
	content_path:   string,
	generated_path: string,
	pages:          [dynamic]Page,
}

Page :: struct {
	directory:      ^Directory,
	name:           string,
	content_path:   string,
	generated_path: string,
	front_matter:   Front_Matter,
	markdown:       string,
}
