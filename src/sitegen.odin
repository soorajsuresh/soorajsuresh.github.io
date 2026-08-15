package sitegen

Directory_ID :: distinct int
Page_ID :: distinct int

Directory :: struct {
	name:                 string,
	content_path:         string,
	generated_path:       string,
	subdirectory_indices: [dynamic]Directory_ID,
	page_indices:         [dynamic]Page_ID,
}

Page :: struct {
	directory:      ^Directory,
	name:           string,
	content_path:   string,
	generated_path: string,
	front_matter:   Front_Matter,
	markdown:       string,
}

Layout :: enum {
	Chapter,
	Section,
}

Lib :: enum {
	KaTeX,
	Three_JS,
}

Front_Matter :: struct {
	title:        string,
	layout:       Layout,
	chapter:      string,
	section:      string,
	libs:         [dynamic]Lib,
	katex_macros: map[string]string,
}
