package sitegen

import "core:flags/example"
import "core:fmt"
import "core:os"
import "core:strings"

DEBUG: bool = true

pages: [dynamic]Page
directories: [dynamic]Directory

content_directory_path: string : "../content"
generated_directory_path: string : "../generated"
main_style: string : "/assets/css/main.css"

root_directory := Directory {
	name           = "content",
	content_path   = content_directory_path,
	generated_path = generated_directory_path,
}

main :: proc() {
	append(&directories, root_directory)
	create_directories_in(&directories[0])
	create_pages()

	if DEBUG {
		fmt.println("Directories:")
		fmt.println()

		for &directory in directories {
			fmt.println("Directory:", directory.name)

			fmt.println("Pages inside:")
			for page_index in directory.page_indices {
				page := pages[Page_ID(page_index)]
				fmt.println("	", page.name)
			}

			fmt.println("Subdirectories inside:")
			for subdirectory_index in directory.subdirectory_indices {
				fmt.println("	- ", directories[subdirectory_index].name)
			}
			fmt.println()
		}
	}

	if DEBUG {
		fmt.println()
		fmt.println("Pages:")
		for page in pages {
			fmt.println(page.directory.name, "->", page.name)
		}
		fmt.println()
	}

	for &page in pages {
		generate_html_file_from_page(&page)
	}
}

generate_html_file_from_page :: proc(page: ^Page) {
	input_path := page.content_path
	output_path := page.generated_path

	data, error := os.read_entire_file(input_path, context.allocator)
	if error != nil {
		fmt.println("Error:", error, "while reading file at", input_path)
		return
	}

	builder := strings.builder_make()
	strings.write_string(&builder, "<!DOCTYPE html>\n")
	strings.write_string(&builder, "<html>\n")

	// head
	strings.write_string(&builder, "\t<head>\n")

	// title
	if page.front_matter.title == "" {
		strings.write_string(&builder, fmt.aprintf("\t\t<title>%s</title>\n", page.name))
	} else {
		strings.write_string(
			&builder,
			fmt.aprintf("\t\t<title>%s</title>\n", page.front_matter.title),
		)
	}

	// main style
	strings.write_string(
		&builder,
		fmt.aprintf("\t\t<link rel=\"stylesheet\" href=\"%s\">\n", main_style),
	)

	// layout
	switch page.front_matter.layout {
	case "chapter":
		strings.write_string(
			&builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/chapter.css\">\n",
		)
	case "section":
		strings.write_string(
			&builder,
			"\t\t<link rel=\"stylesheet\" href=\"/assets/section.css\">\n",
		)
		strings.write_string(&builder, "\t\t<link rel=\"stylesheet\" href=\"/assets/math.css\">\n")
	}

	//libraries
	for lib in page.front_matter.libs {

		// include katex
		if lib == "katex" {
			strings.write_string(
				&builder,
				"\t\t<link rel=\"stylesheet\" href=\"/assets/katex/katex.min.css\">\n",
			)
			strings.write_string(
				&builder,
				"\t\t<script defer src=\"/assets/katex/katex.min.js\"></script>\n",
			)
			strings.write_string(
				&builder,
				"\t\t<script defer src=\"/assets/katex/contrib/auto-render.min.js\"></script>\n",
			)
			strings.write_string(
				&builder,
				"\t\t<script src=\"/assets/include-katex.js\"></script>\n",
			)
		}
	}

	strings.write_string(&builder, "\t</head>\n")

	// body
	strings.write_string(&builder, "\t<body>\n")

	// automatic h1
	strings.write_string(&builder, fmt.aprintf("\t\t<h1>%s</h1>\n", page.front_matter.title))

	// automatic body for index.md linking to subdirectories
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

	for subdirectory_index in directory.subdirectory_indices {
		subdirectory := directories[subdirectory_index]

		h2: string = subdirectory.name
		strings.write_string(&builder, fmt.aprintf("\t\t<h2>%s</h2>\n", title_from_kebab(h2)))

		building_list: bool = false
		for subsubdirectory_index in subdirectory.subdirectory_indices {
			subsubdirectory := directories[subsubdirectory_index]

			if !building_list {
				strings.write_string(&builder, "\t\t<ul>\n")
				building_list = true
			}

			if building_list {
				link := subsubdirectory.generated_path
				strings.write_string(
					&builder,
					fmt.aprintf(
						"\t\t\t<li><a href=\"%s\">%s</a></li>\n",
						link,
						title_from_kebab(subsubdirectory.name),
					),
				)
			}
		}

		if building_list {
			strings.write_string(&builder, "\t\t</ul>\n")
		}
	}

	// manual body
	strings.write_string(&builder, markdown_to_html(page.markdown))
	strings.write_string(&builder, "\t</body>\n")
	strings.write_string(&builder, "</html>\n")

	// generate .html file
	output := strings.to_string(builder)
	error = os.write_entire_file_from_string(output_path, output)
	if error != nil {
		fmt.println("Error:", error, "while writing file at", output_path)
		return
	}
}

create_directories_in :: proc(directory: ^Directory) {
	content_path := directory.content_path
	generated_path := directory.generated_path

	error: os.Error
	folder: ^os.File
	folder, error = os.open(content_path)
	if error != nil {
		fmt.println("Error:", error, "while opening folder at", content_path)
		return
	}

	items: []os.File_Info
	items, error = os.read_dir(folder, 0, context.allocator)
	if error != nil {
		return
	}
	os.close(folder)

	// create directories and missing index.md files
	for item in items {
		if item.type == os.File_Type.Directory {
			if DEBUG {fmt.println("Found directory:", item.name)}
			content_directory_path := fmt.aprintf("%s/%s", content_path, item.name)
			generated_directory_path := fmt.aprintf("%s/%s", generated_path, item.name)
			if DEBUG {fmt.println("content_directory_path:", content_directory_path)}
			if DEBUG {fmt.println("generated_directory_path:", generated_directory_path)}

			subdirectory := Directory {
				name           = item.name,
				content_path   = content_directory_path,
				generated_path = generated_directory_path,
			}

			if DEBUG {
				fmt.println("Creating Directory in:", directory.name)
				fmt.println("name:", subdirectory.name)
				fmt.println("content_path:", subdirectory.content_path)
				fmt.println("generated_path:", subdirectory.generated_path)
				fmt.println()
			}

			subdirectory_index := Directory_ID(len(directories))
			append(&directories, subdirectory)
			append(&directory.subdirectory_indices, subdirectory_index)

			// look for missing index.md
			folder, error = os.open(content_directory_path)
			if error != nil {
				fmt.println("Error:", error, "while opening folder at", content_directory_path)
				return
			}

			items: []os.File_Info
			items, error = os.read_dir(folder, 0, context.allocator)
			if error != nil {
				return
			}
			os.close(folder)

			// use Page?
			found_index: bool = false
			for item in items {
				if item.type == os.File_Type.Regular {
					if strings.has_suffix(item.name, "index.md") {
						found_index = true
					}
				}
			}

			// create missing index.md
			if !found_index {
				if DEBUG {fmt.println("Missing index.md!")}
				front_matter_text := fmt.aprintf(
					"---\ntitle: %s\n---",
					title_from_kebab(item.name),
				)
				error = os.write_entire_file_from_string(
					fmt.aprintf("%s%s", item.fullpath, "/index.md"),
					front_matter_text,
				)
				if error != nil {
					fmt.println("Error:", error, "while writing to", item.fullpath, "/index.md")
					return
				}
			}

			os.make_directory(generated_directory_path)

			create_directories_in(&directories[subdirectory_index])
		}
	}

	if DEBUG {
		fmt.println("Subdirectories created in:", directory.name)
		for subdirectory_index in directory.subdirectory_indices {
			fmt.println("	- ", directories[subdirectory_index].name)
		}
		fmt.println()
	}
}

create_pages :: proc() {

	if DEBUG {fmt.println("Creating pages!")}

	// pages in directories
	for &directory in directories {
		if DEBUG {fmt.println("In directory:", directory.name)}

		// look for .md files
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

		for item in items {
			if item.type == os.File_Type.Regular {
				if strings.has_suffix(item.name, ".md") {
					if DEBUG {fmt.println("Found .md file!")}
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

	if DEBUG {
		fmt.println("Created Page:")
		fmt.println("directory:", page.directory.name)
		fmt.println("name:", page.name)
		fmt.println("content_path:", page.content_path)
		fmt.println("generated_path:", page.generated_path)
		fmt.println("front_matter:", page.front_matter)
		fmt.println("markdown:", page.markdown)
		fmt.println()
	}

	page_index := Page_ID(len(pages))
	append(&pages, page)
	append(&directory.page_indices, page_index)
}

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
