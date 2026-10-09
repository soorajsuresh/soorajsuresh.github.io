package sitegen

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

DEBUG: bool = true

pages: [dynamic]Page
directories: [dynamic]Directory


main_style: string : "/assets/css/main.css"

main :: proc() {
	defer free_memory()

	content_directory_path: string : "../content"
	generated_directory_path: string : "../generated"

	root_directory := Directory {
		name           = "content",
		content_path   = content_directory_path,
		generated_path = generated_directory_path,
	}

	append(&directories, root_directory)
	create_subdirectories_in_directory_with_ID(Directory_ID(0))
	create_pages()

	debug_print_directories()
	debug_print_pages()

	for &page in pages {
		generate_from_page(&page)
	}
}

generate_from_directory :: proc(directory_index: Directory_ID) {
	directory := &directories[directory_index]
	generated_directory_path := directory.generated_path
	os.make_directory(generated_directory_path)
}

generate_from_page :: proc(page: ^Page) {
	input_path := page.content_path
	output_path := page.generated_path

	data, error := os.read_entire_file(input_path, context.allocator)
	if error != nil {
		fmt.println("Error:", error, "while reading file at", input_path)
		return
	}

	html_string_builder := strings.builder_make()
	js_string_builder := strings.builder_make()

	strings.write_string(&html_string_builder, "<!DOCTYPE html>\n")
	strings.write_string(&html_string_builder, "<html>\n")

	// head
	strings.write_string(&html_string_builder, "\t<head>\n")

	// title
	if page.front_matter.title == "" {
		strings.write_string(
			&html_string_builder,
			fmt.aprintf("\t\t<title>%s</title>\n", page.name),
		)
	} else {
		strings.write_string(
			&html_string_builder,
			fmt.aprintf("\t\t<title>%s</title>\n", page.front_matter.title),
		)
	}

	// main style
	style_info: os.File_Info
	style_info, error = os.stat("../assets/css/main.css", context.allocator)
	if error != nil {
		fmt.println("Error:", error, "while getting file info for", main_style)
		return
	}
	style_version := style_info.modification_time
	strings.write_string(
		&html_string_builder,
		fmt.aprintf("\t\t<link rel=\"stylesheet\" href=\"%s?v=%d\">\n", main_style, style_version),
	)

	// layout
	switch page.front_matter.layout {
	case Layout.Chapter:
		strings.write_string(
			&html_string_builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/chapter.css\">\n",
		)
	case Layout.Section:
		append(&page.front_matter.libs, Lib.KaTeX)
		strings.write_string(
			&html_string_builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/section.css\">\n",
		)
		strings.write_string(
			&html_string_builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/math.css\">\n",
		)
	}

	//libraries
	for lib in page.front_matter.libs {

		// include katex
		if lib == Lib.KaTeX {
			strings.write_string(
				&html_string_builder,
				"\t\t<link rel=\"stylesheet\" href=\"/assets/katex/katex.min.css\">\n",
			)
			strings.write_string(
				&html_string_builder,
				"\t\t<script defer src=\"/assets/katex/katex.min.js\"></script>\n",
			)
			strings.write_string(
				&html_string_builder,
				"\t\t<script defer src=\"/assets/katex/contrib/auto-render.min.js\"></script>\n",
			)

			// js
			include_katex: []byte
			include_katex, error = os.read_entire_file(
				"../assets/include-katex.js",
				context.allocator,
			)
			if error != nil {
				fmt.println("Error:", error, "while reading file at", "../assets/include-katex.js")
				return
			}
			katex_js_string := string(include_katex)

			// katex macros
			if len(page.front_matter.katex_macros) > 0 {
				data: []byte
				error: json.Marshal_Error
				data, error = json.marshal(page.front_matter.katex_macros)
				if error != nil {
					fmt.println(
						"Error:",
						error,
						"while JSON marshalling front_matter.katex_macros of",
						page.name,
					)
					return
				}
				katex_js_string, _ = strings.replace(
					katex_js_string,
					"\"__KATEX_MACROS__\"",
					string(data),
					1,
				)
			}

			strings.write_string(&js_string_builder, katex_js_string)
		}
	}

	// load .js
	strings.write_string(
		&html_string_builder,
		fmt.aprintf("\t\t<script src=\"%s.js\"></script>\n", page.name),
	)

	strings.write_string(&html_string_builder, "\t</head>\n")

	// body
	strings.write_string(&html_string_builder, "\t<body>\n")

	// automatic h1
	strings.write_string(
		&html_string_builder,
		fmt.aprintf("\t\t<h1>%s</h1>\n", page.front_matter.title),
	)

	// description
	strings.write_string(
		&html_string_builder,
		fmt.aprintf("\t\t<p>%s</p>\n", page.front_matter.description),
	)

	// links to subdirectories
	directory := page.directory

	folder: ^os.File
	folder, error = os.open(directory.content_path)
	if error != nil {
		fmt.println("Error:", error, "while opening", directory.content_path)
		return
	}

	items: []os.File_Info
	items, error = os.read_dir(folder, 0, context.allocator)
	if error != nil {
		fmt.println("Error:", error, "while reading directory", folder)
		return
	}
	os.close(folder)

	for subdirectory_index in directory.subdirectory_IDs {
		subdirectory := directories[subdirectory_index]

		// display subdirectories as h2
		h2: string = subdirectory.name
		strings.write_string(
			&html_string_builder,
			fmt.aprintf("\t\t<h2>%s</h2>\n", title_from_kebab(h2)),
		)
		/*subdirectory_url := url_from_path(subdirectory.generated_path)
		strings.write_string(
			&html_string_builder,
			fmt.aprintf(
				"\t\t\t\t<a href=\"%s\">\n" +
				"\t\t\t\t\t<span>%s</span>\n" +
				"\t\t\t\t\t<p>%s</p>\n" +
				"\t\t\t\t</a>\n",//"\t\t\t<li class=\"subdirectory\">\n" +
				subdirectory_url, //"\t\t\t</li>\n",
				title_from_kebab(subdirectory.name),
				pages[subdirectory.index_page_ID].front_matter.description,
			),
		)*/

		// display subsubdirectories as tiles
		building_list: bool = false
		for subsubdirectory_index in subdirectory.subdirectory_IDs {
			subsubdirectory := directories[subsubdirectory_index]

			if !building_list {
				strings.write_string(
					&html_string_builder,
					"\t\t<ul class=\"subsubdirectories\">\n",
				)
				building_list = true
			}

			if building_list {
				url := url_from_path(subsubdirectory.generated_path)
				strings.write_string(
					&html_string_builder,
					fmt.aprintf(
						"\t\t\t<li class=\"subsubdirectory\">\n" + "\t\t\t\t<a href=\"%s\">\n",
						url,
					),
				)

				// background video for tile
				if pages[subsubdirectory.index_page_ID].front_matter.video != "" {
					strings.write_string(
						&html_string_builder,
						fmt.aprintf(
							"\t\t\t\t\t<video autoplay muted loop playsinline>\n" +
							"\t\t\t\t\t\t<source src=\"/assets/videos/%s\" type=\"video/mp4\">\n" +
							"\t\t\t\t\t</video>\n",
							pages[subsubdirectory.index_page_ID].front_matter.video,
						),
					)
				}

				strings.write_string(
					&html_string_builder,
					fmt.aprintf(
						"\t\t\t\t\t<span>%s</span>\n" +
						"\t\t\t\t\t<p>%s</p>\n" +
						"\t\t\t\t</a>\n" +
						"\t\t\t</li>\n",
						title_from_kebab(subsubdirectory.name),
						pages[subsubdirectory.index_page_ID].front_matter.description,
					),
				)
			}
			debug(pages[subsubdirectory.index_page_ID])
			debug(pages[subsubdirectory.index_page_ID].front_matter)
			debug(pages[subsubdirectory.index_page_ID].front_matter.description)
		}

		// .md files within subdirectory different from index
		for page_ID in subdirectory.page_IDs {
			page := pages[page_ID]

			if page_ID == subdirectory.index_page_ID {
				continue
			}

			if !building_list {
				strings.write_string(&html_string_builder, "\t\t<ul>\n")
				building_list = true
			}

			url := url_from_path(page.generated_path)
			strings.write_string(
				&html_string_builder,
				fmt.aprintf(
					"\t\t\t<li><a href=\"%s\">%s</a></li>\n",
					url,
					title_from_kebab(page.name),
				),
			)
		}

		if building_list {
			strings.write_string(&html_string_builder, "\t\t</ul>\n")
		}
	}

	// manual body
	strings.write_string(&html_string_builder, markdown_to_html(page.markdown))
	strings.write_string(&html_string_builder, "\t</body>\n")
	strings.write_string(&html_string_builder, "</html>\n")

	// generate .js file
	js_output_path, _ := strings.replace(output_path, ".html", ".js", 1)
	output := strings.to_string(js_string_builder)
	error = os.write_entire_file_from_string(js_output_path, output)
	if error != nil {
		fmt.println("Error:", error, "while writing file at", output_path)
		return
	}

	// generate .html file
	output = strings.to_string(html_string_builder)
	error = os.write_entire_file_from_string(output_path, output)
	if error != nil {
		fmt.println("Error:", error, "while writing file at", output_path)
		return
	}
}

create_subdirectories_in_directory_with_ID :: proc(directory_id: Directory_ID) {
	directory := &directories[directory_id]
	directory_content_path := directory.content_path
	directory_generated_path := directory.generated_path

	folder: ^os.File
	error: os.Error
	folder, error = os.open(directory_content_path)
	if error != nil {
		fmt.println("Error:", error, "while opening folder at", directory_content_path)
		return
	}

	items: []os.File_Info
	items, error = os.read_dir(folder, 0, context.allocator)
	if error != nil {
		return
	}
	os.close(folder)

	// create subdirectories
	for item in items {
		if item.type == os.File_Type.Directory {
			debug("Found subdirectory:", item.name)
			subdirectory_index := subdirectory_create_in_directory_with_id(directory_id, item)
			generate_from_directory(subdirectory_index)
			create_subdirectories_in_directory_with_ID(subdirectory_index)
		}
	}

	directory = &directories[directory_id]
	debug("Subdirectories created in", directory.name, ":")
	for subdirectory_index in directory.subdirectory_IDs {
		debug("	- ", directories[subdirectory_index].name)
	}
	debug()
}

subdirectory_create_in_directory_with_id :: proc(
	directory_id: Directory_ID,
	subdirectory_file_info: os.File_Info,
) -> Directory_ID {
	directory := &directories[directory_id]
	directory_content_path := directory.content_path
	directory_generated_path := directory.generated_path
	subdirectory_content_path := fmt.aprintf(
		"%s/%s",
		directory_content_path,
		subdirectory_file_info.name,
	)
	subdirectory_generated_path := fmt.aprintf(
		"%s/%s",
		directory_generated_path,
		subdirectory_file_info.name,
	)
	subdirectory := Directory {
		name           = subdirectory_file_info.name,
		content_path   = subdirectory_content_path,
		generated_path = subdirectory_generated_path,
	}

	debug("Creating Subdirectory in:", directory.name)
	debug("name:", subdirectory.name)
	debug("content_path:", subdirectory.content_path)
	debug("generated_path:", subdirectory.generated_path)
	debug()

	subdirectory_index := Directory_ID(len(directories))
	append(&directories, subdirectory)
	append(&directories[directory_id].subdirectory_IDs, subdirectory_index)

	return subdirectory_index
}

// searches directories for .md files and creates corresponding pages
create_pages :: proc() {
	debug("Creating pages!")

	for &directory in directories {
		debug("In directory:", directory.name)

		error: os.Error
		folder: ^os.File

		folder, error = os.open(directory.content_path)
		if error != nil {
			fmt.println("Error:", error, "while opening folder at", directory.content_path)
			return
		}

		items: []os.File_Info
		items, error = os.read_dir(folder, 0, context.allocator)
		if error != nil {
			fmt.println("Error:", error, "while reading directory", folder)
			return
		}

		// search for index.md
		debug("Looking for index.md!")
		found_index: bool = false
		for item in items {
			if item.type == os.File_Type.Regular {
				if strings.has_suffix(item.name, "index.md") {
					debug("Found index.md!")
					found_index = true
				}
			}
		}

		if !found_index {
			debug("Missing index.md!")
			front_matter_text := fmt.aprintf(
				"---\ntitle: %s\n---",
				title_from_kebab(directory.name),
			)
			debug("Creating index.md!")
			error = os.write_entire_file_from_string(
				fmt.aprintf("%s%s", directory.content_path, "/index.md"),
				front_matter_text,
			)
			if error != nil {
				fmt.println(
					"Error:",
					error,
					"while writing to",
					directory.content_path,
					"/index.md",
				)
				return
			}
			debug("Created index.md!")
		}

		// create pages
		debug("Looking for .md files!")
		for item in items {
			if item.type == os.File_Type.Regular {
				if strings.has_suffix(item.name, ".md") {
					debug("Found .md file! Creating Page!")
					page_create(&directory, item, directory.content_path, directory.generated_path)
				}
			}
		}
	}
}

page_create :: proc(
	directory: ^Directory,
	item: os.File_Info,
	content_path: string,
	generated_path: string,
) {
	content_file_path := fmt.aprintf("%s/%s", content_path, item.name)
	page_name := strings.trim_suffix(item.name, ".md")
	generated_file_path := fmt.aprintf("%s/%s.html", generated_path, page_name)

	data, error := os.read_entire_file(content_file_path, context.allocator)
	if error != nil {
		fmt.println("Error:", error, "while reading file at", content_file_path)
		return
	}

	front_matter, markdown := parse_front_matter(string(data))

	page := Page {
		directory      = directory,
		name           = page_name,
		content_path   = item.fullpath,
		generated_path = generated_file_path,
		front_matter   = front_matter,
		markdown       = markdown,
	}

	debug("Created Page:")
	debug("directory:", page.directory.name)
	debug("name:", page.name)
	debug("content_path:", page.content_path)
	debug("generated_path:", page.generated_path)
	debug("front_matter:", page.front_matter)
	debug("markdown:", page.markdown)
	debug()

	page_index := Page_ID(len(pages))
	append(&pages, page)
	append(&directory.page_IDs, page_index)
	if page.name == "index" {
		directory.index_page_ID = page_index
	}
}

// TODO: don't capitalize certain words (e.g. "of")
title_from_kebab :: proc(input: string) -> string {
	parts := strings.split(input, "-")
	builder := strings.builder_make()
	for part, i in parts {
		if i > 0 {
			strings.write_string(&builder, " ")
		}
		c := part[0]
		if 'a' <= c && c <= 'z' {
			c = c - 'a' + 'A'
		}
		strings.write_string(&builder, fmt.aprintf("%c%s", c, part[1:]))
	}
	return strings.to_string(builder)
}

url_from_path :: proc(path: string) -> string {
	return strings.trim_prefix(path, "..")
}

free_memory :: proc() {
	for directory in directories {
		delete(directory.subdirectory_IDs)
		delete(directory.page_IDs)
	}
	for page in pages {
		delete(page.front_matter.libs)
		delete(page.front_matter.katex_macros)
	}
}

debug :: proc(args: ..any) {
	if DEBUG {fmt.println(..args)}
}

debug_print_directories :: proc() {

	debug("Directories:")
	debug()

	for &directory in directories {
		debug("Directory:", directory.name)

		debug("Pages inside:")
		for page_index in directory.page_IDs {
			page := pages[Page_ID(page_index)]
			debug("	", page.name)
		}

		debug("Subdirectories inside:")
		for subdirectory_index in directory.subdirectory_IDs {
			debug("	- ", directories[subdirectory_index].name)
		}
		debug()
	}
}

debug_print_pages :: proc() {
	debug()
	debug("Pages:")
	for page in pages {
		debug(page.directory.name, "->", page.name)
		debug("description:", page.front_matter.description)
	}
	debug()
}
