package sitegen

Directory_ID :: distinct int
Page_ID :: distinct int

NO_DIRECTORY :: Directory_ID(-1)

Directory :: struct {
	name:                string,
	content_path:        string,
	generated_path:      string,
	parent_directory_ID: Directory_ID,
	subdirectory_IDs:    [dynamic]Directory_ID,
	page_IDs:            [dynamic]Page_ID,
	index_page_ID:       Page_ID,
}

// TODO: Should directory just be an ID?
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
	description:  string,
	video:        string,
	layout:       Layout,
	chapter:      string,
	section:      string,
	libs:         [dynamic]Lib,
	katex_macros: map[string]string,
}
